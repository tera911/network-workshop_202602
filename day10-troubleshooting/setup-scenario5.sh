#!/bin/bash
# Day 10 シナリオ 5: OSPF 設定ミスのある構成を投入
# 使い方: ./setup-scenario5.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="scenario5"

wait_for_vyos "$LAB_NAME" router-hq router-tokyo router-osaka

configure_vyos "$LAB_NAME" router-hq \
  "set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth2 address 172.16.1.1/24
set interfaces ethernet eth3 address 172.16.2.1/24
set protocols ospf parameters router-id 1.1.1.1
set protocols ospf area 0 network 10.0.0.0/24
set protocols ospf area 0 network 172.16.1.0/24
set protocols ospf area 0 network 172.16.2.0/24"

echo "=== router-tokyo の設定を投入中（意図的なミスあり）==="
configure_vyos "$LAB_NAME" router-tokyo \
  "set interfaces ethernet eth1 address 172.16.1.2/24
set interfaces ethernet eth2 address 10.1.0.1/24
set protocols ospf parameters router-id 2.2.2.2
set protocols ospf area 0 network 10.1.0.0/24
set protocols ospf area 0 network 172.16.10.0/24"

configure_vyos "$LAB_NAME" router-osaka \
  "set interfaces ethernet eth1 address 172.16.2.2/24
set interfaces ethernet eth2 address 10.2.0.1/24
set protocols ospf parameters router-id 3.3.3.3
set protocols ospf area 0 network 10.2.0.0/24
set protocols ospf area 0 network 172.16.2.0/24"

echo ""
echo "=== シナリオ 5 準備完了 ==="
echo "OSPF Neighbor が確立するまで 10-30 秒待ってから確認してください。"
echo ""
echo "症状: host-hq から host-tokyo へ ping が通らない"
echo ""
echo "調査開始:"
echo "  docker exec clab-${LAB_NAME}-host-hq ping -c 3 -W 2 10.1.0.10"
echo "  docker exec -it clab-${LAB_NAME}-router-hq /bin/vbash -c 'show ip ospf neighbor'"
