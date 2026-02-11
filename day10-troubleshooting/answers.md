# Day 10: トラブルシューティング — 解答とヒント

> まずは自力で解いてから、この解答を確認してください！

---

## シナリオ 1: IP 設定ミス

### 原因

host1 の IP アドレスが **192.168.10.10/24** に設定されている。
router の eth1 は **192.168.1.1/24** なので、host1 と router は**異なるサブネット**に属している。

```
host1:    192.168.10.0/24  ← 間違い
router:   192.168.1.0/24   ← 正しいネットワーク
```

host1 の IP が 192.168.1.x/24 でないと、router のインターフェースと通信できない。

### 修正方法

host1 で IP アドレスを修正:

```bash
sudo docker exec clab-scenario1-host1 /bin/sh
ip addr del 192.168.10.10/24 dev eth1
ip addr add 192.168.1.10/24 dev eth1
ip route del default
ip route add default via 192.168.1.1
```

### 検証

```bash
sudo docker exec clab-scenario1-host1 ping -c 3 192.168.2.10
```

### tcpdump での診断方法

修正前に router の eth1 で tcpdump を実行しても、ARP リクエストすら見えない（サブネットが異なるため）:

```bash
sudo docker exec clab-scenario1-router bash -c "tcpdump -i eth1 -n -c 5"
```

---

## シナリオ 2: ルーティング不足

### 原因

router2 に **192.168.1.0/24（host1 のネットワーク）への経路がない**。

- router1 → router2 方向: router1 は 192.168.2.0/24 への経路を持っている → OK
- router2 → router1 方向: router2 は 192.168.1.0/24 への経路を**持っていない** → NG

host1 → host2 の ICMP echo request は到着するが、echo reply の戻り経路がない。

```
host1 → router1 → router2 → host2  ← リクエストは到達
host2 → router2 → ???              ← 応答が返れない（経路なし）
```

### 修正方法

router2 に戻り経路を追加:

```bash
sudo docker exec -it clab-scenario2-router2 /bin/vbash
configure
set protocols static route 192.168.1.0/24 next-hop 10.0.0.1
commit
save
exit
```

### 検証

```bash
sudo docker exec clab-scenario2-host1 ping -c 3 192.168.2.10
```

### tcpdump での診断方法

router2 の eth2 で tcpdump を実行すると、ICMP echo request は到着しているのに reply が見えない:

```bash
# router2 の eth1 側（host2 への方向）
sudo docker exec clab-scenario2-router2 bash -c "tcpdump -i eth2 icmp -n -c 5"
# → echo request が見える（到着している）

# router2 の eth1 側（router1 への方向）
sudo docker exec clab-scenario2-router2 bash -c "tcpdump -i eth1 icmp -n -c 5"
# → echo reply が見えない（戻り経路がないため）
```

---

## シナリオ 3: NAT 設定漏れ

### 原因

NAT の outbound-interface が **eth1**（内部側）に設定されている。
正しくは **eth2**（外部側）であるべき。

```
誤: set nat source rule 10 outbound-interface name eth1  ← 内部インターフェース
正: set nat source rule 10 outbound-interface name eth2  ← 外部インターフェース
```

eth1 方向への通信に対して NAT が適用されてしまい、eth2（外部）方向への通信では NAT が動作しない。

### 修正方法

```bash
sudo docker exec -it clab-scenario3-router-gw /bin/vbash
configure
delete nat source rule 10 outbound-interface name eth1
set nat source rule 10 outbound-interface name eth2
commit
save
exit
```

### 検証

```bash
sudo docker exec clab-scenario3-host-internal ping -c 3 203.0.113.10
```

### tcpdump での診断方法

server-external 側で tcpdump を実行し、パケットが到着するか確認:

```bash
# 修正前: パケットが到着しても送信元が 192.168.1.10（プライベート IP）のまま
# → server-external は応答を返せない（192.168.1.10 への経路がない）
sudo docker exec clab-scenario3-server-external sh -c "apk add --no-cache tcpdump && tcpdump -i eth1 -n -c 5"

# 修正後: 送信元が 203.0.113.1（NAT 変換済み）になる
```

