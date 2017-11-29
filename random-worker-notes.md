## Master Plan: Run all CI via Jenkins

Organizations:

- IPFS
- libp2p
- IPLD
- Multiformats
- IPFS-Shipyard

Platforms to support:

- OSX
- Windows
- Linux


### Example: js-ipfs

On every push: run tests + coverage on three platforms
Before every release: third-party tests


# Where is a worker hosted?

- macOS: MacStadium (self-hosted in the future)
- Linux + Windows: AWS

# macOS manual setup of new nodes

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew cask install java google-chrome
sudo mkdir /var/jenkins
sudo chmod -R 777 /var/jenkins
brew install wget tmux python python3
wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.6/swarm-client-3.6.jar

java -jar swarm-client-3.6.jar -master https://ci.ipfs.team/ -password X -username ImmutableJenkins -tunnel ci.ipfs.team:50000 -labels macos -mode exclusive -name macstadium-macos -fsroot /var/jenkins
```

* Had to change `start-prod` to listen 50000 on all available interfaces
	* done
* Currently running ci.ipfs.team from the cross-platform branch
* macOS setup is currently manual
* Currently having issues with commit status and permissions in Github
	* fix: give ImmutableJenkins access to `commit:status` permission
* Windows worker having permissions problems with npm
	* fixed: turn of realtime protection

* API token for ImmutableJenkins user is different on each boot
* Had to switch ImmutableJenkins password for a API access token for jenkins access

* go-ipfs job needs to run on node with label `linux`
* Give user ImmutableJenkins admin access to jenkins
* Give Github user ImmutableJenkins commit:status access to all orgs

* Workers should have go-ipfs installed?
* Golang tools...
