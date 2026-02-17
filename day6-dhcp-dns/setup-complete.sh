#!/bin/bash
# Day 6: 完成版の設定を投入するスクリプト（DHCP / DNS）
# 使い方: ./setup-complete.sh

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day6-dhcp-dns"

wait_for_vyos "$LAB_NAME" router-gw

configure_vyos "$LAB_NAME" router-gw \
  "set interfaces ethernet eth1 address 192.168.1.1/24
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 start 192.168.1.100
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 stop 192.168.1.200
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 option default-router 192.168.1.1
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 option name-server 192.168.1.1
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 lease 86400
set service dns forwarding listen-address 192.168.1.1
set service dns forwarding allow-from 192.168.1.0/24
set service dns forwarding system
set system static-host-mapping host-name gateway.lab inet 192.168.1.1
set system static-host-mapping host-name server.lab inet 192.168.1.50"

echo "=== DHCP サーバーの起動を待機中（5秒）... ==="
sleep 5

echo "=== host-pc1 で DHCP リクエスト実行中 ==="
docker exec clab-${LAB_NAME}-host-pc1 udhcpc -i eth1 -n -q || echo "  (DHCP 取得を試行中...)"
sleep 2

echo "=== host-pc2 で DHCP リクエスト実行中 ==="
docker exec clab-${LAB_NAME}-host-pc2 udhcpc -i eth1 -n -q || echo "  (DHCP 取得を試行中...)"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # DHCP リースの確認"
echo "  docker exec -it clab-${LAB_NAME}-router-gw /bin/vbash -c 'show dhcp server leases'"
echo ""
echo "  # host-pc1 の IP 確認"
echo "  docker exec clab-${LAB_NAME}-host-pc1 ip addr show eth1"
echo ""
echo "  # host-pc2 の IP 確認"
echo "  docker exec clab-${LAB_NAME}-host-pc2 ip addr show eth1"
echo ""
echo "  # ホスト間の疎通確認"
echo "  docker exec clab-${LAB_NAME}-host-pc1 ping -c 3 192.168.1.50"
