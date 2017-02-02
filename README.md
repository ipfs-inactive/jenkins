# jenkins
> Configuration for IPFS's build system

## WIP: In the process of being setup

You can get an overview of our progress at https://waffle.io/ipfs/jenkins

## Development Environment Setup

### Requirements

* Docker

### Instructions

* Clone repository
* Run `./start-dev.sh`
* Now jenkins should be running at http://localhost:8090

```
username: admin
password: admin
```

## Production Deploy

- Run `./build-prod.sh` on machine with access to our Quay registry
- Run `./provsn exec jenkins "runuser -l jenkins -c 'cd jenkins/ && ./start-prod.sh $VERSION'"` from ipfs/infrastructure
	replace $VERSION with which commit you want to deploy

### Setting up new host

New hosts need:

- Docker installed
- Docker Login generated for Quay read-only access
- User `jenkins` on host for file permissions in running container
- Initial clone of ipfs/jenkins to home directory of jenkins user

## Notes

Secrets are only valid for dev-environment. Make sure to only run jenkins in dev
listening to 127.0.0.1 and not 0.0.0.0. Secrets are replaced when jenkins is deployed

When running in production, `start-prod.sh` require access to protocol/jenkins-secrets
to be able to decrypt and apply production patch.
