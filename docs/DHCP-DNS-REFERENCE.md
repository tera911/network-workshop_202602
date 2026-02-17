# DHCP / DNS リファレンス

> このドキュメントは DHCP と DNS の理解を深めるための補足資料です。
> **関連**: Day 6（DHCP と DNS）

---

## DHCP（Dynamic Host Configuration Protocol）

### DHCP とは

DHCP は、ネットワーク上のデバイスに **IP アドレスやネットワーク設定を自動的に割り当てる** プロトコルです。
手動で1台ずつ IP を設定する必要がなくなります。

### DORA プロセス

DHCP による IP 取得は **4つのステップ**（DORA）で行われます。

```
クライアント                           DHCP サーバー
(IP なし)                             (192.168.1.1)
    │                                     │
    │── 1. Discover（ブロードキャスト）───→│  「DHCP サーバーはいますか？」
    │   送信元: 0.0.0.0                    │
    │   宛先: 255.255.255.255              │
    │                                     │
    │←── 2. Offer ────────────────────────│  「192.168.1.100 を使えますよ」
    │                                     │
    │── 3. Request（ブロードキャスト）────→│  「192.168.1.100 をください」
    │                                     │
    │←── 4. ACK ──────────────────────────│  「了解。使っていいですよ」
    │                                     │
    │   IP: 192.168.1.100 で通信開始      │
```

| ステップ | メッセージ | プロトコル | 説明 |
|---------|-----------|----------|------|
| 1 | **D**iscover | UDP 68→67 | クライアントが DHCP サーバーを探す |
| 2 | **O**ffer | UDP 67→68 | サーバーが IP アドレスを提案 |
| 3 | **R**equest | UDP 68→67 | クライアントが IP アドレスを要求 |
| 4 | **A**CK | UDP 67→68 | サーバーが割り当てを確定 |

> **ポイント**: Discover と Request はブロードキャストで送信されます。これは DHCP リレーの理解に重要です。

### DHCP の主要概念

#### スコープ / プール

割り当て可能な IP アドレスの範囲です。

```bash
# VyOS での DHCP プール設定
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 start 192.168.1.100
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 stop 192.168.1.200
```

#### リース

IP アドレスの「貸出期間」です。期限が切れると更新が必要になります。

```bash
# リース時間の設定（秒単位）
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 lease 86400
# 86400秒 = 24時間
```

#### 予約（Static Mapping）

特定の MAC アドレスに対して、常に同じ IP を割り当てます。プリンターやサーバーなど、IP が変わると困る機器に使用します。

```bash
# MAC アドレスに固定 IP を予約
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 static-mapping printer ip-address 192.168.1.50
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 static-mapping printer mac aa:bb:cc:dd:ee:ff
```

#### DHCP リレー

DHCP の Discover はブロードキャストのため、ルーターを越えられません。
**DHCP リレーエージェント**を使うと、異なるサブネットの DHCP サーバーを利用できます。

```
VLAN 10              ルーター               DHCP サーバー
(192.168.10.0/24)    (リレーエージェント)     (192.168.1.1)
    │                    │                      │
    │── Discover ──→    │                      │
    │  (ブロードキャスト) │── ユニキャスト転送 ──→│
    │                    │                      │
    │                    │←── Offer ────────────│
    │←── Offer ─────────│                      │
```

### 主要な DHCP オプション

| オプション番号 | 名前 | 説明 | VyOS 設定 |
|-------------|------|------|----------|
| 3 | Default Gateway | デフォルトゲートウェイの IP | `default-router` |
| 6 | DNS Server | DNS サーバーの IP | `dns-server` |
| 15 | Domain Name | ドメイン名 | `domain-name` |
| 51 | Lease Time | リース時間 | `lease` |

```bash
# VyOS での DHCP オプション設定
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 default-router 192.168.1.1
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 dns-server 192.168.1.1
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 domain-name example.local
```

---

## DNS（Domain Name System）

### DNS とは

DNS は **ドメイン名を IP アドレスに変換する** システムです。
人間が覚えやすい名前（www.example.com）を、コンピュータが理解できる IP アドレス（93.184.216.34）に変換します。

### DNS の階層構造

```
                    ルートサーバー（.）
                   /        |        \
              .com         .jp        .org
             /    \         |
        example   google   co.jp
           |        |        |
          www      www    example
```

### 名前解決の流れ（再帰クエリ）

```
クライアント     DNSリゾルバ       ルートDNS    .com DNS     example.com DNS
    │               │               │           │              │
    │─ www.example  │               │           │              │
    │  .com は？ ──→│               │           │              │
    │               │── . は？ ───→│           │              │
    │               │←─ .com は    │           │              │
    │               │   ここ ──────│           │              │
    │               │── .com は？ ─────────→│              │
    │               │←─ example.com は       │              │
    │               │   ここ ────────────────│              │
    │               │── www.example.com は？ ─────────────→│
    │               │←─ 93.184.216.34 ────────────────────│
    │←─ 93.184.216  │               │           │              │
    │   .34 ────────│               │           │              │
```

