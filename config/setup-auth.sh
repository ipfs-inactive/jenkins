#! /usr/bin/env bash

set -e

export USERNAME=immutablejenkins
export PASSWORD=$(cat /tmp/userauthtoken)
TOKEN=$(curl --user "$USERNAME:$PASSWORD" -s http://localhost:8080/crumbIssuer/api/json | python -c 'import sys,json;j=json.load(sys.stdin);print j["crumbRequestField"] + "=" + j["crumb"]')
curl --user "$USERNAME:$PASSWORD" -d "$TOKEN" --data-urlencode "script=$(</var/lib/jenkins/setup-auth.groovy)" http://localhost:8080/scriptText

