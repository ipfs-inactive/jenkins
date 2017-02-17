#! /usr/bin/env bash

set -e

echo "## Starting setup"

PUBKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyueuHS8fgII1yIHEvvsEzGp08iXQ0lIH6bMwyDe18XQoh66mU9rYIng0TPSmAENdqKVHeCufFiRBWM5SzFw06RuHYCFJciHzTcI0qFE7yhoDjfk/h3WIuSroDzoQUkJ9Fg2MIUJfChny3sNzZmNHMYEtiEsOvbAIuQvJOlepdUm3FP1g3eMP7WREAkM/t8fTFQqFvUq7jW1Op5OEjcFxyThkY4G1Plb0i13CM5VdwgwOV5rZhBbS4HI3VSkWrh7mFeS6S4clYjX2wdm8dSbfZA5WuO1Rkhbqg5DgTY9Si8pK6rhGzMbgHqqhHbmVppXMOAem9nHHBMGfEt02KxYgT"

# Add docker repository key
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Add docker repository
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'

apt-get update

# Install tools
apt-get install default-jre git docker-engine

# Add worker user
adduser --disabled-password --gecos "" worker

# Add worker user to docker group
usermod -aG docker worker

# Accept pubkey from jenkins master
mkdir -p /home/worker/.ssh
echo $PUBKEY > /home/worker/.ssh/authorized_keys

echo "## Setup complete"
