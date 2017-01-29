#! /bin/bash

docker build -t ipfs/jenkins:latest .
docker run -p 8080:8080 -v $(pwd)/config:/var/jenkins_home ipfs/jenkins:latest
