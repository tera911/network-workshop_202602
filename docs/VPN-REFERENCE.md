# VPN リファレンス

> このドキュメントは VPN（Virtual Private Network）の理解を深めるための補足資料です。
> **関連**: Day 9（VPN / WireGuard）

---

## VPN とは

VPN（Virtual Private Network）は、**インターネットなどの公衆ネットワーク上に、暗号化された仮想的な専用通信路（トンネル）を構築する技術**です。
離れた拠点間でも、あたかも同じ LAN にいるかのようにセキュアに通信できます。

```
拠点 A (192.168.1.0/24)                   拠点 B (192.168.2.0/24)

  PC-A ── Router-A ══════════════════ Router-B ── PC-B
              │      暗号化トンネル       │
              │    （インターネット経由）   │
              └──────────────────────────┘
```

---

## VPN の種類

| 種類 | 説明 | 用途 |
|------|------|------|
| **Site-to-Site** | 拠点間を常時接続 | 本社-支社間の接続 |
| **Remote Access** | 個人端末から企業ネットワークへ接続 | テレワーク、外出先からの接続 |
| **SSL VPN** | Web ブラウザ経由の VPN | 特別なクライアント不要 |

このワークショップでは **Site-to-Site VPN** を WireGuard で構築します。

---

## 暗号化の基礎

### 共通鍵暗号（対称暗号）

送信者と受信者が**同じ鍵**を使います。

```
送信者                          受信者
  │                              │
  │── 共通鍵で暗号化 ──→        │
  │   [暗号文]                   │
  │                 ──→ 同じ共通鍵で復号
```

- **AES**（Advanced Encryption Standard）が代表的
- 処理が高速 → データの暗号化に使用

### 公開鍵暗号（非対称暗号）

**公開鍵**と**秘密鍵**のペアを使います。

```
送信者                          受信者
  │                              │
  │  受信者の公開鍵で暗号化       │
  │── [暗号文] ────────────→    │
  │                  受信者の秘密鍵で復号
```

- 鍵の配送問題を解決
- 処理が遅い → 鍵交換や認証に使用

### ハッシュ関数

データの「指紋」を生成し、改ざんを検知します。

- SHA-256, SHA-384 等
- 同じデータからは必ず同じハッシュ値
- わずかな変更でまったく異なるハッシュ値

---

## VPN プロトコル比較

| プロトコル | 暗号化 | 速度 | 設定の容易さ | 特徴 |
|-----------|--------|------|------------|------|
| **IPsec** | AES 等 | 高速 | 複雑 | 業界標準、幅広い互換性 |
| **OpenVPN** | TLS/SSL | 中程度 | 中程度 | SSL ベース、柔軟な設定 |
| **WireGuard** | ChaCha20 | 非常に高速 | 簡単 | 軽量、モダン、カーネル実装 |
| **L2TP/IPsec** | IPsec | 中程度 | 中程度 | L2 トンネル + IPsec 暗号化 |

---

## WireGuard 詳細

### WireGuard の特徴

| 特徴 | 説明 |
|------|------|
| **シンプル** | コード量が約4,000行（IPsec は数十万行） |
| **高速** | Linux カーネルに組み込まれ、カーネル空間で処理 |
| **モダンな暗号** | ChaCha20, Curve25519, BLAKE2s, SipHash24 |
| **UDP ベース** | デフォルトポート 51820 |
| **ステートレス** | 接続/切断の概念がない。パケットが来れば処理 |

### 公開鍵認証

WireGuard は **公開鍵ペア** を使ってピア同士を認証します。SSH の鍵認証と似た仕組みです。

```
Router-A                          Router-B
┌──────────────┐                ┌──────────────┐
│ 秘密鍵 A     │                │ 秘密鍵 B     │
│ 公開鍵 A ──────── 交換 ──────── 公開鍵 B     │
└──────────────┘                └──────────────┘

Router-A は Router-B の公開鍵を知っている → 認証可能
Router-B は Router-A の公開鍵を知っている → 認証可能
```

### 鍵の生成

```bash
# VyOS での WireGuard 鍵ペア生成
generate pki wireguard key-pair

# 出力例:
# Private key: iHF2...  ← 秘密（絶対に漏らさない）
# Public key:  xT3f...  ← 相手に渡す
```

### Allowed IPs

**Allowed IPs** は WireGuard の重要な概念で、2つの役割を持ちます:

1. **ルーティング**: この IP 宛のパケットをトンネルに送る
2. **アクセス制御**: このピアから受け取れるパケットの送信元 IP を制限

```bash
# 例: Site-B のネットワーク 192.168.2.0/24 をトンネル経由に
set interfaces wireguard wg0 peer site-b allowed-ips 192.168.2.0/24
```

---

## トンネリング

### カプセル化の仕組み

VPN トンネルでは、元のパケット全体を新しいパケットの中に入れて（カプセル化して）送信します。

