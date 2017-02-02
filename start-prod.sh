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
	# for now, just clean out all the users
	rm -r config/users/* || true
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
	docker run -d \
		--name jenkins \
		--restart=always \
		-p 127.0.0.1:8090:8080 \
		-v $(pwd)/config:/var/jenkins_home \
		--env JAVA_OPTS=-Djenkins.install.runSetupWizard=false \
		$IMAGE_TO_DEPLOY
fi
