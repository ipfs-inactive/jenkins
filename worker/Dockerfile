FROM alpine:3.4


RUN apk --update --no-cache add bash git openssh openjdk8 docker=1.11.2-r1 && \
	ssh-keygen -A && \
	rm -rf /var/cache/apk/* && \
	adduser -D jenkins && \
	echo "jenkins:jenkins" | chpasswd && \
	mkdir /jenkins && \
	chown -R jenkins:jenkins /jenkins

EXPOSE 22

COPY start.sh start.sh

CMD ["sh", "./start.sh"]
