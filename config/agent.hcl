vault {
  address = "http://localhost:8200"
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path = "/vault/approle/roleid"
      secret_id_file_path = "/vault/approle/secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

template_config {
  static_secret_render_interval = "30s"
}

template {
  contents = <<-EOF
  {{- with secret "kv/path/to/secret" -}}
  foo={{ .Data.data.foo }}
  fizz={{ .Data.data.fizz }}
  ping={{ .Data.data.ping }}
  hello={{ .Data.data.hello }}
  {{- end }}
  EOF
  destination  = "/secrets/static.env"

  perms = "640"
  user = "vault"
  group = "nobody"

  exec = {
    command = "/usr/bin/supervisorctl signal HUP webapp || true"
  }
}

template {
  contents = <<-EOF
  {{- with secret "database/creds/demo" -}}
  username={{ .Data.username }}
  password={{ .Data.password }}
  {{- end }}
  EOF
  destination  = "/secrets/database.env"

  perms = "640"
  user = "vault"
  group = "nobody"

  exec = {
    command = "/usr/bin/supervisorctl signal HUP webapp || true"
  }
}

template {
  contents = <<-EOF
  {{- with pkiCert "pki/issue/demo" "common_name=localhost" "ttl=24h" -}}
  {{ .Data.Key }}{{ .Data.Cert }}{{ .Data.CA }}
  {{- .Key | writeToFile "/secrets/server.key" "vault" "nobody" "640" }}
  {{- .Cert | writeToFile "/secrets/server.crt" "vault" "nobody" "644" "newline" }}
  {{- .CA | writeToFile "/secrets/server.crt" "vault" "nobody" "644" "append" }}
  {{- end -}}
  EOF
  destination = "/secrets/cache"

  perms = "600"
  user = "vault"
  group = "vault"

  exec = {
    command = "/usr/bin/supervisorctl signal HUP webapp || true"
  }
}