```
元のパケット:
┌──────────┬──────────┬──────┐
│ IP ヘッダー │ TCP ヘッダー │ Data │
│ src: 192. │ dst port │      │
│ dst: 192. │ : 80     │      │
└──────────┴──────────┴──────┘

WireGuard でカプセル化後:
┌──────────┬──────────┬─────────────────────────────────┐
│ 外部 IP   │ UDP      │ 暗号化された元のパケット            │
│ src: WAN  │ dst:     │ [IP ヘッダー][TCP ヘッダー][Data]   │
│ dst: WAN  │ 51820    │                                 │
└──────────┴──────────┴─────────────────────────────────┘
                        ↑ 中身は暗号化されており読めない
```

### tcpdump での確認

```bash
# WAN 側（暗号化されたパケットが見える）
sudo tcpdump -i eth0 -n udp port 51820
# → UDP パケット、中身は暗号化されて読めない

# トンネルインターフェース（復号されたパケットが見える）
sudo tcpdump -i wg0 -n
# → 通常の IP パケット（192.168.x.x）が見える
```

### MTU の問題

カプセル化によりパケットサイズが増加するため、MTU（Maximum Transmission Unit）の調整が必要な場合があります。

```
通常の MTU:     1500 バイト
WireGuard ヘッダー: 約 60 バイト
トンネル内 MTU: 1500 - 60 = 1440 バイト
```

```bash
# VyOS での MTU 設定
set interfaces wireguard wg0 mtu 1420
```

---

## VyOS での WireGuard 設定例

### Site-A（192.168.1.0/24）

```bash
# WireGuard インターフェースの作成
set interfaces wireguard wg0 address 10.255.255.1/30
set interfaces wireguard wg0 port 51820
set interfaces wireguard wg0 private-key <Site-A の秘密鍵>

# ピア（Site-B）の設定
set interfaces wireguard wg0 peer site-b public-key <Site-B の公開鍵>
set interfaces wireguard wg0 peer site-b allowed-ips 192.168.2.0/24
set interfaces wireguard wg0 peer site-b allowed-ips 10.255.255.2/32
set interfaces wireguard wg0 peer site-b endpoint <Site-B のWAN IP>:51820
```

### Site-B（192.168.2.0/24）

```bash
# WireGuard インターフェースの作成
set interfaces wireguard wg0 address 10.255.255.2/30
set interfaces wireguard wg0 port 51820
set interfaces wireguard wg0 private-key <Site-B の秘密鍵>

# ピア（Site-A）の設定
set interfaces wireguard wg0 peer site-a public-key <Site-A の公開鍵>
set interfaces wireguard wg0 peer site-a allowed-ips 192.168.1.0/24
set interfaces wireguard wg0 peer site-a allowed-ips 10.255.255.1/32
set interfaces wireguard wg0 peer site-a endpoint <Site-A のWAN IP>:51820
```

---

## よくあるトラブルと対処

### 1. ハンドシェイクが確立されない

```bash
# 確認コマンド
show interfaces wireguard wg0

# 確認ポイント:
# - 公開鍵が正しく交換されているか（コピーミスに注意）
# - endpoint の IP アドレスとポートが正しいか
# - ファイアウォールで UDP 51820 が許可されているか
# - 両端の WireGuard インターフェースが UP か
```

### 2. トンネルは張れるが通信できない

```
確認ポイント:
  - allowed-ips に相手側のネットワークが含まれているか
  - ルーティングテーブルに相手側ネットワークへの経路があるか
  - ファイアウォールでトンネルインターフェース（wg0）の通信が許可されているか
```

### 3. MTU 問題

```
症状: ping は通るが、大きなデータ転送が失敗する
原因: カプセル化によるパケットサイズ超過
対処: WireGuard インターフェースの MTU を 1420 に設定
```

### 4. 片方向のみ通信可能

```
確認ポイント:
  - 両端の allowed-ips が対称的に設定されているか
  - 両端のルーティングが正しいか（行きと帰りの経路）
```

---

## 用語集

| 用語 | 説明 |
|------|------|
| VPN | Virtual Private Network。仮想的な専用ネットワーク |
| トンネル | 暗号化されたパケットを別のパケットに包んで転送する通信路 |
| カプセル化 | パケットを別のパケットの中に入れること |
| WireGuard | モダンで高速な VPN プロトコル |
| 公開鍵 | 相手に渡す鍵。暗号化・認証に使用 |
| 秘密鍵 | 自分だけが持つ鍵。絶対に漏らさない |
| Allowed IPs | トンネル経由で通信する IP 範囲の定義 |
| Endpoint | 相手の WAN 側 IP アドレスとポート |
| MTU | Maximum Transmission Unit。1パケットの最大サイズ |
| Site-to-Site | 拠点間を常時接続する VPN 構成 |

---

## 関連ドキュメント

- [FIREWALL-REFERENCE.md](FIREWALL-REFERENCE.md) - VPN 通信のファイアウォール許可
- [NAT-REFERENCE.md](NAT-REFERENCE.md) - VPN と NAT の関係
- [NETWORK-FUNDAMENTALS.md](NETWORK-FUNDAMENTALS.md) - 暗号化、カプセル化の基礎
- [ABOUT-VYOS.md](ABOUT-VYOS.md) - VyOS の CLI 操作
