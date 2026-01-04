# Redis TLS Certificate Generation

This module contains a **bash script** that generates TLS certificates for Redis and a **Java truststore** for Spring Boot.  

This setup corresponds to **Layer 1** of the security learning plan:  

> Redis secured with TLS using manually created certificates  
> (no Vault, no Kubernetes, no automation)  

The objective is to fully understand **TLS, trust chains, SANs, and Java verification rules** before introducing higher-level tools.  

---

## Why this script exists

Manually creating TLS certificates often leads to issues such as:  

- Missing Subject Alternative Names (SAN)  
- Incorrect truststore contents  
- Hostname verification failures  
- Inconsistent setups across environments  

This script provides:  

- A **repeatable** way to generate certificates  
- Correct SAN configuration by default  
- A Java-compatible truststore  
- Clear separation between CA material and server material  

No security shortcuts are taken.  

---

## Directory structure (generated)

After running the script, the following structure is created:  
```text
redis/  
└── certs/  
    ├── root/  
    │   ├── ca.key # Root CA private key  
    │   └── ca.crt # Root CA certificate  
    ├── redis/  
    │   ├── redis.key # Redis server private key  
    │   ├── redis.csr # Redis CSR  
    │   ├── redis.crt # Redis server certificate  
    │   └── redis.ext # SAN configuration  
    └── redis-truststore.jks # Java truststore (CA only)  
```
---

## Subject Alternative Names (SAN)

The Redis server certificate is generated with the following SAN entries:  

- `DNS:redis`  
- `DNS:localhost`  
- `IP:127.0.0.1`  

This allows the same certificate to work for:  

- Local development  
- Docker networking  
- Direct IP access  

---

## Prerequisites

The following tools must be available on your system:  

- `bash`  
- `openssl`  
- `keytool` (comes with JDK)  

---

## How to run the script

### 1. Make the script executable

```bash
chmod +x generate-redis-tls.sh
bash .\generate-redis-tls.sh
```

### Using the truststore in Spring Boot

#### Copy the truststore into application resources

```text
src/main/resources/
└── certs/
    └── redis-truststore.jks
```

#### Configure Spring Boot to use the truststore

```yaml
redis:
  host: 127.0.0.1
  port: 6379
  ssl:
    enabled: true
    trust-store: classpath:certs/redis-truststore.jks
    trust-store-password: changeit
```
