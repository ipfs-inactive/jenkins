#! /usr/bin/env bash

set -e

if [ -z "$1" ]
then
	echo "Version/Commit is required as first argument"
	exit 1
fi
# Which version/commit we're gonna use
VERSION="$1"

# Which docker image we're gonna use
IMAGE="quay.io/ipfs/jenkins"

# Git checkout
CURRENT_COMMIT=$(git rev-parse HEAD)
if [ "$VERSION" == "$CURRENT_COMMIT" ]; then
	echo "SCM up-to-date"
else
	echo "Updating config"
	git fetch
	git checkout $VERSION
	# TODO changes to config would happen here, decrypting secrets and such
fi

# Image deploy
IMAGE_TO_DEPLOY="$IMAGE:$VERSION"
CURRENT_IMAGE=$(docker inspect jenkins -f "{{ .Config.Image }}" || echo)
if [ "$IMAGE_TO_DEPLOY" == "$CURRENT_IMAGE" ]; then
	echo "Image up-to-date"
else
	echo "Different image currently running, deploying new image"
	docker stop jenkins || true
	docker rm jenkins || true
	docker run -d --name jenkins -p 80:8080 -v $(pwd)/config $IMAGE_TO_DEPLOY
fi
