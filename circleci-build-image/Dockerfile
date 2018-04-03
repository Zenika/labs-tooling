# Start from CircleCI image with Node 6, Yarn, Chrome...
FROM circleci/node:6-stretch-browsers

ARG RANCHER_CLI_VERSION=v0.6.4
ARG RANCHER_COMPOSE_VERSION=v0.12.5

# Install apt-get repos and update
RUN sudo apt-get install apt-transport-https
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN sudo apt-get update

# Install newer Yarn version
RUN sudo apt-get install yarn
RUN sudo ln -sf /usr/bin/yarn /usr/local/bin/yarn
RUN sudo ln -sf /usr/bin/yarn /usr/local/bin/yarnpkg

# Install Java 8 JDK and Maven
RUN sudo apt-get install openjdk-8-jdk
RUN sudo apt-get install maven

# Install AWS CLI
RUN sudo apt-get install python-dev python-pip
RUN sudo pip install --upgrade pip
RUN sudo pip install --upgrade setuptools
RUN sudo pip install --upgrade awscli

# Install Rancher CLI
RUN sudo curl -fsSLO https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz
RUN sudo tar --strip-components=2 -xzvf rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz -C /usr/local/bin
RUN sudo chmod +x /usr/local/bin/rancher
RUN sudo rm rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz

# Install Rancher Compose
RUN sudo curl -fsSLO https://github.com/rancher/rancher-compose/releases/download/${RANCHER_COMPOSE_VERSION}/rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz
RUN sudo tar --strip-components=2 -xzvf rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz -C /usr/local/bin
RUN sudo chmod +x /usr/local/bin/rancher-compose
RUN sudo rm rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz
