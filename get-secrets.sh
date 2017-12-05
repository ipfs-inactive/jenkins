#! /usr/bin/env bash
set -e

go get -u -v github.com/jbenet/go-simple-encrypt/senc
rm -r config/users/* || true
git submodule init
git submodule update
(cd jenkins-secrets && ./decrypt.sh)
