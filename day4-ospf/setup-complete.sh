#!/bin/bash
# Day 4: 完成版の設定を投入するスクリプト（OSPF）
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day4-ospf"

wait_for_vyos "$LAB_NAME" router-hq router-tokyo router-osaka

configure_vyos "$LAB_NAME" router-hq \
  "set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth2 address 172.16.1.1/24
set interfaces ethernet eth3 address 172.16.2.1/24
set protocols ospf parameters router-id 1.1.1.1
set protocols ospf area 0 network 10.0.0.0/24
set protocols ospf area 0 network 172.16.1.0/24
set protocols ospf area 0 network 172.16.2.0/24"

configure_vyos "$LAB_NAME" router-tokyo \
  "set interfaces ethernet eth1 address 172.16.1.2/24
set interfaces ethernet eth2 address 10.1.0.1/24
set interfaces ethernet eth3 address 172.16.3.1/24
set protocols ospf parameters router-id 2.2.2.2
set protocols ospf area 0 network 10.1.0.0/24
set protocols ospf area 0 network 172.16.1.0/24
set protocols ospf area 0 network 172.16.3.0/24"

configure_vyos "$LAB_NAME" router-osaka \
  "set interfaces ethernet eth1 address 172.16.2.2/24
set interfaces ethernet eth2 address 10.2.0.1/24
set interfaces ethernet eth3 address 172.16.3.2/24
set protocols ospf parameters router-id 3.3.3.3
set protocols ospf area 0 network 10.2.0.0/24
set protocols ospf area 0 network 172.16.2.0/24
set protocols ospf area 0 network 172.16.3.0/24"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "OSPF Neighbor が確立するまで 10-30 秒待ってから確認してください。"
echo ""
echo "確認コマンド:"
echo "  # OSPF Neighbor 確認"
echo "  docker exec clab-${LAB_NAME}-router-hq /bin/vbash -c 'show ip ospf neighbor'"
echo ""
echo "  # ルーティングテーブル確認"
echo "  docker exec clab-${LAB_NAME}-router-hq /bin/vbash -c 'show ip route'"
echo ""
echo "  # 疎通確認"
echo "  docker exec clab-${LAB_NAME}-host-hq ping -c 3 10.1.0.10"
echo "  docker exec clab-${LAB_NAME}-host-tokyo ping -c 3 10.2.0.10"
