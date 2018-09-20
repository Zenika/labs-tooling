FROM circleci/node:9-browsers

USER root

RUN npm install -g sonarqube-scanner \
    && npm install -g typescript@2.9.2 \
    && npm cache clean --force

ENV NODE_PATH "/usr/local/lib/node_modules/"

USER circleci

CMD ["/bin/sh"]
