#! /usr/bin/env bash

set -e

IMAGE_NAME="quay.io/ipfs/jenkins"

# Making sure jenkins-secrets are not included in the image
git submodule deinit --force .

if [[ -n $(git status --porcelain) ]]; then
	echo "Repository is dirty, please reset or commit your changes"
	exit 1
fi

COMMIT=$(git rev-parse HEAD)
CURRENT_IMAGE="$IMAGE_NAME:$COMMIT"

echo "## Building $CURRENT_IMAGE"

docker build -t $CURRENT_IMAGE .
docker tag $CURRENT_IMAGE $IMAGE_NAME:latest
docker push $IMAGE_NAME

echo "## Built and pushed $CURRENT_IMAGE"
