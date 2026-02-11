# Day 10: トラブルシューティング総合演習

## 学習目標

- tcpdump を使ったパケットキャプチャの基本を習得する
- ネットワーク障害の切り分け手順を理解する
- Day 1〜9 で学んだ知識を活用して障害を特定・修正できるようになる

---

## 事前知識: tcpdump の使い方

### tcpdump とは

ネットワークインターフェースを流れるパケットを**リアルタイムでキャプチャ**するツール。
ネットワーク障害の原因調査に最も重要なツールの1つです。

### 基本的な使い方

```bash
# eth1 のすべてのパケットをキャプチャ
tcpdump -i eth1

# ICMP（ping）パケットのみ
tcpdump -i eth1 icmp

# 特定ホスト宛のパケット
tcpdump -i eth1 host 192.168.1.10

# 特定ポートのパケット
tcpdump -i eth1 port 80

# DNS 名前解決せず表示（-n オプション、通常はこれを使う）
tcpdump -i eth1 -n

# パケット数を制限
tcpdump -i eth1 -n -c 10
```

### tcpdump の読み方

```
10:23:45.123456 IP 192.168.1.10 > 203.0.113.10: ICMP echo request
   │              │   │              │              │
   タイムスタンプ   │   送信元         宛先            プロトコル・内容
                  プロトコル
```

### Alpine Linux での tcpdump インストール

```bash
apk add --no-cache tcpdump
```

### VyOS での tcpdump

VyOS では `tcpdump` がプリインストールされています:

```bash
# VyOS 内で直接実行
tcpdump -i eth1 -n
```

---

## トラブルシューティングの基本手順

### 1. 症状を確認する

```bash
ping <宛先>           # 通信できるか？
traceroute <宛先>      # どこまで到達するか？
```

### 2. 段階的に切り分ける

```
自分自身 → デフォルトゲートウェイ → 次のルーター → ... → 宛先
  (1)          (2)                  (3)              (N)
```

近い方から順に確認し、通信が途切れるポイントを特定する。

### 3. tcpdump で詳細を調べる

通信が途切れるポイントの前後で tcpdump を実行し、パケットが:
- **送信されているか？** → 送信元の問題
- **到着しているか？** → 経路の問題
- **応答が返っているか？** → 宛先または戻り経路の問題

### 4. 設定を確認・修正する

```bash
# IP アドレス確認
ip addr show
show interfaces            # VyOS

# ルーティング確認
ip route show
show ip route              # VyOS

# NAT 確認
show nat source rules      # VyOS

# ファイアウォール確認
show firewall              # VyOS

# OSPF 確認
show ip ospf neighbor      # VyOS
```

---

## シナリオ一覧

| シナリオ | テーマ | 関連 Day | 難易度 |
|---------|--------|---------|--------|
| 1 | IP 設定ミス | Day 1 | ★☆☆ |
| 2 | ルーティング不足 | Day 2 | ★★☆ |
| 3 | NAT 設定漏れ | Day 5 | ★★☆ |
| 4 | ファイアウォール設定ミス | Day 7 | ★★★ |
| 5 | OSPF 設定ミス | Day 4 | ★★★ |

各シナリオは独立しているので、順番に実施しても、興味のあるものだけ実施しても OK です。

---

## シナリオ 1: IP 設定ミス

### 症状

host1 から host2 へ ping が通らない。

### ラボを起動する

```bash
cd day10-troubleshooting
sudo containerlab deploy -t scenario1.clab.yml
./setup-scenario1.sh
```

### 調査のヒント

1. まず host1 から host2 に ping を試す:
   ```bash
   sudo docker exec clab-scenario1-host1 ping -c 3 -W 2 192.168.2.10
   ```

2. host1 の IP 設定を確認:
   ```bash
   sudo docker exec clab-scenario1-host1 ip addr show eth1
   ```

3. router のインターフェースを確認:
   ```bash
   sudo docker exec -it clab-scenario1-router /bin/vbash
   show interfaces
   ```

4. host1 と router が同じサブネットにいるか確認

### クリーンアップ

```bash
sudo containerlab destroy -t scenario1.clab.yml
```

---

## シナリオ 2: ルーティング不足

### 症状

host1 から host2 へ ping が通らない。しかし、router1 から host2 への ping は通る。

### ラボを起動する

```bash
sudo containerlab deploy -t scenario2.clab.yml
./setup-scenario2.sh
```

### 調査のヒント

1. host1 から host2 に ping:
   ```bash
   sudo docker exec clab-scenario2-host1 ping -c 3 -W 2 192.168.2.10
   ```

2. router1 から host2 に ping:
   ```bash
   sudo docker exec -it clab-scenario2-router1 /bin/vbash
   ping 192.168.2.10 count 3
   ```

3. 各ルーターのルーティングテーブルを確認:
   ```bash
   show ip route
   ```

4. router2 側で tcpdump を実行して、リクエストが到着するか確認:
   ```bash
   sudo docker exec clab-scenario2-router2 bash -c "tcpdump -i eth2 icmp -n -c 5"
   ```

5. 片方向の通信はどこで途切れているか？

### クリーンアップ

