#!/bin/bash
# Day 10 シナリオ 2: ルーティング不足のある構成を投入
# 使い方: ./setup-scenario2.sh

set -e

echo "=== router1 の設定を投入中 ==="
sudo docker exec clab-scenario2-router1 /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 10.0.0.1/24
set protocols static route 192.168.2.0/24 next-hop 10.0.0.2
commit
save
exit
"

echo "=== router2 の設定を投入中（意図的なミスあり）==="
sudo docker exec clab-scenario2-router2 /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 10.0.0.2/24
set interfaces ethernet eth2 address 192.168.2.1/24
commit
save
exit
"

echo ""
echo "=== シナリオ 2 準備完了 ==="
echo "症状: host1 から host2 へ ping が通らない"
echo "ヒント: router1 から host2 への ping は通る"
echo ""
echo "調査開始:"
echo "  sudo docker exec clab-scenario2-host1 ping -c 3 -W 2 192.168.2.10"
