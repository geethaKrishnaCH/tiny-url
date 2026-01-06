# Redis TLS with Vault PKI (Layer 4)

This document describes how to secure Redis with TLS using **HashiCorp Vault as a PKI (Certificate Authority)** and how a Spring Boot application trusts Redis using Vault-issued certificates.

This replaces manual OpenSSL-based certificate generation with a **documented, auditable Vault workflow**.

---

## Architecture Overview

```
Vault (PKI / CA)
   |
   | issues certificates
   |
Redis  <── TLS ──>  Spring Boot
```

* Vault is **not** in the runtime data path
* Vault manages **certificate lifecycle only**
* Redis and Spring Boot consume certificates as files

---

## Prerequisites

* Docker and Docker Compose
* Vault CLI installed on the host
* `jq`, `openssl`, `keytool`
* Redis + Spring Boot already working with TLS (Layer 3)

---

## 1. Start Vault with Persistent Storage

Vault is run in non-dev mode with a file-based storage backend.

### Directory Structure

```
vault/
├── config/
│   └── vault.hcl
└── data/
```

### `vault/config/vault.hcl`

```hcl
ui = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
```

### Docker Compose (Vault service)

```yaml
vault:
  image: hashicorp/vault:1.15
  container_name: vault
  ports:
    - "8200:8200"
  volumes:
    - ./vault/config:/vault/config
    - ./vault/data:/vault/data
  cap_add:
    - IPC_LOCK
  command: ["vault", "server", "-config=/vault/config/vault.hcl"]
```

Start Vault:

```bash
docker compose up -d vault
```

---

## 2. Initialize and Unseal Vault

Run on the host machine:

```bash
export VAULT_ADDR=http://localhost:8200
vault operator init
```

Save:

* Unseal keys
* Root token

Unseal Vault (repeat until unsealed):

```bash
vault operator unseal
```

Login:

```bash
vault login <root-token>
```

---

## 3. Enable PKI Secrets Engine
`<PKI_MOUNT_PATH>` for redis pki 
secret engine is `pki-redis`
```bash
vault secrets enable -path=<PKI_MOUNT_PATH> pki
```

Set maximum certificate lifetime:

```bash
vault secrets tune -max-lease-ttl=8760h <PKI_MOUNT_PATH>
```

---

## 4. Generate Root CA (Vault-managed)

Vault becomes the Root Certificate Authority.

```bash
vault write <PKI_MOUNT_PATH>/root/generate/internal \
  common_name="root-ca" \
  ttl=8760h
```

Notes:

* CA private key never leaves Vault
* Vault is now the trust anchor

---

## 5. Export CA Certificate (Public Only)

Redis and Spring Boot must trust the CA.

```bash
vault read -field=certificate <PKI_MOUNT_PATH>/cert/ca \
  > redis/certs/root/ca.crt
```

Verify:

```bash
openssl x509 -in redis/certs/root/ca.crt -text -noout
```

---

## 6. Create PKI Role for Redis

The role defines what kind of certificates are allowed to exist.

```bash
vault write <PKI_MOUNT_PATH>/roles/redis-server \
  allowed_domains="redis,localhost" \
  allow_subdomains=true \
  allow_bare_domains=true \
  allow_ip_sans=true \
  max_ttl="24h"
```

---

## 7. Issue Redis Server Certificate

```bash
vault write -format=json <PKI_MOUNT_PATH>/issue/redis-server \
  common_name="redis" \
  alt_names="localhost" \
  ip_sans="127.0.0.1" \
  > redis-cert.json
```

Extract certificate and key:

```bash
jq -r '.data.certificate' redis-cert.json \
  > redis/certs/redis/redis.crt

jq -r '.data.private_key' redis-cert.json \
  > redis/certs/redis/redis.key

chmod 600 redis/certs/redis/redis.key
```

---

## 8. Create Java Truststore from Vault CA

Spring Boot trusts Redis via the CA.

```bash
keytool -importcert \
  -alias vault-redis-ca \
  -file redis/certs/root/ca.crt \
  -keystore redis/certs/redis-truststore.jks \
  -storepass changeit \
  -noprompt
```

Verify:

```bash
keytool -list -v \
  -keystore redis/certs/redis-truststore.jks \
  -storepass changeit
```

---

## 9. Restart Redis and Application

```bash
docker compose restart redis app
```

---

## 10. Verification

### Redis presents Vault-issued certificate

```bash
openssl s_client -connect redis:6379 -showcerts
```

Expected:

```
Issuer: CN=root-ca
```

### Application behavior

* Spring Boot starts successfully
* Redis operations succeed
* TLS verification is strict
* No hostname verification bypass

---

## Security Model Summary

* Vault is the control plane
* Redis and Spring Boot never talk to Vault
* Certificates are the trust boundary
* Root CA private key never leaves Vault
* Short-lived certs reduce blast radius

---

## What This Enables Next

* Vault Agent (file-based cert delivery)
* Automated certificate rotation
* Kubernetes authentication
* mTLS
* Service meshes (Istio)

---

## Status

✔ Layer 4 complete
➡ Ready for **Layer 5 – Vault Agent**
