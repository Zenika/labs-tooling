FROM alpine:3.8

RUN apk update && \
    apk add ca-certificates python py-pip && \
    pip install --upgrade awscli && \
    apk --purge del py-pip && \
    rm -rf /var/cache/apk/*
