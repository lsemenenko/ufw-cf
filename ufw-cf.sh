#!/bin/bash

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

}

main() {

    local var

    if [[ $# -gt 0 ]]; then
        while true; do
            local var="$1"
            case "${var}" in

              enable) cloudflare_enable ;;
              disable) cloudflare_disable ;;

            esac

            shift 1 || true

            if [[ -z "${var}" ]]; then
                break
            fi

        done
    else
        echo "Not enough args..."
    fi

}

main "$@"