#!/bin/bash

set -o pipefail

main() {

  local var

  if [[ $# -gt 0 ]]; then
    local var="$1"
    case "${var}" in
      enable) cloudflare_enable ;;
      disable) cloudflare_disable ;;
      update) cloudflare_update ;;
      *) echo "Do nothing!"
    esac
  fi

  exit 0

}

cloudflare_enable() {

  local cf_ip
  local cf_ips=()

  cf_ips=($(curl -s https://www.cloudflare.com/ips-v4))
  cf_ips+=($(curl -s https://www.cloudflare.com/ips-v6))

  ufw delete allow in 80
  ufw delete allow in 80/tcp
  ufw delete allow in 443
  ufw delete allow in 443/tcp

  ufw deny in 80/tcp
  ufw deny in 443/tcp

  for cf_ip in ${cf_ips[@]}; do
    ufw allow proto tcp from ${cf_ip} to any port 80,443 comment 'Cloudflare IP'
  done

  checksum="$(md5sum < <(echo "${cf_ips[*]}"))"
  echo "${checksum}" | tee "$HOME/ufw-cf.ip.checksum" >/dev/null 2>&1

  return 0

}

cloudflare_disable() {

  local cf_ip
  local cf_ips=()

  cf_ips=($(ufw status | grep "Cloudflare IP" | awk '{print $3}'))

  ufw delete deny in 80/tcp
  ufw delete deny in 443/tcp

  ufw allow in 80/tcp
  ufw allow in 443/tcp

  for cf_ip in ${cf_ips[@]}; do
    ufw delete allow proto tcp from ${cf_ip} to any port 80,443 comment 'Cloudflare IP'
  done

  return 0

}

cloudflare_update() {

  local cf_ip
  local cf_ips=()
  local checksum
  local line

  cf_ips=($(curl -s https://www.cloudflare.com/ips-v4))
  cf_ips+=($(curl -s https://www.cloudflare.com/ips-v6))

  checksum="$(md5sum < <(echo "${cf_ips[*]}"))"

  if [[ -f "$HOME/ufw-cf.ip.checksum" ]]; then
    while read -r line; do
      if [[ "${checksum}" != "${line}" ]]; then
        cloudflare_disable && \
        cloudflare_enable && \
        exit 0 || \
        exit 1
      fi
    done < "$HOME/ufw-cf.ip.checksum"
  else
    echo "${checksum}" | tee "$HOME/ufw-cf.ip.checksum" >/dev/null 2>&1
  fi

  return 0

}

main "$@"