# Day 3: VLAN

## 学習目標

- VLAN の概念と必要性を理解する
- 同じスイッチでも VLAN が違うと通信できないことを体験する
- Linux Bridge を使った VLAN 分離を設定できるようになる

---

## ネットワーク構成

4台のホストが1台のスイッチに接続された構成です。

```
              [switch]
             /  |  |  \
    [host1] [host2] [host3] [host4]
     VLAN10  VLAN20  VLAN10  VLAN20
    営業部   開発部   営業部   開発部
```

### VLAN 設計

| VLAN ID | 名称 | ネットワーク | 所属ホスト |
|---------|------|-------------|-----------|
| 10 | 営業部 | 192.168.10.0/24 | host1, host3 |
| 20 | 開発部 | 192.168.20.0/24 | host2, host4 |

---

## 事前知識: VLAN とは

### VLAN（Virtual LAN）とは

物理的に同じスイッチに接続されていても、**論理的にネットワークを分離**する技術。

### なぜ VLAN が必要？

1. **セキュリティ**: 部署ごとにネットワークを分離
2. **ブロードキャスト抑制**: 不要な通信を減らす
3. **柔軟な構成**: 物理配置に縛られない

### VLAN がない場合

```
[PC-A]---[スイッチ]---[PC-B]
    \              /
     [PC-C]---[PC-D]

→ 全員が同じネットワーク、全員が通信可能
```

### VLAN がある場合

```
[PC-A]---[スイッチ]---[PC-B]    ← VLAN 10（営業部）
    \              /
     [PC-C]---[PC-D]            ← VLAN 20（開発部）

→ VLAN 10 と VLAN 20 は互いに通信不可
  （ルーターがないと通信できない）
```

---

## ハンズオン

### Step 1: VLAN なしの状態を確認する

まず、演習用のラボを起動します:

```bash
cd day3-vlan
sudo containerlab deploy -t exercise.clab.yml
```

現在の状態では、すべてのホストが同じブリッジに接続されています。

host1 から他のすべてのホストに ping を打ってみましょう:

```bash
sudo docker exec -it clab-day3-exercise-host1 /bin/sh
```

```bash
# 同じ 192.168.10.0/24 の host3 への ping
ping -c 2 192.168.10.3

# 本来は通信できないはずの host2 への ping
ping -c 2 192.168.20.2

# 本来は通信できないはずの host4 への ping
ping -c 2 192.168.20.4
```

**注意**: IPアドレスが違うサブネットでも、同じL2ブリッジ上にいるため、
ARPが通って通信できてしまいます（これが問題！）。

### Step 2: 完成版で VLAN 分離を確認する

演習用を破棄して、完成版を起動:

```bash
sudo containerlab destroy -t exercise.clab.yml
sudo containerlab deploy -t topology.clab.yml
```

host1 から ping を試してみましょう:

```bash
sudo docker exec -it clab-day3-vlan-host1 /bin/sh
```

```bash
# 同じ VLAN 10 の host3 → 通信成功
ping -c 2 192.168.10.3

# 違う VLAN 20 の host2 → 通信失敗
ping -c 2 192.168.20.2

# 違う VLAN 20 の host4 → 通信失敗
ping -c 2 192.168.20.4
```

→ 同じ VLAN 内でしか通信できないことを確認！

### Step 3: スイッチのブリッジ構成を確認する

スイッチにログインして、ブリッジの状態を確認:

```bash
sudo docker exec -it clab-day3-vlan-switch /bin/sh
```

```bash
# ブリッジ一覧を表示
bridge link show

# ブリッジごとの接続ポートを確認
ip link show master br-vlan10
ip link show master br-vlan20
```

出力例:
```
# br-vlan10 に所属するポート
eth1: ... master br-vlan10
eth3: ... master br-vlan10

# br-vlan20 に所属するポート
eth2: ... master br-vlan20
eth4: ... master br-vlan20
```

---

## 演習問題

### 問題: 自分で VLAN を分離してみよう

完成版を破棄して、演習用を再起動:

```bash
sudo containerlab destroy -t topology.clab.yml
sudo containerlab deploy -t exercise.clab.yml
```

スイッチにログインして、ブリッジを分離してください:

```bash
sudo docker exec -it clab-day3-exercise-switch /bin/sh
```

現在の構成（すべて同じブリッジ）:
```bash
bridge link show
# eth1, eth2, eth3, eth4 がすべて br0 に所属
```

以下のコマンドで VLAN を分離:

```bash
# 1. 現在のブリッジからポートを外す
ip link set eth1 nomaster
ip link set eth2 nomaster
ip link set eth3 nomaster
ip link set eth4 nomaster

# 2. VLAN 10 用ブリッジを作成
ip link add br-vlan10 type bridge
ip link set br-vlan10 up

# 3. VLAN 20 用ブリッジを作成
ip link add br-vlan20 type bridge
ip link set br-vlan20 up

# 4. 各ポートを適切なブリッジに追加
ip link set eth1 master br-vlan10   # host1 → VLAN10
ip link set eth3 master br-vlan10   # host3 → VLAN10
ip link set eth2 master br-vlan20   # host2 → VLAN20
ip link set eth4 master br-vlan20   # host4 → VLAN20
```

### 確認

設定が完了したら、通信を確認:

```bash
# host1 から host3（同じ VLAN 10）→ 成功するはず
sudo docker exec -it clab-day3-exercise-host1 ping -c 2 192.168.10.3

# host1 から host2（異なる VLAN 20）→ 失敗するはず
sudo docker exec -it clab-day3-exercise-host1 ping -c 2 192.168.20.2
```

---

## 発展: タグVLAN（トランク）

### アクセスポートとトランクポート

- **アクセスポート**: 1つの VLAN のみ所属、タグなしフレーム
- **トランクポート**: 複数の VLAN を通す、タグ付きフレーム

### 802.1Q タグ

イーサネットフレームに VLAN ID を付加する規格:

```
[宛先MAC][送信元MAC][802.1Qタグ(VLAN ID)][タイプ][データ]
```

### VyOS でのタグ VLAN 設定

VyOS ルーターで VLAN を扱う場合（Inter-VLAN ルーティング）:

```bash
configure

# eth1 上に VLAN 10 サブインターフェースを作成
set interfaces ethernet eth1 vif 10 address 192.168.10.1/24

# eth1 上に VLAN 20 サブインターフェースを作成
set interfaces ethernet eth1 vif 20 address 192.168.20.1/24

commit
save
```

これにより、1つの物理インターフェースで複数の VLAN を扱えます。

---

## まとめ

今日学んだこと:

1. **VLAN** = 論理的にネットワークを分離する技術
2. **同じスイッチでも VLAN が違えば通信不可**
3. **ブリッジを分ける** = VLAN を分離するシンプルな方法
4. **アクセスポート** = 1 VLAN、**トランクポート** = 複数 VLAN

VLAN 間で通信するには:
→ ルーターまたは L3 スイッチが必要（Inter-VLAN ルーティング）

---

## クリーンアップ

```bash
sudo containerlab destroy -t topology.clab.yml
# または
sudo containerlab destroy -t exercise.clab.yml
```
