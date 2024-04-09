FROM alpine:3.17

RUN apk add --no-cache \
    bash \
    bind-tools \
    iptables \
    iptables6 \
    iproute2 \
    curl \
    openvpn

COPY --chmod=0755 entry.sh /usr/local/sbin/entry.sh

WORKDIR /tmp

ARG KILL_SWITCH=off
ENV KILL_SWITCH=${KILL_SWITCH}

ENTRYPOINT [ "/usr/local/sbin/entry.sh" ]
