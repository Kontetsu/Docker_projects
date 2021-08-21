FROM jenkins/jenkins

EXPOSE 8080:8080
EXPOSE 50000:50000

VOLUME $HOME:/var/jenkins_home

RUN jenkins-plugin-cli --plugins "sonar:2.13.1"