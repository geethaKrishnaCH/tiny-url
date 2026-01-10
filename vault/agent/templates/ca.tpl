{{ with secret "pki-redis/cert/ca" }}
{{ .Data.certificate }}
{{ end }}