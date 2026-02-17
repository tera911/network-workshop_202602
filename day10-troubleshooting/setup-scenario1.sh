#!/bin/bash
# Day 10 シナリオ 1: IP 設定ミスのある構成を投入
# 使い方: ./setup-scenario1.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="scenario1"

wait_for_vyos "$LAB_NAME" router

configure_vyos "$LAB_NAME" router \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 192.168.2.1/24
set protocols static route 192.168.10.0/24 next-hop 192.168.1.10"

echo ""
echo "=== シナリオ 1 準備完了 ==="
echo "症状: host1 から host2 へ ping が通らない"
echo ""
echo "調査開始:"
echo "  docker exec clab-${LAB_NAME}-host1 ping -c 3 -W 2 192.168.2.10"
