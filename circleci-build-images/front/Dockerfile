FROM circleci/node:12-stretch-browsers

USER root

RUN npm install -g sonarqube-scanner \
    && npm install -g typescript@3.4.5 \
    && npm cache clean --force

ENV NODE_PATH "/usr/local/lib/node_modules/"

USER circleci

CMD ["/bin/sh"]
