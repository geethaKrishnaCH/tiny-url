path "pki-redis/issue/redis-server" {
    capabilities = ["create", "update"]
}

path "pki-redis/cert/ca" {
    capabilities = ["read"]
}

path "auth/token/lookup-self" {
    capabilities = ["read"]
}