# トラブルシューティング集

勉強会でよく発生する問題と解決方法をまとめています。

---

## 目次

1. [環境構築時の問題](#環境構築時の問題)
2. [Containerlab の問題](#containerlab-の問題)
3. [VyOS の問題](#vyos-の問題)
4. [ネットワーク疎通の問題](#ネットワーク疎通の問題)
5. [パフォーマンスの問題](#パフォーマンスの問題)

---

## 環境構築時の問題

### Multipass が起動しない（macOS）

**症状**: `multipass launch` が失敗する、タイムアウトする

**解決策**:
```bash
# Multipass デーモンを再起動
sudo launchctl stop com.canonical.multipassd
sudo launchctl start com.canonical.multipassd

# それでもダメなら
brew reinstall multipass
```

### Multipass VM が起動しない

**症状**: `State: Starting` のまま進まない

**解決策**:
```bash
# VM を強制停止して再起動
multipass stop workshop --force
multipass start workshop

# それでもダメなら VM を作り直し
multipass delete workshop
multipass purge
multipass launch --name workshop --memory 4G --cpus 2 --disk 20G 22.04
```

### Docker がインストールできない

**症状**: `curl -fsSL https://get.docker.com | sh` がエラー

**解決策**:
```bash
# 手動インストール
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

### Docker 権限エラー

**症状**: `permission denied while trying to connect to the Docker daemon socket`

**解決策**:
```bash
# docker グループに追加
sudo usermod -aG docker $USER

# 現在のセッションに反映（再ログインの代わり）
newgrp docker

# 確認
docker ps
```

### VyOS イメージが取得できない

**症状**: `docker pull ghcr.io/vyos/vyos:current` が失敗

**解決策**:
```bash
# ネットワーク確認
ping github.com

# DNS 問題の場合
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# 別のタグを試す
docker pull ghcr.io/vyos/vyos:1.4-rolling-202401010317

# プロキシ環境の場合
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://proxy:port"
Environment="HTTPS_PROXY=http://proxy:port"
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## Containerlab の問題

### ラボが起動しない

**症状**: `containerlab deploy` がエラー

**解決策**:
```bash
# Docker が動いているか確認
sudo systemctl status docker
sudo systemctl start docker

# 前回のラボが残っている場合
sudo containerlab destroy --all

# YAMLファイルの構文エラー確認
cat -A topology.clab.yml  # 不正な文字を確認
```

### コンテナが Exited 状態になる

**症状**: `docker ps -a` で `Exited` と表示される

**解決策**:
```bash
# ログを確認
docker logs <container-name>

# メモリ不足の場合が多い
free -h

# VM のメモリを増やす（Multipass の場合）
multipass stop workshop
multipass set local.workshop.memory=6G
multipass start workshop
```

### ノード名が長すぎる

**症状**: `name too long` エラー

**解決策**:
```yaml
# topology.clab.yml のラボ名を短くする
name: day1  # day1-ip-basics → day1
```

### ネットワークリンクが作成されない

**症状**: コンテナ間で通信できない、インターフェースがない

**解決策**:
```bash
# ラボを再作成
sudo containerlab destroy -t topology.clab.yml
sudo containerlab deploy -t topology.clab.yml

# インターフェース確認
docker exec <container> ip link show
```

---

## VyOS の問題

### VyOS にログインできない

**症状**: `/bin/vbash: No such file or directory`

**解決策**:
```bash
# 正しいシェルパス
docker exec -it <container> /bin/vbash

# それでもダメなら bash を試す
docker exec -it <container> /bin/bash

# コンテナが VyOS か確認
docker inspect <container> --format '{{.Config.Image}}'
```

### configure が効かない

**症状**: `configure: command not found`

**解決策**:
```bash
# VyOS シェルで実行しているか確認
# プロンプトが vyos@xxx:~$ になっているか

# /bin/sh で入ってしまった場合
exit
docker exec -it <container> /bin/vbash
```

### commit がエラーになる

**症状**: `Commit failed` エラー

**解決策**:
```bash
# 設定の競合を確認
show | compare

# 設定を破棄してやり直し
discard
exit
```

### 設定が保存されない

**症状**: コンテナ再起動後に設定が消える

**解決策**:
```bash
# commit だけでなく save も必要
configure
set ...
commit
save    # ← これを忘れがち
exit
```

### show コマンドが動かない

**症状**: `Invalid command` エラー

**解決策**:
```bash
# 設定モード中は show の前に run をつける
run show interfaces

# または設定モードを抜けてから
exit
show interfaces
```

---

## ネットワーク疎通の問題

### ping が通らない（基本チェック）

```bash
# 1. インターフェースに IP があるか
show interfaces

# 2. インターフェースが up しているか
show interfaces ethernet eth1

# 3. ルーティングテーブルに経路があるか
show ip route

# 4. 対向も同様に確認
```

### 直接接続なのに ping が通らない

**症状**: 同じセグメントなのに通信できない

**チェックポイント**:
```bash
# IP アドレスが同じサブネットか
# 192.168.1.1/24 と 192.168.1.10/24 → OK
# 192.168.1.1/24 と 192.168.2.10/24 → NG（サブネット違い）

# ARP テーブル確認（Linux ホスト）
arp -n

# VyOS での ARP 確認
show arp
```

### ルーター越しで ping が通らない

**症状**: 直接接続は OK だが、ルーター越しは NG

**チェックポイント**:
```bash
# 1. 両方向のルーティングがあるか
#    送信元 → 宛先 のルート
#    宛先 → 送信元 のルート（戻りの経路）

# 2. 中継ルーターに両方向の経路があるか

# 3. traceroute で止まる場所を特定
traceroute <destination>
```

### OSPF Neighbor が確立しない

**症状**: `show ip ospf neighbor` が空

**チェックポイント**:
```bash
# 1. OSPF が有効か
show configuration commands | grep ospf

# 2. 正しいネットワークが area に含まれているか
# 3. 両ルーターが同じ area か
# 4. インターフェースが up しているか
# 5. Hello/Dead タイマーが一致しているか（デフォルトは同じ）
```

### VLAN で通信できない

**症状**: 同じ VLAN なのに通信できない

**チェックポイント**:
```bash
# 1. VLAN ID が一致しているか
# 2. トランクポートの設定が正しいか
# 3. ブリッジの設定を確認
bridge link show
ip link show master <bridge-name>
```

---

## パフォーマンスの問題

### 動作が遅い

**症状**: コマンドの応答が遅い、ラボ起動に時間がかかる

**解決策**:
```bash
# メモリ使用量確認
free -h

# CPU 使用量確認
top

# 不要なコンテナを停止
sudo containerlab destroy --all

# Docker のクリーンアップ
docker system prune -f
```

### VM のディスクが足りない

**症状**: `No space left on device`

**解決策**:
```bash
# ディスク使用量確認
df -h

# Docker イメージのクリーンアップ
docker image prune -a

# 古いラボファイルの削除
sudo rm -rf /var/lib/docker/containers/*
```

### コンテナが頻繁に落ちる

**症状**: `OOM Killed` でコンテナが停止

**解決策**:
```bash
# VM のメモリを増やす
# Multipass の場合
multipass stop workshop
multipass set local.workshop.memory=8G
multipass start workshop

# 同時に起動するノード数を減らす
# Day 4 の OSPF は 6 ノード必要なので注意
```

---

## 緊急リセット手順

何をやってもダメな場合の最終手段：

```bash
# 1. すべてのラボを破棄
sudo containerlab destroy --all

# 2. Docker を完全クリーンアップ
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker system prune -af

# 3. VyOS イメージを再取得
docker pull ghcr.io/vyos/vyos:current
docker pull alpine:latest

# 4. ラボを再起動
cd ~/network-workshop-vyos/day1-ip-basics
sudo containerlab deploy -t exercise.clab.yml
```

---

## ヘルプを求める

上記で解決しない場合：

1. **エラーメッセージ全文**をコピー
2. **実行したコマンド**を記録
3. **環境情報**を収集：
   ```bash
   uname -a
   docker --version
   containerlab version
   free -h
   df -h
   ```
4. 講師またはサポートに連絡
