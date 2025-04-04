FROM hashicorp/vault:1.19

RUN apk add --no-cache supervisor openssl
RUN mkdir -p /etc/vault /var/log/supervisor /run/vault/tls /app

COPY config/agent.hcl /etc/vault/agent.hcl
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./scripts /bin
RUN chmod +x /bin/*.sh

EXPOSE 8200

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
