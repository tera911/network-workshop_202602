# VyOS とは

## 概要

VyOS（ヴィーワイオーエス）は、**オープンソースのネットワークOS**です。
Linuxベースで動作し、ルーター、ファイアウォール、VPNゲートウェイなどの機能を提供します。

## 歴史

```
2006年: Vyatta（ヴィアッタ）として開発開始
2012年: Brocade に買収、商用化が進む
2013年: コミュニティが VyOS としてフォーク（分岐）
現在:   VyOS はオープンソースとして活発に開発継続中
```

## 特徴

### 1. Juniper/Cisco ライクな CLI

ネットワーク機器でおなじみのコマンド体系を採用:

```bash
configure           # 設定モードに入る
set ...             # 設定を追加
delete ...          # 設定を削除
commit              # 設定を反映
save                # 設定を永続化
show ...            # 状態を確認
```

### 2. 完全なルーティングスタック

- スタティックルーティング
- OSPF / OSPFv3
- BGP
- RIP
- IS-IS
- Policy-based routing

### 3. 豊富なネットワーク機能

| カテゴリ | 機能 |
|----------|------|
| L2 | VLAN、ブリッジ、LACP |
| L3 | NAT、DHCP、DNS フォワーディング |
| VPN | IPsec、OpenVPN、WireGuard |
| セキュリティ | ファイアウォール、ゾーンベースFW |
| 高可用性 | VRRP、conntrack-sync |

### 4. オープンソース

- コミュニティ版は完全無料
- ソースコードが公開されている
- 商用サポート版（VyOS Universal Router）も存在

## なぜ勉強会で VyOS を選んだか

| 観点 | VyOS | 他の選択肢との比較 |
|------|------|-------------------|
| **CLI の学習効果** | Juniper/Cisco に近く実務に役立つ | GNS3/EVE-NG は重い |
| **軽量さ** | 512MB〜1GB/ノード | SR Linux は 2-4GB 必要 |
| **導入の容易さ** | Docker イメージで即起動 | Cisco IOS は別途ライセンス |
| **ドキュメント** | 日本語情報も豊富 | SR Linux は英語のみ |
| **実用性** | 実際の本番環境でも利用可能 | 学習用に閉じない |

## VyOS のエディション

| エディション | 対象 | 費用 |
|-------------|------|------|
| **Rolling Release** | 開発者・学習者 | 無料 |
| **LTS (Long Term Support)** | 本番環境 | 有料サブスクリプション |

この勉強会では **Rolling Release**（`ghcr.io/vyos/vyos:current`）を使用します。

## CLI の基本構造

### 設定の階層構造

VyOS の設定は階層構造になっています:

```
interfaces {
    ethernet eth0 {
        address 192.168.1.1/24
        description "WAN"
    }
    ethernet eth1 {
        address 10.0.0.1/24
        description "LAN"
    }
}
protocols {
    static {
        route 0.0.0.0/0 {
            next-hop 192.168.1.254
        }
    }
}
```

これを CLI で設定すると:

```bash
set interfaces ethernet eth0 address 192.168.1.1/24
set interfaces ethernet eth0 description "WAN"
set interfaces ethernet eth1 address 10.0.0.1/24
set interfaces ethernet eth1 description "LAN"
set protocols static route 0.0.0.0/0 next-hop 192.168.1.254
```

### コマンド補完

Tab キーで補完が効きます:

```bash
set inter[Tab]          → set interfaces
set interfaces eth[Tab] → set interfaces ethernet
```

### 設定の確認

```bash
show configuration       # 全設定を表示
show configuration commands  # コマンド形式で表示
compare                  # 未コミットの変更を表示
```

## Cisco / Juniper との比較

| 操作 | Cisco IOS | Juniper | VyOS |
|------|-----------|---------|------|
| 設定モード | `configure terminal` | `configure` | `configure` |
| 設定追加 | `ip address ...` | `set ...` | `set ...` |
| 設定削除 | `no ip address ...` | `delete ...` | `delete ...` |
| 反映 | 即時反映 | `commit` | `commit` |
| 保存 | `write memory` | `commit` で自動保存 | `save` |

→ VyOS は Juniper に近い操作感です

## 参考リンク

- [VyOS 公式サイト](https://vyos.io/)
- [VyOS ドキュメント](https://docs.vyos.io/)
- [VyOS GitHub](https://github.com/vyos)
- [VyOS コンテナイメージ](https://github.com/vyos/vyos-build/pkgs/container/vyos)

## コミュニティ

- [VyOS Forum](https://forum.vyos.io/)
- [VyOS Slack](https://vyos.slack.com/)

質問や困ったときはコミュニティを活用してください。日本語での質問も可能です。
