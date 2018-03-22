FROM jenkins/jenkins:2.112-alpine

USER root

RUN apk update && apk add --no-cache docker=1.12.6-r0

USER jenkins
