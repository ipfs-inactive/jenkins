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

echo "Updating config"
git reset --hard
git checkout master
git pull origin master
git checkout $VERSION
rm -r config/users/* || true
git submodule init
git submodule update
(cd jenkins-secrets && ./decrypt.sh)
git apply jenkins-secrets/plain_config_production.patch
mv jenkins-secrets/plain_credentials.xml config/credentials.xml

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
		-v $(pwd)/jenkins-secrets:/home/jenkins/secrets \
		--group-add "$(getent group docker | cut -d':' -f 3)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--env JAVA_OPTS="-Xmx4096m -Djenkins.install.runSetupWizard=false" \
		$IMAGE_TO_DEPLOY
fi
