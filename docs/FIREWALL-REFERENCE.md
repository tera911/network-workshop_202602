# ファイアウォール リファレンス

> このドキュメントはファイアウォールの理解を深めるための補足資料です。
> **関連**: Day 7（ファイアウォール）

---

## ファイアウォールとは

ファイアウォールは、ネットワーク上のトラフィックを**監視・制御**し、許可された通信のみを通過させるセキュリティ機能です。
「防火壁」の名の通り、信頼できないネットワークからの不正な通信をブロックします。

---

## ファイアウォールの種類

| 種類 | 動作レイヤー | 特徴 |
|------|------------|------|
| **パケットフィルタ** | L3-L4 | IP/ポート/プロトコルで判定。シンプルで高速 |
| **ステートフル** | L3-L4 | 接続状態を追跡。応答パケットを自動許可 |
| **アプリケーション層 FW** | L7 | HTTP の中身まで検査。プロキシ型 |
| **NGFW** | L3-L7 | 上記すべて + IDS/IPS、アプリ識別 |

VyOS はステートフルファイアウォール機能を提供します。

---

## パケットフィルタリング

### 5タプル

パケットフィルタリングでは、以下の **5つの要素**（5タプル）で通信を識別します。

| # | 要素 | 説明 | 例 |
|---|------|------|-----|
| 1 | 送信元 IP | パケットの送り主 | 192.168.1.10 |
| 2 | 宛先 IP | パケットの届け先 | 10.0.1.100 |
| 3 | プロトコル | 通信プロトコル | TCP, UDP, ICMP |
| 4 | 送信元ポート | 送り主のポート番号 | 50123（ランダム） |
| 5 | 宛先ポート | 届け先のポート番号 | 80（HTTP） |

### ルール評価順序

ファイアウォールルールは**番号順に上から評価**され、最初に一致したルールが適用されます。

```
ルール 10: TCP ポート 22 を許可    ← SSH OK
ルール 20: TCP ポート 80 を許可    ← HTTP OK
ルール 30: TCP ポート 443 を許可   ← HTTPS OK
デフォルト: すべて拒否             ← 上記以外はブロック
```

> **重要**: ルール番号は10刻みで設定すると、後から間にルールを挿入しやすくなります。

### デフォルトポリシー（デフォルトアクション）

どのルールにも一致しなかった場合の動作です。

| ポリシー | 動作 | 安全性 |
|---------|------|--------|
| **accept** | すべて許可 | 低（ブラックリスト方式） |
| **drop** | すべて拒否（通知なし） | 高（ホワイトリスト方式） |
| **reject** | すべて拒否（ICMP で通知） | 高（デバッグしやすい） |

```bash
# VyOS でのデフォルトアクション設定
set firewall ipv4 forward filter default-action drop
```

---

## ステートフルインスペクション

### 接続状態（Connection State）

ステートフルファイアウォールは、**通信の状態を追跡**します。

| 状態 | 説明 |
|------|------|
| **new** | 新しい接続の最初のパケット |
| **established** | 確立済みの接続に属するパケット |
| **related** | 既存の接続に関連するパケット（ICMP エラー等） |
| **invalid** | どの接続にも属さない不正なパケット |

### 動作の仕組み

```
内部 (PC)                  ファイアウォール              外部 (Web サーバー)
   │                           │                          │
   │── SYN ──────────────→    │                          │
   │  (state: new)             │── 許可 & 状態記録 ──→   │
   │                           │                          │
   │                           │    ←── SYN+ACK ─────────│
   │  ←── 自動許可 ───────────│  (state: established)     │
   │  (established として許可)  │                          │
   │                           │                          │
   │── データ ──────────────→│                          │
   │  (state: established)     │── 自動許可 ──────────→  │
```

→ **行きの通信を許可すれば、戻りの応答は自動的に許可されます**

```bash
# VyOS でのステートフルルール設定
# established / related は許可
set firewall ipv4 forward filter rule 1 action accept
set firewall ipv4 forward filter rule 1 state established
set firewall ipv4 forward filter rule 1 state related

# invalid はドロップ
set firewall ipv4 forward filter rule 2 action drop
set firewall ipv4 forward filter rule 2 state invalid
```

---

## ゾーンベースファイアウォール

### ゾーンの概念

ネットワークをセキュリティレベルの異なる「ゾーン」に分割して管理します。

```
┌─────────────────────────────────────────────┐
│                                             │
│   ┌─── Internal ───┐   ┌─── DMZ ────────┐  │
│   │ (Trust)        │   │ (Semi-Trust)   │  │
│   │                │   │                │  │
│   │  PC, プリンター  │   │  Web サーバー   │  │
│   └───────┬────────┘   └──────┬─────────┘  │
│           │                   │             │
│           └───── ルーター/FW ──┘             │
│                    │                        │
│             ┌──────┴──────┐                 │
│             │  External   │                 │
│             │ (Untrust)   │                 │
│             │             │                 │
│             │ インターネット│                 │
│             └─────────────┘                 │
└─────────────────────────────────────────────┘
```

