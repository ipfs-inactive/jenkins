FROM jenkins:2.32.1-alpine

USER root

RUN apk add --no-cache docker

USER jenkins
