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

// template {
//   source      = "./vault/agent/templates/redis.crt.tpl"
//   destination = "./vault/agent/secrets/redis.crt"
// }
//
// template {
//   source      = "./vault/agent/templates/redis.key.tpl"
//   destination = "./vault/agent/secrets/redis.key"
// }

template {
  source = "/vault/agent/templates/redis.tpl"
  destination = "/home/vault/null"
}