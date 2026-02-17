# OSPF リファレンス

> このドキュメントは OSPF（Open Shortest Path First）の理解を深めるための補足資料です。
> **関連**: Day 2（スタティックルーティング）、Day 4（OSPF）

---

## 動的ルーティングの分類

ルーティングプロトコルは大きく2つに分類されます。

### IGP と EGP

| 分類 | 正式名称 | 用途 | 代表プロトコル |
|------|---------|------|--------------|
| **IGP** | Interior Gateway Protocol | 組織内のルーティング | OSPF, RIP, IS-IS |
| **EGP** | Exterior Gateway Protocol | 組織間（インターネット）のルーティング | BGP |

```
┌──── AS 65001 ────┐          ┌──── AS 65002 ────┐
│                  │          │                  │
│  OSPF（IGP）で   │── BGP ──│  OSPF（IGP）で   │
│  内部経路交換     │ （EGP）  │  内部経路交換     │
│                  │          │                  │
└──────────────────┘          └──────────────────┘
```

### 主要な IGP プロトコル

| プロトコル | タイプ | メトリック | 特徴 |
|-----------|--------|----------|------|
| **RIP** | ディスタンスベクタ | ホップ数 | シンプルだが収束が遅い。最大15ホップ |
| **OSPF** | リンクステート | コスト（帯域幅） | 高速収束、大規模対応、エリア分割 |
| **IS-IS** | リンクステート | コスト | ISP で広く使用 |

---

## OSPF の仕組み

### リンクステート型プロトコル

OSPF は「リンクステート型」のプロトコルです。各ルーターが**ネットワーク全体のトポロジ情報（地図）を持ち**、そこから最短経路を計算します。

```
ディスタンスベクタ型（RIP）:     リンクステート型（OSPF）:
「隣から聞いた情報を信じる」      「全体の地図を持って自分で計算」

  A → B: "Cは2ホップ先"           全ルーターが同じ地図（LSDB）を持つ
  B → A: "Dは1ホップ先"           各自で SPF アルゴリズムを実行
                                  → より正確で高速な経路計算
```

### SPF アルゴリズム（ダイクストラ法）

OSPF は **SPF（Shortest Path First）アルゴリズム** を使い、自分を起点とした最短パスツリーを計算します。

```
        コスト10        コスト10
  A ──────────── B ──────────── D
  │                              │
  │ コスト10                コスト5│
  │                              │
  C ─────────────────────────────┘
        コスト30

A → D の最短パス:
  A → B → D = 10 + 10 = 20  ← 選択
  A → C → D = 10 + 30 = 40
```

### LSDB（Link State Database）

すべての OSPF ルーターは、同じエリア内で **同一の LSDB** を持ちます。LSDB にはネットワークのトポロジ情報（どのルーターがどのネットワークに接続しているか）が格納されています。

```bash
# VyOS での LSDB 確認
show ip ospf database
```

---

## 主要概念

### Router ID

OSPF ルーターを一意に識別する **32ビットの値** です。IP アドレスの形式で表記されます。

選択の優先順位:
1. 手動設定した Router ID
2. ループバックインターフェースの最大 IP
3. 物理インターフェースの最大 IP

```bash
# VyOS での Router ID 設定
set protocols ospf parameters router-id 1.1.1.1
```

### Hello プロトコル

隣接ルーター（Neighbor）を**発見・維持**するためのメッセージです。

| パラメータ | デフォルト値 | 説明 |
|-----------|------------|------|
| Hello Interval | 10秒 | Hello パケットの送信間隔 |
| Dead Interval | 40秒 | この時間 Hello が来なければ Neighbor ダウンと判断 |

> **重要**: 隣接するルーター同士で Hello Interval と Dead Interval が一致していないと、Neighbor 関係が確立されません。

### Area（エリア）

OSPF ネットワークを分割する論理的な単位です。

```
┌─── Area 0（バックボーン）───┐
│                            │
│  Router-A ──── Router-B    │
│      │                     │
└──────│─────────────────────┘
       │
┌──────│─── Area 1 ──────────┐
│      │                     │
│  Router-C ──── Router-D    │
│                            │
└────────────────────────────┘
```

- **Area 0**（バックボーンエリア）はすべての OSPF ネットワークに必須です
- 他のエリアは Area 0 に接続する必要があります
- このワークショップでは **全ルーターが Area 0** に所属します

### DR / BDR

マルチアクセスネットワーク（イーサネットなど）では、LSA の交換を効率化するために **DR（Designated Router）** と **BDR（Backup DR）** が選出されます。

