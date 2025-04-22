#!/bin/sh

export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='root'

# wait for vault
until vault status >/dev/null 2>&1; do
    sleep 1
done

# wait for mongo
until mongo -u admin -p admin --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    sleep 1
done

##################
# Static Secrets
##################
vault secrets enable -version=2 kv

vault kv put kv/path/to/secret \
  foo=bar \
  fizz=buzz \
  hello=world \
  ping=pong

##################
# Database Secrets
##################
vault secrets enable database

vault write database/config/db001 \
    plugin_name=mongodb-database-plugin \
    allowed_roles="demo" \
    connection_url="mongodb://{{username}}:{{password}}@localhost:27017/admin" \
    username="admin" \
    password="admin"

vault write database/roles/demo \
    db_name=db001 \
    creation_statements='{ "db": "admin", "roles": [{ "role": "read" }] }' \
    default_ttl="20s" \
    max_ttl="20s"

##################
# PKI Secrets Engine
##################
# Root CA
vault secrets enable -path=pki_root pki
vault secrets tune -max-lease-ttl=87600h pki_root
vault write -field=certificate pki_root/root/generate/internal common_name="localhost" issuer_name="root-2025" ttl=87600h > /tmp/root_2025_ca.crt
vault write pki_root/config/urls issuing_certificates="$VAULT_ADDR/v1/pki_root/ca" crl_distribution_points="$VAULT_ADDR/v1/pki_root/crl"

# Intermediate CA
vault secrets enable pki
vault secrets tune -max-lease-ttl=43800h pki
vault write -field=csr pki/intermediate/generate/internal common_name="localhost Intermediate Authority" > /tmp/pki_intermediate.csr
vault write -field=certificate pki_root/root/sign-intermediate issuer_ref="root-2025" csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" > /tmp/intermediate.cert.pem
vault write pki/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem

vault write pki/roles/demo \
  issuer_ref="default" \
  allowed_domains="localhost" \
  allow_subdomains=false \
  allow_bare_domains=true \
  ttl=24h \
  ou="Engineering" \
  organization="My Company" \
  country="US" \
  locality="San Francisco" \
  postal_code="94105"

rm /tmp/*.crt /tmp/*.csr /tmp/*.pem

##################
# AppRole Auth
##################
vault auth enable approle

vault policy write my-policy - <<EOF
path "kv/data/path/to/secret" {
  capabilities = ["read"]
}
path "pki/issue/demo" {
  capabilities = ["create", "update"]
}
path "database/creds/demo" {
  capabilities = ["read"]
}
EOF

vault write auth/approle/role/my-role \
  token_policies="my-policy" \
  token_ttl=30s \
  token_max_ttl=1m

# generate approle credentials
vault read -field=role_id auth/approle/role/my-role/role-id > /vault/approle/roleid
vault write -f -field=secret_id auth/approle/role/my-role/secret-id > /vault/approle/secretid
