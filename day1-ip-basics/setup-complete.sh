#!/bin/bash
# Day 1: 完成版の設定を投入するスクリプト
# 使い方: ./setup-complete.sh

set -e

echo "=== router1 の設定を投入中 ==="
sudo docker exec -it clab-day1-ip-basics-router1 /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 10.0.0.1/24
set protocols static route 192.168.2.0/24 next-hop 10.0.0.2
commit
save
exit
"

echo "=== router2 の設定を投入中 ==="
sudo docker exec -it clab-day1-ip-basics-router2 /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 address 10.0.0.2/24
set interfaces ethernet eth2 address 192.168.2.1/24
set protocols static route 192.168.1.0/24 next-hop 10.0.0.1
commit
save
exit
"

echo ""
echo "=== 設定完了 ==="
echo "確認: sudo docker exec -it clab-day1-ip-basics-host1 ping -c 3 192.168.2.10"
