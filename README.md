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

## Setting up new worker

### Worker setup

Clone this repository to the worker and run `./worker/{debian,osx}-setup.sh`,
depending on what OS your worker is using.

Also, once docker is installed, make sure you login to Quay so images can be
pushed to quay. You can find the details about this by clicking on the "ipfs+deployer"
robot account over here: https://quay.io/organization/ipfs?tab=robots

### Connecting to jenkins

Create a new entry by copying to already existing `config/nodes/linux-01` to
a new directory, replacing the values in `config.xml` of the node.

Once created, submit the changes and make a deploy of new jenkins. Once it's
deployed, jenkins should automatically start the worker on your node.

## Notes

Secrets are only valid for dev-environment. Make sure to only run jenkins in dev
listening to 127.0.0.1 and not 0.0.0.0. Secrets are replaced when jenkins is deployed

When running in production, `start-prod.sh` require access to protocol/jenkins-secrets
to be able to decrypt and apply production patch.

## Running dev-environment

* Have Github OAuth application setup
* Replace SecretID and ClientID in config with dev tokens
* Setup ngrok to redirect jenkins traffic
* Change Github OAuth application to redirect to ngrok url
