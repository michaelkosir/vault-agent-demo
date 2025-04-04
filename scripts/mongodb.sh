#!/bin/sh

echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories
echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories

apk update
apk add --no-cache mongodb

mkdir -p /data/db
mongod --auth --bind_ip 127.0.0.1 &

while ! nc -z 127.0.0.1 27017; do
  sleep 1
done

mongo <<EOF
use admin
db.createUser({
  user: "admin",
  pwd: "admin",
  roles: [{ role: "root", db: "admin" }]
})
EOF
