{{ with secret "pki-redis/issue/redis-server"
  "common_name=redis"
  "alt_names=localhost"
  "ip_sans=127.0.0.1"
  "ttl=15s" }}
{{ .Data.private_key }}
{{ end }}