### ゾーン間の通信ポリシー

| 送信元 → 宛先 | ポリシー | 理由 |
|-------------|---------|------|
| Internal → External | 許可（NAT 経由） | 内部からの外部アクセス |
| Internal → DMZ | 許可 | 内部からサーバー管理 |
| External → DMZ | 一部許可（HTTP/HTTPS） | 外部からの Web アクセス |
| External → Internal | 拒否 | 外部からの直接アクセスは危険 |
| DMZ → Internal | 拒否 | DMZ 侵害時の横展開を防止 |
| DMZ → External | 一部許可 | サーバーからの更新通信等 |

---

## ルール設計のベストプラクティス

### 1. ホワイトリスト方式

```
原則: デフォルトはすべて拒否 → 必要な通信のみ許可
```

### 2. 最小権限の原則

必要最小限のアクセスのみ許可します。

```
✗ 悪い例: "Internal からのすべての通信を許可"
○ 良い例: "Internal から DMZ の TCP 80, 443 のみ許可"
```

### 3. ルール順序の設計

```bash
# 推奨するルール順序
# 1. established/related の許可（高頻度のため最初に）
# 2. invalid のドロップ
# 3. 具体的な許可ルール
# 4. デフォルト: drop
```

### 4. ログ記録

```bash
# 拒否された通信をログに記録
set firewall ipv4 forward filter rule 999 action drop
set firewall ipv4 forward filter rule 999 log
```

---

## VyOS ファイアウォール設定例

Day 7 のような3ゾーン構成での設定例:

```bash
# 基本: established/related を許可
set firewall ipv4 forward filter default-action drop
set firewall ipv4 forward filter rule 1 action accept
set firewall ipv4 forward filter rule 1 state established
set firewall ipv4 forward filter rule 1 state related

# Internal → External: 許可
set firewall ipv4 forward filter rule 100 action accept
set firewall ipv4 forward filter rule 100 inbound-interface name eth1
set firewall ipv4 forward filter rule 100 outbound-interface name eth0

# External → DMZ: HTTP のみ許可
set firewall ipv4 forward filter rule 200 action accept
set firewall ipv4 forward filter rule 200 inbound-interface name eth0
set firewall ipv4 forward filter rule 200 outbound-interface name eth2
set firewall ipv4 forward filter rule 200 protocol tcp
set firewall ipv4 forward filter rule 200 destination port 80
```

---

## よくあるトラブルと対処

### 1. 正当な通信がブロックされる

```bash
# 確認手順
# 1. ファイアウォールルールを確認
show firewall

# 2. ログで拒否されたパケットを確認
show log | match firewall

# 3. nc（netcat）で特定ポートの到達性を確認
nc -zv 10.0.1.100 80

# よくある原因:
# - established/related の許可ルールがない
# - ルール番号の順序が間違っている（具体的なルールの前に拒否ルール）
# - プロトコル指定の漏れ（TCP と UDP の区別）
```

### 2. ルール順序の問題

```
症状: 許可ルールを追加したのに通信が拒否される
原因: 許可ルールより前に、より広い拒否ルールが存在
対処: ルール番号を確認し、許可ルールを拒否ルールより前に配置
```

### 3. ICMP（ping）がブロックされる

```bash
# ICMP を許可するルールを追加
set firewall ipv4 forward filter rule 50 action accept
set firewall ipv4 forward filter rule 50 protocol icmp
```

---

## 用語集

| 用語 | 説明 |
|------|------|
| ファイアウォール | ネットワークトラフィックを監視・制御するセキュリティ機能 |
| パケットフィルタ | IP/ポート/プロトコルに基づくフィルタリング |
| ステートフル | 通信の状態を追跡するファイアウォール方式 |
| 5タプル | 送信元IP、宛先IP、プロトコル、送信元ポート、宛先ポートの5要素 |
| ゾーン | セキュリティレベルで分類したネットワーク領域 |
| DMZ | DeMilitarized Zone。外部公開サーバーを配置する中間領域 |
| ホワイトリスト | デフォルト拒否、明示的に許可のみ通す方式 |
| established | 確立済みの接続に属するパケット |
| related | 既存の接続に関連するパケット |
| デフォルトアクション | どのルールにも一致しない場合の動作 |

---

## 関連ドキュメント

- [NAT-REFERENCE.md](NAT-REFERENCE.md) - NAT（ファイアウォールと組み合わせて使用）
- [VLAN-REFERENCE.md](VLAN-REFERENCE.md) - VLAN（ゾーン分割の基盤）
- [NETWORK-FUNDAMENTALS.md](NETWORK-FUNDAMENTALS.md) - TCP/UDP, ポート番号の基礎
- [ABOUT-VYOS.md](ABOUT-VYOS.md) - VyOS の CLI 操作
