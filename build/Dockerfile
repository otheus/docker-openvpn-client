FROM alpine:3.17

RUN apk add --no-cache \
    bash \
    bind-tools \
    iproute2 \
    curl \
    openvpn

COPY --chmod=0755 *.sh /usr/local/sbin/

WORKDIR /tmp

ARG UP_SCRIPT
ENV UP_SCRIPT=${UP_SCRIPT}

ENTRYPOINT [ "/usr/local/sbin/entry.sh" ]
