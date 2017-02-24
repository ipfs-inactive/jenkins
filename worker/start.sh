#!/bin/sh

delgroup docker
addgroup -g $(stat -c "%g" /var/run/docker.sock) docker
addgroup jenkins docker

/usr/sbin/sshd -D