### DNS レコードの種類

| レコード | 説明 | 例 |
|---------|------|-----|
| **A** | ドメイン → IPv4 アドレス | `www.example.com → 93.184.216.34` |
| **AAAA** | ドメイン → IPv6 アドレス | `www.example.com → 2606:2800:...` |
| **CNAME** | ドメインの別名（エイリアス） | `blog.example.com → www.example.com` |
| **MX** | メールサーバーの指定 | `example.com → mail.example.com` |
| **PTR** | IP アドレス → ドメイン（逆引き） | `93.184.216.34 → www.example.com` |
| **NS** | 権威 DNS サーバーの指定 | `example.com → ns1.example.com` |
| **SOA** | ゾーンの管理情報 | シリアル番号、TTL 等 |

---

## DNS フォワーディングとキャッシュ

### フォワーダーの役割

VyOS をローカル DNS フォワーダーとして使用すると:

```
クライアント ──→ VyOS（DNS フォワーダー）──→ 上位 DNS サーバー
                    │
                    └── キャッシュに保存
```

1. クライアントからのクエリを受信
2. キャッシュに回答があればそれを返す
3. なければ上位 DNS サーバーに問い合わせ
4. 結果をキャッシュして返す

```bash
# VyOS での DNS フォワーディング設定
set service dns forwarding listen-address 192.168.1.1
set service dns forwarding allow-from 192.168.1.0/24
set service dns forwarding name-server 8.8.8.8
set service dns forwarding name-server 8.8.4.4
```

### TTL（Time To Live）

DNS レコードのキャッシュ有効時間です。TTL が切れるとキャッシュが破棄され、再度上位に問い合わせが行われます。

---

## ローカル DNS（スタティックホストマッピング）

VyOS では、ローカルネットワーク内のホスト名を静的に登録できます。`/etc/hosts` ファイルのネットワーク版のようなものです。

```bash
# スタティックホストマッピングの設定
set system static-host-mapping host-name server1.lab inet 192.168.1.10
set system static-host-mapping host-name server2.lab inet 192.168.1.20
set system static-host-mapping host-name printer.lab inet 192.168.1.50
```

これにより、クライアントは `ping server1.lab` のように名前で通信できます。

---

## よくあるトラブルと対処

### DHCP 関連

#### 1. IP アドレスが取得できない

```bash
# サーバー側の確認
show dhcp server leases        # リース情報の確認
show dhcp server statistics    # DHCP 統計

# 確認ポイント:
# - DHCP サービスが起動しているか
# - プール（range）に空きがあるか
# - クライアントのインターフェースが正しいサブネットか
# - ファイアウォールで UDP 67/68 がブロックされていないか
```

#### 2. 169.254.x.x のアドレスになる

```
原因: DHCP サーバーに到達できず、リンクローカルアドレスが自動設定された
確認: DHCP サーバーが同一サブネットにあるか、リレーが設定されているか
```

### DNS 関連

#### 3. 名前解決ができない

```bash
# 確認手順
# 1. DNS サーバーへの到達性
ping 192.168.1.1

# 2. DNS クエリのテスト（ホストから）
nslookup www.example.com 192.168.1.1

# 確認ポイント:
# - DNS フォワーディングサービスが起動しているか
# - listen-address が正しいか
# - allow-from にクライアントのネットワークが含まれているか
# - 上位 DNS サーバーに到達可能か
```

#### 4. ローカルホスト名だけ解決できない

```
確認ポイント:
  - static-host-mapping が正しく設定されているか
  - クライアントの DNS サーバーが VyOS を指しているか
```

---

## 用語集

| 用語 | 説明 |
|------|------|
| DHCP | Dynamic Host Configuration Protocol。IP 自動割り当て |
| DORA | Discover, Offer, Request, ACK。DHCP の4ステップ |
| リース | DHCP で割り当てた IP の貸出期間 |
| スコープ/プール | DHCP で割り当て可能な IP の範囲 |
| DHCP リレー | ブロードキャストを超えて DHCP を中継する仕組み |
| DNS | Domain Name System。名前 → IP の変換 |
| FQDN | Fully Qualified Domain Name。完全修飾ドメイン名 |
| A レコード | ドメイン → IPv4 の対応 |
| PTR レコード | IP → ドメインの対応（逆引き） |
| TTL | Time To Live。DNS キャッシュの有効時間 |
| フォワーダー | DNS クエリを上位サーバーに転送する中継サーバー |
| スタティックホストマッピング | ローカルのホスト名と IP の静的対応 |

---

## 関連ドキュメント

- [NETWORK-FUNDAMENTALS.md](NETWORK-FUNDAMENTALS.md) - プロトコルの基礎（UDP, ポート番号）
- [FIREWALL-REFERENCE.md](FIREWALL-REFERENCE.md) - DHCP/DNS トラフィックの許可設定
- [ABOUT-VYOS.md](ABOUT-VYOS.md) - VyOS の CLI 操作
