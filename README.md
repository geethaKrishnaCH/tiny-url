# Layer 5 – Vault Agent with Docker Compose (Vault + Redis + Spring Boot)

This layer introduces **Vault Agent** into the architecture and demonstrates how a Spring Boot application securely connects to Redis over TLS **without the application or Redis ever talking directly to Vault**.

The focus of this layer is:

* Understanding **why Vault Agent exists**
* Seeing **how secrets and certificates flow** from Vault → filesystem → application
* Running everything locally using **Docker Compose**, while keeping the setup production-realistic

---

## Architecture Overview

We run **four services**, each with a clear responsibility:

| Service         | Responsibility                                          |
| --------------- | ------------------------------------------------------- |
| Vault           | Source of truth (PKI, auth, policies)                   |
| Vault Agent     | Authenticates to Vault and materializes certs as files  |
| Redis           | TLS server using certs written by Vault Agent           |
| Spring Boot App | TLS client that trusts Redis via a generated truststore |

**Key design rule**:

> Redis and the application are completely **Vault-agnostic**. Only Vault Agent talks to Vault.

---

## High-Level Startup Sequence

⚠️ **Order matters in this layer**. Vault bootstrap is intentionally manual to build understanding.

1. Start Vault
2. Initialize and unseal Vault
3. Enable PKI, create policy and AppRole
4. Fetch `role_id` and `secret_id`
5. Start Vault Agent
6. Start Redis
7. Start Spring Boot application

---

## 1. Start Vault

Vault is started **separately** from Docker Compose.

Example (dev mode):

```bash
docker compose start vault
```

Set environment variable:

```bash
export VAULT_ADDR=http://localhost:8200
```

Verify:

```bash
vault status
```

---

## 2. Initialize & Unseal Vault (non-dev mode only)

If running Vault in non-dev mode:

```bash
vault operator init
vault operator unseal
```

(Dev mode skips this step.)

---

## 3. Enable PKI and Create CA

Enable PKI:

```bash
vault secrets enable -path=pki-redis pki
```

Tune max TTL:

```bash
vault secrets tune -max-lease-ttl=8760h pki-redis
```

Generate root CA:

```bash
vault write pki-redis/root/generate/internal \
  common_name="redis-root-ca" \
  ttl=8760h
```

---

## 4. Create PKI Role for Redis

```bash
vault write pki-redis/roles/redis-server \
  allowed_domains="redis,localhost" \
  allow_bare_domains=true \
  allow_subdomains=true \
  allow_ip_sans=true \
  max_ttl="5m"
```

This role controls **what certificates Vault Agent is allowed to issue**.

---

## 5. Create Vault Policy for Vault Agent

Create policy file `agent-certs-policy.hcl`:

```hcl
path "pki-redis/issue/redis-server" {
  capabilities = ["create", "update"]
}

path "pki-redis/cert/ca" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
```

Apply policy:

```bash
vault policy write agent-policy ./vault/agent/policy/agent-certs-policy.hcl
```

---

## 6. Create AppRole

```bash
vault auth enable approle
```

```bash
vault write auth/approle/role/redis-agent \
  policies="agent-policy" \
  token_ttl=10m \
  token_max_ttl=30m \
  secret_id_num_uses=0 \
  secret_id_ttl=1h
```

---

## 7. Fetch role_id and secret_id

```bash
vault read auth/approle/role/redis-agent/role-id
```

```bash
vault write -f auth/approle/role/redis-agent/secret-id
```

Save outputs as files:

```text
echo <ROLE_ID> ./vault/agent/auth/role_id
echo <SECRET_ID> ./vault/agent/auth/secret_id
```

⚠️ secret_id will be deleted once vault-agent starts

⚠️ These files must **not** be committed to source control.

---

## 8. Start Vault Agent

Vault Agent is started via Docker Compose. 

Vault agent config file `vault-agent.hcl`

```text
vault {
  address = "http://vault:8200"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/vault/agent/auth/role_id"
      secret_id_file_path = "/vault/agent/auth/secret_id"
    }
  }

  sink "file" {
    config = {
      path = "/vault/agent/auth/token"
    }
  }
}

template {
  source      = "/vault/agent/templates/hello.tpl"
  destination = "/home/vault/hello.txt"
}

template {
    source      = "/vault/agent/templates/ca.tpl"
    destination = "/home/vault/ca.crt"
}

template {
  source = "/vault/agent/templates/redis.tpl"
  destination = "/home/vault/null"
}
```


It will:

* Authenticate using AppRole
* Fetch CA certificate
* Issue Redis certificate + private key
* Write all material into `/home/vault`

```bash
docker compose up vault-agent
```

Verify:

```bash
docker exec -it vault-agent sh
ls -l home/vault
```

Expected:

* `ca.crt`
* `redis.crt`
* `redis.key`

---

## 9. Start Redis

Redis uses TLS and reads certs from the shared volume:

```bash
docker compose up redis
```

Redis **never talks to Vault**.

---

## 10. Start Spring Boot Application

The application startup script:

* Waits for `ca.crt`
* Generates a JKS truststore using `keytool`
* Starts the JVM

```bash
docker compose up app
```

Spring Boot connects to Redis using TLS with the generated truststore.

---

## Important Design Notes

### Why Vault Agent Exists

* Removes Vault SDK from applications
* Eliminates secret handling in code
* Enables short-lived certs and rotation

### Why AppRole Is Manual Here

* Docker Compose has no identity system
* AppRole provides a generic bootstrap mechanism
* This disappears in Kubernetes (Layer 6)

### Why Startup Order Matters

* Vault must be ready before Vault Agent
* Vault Agent must write certs before Redis
* Truststore must exist before JVM starts

---

## What This Layer Demonstrates

✔ End-to-end TLS using Vault PKI
✔ No secrets in application code
✔ Vault Agent as a sidecar process
✔ Runtime truststore generation
✔ Production-grade separation of concerns

---

## What Comes Next

* Layer 6: Kubernetes (Vault Agent injection)
* Layer 7: Vault Kubernetes auth
* Layer 8: Certificate rotation strategies
* Layer 9: mTLS
* Layer 10: Service mesh integration

---

**Layer 5 is complete.**

This layer is intentionally complex because it builds the mental model required for secure systems. Kubernetes will simplify mechanics — not concepts.
