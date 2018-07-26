FROM circleci/golang:1-stretch

ARG RANCHER_COMPOSE_VERSION=v0.12.5

RUN sudo curl -fsSLO https://github.com/rancher/rancher-compose/releases/download/${RANCHER_COMPOSE_VERSION}/rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz && \
    sudo tar --strip-components=2 -xzvf rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz -C /usr/local/bin && \
    sudo chmod +x /usr/local/bin/rancher-compose && \
    sudo rm rancher-compose-linux-amd64-${RANCHER_COMPOSE_VERSION}.tar.gz
