#!/bin/sh

ROLE_ID_FILE="/etc/vault/roleid"
SECRET_ID_FILE="/etc/vault/secretid"

while [[ ! -f $ROLE_ID_FILE || ! -f $SECRET_ID_FILE ]]; do
    sleep 1
done

/bin/vault agent -config=/etc/vault/agent.hcl
