# Pull base image.
FROM ubuntu:latest

RUN \
# Update
apt-get update -y && \
# Install Java
apt-get install default-jre -y

ADD ./target/gs-serving-web-content.jar gs-serving-web-content.jar

EXPOSE 8080

CMD java -jar gs-serving-web-content.jar