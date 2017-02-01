#! /bin/bash

docker build -t ipfs/jenkins:latest .
# TODO detect if /var/run/docker.sock exists and errors if it doesn't
# TODO allow people to change path to socket

DOCKER_ARGS=(
-p 8090:8080

-v /var/run/docker.sock:/var/run/docker.sock
# --group-add adds main process to supplementary group
#  we have to use GID instead of name as name will have different mapping in the container
--group-add "$(getent group docker | cut -d':' -f 3)"

-v $(pwd)/config:/var/jenkins_home # insert config
ipfs/jenkins:latest # image to run
)

docker run "${DOCKER_ARGS[@]}"
