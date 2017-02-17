#! /usr/bin/env bash

set -e

echo "## Starting setup"

USERNAME=worker
PUBKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyueuHS8fgII1yIHEvvsEzGp08iXQ0lIH6bMwyDe18XQoh66mU9rYIng0TPSmAENdqKVHeCufFiRBWM5SzFw06RuHYCFJciHzTcI0qFE7yhoDjfk/h3WIuSroDzoQUkJ9Fg2MIUJfChny3sNzZmNHMYEtiEsOvbAIuQvJOlepdUm3FP1g3eMP7WREAkM/t8fTFQqFvUq7jW1Op5OEjcFxyThkY4G1Plb0i13CM5VdwgwOV5rZhBbS4HI3VSkWrh7mFeS6S4clYjX2wdm8dSbfZA5WuO1Rkhbqg5DgTY9Si8pK6rhGzMbgHqqhHbmVppXMOAem9nHHBMGfEt02KxYgT"

dscl . -create /Users/$USERNAME
dscl . -create /Users/$USERNAME UserShell /bin/bash
dscl . -create /Users/$USERNAME UniqueID "1010"
dscl . -create /Users/$USERNAME NFSHomeDirectory /Users/$USERNAME
chown -R $USERNAME /Users/$USERNAME
mkdir /Users/$USERNAME
chown -R $USERNAME /Users/$USERNAME
mkdir -p /Users/$USERNAME/.ssh
echo $PUBKEY > /Users/$PUBKEY/.ssh/authorized_keys

echo "## Setup complete"
