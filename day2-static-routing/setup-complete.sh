#!/bin/bash
# Day 2: 完成版の設定を投入するスクリプト
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day2-static-routing"

wait_for_vyos "$LAB_NAME" router-hq router-tokyo router-osaka

configure_vyos "$LAB_NAME" router-hq \
  "set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth2 address 172.16.1.1/24
set interfaces ethernet eth3 address 172.16.2.1/24
set protocols static route 10.1.0.0/24 next-hop 172.16.1.2
set protocols static route 10.2.0.0/24 next-hop 172.16.2.2"

configure_vyos "$LAB_NAME" router-tokyo \
  "set interfaces ethernet eth1 address 172.16.1.2/24
set interfaces ethernet eth2 address 10.1.0.1/24
set protocols static route 10.0.0.0/24 next-hop 172.16.1.1
set protocols static route 10.2.0.0/24 next-hop 172.16.1.1"

configure_vyos "$LAB_NAME" router-osaka \
  "set interfaces ethernet eth1 address 172.16.2.2/24
set interfaces ethernet eth2 address 10.2.0.1/24
set protocols static route 10.0.0.0/24 next-hop 172.16.2.1
set protocols static route 10.1.0.0/24 next-hop 172.16.2.1"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # HQ → Tokyo"
echo "  docker exec clab-${LAB_NAME}-host-hq ping -c 3 10.1.0.10"
echo ""
echo "  # HQ → Osaka"
echo "  docker exec clab-${LAB_NAME}-host-hq ping -c 3 10.2.0.10"
echo ""
echo "  # Tokyo → Osaka"
echo "  docker exec clab-${LAB_NAME}-host-tokyo ping -c 3 10.2.0.10"
