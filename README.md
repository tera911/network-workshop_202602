# ネットワーク勉強会 - VyOS 版

Docker + Containerlab を使ったネットワーク勉強会のハンズオン教材です。

## カリキュラム

| Day | テーマ | 学習内容 |
|-----|--------|----------|
| 1 | IPアドレスと疎通確認 | IPアドレス/サブネット、ping、traceroute、VyOS基本操作 |
| 2 | スタティックルーティング | ルーティングテーブル、3拠点構成、静的経路設定 |
| 3 | VLAN | L2セグメント分離、タグVLAN、トランク |
| 4 | OSPF入門 | 動的ルーティング、Neighbor、Area、障害時の自動迂回 |

## 環境構築（macOS）

### 1. Multipass で Ubuntu VM を作成

```bash
# Multipass インストール
brew install multipass

# VM 作成（メモリ 4GB、CPU 2コア、ディスク 20GB）
multipass launch --name workshop --memory 4G --cpus 2 --disk 20G 22.04

# VM にログイン
multipass shell workshop
```

### 2. Docker インストール

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
exit  # 再ログインして docker グループを反映
```

再度ログイン後:
```bash
multipass shell workshop
docker --version  # 動作確認
```

### 3. Containerlab インストール

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version  # 動作確認
```

### 4. VyOS イメージ取得

```bash
docker pull ghcr.io/vyos/vyos:current
```

### 5. 教材を VM に転送

ホスト側（macOS）で:
```bash
multipass transfer network-workshop-vyos.zip workshop:/home/ubuntu/
```

VM 側で:
```bash
unzip network-workshop-vyos.zip
cd network-workshop-vyos
```

---

## Containerlab 基本操作

```bash
# ラボ起動
sudo containerlab deploy -t <file>.clab.yml

# 状態確認
sudo containerlab inspect -t <file>.clab.yml

# ノードに接続
sudo docker exec -it <node-name> /bin/vbash

# ラボ破棄
sudo containerlab destroy -t <file>.clab.yml

# 全ラボ破棄（クリーンアップ）
sudo containerlab destroy --all
```

---

## VyOS CLI リファレンス

### 基本的な流れ

```
configure           # 設定モードに入る
set ...             # 設定を追加
delete ...          # 設定を削除
commit              # 設定を反映
save                # 設定を永続化（再起動後も有効）
exit                # 設定モードを抜ける
```

### よく使うコマンド

#### 設定モード（configure）

```bash
# インターフェース設定
set interfaces ethernet eth1 address 192.168.1.1/24
set interfaces ethernet eth1 description "to-host1"

# スタティックルート
set protocols static route 10.0.0.0/24 next-hop 192.168.1.254

# OSPF
set protocols ospf area 0 network 192.168.1.0/24
set protocols ospf parameters router-id 1.1.1.1

# VLAN（サブインターフェース）
set interfaces ethernet eth1 vif 10 address 192.168.10.1/24
set interfaces ethernet eth1 vif 20 address 192.168.20.1/24

# 設定の確認
show                # 現在の設定を表示
compare             # 変更差分を表示
```

#### 運用モード（通常モード）

```bash
# インターフェース確認
show interfaces

# ルーティングテーブル
show ip route

# OSPF 状態
show ip ospf neighbor
show ip ospf database

# 疎通確認
ping 192.168.1.1
traceroute 10.0.0.1
```

### 設定モードの切り替え

```
vyos@router:~$ configure      # 運用モード → 設定モード
[edit]
vyos@router# exit             # 設定モード → 運用モード
vyos@router:~$
```

プロンプトの見分け方:
- `~$` = 運用モード
- `#` = 設定モード

---

## リソース要件

| 構成 | 推奨メモリ |
|------|-----------|
| Day 1（2ルーター + 2ホスト） | 2GB |
| Day 2（3ルーター + 3ホスト） | 3GB |
| Day 3（1スイッチ + 4ホスト） | 2GB |
| Day 4（3ルーター + 3ホスト） | 3GB |

VM 全体で **4GB** あれば全 Day に対応できます。

---

## トラブルシューティング

### Containerlab が起動しない

```bash
# Docker が動いているか確認
sudo systemctl status docker

# 動いていなければ起動
sudo systemctl start docker
```

### VyOS にログインできない

```bash
# コンテナの状態確認
sudo docker ps -a

# ログ確認
sudo docker logs <container-name>
```

### 設定が反映されない

```bash
# 設定モードで commit を忘れていないか確認
configure
compare    # 未コミットの変更があれば表示される
commit     # 変更を反映
```

### ping が通らない

1. インターフェースに IP アドレスが設定されているか確認
2. ルーティングテーブルに経路があるか確認
3. 対向のインターフェースが up しているか確認

```bash
show interfaces
show ip route
```

---

## ショートカットコマンド（推奨）

長い `docker exec -it ...` コマンドを簡略化できます。

### インストール

```bash
cd ~/network-workshop-vyos
./scripts/install-helpers.sh
source ~/.bashrc
```

### 使い方

```bash
# ヘルプ表示
vhelp

# VyOS ルーターに接続
vrouter router1          # docker exec -it clab-xxx-router1 /bin/vbash の代わり
vrouter router-hq        # 部分一致でOK

# Alpine ホストに接続
vhost host1              # docker exec -it clab-xxx-host1 /bin/sh の代わり

# ラボ管理
vdeploy                  # topology.clab.yml を起動
vdeploy exercise.clab.yml
vdestroy                 # ラボを破棄
vlab                     # 現在のラボ状態を表示

# 簡易 ping
vping host1 192.168.2.10 # host1 から ping
```

---

## ドキュメント

| ファイル | 内容 |
|----------|------|
| [README.md](README.md) | このファイル（概要） |
| [SETUP.md](SETUP.md) | 詳細な環境構築ガイド |
| [docs/ABOUT-VYOS.md](docs/ABOUT-VYOS.md) | VyOS とは何か |

---

## 参考リンク

- [VyOS Documentation](https://docs.vyos.io/)
- [Containerlab Documentation](https://containerlab.dev/)
- [VyOS Container Image](https://github.com/vyos/vyos-build/pkgs/container/vyos)
