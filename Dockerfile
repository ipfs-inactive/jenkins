FROM jenkins:2.32.1-alpine

USER root

RUN apk update && apk add --no-cache docker=1.11.2-r1

USER jenkins
