#!/bin/sh
set -e

CERT_DIR=/app/certs
TRUSTSTORE_DIR=/app
TRUSTSTORE=redis-truststore.jks
STOREPASS=changeit
ALIAS=redis-ca

# Wait until Vault Agent writes ca.crt
echo "Waiting for CA certificate..."
while [ ! -f "$CERT_DIR/ca.crt" ]; do
  sleep 1
done

# Remove old truststore if exists (important for rotation)
# rm -f "$TRUSTSTORE"

# Import CA cert into JKS
keytool -importcert \
  -trustcacerts \
  -noprompt \
  -alias "$ALIAS" \
  -file "$CERT_DIR/ca.crt" \
  -keystore "$TRUSTSTORE" \
  -storepass "$STOREPASS"

echo "Truststore generated at $TRUSTSTORE"

# Execute the main app
exec java -jar /app/tiny-url-app.jar
