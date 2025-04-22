# Build stage
FROM golang:1.24-alpine AS build

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY ./src/ /app
RUN go mod download
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o webapp .

# Final stage
FROM hashicorp/vault:1.19

COPY --from=build /app/webapp /bin

# mongo
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories

RUN apk update && apk add --no-cache mongodb supervisor openssl
RUN mkdir -p /data/db /var/log/supervisor /secrets /vault/approle

COPY config/agent.hcl /vault/config/agent.hcl
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./scripts /bin
RUN chmod +x /bin/*.sh

EXPOSE 8000 8200

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]