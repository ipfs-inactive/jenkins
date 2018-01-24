#! /usr/bin/env bash

# This script downloads all plugins from a jenkins master into your local workspace
# Run this script after updating plugins to persist the actual upgrades, since
# when deploying jenkins, plugins are copied into the jenkins configuration

set -e

IP=$(terraform output --json | jq -r .jenkins_masters.value[0])
echo "Using Master IP $IP"

rsync -zarv --prune-empty-dirs --include="*/" --include="*.jpi" --exclude="*" ubuntu@$IP:/efs/jenkins/plugins ./config
