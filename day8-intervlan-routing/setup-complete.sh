#!/bin/bash
# Day 8: 完成版の設定を投入するスクリプト（Inter-VLAN ルーティング）
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day8-intervlan-routing"

wait_for_vyos "$LAB_NAME" router-gw

configure_vyos "$LAB_NAME" router-gw \
  "set interfaces ethernet eth1 vif 10 address 192.168.10.1/24
set interfaces ethernet eth1 vif 20 address 192.168.20.1/24"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # 同じ VLAN 内（host1 → host3）"
echo "  docker exec clab-${LAB_NAME}-host1 ping -c 3 192.168.10.13"
echo ""
echo "  # 異なる VLAN 間（host1 → host2: ルーター経由）"
echo "  docker exec clab-${LAB_NAME}-host1 ping -c 3 192.168.20.12"
echo ""
echo "  # 経路確認"
echo "  docker exec clab-${LAB_NAME}-host1 traceroute 192.168.20.12"
