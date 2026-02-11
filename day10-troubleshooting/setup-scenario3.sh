#!/bin/bash
# Day 10 シナリオ 3: NAT 設定漏れのある構成を投入
# 使い方: ./setup-scenario3.sh

set -e

echo "=== router-gw の設定を投入中（意図的なミスあり）==="
sudo docker exec clab-scenario3-router-gw /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 203.0.113.1/24
set nat source rule 10 outbound-interface name eth1
set nat source rule 10 source address 192.168.1.0/24
set nat source rule 10 translation address masquerade
commit
save
exit
"

echo ""
echo "=== シナリオ 3 準備完了 ==="
echo "症状: host-internal から server-external へ ping が通らない"
echo ""
echo "調査開始:"
echo "  sudo docker exec clab-scenario3-host-internal ping -c 3 -W 2 203.0.113.10"