| 役割 | 説明 |
|------|------|
| DR | LSA の集約・配布を担当 |
| BDR | DR のバックアップ。DR 障害時に昇格 |
| DROther | DR/BDR 以外のルーター。DR にのみ LSA を送信 |

---

## Neighbor 確立プロセス

OSPF ルーター同士が Neighbor 関係を確立するまでの状態遷移:

```
Down → Init → 2-Way → ExStart → Exchange → Loading → Full
```

| 状態 | 説明 |
|------|------|
| **Down** | 初期状態。Hello を受信していない |
| **Init** | 相手から Hello を受信したが、自分の Router ID が含まれていない |
| **2-Way** | 相互に Hello を認識。DR/BDR 選出が行われる |
| **ExStart** | LSDB 交換の準備。Master/Slave を決定 |
| **Exchange** | DBD（Database Description）パケットで LSDB の概要を交換 |
| **Loading** | 不足している LSA を要求・取得 |
| **Full** | LSDB が完全に同期。Neighbor 関係が完全に確立 |

```bash
# VyOS での Neighbor 確認
show ip ospf neighbor
```

出力例:

```
Neighbor ID   Pri  State     Dead Time  Address       Interface
2.2.2.2       1    Full/DR   00:00:38   10.0.1.2      eth1:10.0.1.1
3.3.3.3       1    Full/BDR  00:00:35   10.0.2.2      eth2:10.0.2.1
```

---

## コストとメトリック

OSPF のメトリック（コスト）は**インターフェースの帯域幅**に基づいて計算されます。

### コスト計算式

```
コスト = リファレンス帯域幅 / インターフェース帯域幅
```

デフォルトのリファレンス帯域幅は **100 Mbps** です。

| インターフェース | 帯域幅 | コスト |
|----------------|--------|-------|
| 10 Mbps | 10 Mbps | 10 |
| 100 Mbps (FastEthernet) | 100 Mbps | 1 |
| 1 Gbps (GigabitEthernet) | 1000 Mbps | 1 |

> **注意**: 100 Mbps 以上はすべてコスト 1 になるため、ギガビット環境ではリファレンス帯域幅の変更が推奨されます。

### VyOS での OSPF 設定例

```bash
# OSPF の有効化
set protocols ospf parameters router-id 1.1.1.1

# ネットワークの広告
set protocols ospf area 0 network 10.0.1.0/24
set protocols ospf area 0 network 10.0.2.0/24

# 確認
show ip ospf neighbor
show ip ospf route
show ip route ospf
```

---

## よくあるトラブルと対処

### 1. Neighbor が確立されない

```bash
# 確認コマンド
show ip ospf neighbor

# 確認ポイント:
# - Hello Interval / Dead Interval が一致しているか
# - Area ID が一致しているか
# - サブネットマスクが一致しているか
# - network コマンドで該当インターフェースが含まれているか
```

### 2. ルートが伝播されない

```bash
# 確認コマンド
show ip route ospf
show ip ospf database

# 確認ポイント:
# - 広告するネットワークが network コマンドに含まれているか
# - Neighbor が Full 状態か
# - フィルタやルートマップが設定されていないか
```

### 3. 経路が最適でない

```
確認ポイント:
  - コスト値が意図した通りか（show ip ospf interface）
  - リファレンス帯域幅の設定が適切か
```

---

## 用語集

| 用語 | 説明 |
|------|------|
| OSPF | Open Shortest Path First。リンクステート型ルーティングプロトコル |
| IGP | Interior Gateway Protocol。組織内のルーティングプロトコル |
| SPF | Shortest Path First。最短経路を計算するアルゴリズム |
| LSDB | Link State Database。ネットワークトポロジ情報のデータベース |
| LSA | Link State Advertisement。トポロジ情報の広告 |
| Area | OSPF ネットワークを分割する論理的な単位 |
| Router ID | OSPF ルーターの一意な識別子 |
| DR/BDR | Designated Router / Backup DR。LSA 交換の効率化 |
| Hello プロトコル | Neighbor 発見・維持のためのメッセージ |
| コスト | OSPF のメトリック。帯域幅に基づいて計算 |
| 収束 | 全ルーターの LSDB が一致し、最適経路が計算された状態 |

---

## 関連ドキュメント

- [ROUTING-REFERENCE.md](ROUTING-REFERENCE.md) - ルーティングの基礎（スタティックルート）
- [NETWORK-FUNDAMENTALS.md](NETWORK-FUNDAMENTALS.md) - ネットワーク基礎
- [ABOUT-VYOS.md](ABOUT-VYOS.md) - VyOS の CLI 操作
