## Overview
This [image](https://hub.docker.com/r/kosir/vault-agent-demo) is a simple one click demo of HashiCorp Vault and Vault Agent. It is by no means an example of a good production setup, as it violates the one process per container model.

This image is meant for demos and proof of concepts showing how Vault Agent interacts with Vault, including rendering both static and dynamic secrets to a file.

This demo is geared towards Virtual Machine based use cases.\
If you are on Kubernetes or OpenShift, be sure checkout the following integration patterns:
- [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Vault CSI Provider](https://developer.hashicorp.com/vault/docs/platform/k8s/csi)

## Instructions
Launch the container
```shell
docker run \
  --rm \
  --detach \
  --publish 8000:8000 \
  --publish 8200:8200 \
  --name vault-agent-demo \
  kosir/vault-agent-demo
```

Exec into the container:
```shell
docker exec -it vault-agent-demo /bin/sh
```

### Vault Agent Config
View the `vault` and `auto_auth` stanza
```shell
head -n 14 /vault/config/agent.hcl
```

### Static Secrets
View the Vault Agent template stanza
```shell
cat /vault/config/agent.hcl | grep "template_config" -A22
```

View the rendered static secrets
```shell
cat /secrets/static.env
```

### Database Secrets
View the Vault Agent template stanza
```shell
cat /vault/config/agent.hcl | grep "database/creds/demo" -B2 -A14
```

Watch the rendered database secrets change (~20s)
```shell
watch cat /secrets/database.env
```

### PKI
View the Vault Agent template stanza
```shell
cat /vault/config/agent.hcl | grep "with pkiCert" -B2 -A16
```

View the rendered Private Key
```shell
cat /secrets/server.key
```

View the rendered CA Cert and Public Key
```shell
cat /secrets/server.crt
```

View the TLS certificate metadata
```shell
openssl x509 -in /secrets/server.crt -text -noout
```

### Update Secrets
- In a browser, visit `http://localhost:8200` and login with `root`.
- Navigate to `kv/path/to/secret` and click the `Secret` tab
- Click `Create new version`
- View the secrets by clicking the `eye` icon on each secret
- Change **only** the values for the secret
- Click `Save`

Watch Vault Agent pull the updated secrets
```shell
watch cat /secrets/static.env
```

### Browser
Exit the container
```shell
exit
```

- In a browser, visit `https://localhost:8000`
- The certificate for this demo is self-signed, so proceed with the browser warning
- View the secrets returned from the web application
- Database credentials change every ~20 seconds

If you have `jq` installed, you can watch the changes from the command line.
```shell
watch "curl -sk https://localhost:8000 | jq"
```

### Cleanup
```shell
docker stop vault-agent-demo
docker rmi kosir/vault-agent-demo
```

## Image Build
```shell
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag kosir/vault-agent-demo:latest \
  --push \
  .
```
