#!/bin/bash
# Day 10 シナリオ 5: OSPF 設定ミスのある構成を投入
# 使い方: ./setup-scenario5.sh

set -e

echo "=== router-hq の設定を投入中 ==="
sudo docker exec clab-scenario5-router-hq /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth2 address 172.16.1.1/24
set interfaces ethernet eth3 address 172.16.2.1/24
set protocols ospf parameters router-id 1.1.1.1
set protocols ospf area 0 network 10.0.0.0/24
set protocols ospf area 0 network 172.16.1.0/24
set protocols ospf area 0 network 172.16.2.0/24
commit
save
exit
"

echo "=== router-tokyo の設定を投入中（意図的なミスあり）==="
sudo docker exec clab-scenario5-router-tokyo /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 172.16.1.2/24
set interfaces ethernet eth2 address 10.1.0.1/24
set protocols ospf parameters router-id 2.2.2.2
set protocols ospf area 0 network 10.1.0.0/24
set protocols ospf area 0 network 172.16.10.0/24
commit
save
exit
"

echo "=== router-osaka の設定を投入中 ==="
sudo docker exec clab-scenario5-router-osaka /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 172.16.2.2/24
set interfaces ethernet eth2 address 10.2.0.1/24
set protocols ospf parameters router-id 3.3.3.3
set protocols ospf area 0 network 10.2.0.0/24
set protocols ospf area 0 network 172.16.2.0/24
commit
save
exit
"

echo ""
echo "=== シナリオ 5 準備完了 ==="
echo "OSPF Neighbor が確立するまで 10-30 秒待ってから確認してください。"
echo ""
echo "症状: host-hq から host-tokyo へ ping が通らない"
echo ""
echo "調査開始:"
echo "  sudo docker exec clab-scenario5-host-hq ping -c 3 -W 2 10.1.0.10"
echo "  sudo docker exec -it clab-scenario5-router-hq /bin/vbash -c 'show ip ospf neighbor'"
