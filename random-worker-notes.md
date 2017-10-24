# Overall plan on what to do with Jenkins Q4



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

Linux worker: EC2
OSX worker: VB0
Windows worker: EC2

How pipeline should be written for different platforms?

How Jenkinsfile is shaped for cross-platform jobs?

## Setup

Using Lightsail for Linux + Windows worker. Macbook at home for OSX.

### Linux

New node: http://localhost:8090/computer/new

Create new keys for user `agent` and create that user on the instance.

```
sudo apt update && sudo apt install default-jre
```

### OSX

Create OSX Machine

```
    6  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    7  brew cask install java
    8  sudo mkdir /var/jenkins
    9  sudo chmod -R 777 /var/jenkins
```


## Give user ImmutableJenkins admin access to jenkins


### Windows

Start new node, RDP into it.

```
Set-ExecutionPolicy Bypass; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
refreshenv
choco install -y jre8
refreshenv
wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.6/swarm-client-3.6.jar -OutFile swarm.jar
& "C:\Program Files\Java\jre1.8.0_144\bin\java.exe" -jar swarm.jar -master https://jenkinsci.ngrok.io/ -password admin -username admin -tunnel 0.tcp.ngrok.io:13228 -labels windows -mode exclusive
```

#### On the agent

https://www.java.com/en/download/windows-64bit.jsp

Install Java

https://git-scm.com/download/win

- [x] Use Git from the windows command prompt
- [x] Use the OpenSSL library
- [x] Use windows' default console window

### On master

https://jenkinsci.ngrok.io/computer/new

Node Name: worker-windows-02

- [X] Permanent Agent

Remote directory: c:\jenkins
Labels: windows

- [X] Launch agent via java web start

Tunnel: 0.tcp.ngrok.io:13228

### On the agent

Download https://jenkinsci.ngrok.io/jnlpJars/slave.jar

Open terminal in Downloads directory

Run `java -jar slave.jar -jnlpUrl https://jenkinsci.ngrok.io/computer/worker-windows-02/slave-agent.jnlp -secret cc938d60937edb75cd472f4ba28a6944560589619eb26ef8801da0925d4b775b -workDir "c:\jenkins"`

# Swarm Plugin Exploration

Workers need to:
- Install Java
	- macOS: install brew + brew cask install java (sh)
	- Windows: download .exe + install (bat)
	- Linux: apt update && apt install default-jre (sh)
- Download Swarm CLI
- Run Swarm CLI

Linux example:
```
java -jar swarm.jar -master https://jenkinsci.ngrok.io/ -password admin -username admin -tunnel 0.tcp.ngrok.io:13228 -labels linux -mode exclusive
```

# Changes in Jenkins Master

- Have user for connecting with CLI
- Add Swarm Plugin

# Where is a worker hosted?

- macOS: MacStadium (self-hosted in the future)
- Linux + Windows: AWS

```
java -jar swarm.jar -master https://jenkinsci.ngrok.io/ -password admin -username admin -tunnel 0.tcp.ngrok.io:13228 -labels windows -mode exclusive
```

# Windows logs

Something like:

```
Get-Content -Path "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserdataExecution.log" -Wait
```

# Next steps

- Figure out firewall/security groups for windows + linux with multiple ingress rules
- Refactor code base
- Commit


# run in background

wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.6/swarm-client-3.6.jar
START java -jar swarm-client-3.6.jar -master https://jenkinsci.ngrok.io/ -password admin -username admin -tunnel 0.tcp.ngrok.io:11176 -labels windows -mode exclusive -name aws-windows -fsroot c:\jenkins




START /b java -jar swarm-client-3.6.jar -master https://jenkinsci.ngrok.io/ -password admin -username admin -tunnel 0.tcp.ngrok.io:11176 -labels windows -mode exclusive -name aws-windows -fsroot c:\jenkins