```bash
sudo containerlab destroy -t scenario2.clab.yml
```

---

## シナリオ 3: NAT 設定漏れ

### 症状

host-internal から server-external へ ping が通らない。

### ラボを起動する

```bash
sudo containerlab deploy -t scenario3.clab.yml
./setup-scenario3.sh
```

### 調査のヒント

1. host-internal から server-external に ping:
   ```bash
   sudo docker exec clab-scenario3-host-internal ping -c 3 -W 2 203.0.113.10
   ```

2. router-gw の NAT 設定を確認:
   ```bash
   sudo docker exec -it clab-scenario3-router-gw /bin/vbash
   show nat source rules
   ```

3. server-external 側で tcpdump:
   ```bash
   sudo docker exec clab-scenario3-server-external sh -c "apk add --no-cache tcpdump && tcpdump -i eth1 -n -c 10"
   ```
   別ターミナルで ping を送信し、パケットの送信元 IP を確認

4. NAT ルールの outbound-interface は正しいか？

### クリーンアップ

```bash
sudo containerlab destroy -t scenario3.clab.yml
```

---

## シナリオ 4: ファイアウォール設定ミス

### 症状

host-internal から host-external への ping は通る。
しかし、host-external から host-dmz の HTTP（TCP 80）にアクセスできない。

### ラボを起動する

```bash
sudo containerlab deploy -t scenario4.clab.yml
./setup-scenario4.sh
```

### 調査のヒント

1. host-internal → host-external の ping を確認（通るはず）:
   ```bash
   sudo docker exec clab-scenario4-host-internal ping -c 3 203.0.113.10
   ```

2. host-dmz で HTTP サーバーを起動:
   ```bash
   sudo docker exec -it clab-scenario4-host-dmz sh -c "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nHello' | nc -l -p 80; done" &
   ```

3. host-external から HTTP アクセス:
   ```bash
   sudo docker exec clab-scenario4-host-external sh -c "echo 'GET /' | nc -w 3 172.16.0.10 80"
   ```

4. router-fw のファイアウォールルールを確認:
   ```bash
   sudo docker exec -it clab-scenario4-router-fw /bin/vbash
   show firewall
   ```

5. 外部→DMZ の HTTP ルールに問題はないか？ ポート番号や action を確認

### クリーンアップ

```bash
sudo containerlab destroy -t scenario4.clab.yml
```

---

## シナリオ 5: OSPF 設定ミス

### 症状

3拠点（HQ, Tokyo, Osaka）間で OSPF が正しく動作しない。
host-hq から host-tokyo へ ping が通らない。

### ラボを起動する

```bash
sudo containerlab deploy -t scenario5.clab.yml
./setup-scenario5.sh
```

### 調査のヒント

1. host-hq から host-tokyo に ping:
   ```bash
   sudo docker exec clab-scenario5-host-hq ping -c 3 -W 2 10.1.0.10
   ```

2. router-hq の OSPF Neighbor を確認:
   ```bash
   sudo docker exec -it clab-scenario5-router-hq /bin/vbash
   show ip ospf neighbor
   ```
   → Neighbor が確立されていない場合、設定に問題がある

3. 各ルーターの OSPF 設定を確認:
   ```bash
   show configuration commands | grep ospf
   ```

4. OSPF で広告しているネットワークは正しいか？
   ```bash
   show ip ospf interface
   ```

5. router-tokyo の OSPF ネットワーク設定を注意深く確認

### クリーンアップ

```bash
sudo containerlab destroy -t scenario5.clab.yml
```

---

## 全シナリオ共通: 解答の確認

各シナリオの解答とヒントは `answers.md` を参照してください。
ただし、まずは自力で原因を特定してから確認することをお勧めします。

---

## まとめ

今日学んだこと:

1. **tcpdump** = ネットワーク障害調査の最重要ツール
2. **段階的切り分け** = 近い方から順に確認して、問題箇所を絞り込む
3. **IP 設定ミス** = サブネットが一致しないと通信不可
4. **ルーティング不足** = 行き（forward）と帰り（return）の両方の経路が必要
5. **NAT / ファイアウォール** = ルールの細かい設定ミスが通信障害の原因になる
6. **OSPF** = ネットワーク宣言の誤りで Neighbor が確立しない

### トラブルシューティングのチェックリスト

```
□ IP アドレスとサブネットマスクは正しいか？
□ デフォルトゲートウェイは設定されているか？
□ ルーティングテーブルに宛先への経路があるか？
□ NAT ルールのインターフェースは正しいか？
□ ファイアウォールでブロックされていないか？
□ OSPF の Neighbor は確立されているか？
□ 物理リンクは UP しているか？
```

---

## クリーンアップ

すべてのシナリオを破棄:

```bash
sudo containerlab destroy -t scenario1.clab.yml 2>/dev/null
sudo containerlab destroy -t scenario2.clab.yml 2>/dev/null
sudo containerlab destroy -t scenario3.clab.yml 2>/dev/null
sudo containerlab destroy -t scenario4.clab.yml 2>/dev/null
sudo containerlab destroy -t scenario5.clab.yml 2>/dev/null
```
