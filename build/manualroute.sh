#!/usr/bin/env bash

## Somehow the pushed config screws up the route
## Do it manually

iphost=172.17.0.1
dnshost=192.168.65.7
remote=$( host sgvpn.trubox.com | cut -d ' ' -f4 )
ip route add 172.17.0.0/16 via $iphost dev eth0
ip route add "$dnshost" via $iphost dev eth0
ip route add "$remote" via $iphost dev eth0
ip route del default
ip route add default dev tun0
cat << RESOLV > /etc/resolv.conf
nameserver 192.168.65.7
nameserver 8.8.8.8
RESOLV

# curl ifconfig.me | grep -q ^ 
