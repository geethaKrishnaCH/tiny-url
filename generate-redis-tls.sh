#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="redis/certs"
ROOT_DIR="$BASE_DIR/root"
REDIS_DIR="$BASE_DIR/redis"
TRUSTSTORE="$BASE_DIR/redis-truststore.jks"
TRUSTSTORE_PASS="changeit"

echo "▶ Creating directory structure..."
mkdir -p "$ROOT_DIR" "$REDIS_DIR"

########################################
# 1️⃣ Generate Root CA
########################################

echo "▶ Generating Root CA..."

openssl genrsa -out "$ROOT_DIR/ca.key" 4096

openssl req -x509 -new -nodes \
  -key "$ROOT_DIR/ca.key" \
  -sha256 \
  -days 365 \
  -subj "/CN=redis-root-ca" \
  -out "$ROOT_DIR/ca.crt"

########################################
# 2️⃣ Generate Redis Server Certificate
########################################

echo "▶ Generating Redis server key..."

openssl genrsa -out "$REDIS_DIR/redis.key" 2048

echo "▶ Generating Redis CSR..."

openssl req -new \
  -key "$REDIS_DIR/redis.key" \
  -subj "/CN=redis" \
  -out "$REDIS_DIR/redis.csr"

echo "▶ Creating SAN extension file..."

cat > "$REDIS_DIR/redis.ext" <<EOF
subjectAltName = DNS:redis,DNS:localhost,IP:127.0.0.1
EOF

echo "▶ Signing Redis certificate with Root CA..."

openssl x509 -req \
  -in "$REDIS_DIR/redis.csr" \
  -CA "$ROOT_DIR/ca.crt" \
  -CAkey "$ROOT_DIR/ca.key" \
  -CAcreateserial \
  -out "$REDIS_DIR/redis.crt" \
  -days 365 \
  -sha256 \
  -extfile "$REDIS_DIR/redis.ext"

########################################
# 3️⃣ Verify Redis Certificate
########################################

echo "▶ Verifying Redis certificate SAN..."

openssl x509 -in "$REDIS_DIR/redis.crt" -text -noout | grep -A 2 "Subject Alternative Name"

########################################
# 4️⃣ Create Java Truststore (CA only)
########################################

echo "▶ Creating Java truststore..."

rm -f "$TRUSTSTORE"

keytool -importcert \
  -alias redis-root-ca \
  -file "$ROOT_DIR/ca.crt" \
  -keystore "$TRUSTSTORE" \
  -storepass "$TRUSTSTORE_PASS" \
  -noprompt

echo "▶ Verifying truststore contents..."

keytool -list -v \
  -keystore "$TRUSTSTORE" \
  -storepass "$TRUSTSTORE_PASS" \
  | grep -E "Alias name|Owner:|Issuer:"

########################################
# Done
########################################

echo "✅ Redis TLS certificates and truststore generated successfully."
echo "📁 Root CA     : $ROOT_DIR"
echo "📁 Redis certs : $REDIS_DIR"
echo "📦 Truststore : $TRUSTSTORE"

