#!/bin/sh

# start mongodb
mongod --auth --bind_ip 127.0.0.1 &

# wait for mongodb to start
while ! nc -z 127.0.0.1 27017; do
  sleep 1
done

# create admin user
mongo <<EOF
use admin
db.createUser({
  user: "admin",
  pwd: "admin",
  roles: [{ role: "root", db: "admin" }]
})
EOF
