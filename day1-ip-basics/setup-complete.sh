#!/bin/bash
# Day 1: 完成版の設定を投入するスクリプト
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day1-ip-basics"

wait_for_vyos "$LAB_NAME" router1 router2

configure_vyos "$LAB_NAME" router1 \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 10.0.0.1/24
set protocols static route 192.168.2.0/24 next-hop 10.0.0.2"

configure_vyos "$LAB_NAME" router2 \
  "set interfaces ethernet eth1 address 10.0.0.2/24
set interfaces ethernet eth2 address 192.168.2.1/24
set protocols static route 192.168.1.0/24 next-hop 10.0.0.1"

echo ""
echo "=== 設定完了 ==="
echo "確認: docker exec clab-${LAB_NAME}-host1 ping -c 3 192.168.2.10"
