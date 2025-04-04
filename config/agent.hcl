vault {
  address = "http://localhost:8200"
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path = "/etc/vault/roleid"
      secret_id_file_path = "/etc/vault/secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

template {
  contents = <<-EOF
  {{- with secret "kv/path/to/secret" -}}
  foo={{ .Data.data.foo }}
  username={{ .Data.data.username }}
  password={{ .Data.data.password }}
  {{- end }}
  EOF
  destination  = "/run/vault/static.env"

  perms = "640"
  user = "vault"
  group = "nobody"

  exec = {
    command = "echo 'reloading application...'"
  }
}

template {
  contents = <<-EOF
  {{- with secret "database/creds/demo" -}}
  username={{ .Data.username }}
  password={{ .Data.password }}
  {{- end }}
  EOF
  destination  = "/run/vault/database.env"

  perms = "640"
  user = "vault"
  group = "nobody"

  exec = {
    command = "echo 'reloading application...'"
  }
}

template {
  contents = <<-EOF
  {{- with pkiCert "pki/issue/demo" "common_name=webapp.example.com" "ttl=24h" -}}
  {{ .Data.Key }}{{ .Data.Cert }}{{ .Data.CA }}
  {{- .Key | writeToFile "/run/vault/tls/server.key" "vault" "nobody" "640" }}
  {{- .Cert | writeToFile "/run/vault/tls/server.pem" "vault" "nobody" "644" "newline" }}
  {{- .CA | writeToFile "/run/vault/tls/server.pem" "vault" "nobody" "644" "append" }}
  {{- end -}}
  EOF
  destination = "/run/vault/tls/cache"

  perms = "600"
  user = "vault"
  group = "vault"

  exec = {
    command = "echo 'reloading application...'"
  }
}
