#!/bin/bash
# Day 5: 完成版の設定を投入するスクリプト（NAT）
# 使い方: ./setup-complete.sh

set -e

echo "=== router-gw の設定を投入中 ==="
sudo docker exec clab-day5-nat-router-gw /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 203.0.113.1/24
set nat source rule 10 outbound-interface name eth2
set nat source rule 10 source address 192.168.1.0/24
set nat source rule 10 translation address masquerade
commit
save
exit
"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # 内部 → 外部への ping"
echo "  sudo docker exec clab-day5-nat-host-internal ping -c 3 203.0.113.10"
echo ""
echo "  # tcpdump でアドレス変換を確認（別ターミナルで実行）"
echo "  sudo docker exec clab-day5-nat-server-external sh -c 'apk add --no-cache tcpdump && tcpdump -i eth1 icmp -n'"
