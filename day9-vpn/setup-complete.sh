#!/bin/bash
# Day 9: 完成版の設定を投入するスクリプト（WireGuard VPN）
# 使い方: ./setup-complete.sh
#
# このスクリプトは:
# 1. 各拠点ルーターで WireGuard 鍵ペアを生成
# 2. 公開鍵を交換して VPN トンネルを設定

set -e
source "$(dirname "$0")/../scripts/vyos-setup-helpers.sh"

LAB_NAME="day9-vpn"

wait_for_vyos "$LAB_NAME" router-site-a router-site-b

echo "=== WireGuard 鍵ペアを生成中 ==="

# Site A の鍵生成
docker exec clab-${LAB_NAME}-router-site-a bash -c "wg genkey | tee /tmp/privkey | wg pubkey > /tmp/pubkey"
SITE_A_PRIVKEY=$(docker exec clab-${LAB_NAME}-router-site-a cat /tmp/privkey)
SITE_A_PUBKEY=$(docker exec clab-${LAB_NAME}-router-site-a cat /tmp/pubkey)

# Site B の鍵生成
docker exec clab-${LAB_NAME}-router-site-b bash -c "wg genkey | tee /tmp/privkey | wg pubkey > /tmp/pubkey"
SITE_B_PRIVKEY=$(docker exec clab-${LAB_NAME}-router-site-b cat /tmp/privkey)
SITE_B_PUBKEY=$(docker exec clab-${LAB_NAME}-router-site-b cat /tmp/pubkey)

echo "  Site A Public Key: $SITE_A_PUBKEY"
echo "  Site B Public Key: $SITE_B_PUBKEY"
echo ""

configure_vyos "$LAB_NAME" router-site-a \
  "set interfaces ethernet eth1 address 10.1.0.1/24
set interfaces ethernet eth2 address 203.0.113.1/24
set protocols static route 198.51.100.0/24 next-hop 203.0.113.254
set interfaces wireguard wg0 address 10.10.10.1/24
set interfaces wireguard wg0 port 51820
set interfaces wireguard wg0 private-key ${SITE_A_PRIVKEY}
set interfaces wireguard wg0 peer site-b public-key ${SITE_B_PUBKEY}
set interfaces wireguard wg0 peer site-b allowed-ips 10.2.0.0/24
set interfaces wireguard wg0 peer site-b allowed-ips 10.10.10.2/32
set interfaces wireguard wg0 peer site-b endpoint 198.51.100.1:51820
set protocols static route 10.2.0.0/24 next-hop 10.10.10.2"

configure_vyos "$LAB_NAME" router-site-b \
  "set interfaces ethernet eth1 address 198.51.100.1/24
set interfaces ethernet eth2 address 10.2.0.1/24
set protocols static route 203.0.113.0/24 next-hop 198.51.100.254
set interfaces wireguard wg0 address 10.10.10.2/24
set interfaces wireguard wg0 port 51820
set interfaces wireguard wg0 private-key ${SITE_B_PRIVKEY}
set interfaces wireguard wg0 peer site-a public-key ${SITE_A_PUBKEY}
set interfaces wireguard wg0 peer site-a allowed-ips 10.1.0.0/24
set interfaces wireguard wg0 peer site-a allowed-ips 10.10.10.1/32
set interfaces wireguard wg0 peer site-a endpoint 203.0.113.1:51820
set protocols static route 10.1.0.0/24 next-hop 10.10.10.1"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "WireGuard トンネルが確立するまで数秒待ってから確認してください。"
echo ""
echo "確認コマンド:"
echo "  # Site A → Site B（VPN 経由）"
echo "  docker exec clab-${LAB_NAME}-host-site-a ping -c 3 10.2.0.10"
echo ""
echo "  # Site B → Site A"
echo "  docker exec clab-${LAB_NAME}-host-site-b ping -c 3 10.1.0.10"
echo ""
echo "  # WireGuard インターフェース確認"
echo "  docker exec -it clab-${LAB_NAME}-router-site-a /bin/vbash -c 'show interfaces wireguard wg0'"
