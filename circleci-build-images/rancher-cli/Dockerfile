FROM circleci/golang:1-stretch

ARG RANCHER_COMPOSE_VERSION=v0.12.5
RUN sudo curl -fsSLO https://github.com/rancher/rancher-compose/releases/download/${RANCHER_COMPOSE_VERSION}/rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz && \
    sudo tar --strip-components=2 -xzvf rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz -C /usr/local/bin && \
    sudo chmod +x /usr/local/bin/rancher-compose && \
    sudo rm rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz

ARG RANCHER_CLI_VERSION=v0.6.4
RUN sudo curl -fsSLO https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz && \
    sudo tar --strip-components=2 -xzvf rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz -C /usr/local/bin && \
    sudo chmod +x /usr/local/bin/rancher && \
    sudo rm rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz
