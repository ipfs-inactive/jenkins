FROM jenkins:2.32.1

USER root

RUN apt-get update

RUN apt-get install --yes apt-transport-https ca-certificates software-properties-common

RUN curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -

RUN add-apt-repository \
       "deb https://apt.dockerproject.org/repo/ \
       debian-$(lsb_release -cs) \
       main"

RUN apt-get update

RUN apt-cache madison docker-engine

RUN apt-get -y install docker-engine=1.13.0-0~debian-jessie

RUN usermod -aG docker jenkins

USER jenkins
