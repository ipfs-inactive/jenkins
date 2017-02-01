#! /bin/bash

docker build -t ipfs/jenkins:latest .
# TODO detect if /var/run/docker.sock exists and errors if it doesn't
# TODO allow people to change path to socket
docker run -p 8090:8080 \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v $(pwd)/config:/var/jenkins_home \
	ipfs/jenkins:latest
