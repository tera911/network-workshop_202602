#!/bin/bash
# Day 8: 完成版の設定を投入するスクリプト（Inter-VLAN ルーティング）
# 使い方: ./setup-complete.sh

set -e

echo "=== router-gw のサブインターフェースを設定中 ==="
sudo docker exec clab-day8-intervlan-routing-router-gw /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth1 vif 10 address 192.168.10.1/24
set interfaces ethernet eth1 vif 20 address 192.168.20.1/24
commit
save
exit
"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # 同じ VLAN 内（host1 → host3）"
echo "  sudo docker exec clab-day8-intervlan-routing-host1 ping -c 3 192.168.10.13"
echo ""
echo "  # 異なる VLAN 間（host1 → host2: ルーター経由）"
echo "  sudo docker exec clab-day8-intervlan-routing-host1 ping -c 3 192.168.20.12"
echo ""
echo "  # 経路確認"
echo "  sudo docker exec clab-day8-intervlan-routing-host1 traceroute 192.168.20.12"
