#!/bin/bash
# Day 7: 完成版の設定を投入するスクリプト（ファイアウォール）
# 使い方: ./setup-complete.sh

set -e

echo "=== router-fw の設定を投入中 ==="
sudo docker exec clab-day7-firewall-router-fw /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure

set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth2 address 172.16.0.1/24
set interfaces ethernet eth3 address 203.0.113.1/24

set firewall ipv4 forward filter default-action drop

set firewall ipv4 forward filter rule 1 action accept
set firewall ipv4 forward filter rule 1 state established
set firewall ipv4 forward filter rule 1 state related

set firewall ipv4 forward filter rule 10 action accept
set firewall ipv4 forward filter rule 10 inbound-interface name eth1
set firewall ipv4 forward filter rule 10 outbound-interface name eth3

set firewall ipv4 forward filter rule 20 action accept
set firewall ipv4 forward filter rule 20 inbound-interface name eth1
set firewall ipv4 forward filter rule 20 outbound-interface name eth2

set firewall ipv4 forward filter rule 30 action accept
set firewall ipv4 forward filter rule 30 inbound-interface name eth3
set firewall ipv4 forward filter rule 30 outbound-interface name eth2
set firewall ipv4 forward filter rule 30 protocol tcp
set firewall ipv4 forward filter rule 30 destination port 80

commit
save
exit
"

echo ""
echo "=== 設定完了 ==="
echo ""
echo "確認コマンド:"
echo "  # 内部 → 外部（許可）"
echo "  sudo docker exec clab-day7-firewall-host-internal ping -c 3 203.0.113.10"
echo ""
echo "  # 外部 → 内部（拒否）"
echo "  sudo docker exec clab-day7-firewall-host-external ping -c 3 -W 2 192.168.1.10"
echo ""
echo "  # 外部 → DMZ HTTP テスト"
echo "  # ターミナル1: sudo docker exec -it clab-day7-firewall-host-dmz sh -c 'while true; do echo -e \"HTTP/1.0 200 OK\r\n\r\nHello from DMZ\" | nc -l -p 80; done'"
echo "  # ターミナル2: sudo docker exec clab-day7-firewall-host-external sh -c 'echo \"GET /\" | nc -w 3 172.16.0.10 80'"