---

## シナリオ 4: ファイアウォール設定ミス

### 原因

外部→DMZ の HTTP 許可ルール（rule 30）の destination port が **8080** に設定されている。
DMZ の Web サーバーはポート **80** で待ち受けているため、ポート 80 へのアクセスがブロックされる。

```
誤: set firewall ipv4 forward filter rule 30 destination port 8080
正: set firewall ipv4 forward filter rule 30 destination port 80
```

### 修正方法

```bash
sudo docker exec -it clab-scenario4-router-fw /bin/vbash
configure
delete firewall ipv4 forward filter rule 30 destination port 8080
set firewall ipv4 forward filter rule 30 destination port 80
commit
save
exit
```

### 検証

```bash
# host-dmz で HTTP サーバーを起動
sudo docker exec -it clab-scenario4-host-dmz sh -c "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nHello' | nc -l -p 80; done" &

# host-external から HTTP アクセス
sudo docker exec clab-scenario4-host-external sh -c "echo 'GET /' | nc -w 3 172.16.0.10 80"
```

### tcpdump での診断方法

router-fw の eth2（DMZ 側）で tcpdump を実行して、TCP 80 のパケットが転送されているか確認:

```bash
sudo docker exec clab-scenario4-router-fw bash -c "tcpdump -i eth2 port 80 -n -c 5"
# → 修正前: パケットが見えない（ファイアウォールでドロップ）
# → 修正後: TCP SYN パケットが転送される
```

---

## シナリオ 5: OSPF 設定ミス

### 原因

router-tokyo の OSPF network 文が **172.16.10.0/24** になっている。
正しくは **172.16.1.0/24**（router-hq との接続ネットワーク）。

```
誤: network 172.16.10.0/24 area 0  ← 存在しないネットワーク
正: network 172.16.1.0/24 area 0   ← HQ との接続ネットワーク
```

router-tokyo の eth1（172.16.1.2/24）が OSPF に参加しないため、router-hq との Neighbor 関係が確立しない。

### 修正方法

```bash
sudo docker exec -it clab-scenario5-router-tokyo /bin/vbash
configure
delete protocols ospf area 0 network 172.16.10.0/24
set protocols ospf area 0 network 172.16.1.0/24
commit
save
exit
```

### 検証

```bash
# OSPF Neighbor 確認（10-30 秒待つ）
sudo docker exec -it clab-scenario5-router-hq /bin/vbash -c "show ip ospf neighbor"

# 疎通確認
sudo docker exec clab-scenario5-host-hq ping -c 3 10.1.0.10
```

### tcpdump での診断方法

router-hq の eth2（Tokyo 向け）で OSPF パケットを確認:

```bash
sudo docker exec clab-scenario5-router-hq bash -c "tcpdump -i eth2 proto ospf -n -c 10"
# → OSPF Hello パケットは router-hq から送信されている
# → router-tokyo からの Hello も見えるが、Neighbor が Full にならない

# router-tokyo 側でも確認:
sudo docker exec clab-scenario5-router-tokyo bash -c "tcpdump -i eth1 proto ospf -n -c 10"
# → Hello パケットの交換は行われているが、network 文の不一致で
#    eth1 が OSPF インターフェースとして認識されていない
```

---

## 共通のデバッグテクニック

### 1. レイヤーごとの確認

```
L1（物理層）: リンクは UP か？ → ip link show
L2（データリンク層）: ARP は動作しているか？ → ip neigh show
L3（ネットワーク層）: IP/ルーティングは正しいか？ → ip route show
L4（トランスポート層）: ポートは正しいか？ → nc -z host port
```

### 2. 比較法

正しく動作するパスと動作しないパスを比較する。

### 3. 二分法

問題箇所を絞り込むために、パスの中間地点で確認する。
