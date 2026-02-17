#!/bin/bash
# Day 10 シナリオ 4: ファイアウォール設定ミスのある構成を投入
# 使い方: ./setup-scenario4.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="scenario4"

wait_for_vyos "$LAB_NAME" router-fw

echo "=== router-fw の設定を投入中（意図的なミスあり）==="
configure_vyos "$LAB_NAME" router-fw \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 172.16.0.1/24
set interfaces ethernet eth3 address 203.0.113.1/24
set firewall ipv4 forward filter default-action drop
set firewall ipv4 forward filter rule 1 action accept
set firewall ipv4 forward filter rule 1 state established
set firewall ipv4 forward filter rule 1 state related
set firewall ipv4 forward filter rule 10 action accept
set firewall ipv4 forward filter rule 10 inbound-interface name eth1
set firewall ipv4 forward filter rule 10 outbound-interface name eth3
set firewall ipv4 forward filter rule 20 action accept
set firewall ipv4 forward filter rule 20 inbound-interface name eth1
set firewall ipv4 forward filter rule 20 outbound-interface name eth2
set firewall ipv4 forward filter rule 30 action accept
set firewall ipv4 forward filter rule 30 inbound-interface name eth3
set firewall ipv4 forward filter rule 30 outbound-interface name eth2
set firewall ipv4 forward filter rule 30 protocol tcp
set firewall ipv4 forward filter rule 30 destination port 8080"

echo ""
echo "=== シナリオ 4 準備完了 ==="
echo "症状: host-internal → host-external の ping は通る"
echo "      host-external → host-dmz の HTTP（TCP 80）が通らない"
echo ""
echo "調査開始:"
echo "  # これは通る"
echo "  docker exec clab-${LAB_NAME}-host-internal ping -c 3 203.0.113.10"
echo "  # これが通らない"
echo "  docker exec clab-${LAB_NAME}-host-external sh -c 'echo GET / | nc -w 3 172.16.0.10 80'"
