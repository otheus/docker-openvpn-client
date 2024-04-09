#!/usr/bin/env bash
# vim:sts=4 et ts=4 sw=2:

set -o errexit
set -o nounset
set -o pipefail

cleanup() {
    kill TERM "$openvpn_pid"
    exit 0
}

is_enabled() {
    [[ ${1,,} =~ ^(true|t|yes|y|1|on|enable|enabled)$ ]]
}

create_dev_tun() { 
# must be done at *run time* because /dev is mounted after container start. 
# ie, commands are useless at build-time in Dockerfile
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 0600 /dev/net/tun
}

_run() { 
  if ! "$@"; then 
    echo >&2 "Error running <<" "$@" ">>"
    return $?
  fi
}

# Escape hatch for custom CLI behavior. If first argument begins with /, treat as executable to replace standard behavior
[[ $# != 0 ]] && [[ "${1#/}" != "${1}" ]] && exec "$@"

create_dev_tun

# initialize arguments array
openvpn_args=( "--cd" "/config" )

# Either a specific file name or a pattern.
# NB: if no CONFIG_FILE provided, use the most recently updated file in the config dir
if [[ ${CONFIG_FILE-} ]]; then
    config_file=$(find /config -name "$CONFIG_FILE" 2> /dev/null | sort | shuf -n 1)
else
    # NB: busybox's find is limited in what it can do. Pipe through xargs and ls to get the most recently changed file
    config_file=$(find /config -type f \( -name '*.conf' -o -name '*.ovpn' \) -print0 | ( xargs -0r -n1000 ls -1t || : ) | head -n1 || : > /dev/null )
fi

if [[ -z $config_file ]]; then
    echo "no openvpn configuration file found" >&2
    exit 1
else
    openvpn_args+=("--config" "$config_file")
    echo "using openvpn configuration file: $config_file"
fi

if is_enabled "$KILL_SWITCH"; then
    openvpn_args+=("--route-up" "/usr/local/bin/killswitch.sh ${ALLOWED_SUBNETS-}")
fi

# Docker secret that contains the credentials for accessing the VPN.
if [[ ${AUTH_SECRET-} ]]; then
    if [[ ! -r ${AUTH_SECRET} ]]; then
        echo "Authentication file not found at ${AUTH_SECRET}"
        exit 2
    fi
    openvpn_args+=("--auth-user-pass" "/run/secrets/$AUTH_SECRET")
fi

trap cleanup TERM

# DO NOT BACKGROUND. se --detach if you dont want it in foreground
# cleanup: what are we doing with cleanup?
_run openvpn "${openvpn_args[@]}" ${1:+"${@-}"}
