{{ with secret "pki-redis/issue/redis-server"
  "common_name=redis"
  "alt_names=localhost"
  "ip_sans=127.0.0.1"
  "ttl=1h" }}
{{ .Data.certificate | writeToFile "/home/vault/redis.crt" "" "" "0644" }}
{{ .Data.private_key | writeToFile "/home/vault/redis.key" "" "" "0644" }}
{{ end }}
