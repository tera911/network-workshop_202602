#!/bin/bash
# Day 10 シナリオ 2: ルーティング不足のある構成を投入
# 使い方: ./setup-scenario2.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="scenario2"

wait_for_vyos "$LAB_NAME" router1 router2

configure_vyos "$LAB_NAME" router1 \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 10.0.0.1/24
set protocols static route 192.168.2.0/24 next-hop 10.0.0.2"

echo "=== router2 の設定を投入中（意図的なミスあり）==="
configure_vyos "$LAB_NAME" router2 \
  "set interfaces ethernet eth1 address 10.0.0.2/24
set interfaces ethernet eth2 address 192.168.2.1/24"

echo ""
echo "=== シナリオ 2 準備完了 ==="
echo "症状: host1 から host2 へ ping が通らない"
echo "ヒント: router1 から host2 への ping は通る"
echo ""
echo "調査開始:"
echo "  docker exec clab-${LAB_NAME}-host1 ping -c 3 -W 2 192.168.2.10"
