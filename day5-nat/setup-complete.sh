#!/bin/bash
# Day 5: 完成版の設定を投入するスクリプト（NAT）
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day5-nat"

wait_for_vyos "$LAB_NAME" router-gw

configure_vyos "$LAB_NAME" router-gw \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 203.0.113.1/24
set nat source rule 10 outbound-interface name eth2
set nat source rule 10 source address 192.168.1.0/24
set nat source rule 10 translation address masquerade"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # 内部 → 外部への ping"
echo "  docker exec clab-${LAB_NAME}-host-internal ping -c 3 203.0.113.10"
echo ""
echo "  # tcpdump でアドレス変換を確認（別ターミナルで実行）"
echo "  docker exec clab-${LAB_NAME}-server-external sh -c 'apk add --no-cache tcpdump && tcpdump -i eth1 icmp -n'"
