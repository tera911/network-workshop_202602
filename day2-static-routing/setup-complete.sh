#!/bin/bash
# Day 2: 完成版の設定を投入するスクリプト
# 使い方: ./setup-complete.sh

set -e

echo "=== router-hq の設定を投入中 ==="
sudo docker exec clab-day2-static-routing-router-hq /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth2 address 172.16.1.1/24
set interfaces ethernet eth3 address 172.16.2.1/24
set protocols static route 10.1.0.0/24 next-hop 172.16.1.2
set protocols static route 10.2.0.0/24 next-hop 172.16.2.2
commit
save
exit
"

echo "=== router-tokyo の設定を投入中 ==="
sudo docker exec clab-day2-static-routing-router-tokyo /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 172.16.1.2/24
set interfaces ethernet eth2 address 10.1.0.1/24
set protocols static route 10.0.0.0/24 next-hop 172.16.1.1
set protocols static route 10.2.0.0/24 next-hop 172.16.1.1
commit
save
exit
"

echo "=== router-osaka の設定を投入中 ==="
sudo docker exec clab-day2-static-routing-router-osaka /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 172.16.2.2/24
set interfaces ethernet eth2 address 10.2.0.1/24
set protocols static route 10.0.0.0/24 next-hop 172.16.2.1
set protocols static route 10.1.0.0/24 next-hop 172.16.2.1
commit
save
exit
"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # HQ → Tokyo"
echo "  sudo docker exec clab-day2-static-routing-host-hq ping -c 3 10.1.0.10"
echo ""
echo "  # HQ → Osaka"
echo "  sudo docker exec clab-day2-static-routing-host-hq ping -c 3 10.2.0.10"
echo ""
echo "  # Tokyo → Osaka"
echo "  sudo docker exec clab-day2-static-routing-host-tokyo ping -c 3 10.2.0.10"
