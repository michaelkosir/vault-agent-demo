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
docker run --rm -dp 8200:8200 --name vault-agent-demo kosir/vault-agent-demo:1.19
```

Exec into the container:
```shell
docker exec -it vault-agent-demo /bin/sh
```

### Vault Agent Config
View the `vault` and `auto_auth` stanza
```shell
head -n 14 /etc/vault/agent.hcl
```

### Static Secrets
View the rendered static secrets
```shell
cat /run/vault/static.env
```

View the Vault Agent template stanza
```shell
cat /etc/vault/agent.hcl | grep "kv/path/to/secret" -B2 -A15
```

### Database Secrets
Watch the rendered database secrets change (~15s)
```shell
watch cat /run/vault/database.env
```

View the Vault Agent template stanza
```shell
cat /etc/vault/agent.hcl | grep "database/creds/demo" -B2 -A14
```

### PKI
View the rendered PKI files
```shell
ls -al /run/vault/tls
```

View the rendered Private Key
```shell
cat /run/vault/tls/server.key
```

View the rendered CA Cert and Public Key
```shell
cat /run/vault/tls/server.pem
```

View the Vault Agent template stanza
```shell
cat /etc/vault/agent.hcl | grep "with pkiCert" -B2 -A16
```

### Logs
View the Vault Agent logs
```shell
tail -n 20 /var/log/supervisor/vault-agent.err.log
```

Watch Vault Agent renew auth (~30s) and reauth (~60s)
```shell
tail -f /var/log/supervisor/vault-agent.err.log
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
watch cat /run/vault/static.env
```

View the Vault Agent logs to see the rendering and command execution
```shell
tail -n 20 /var/log/supervisor/vault-agent.err.log
```

### Cleanup
Exit the container
```shell
exit
```

Stop the container
```
docker stop vault-agent-demo
```
## Docker Build
```shell
docker buildx create --use

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t kosir/vault-agent-demo:1.19 \
  --push \
  .
```