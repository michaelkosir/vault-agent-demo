vault {
  address = "http://localhost:8200" # replace with your Vault address
}

auto_auth {
  method {
    type = "approle" # approle for demo purposes
    config = {
      role_id_file_path = "/etc/vault/roleid"
      secret_id_file_path = "/etc/vault/secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

# kv secret
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
  group = "nobody" # replace with the group you want

  exec = {
    command = "echo 'reloading application...'" # replace with the command you want to run
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
    command = "echo 'reloading application...'" # replace with the command you want to run
  }
}
