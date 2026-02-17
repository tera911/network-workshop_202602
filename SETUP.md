# 環境構築ガイド

このガイドでは、macOS 上に Multipass + cloud-init を使って勉強会環境を構築する手順を説明します。

---

## 前提条件

- macOS（Intel または Apple Silicon）
- Homebrew がインストール済み
- 管理者権限
- インターネット接続

---

## セットアップ手順

cloud-init を使って必要な環境を一括でセットアップします。

### 1. Multipass インストール

```bash
brew install multipass
```

### 2. cloud-init ファイルを確認

教材に同梱の `cloud-init.yaml` を使用します。

```bash
# 教材フォルダにある cloud-init.yaml を確認
ls cloud-init.yaml
```

### 3. VM 作成

```bash
multipass launch \
  --name workshop \
  --disk 10G \
  --memory 2G \
  --cloud-init cloud-init.yaml \
  22.04
```

cloud-init により以下が自動インストールされます:
- Docker
- Containerlab
- VyOS / Alpine コンテナイメージ
- **シェルヘルパー**（`vrouter`, `vhost` 等のショートカット）

### 4. セットアップ完了を待つ(以下のコマンドは叩かなくても良いです)

```bash
# セットアップ状況を確認（5-10分かかります）
multipass exec workshop -- tail -f /var/log/cloud-init-output.log
```

`Cloud-init completed` と表示されたら完了です（Ctrl+C で終了）。  
上記tailをしなければ、`Launched: workshop`と表示されたら完了です。

### 5. 教材を VM に転送

macOS 側で:

```bash
# VM に転送
multipass transfer -r . workshop:/home/ubuntu/network-workshop
```

VM 側で:
```bash
cd network-workshop

# ディレクトリ確認
ls -la
```

### 6. VM にログイン

```bash
multipass shell workshop
```

---

## VyOS イメージの手動取得（オプション）

cloud-init で VyOS イメージが正常に取得できなかった場合は、以下の方法で手動取得してください。

**方法A: 講師から配布されたイメージを使う（勉強会参加者向け）**

```bash
cd ~/network-workshop-vyos
./scripts/import-vyos-image.sh vyos-workshop.tar

# または URL から直接取得
./scripts/import-vyos-image.sh http://<講師のIP>:8000/vyos-workshop.tar
```

**方法B: 公式イメージを取得（個人学習向け）**

```bash
docker pull ghcr.io/vyos/vyos:current
docker pull alpine:latest
docker images
```

**方法C: 自分でビルド**

VyOS のポリシー変更により、公式イメージが取得できない場合があります。

```bash
cd ~/network-workshop-vyos
./scripts/build-vyos-docker.sh
./scripts/switch-vyos-image.sh local
```

詳細は [docs/BUILD-VYOS.md](docs/BUILD-VYOS.md) を参照してください。

---

## 環境の動作確認

### テストラボを起動

```bash
cd ~/network-workshop-vyos/day1-ip-basics

# ラボを起動
sudo containerlab deploy -t exercise.clab.yml
```

### ノードの状態確認

```bash
sudo containerlab inspect -t exercise.clab.yml
```

### VyOS にログイン

```bash
docker exec -it clab-day1-exercise-router1 /bin/vbash
```

VyOS プロンプトが表示されれば成功:
```
vyos@router1:~$
```

`exit` で抜けます。

### テストラボを破棄

```bash
sudo containerlab destroy -t exercise.clab.yml
```

---

## Multipass 便利コマンド

```bash
# VM 一覧
multipass list

# VM 停止
multipass stop workshop

# VM 起動
multipass start workshop

# VM 削除
multipass delete workshop
multipass purge  # 完全削除

# VM の情報
multipass info workshop

# ファイル転送（ホスト → VM）
multipass transfer local-file.txt workshop:/home/ubuntu/

# ファイル転送（VM → ホスト）
multipass transfer workshop:/home/ubuntu/remote-file.txt ./
```

---

## トラブルシューティング

問題が発生した場合は **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** を参照してください。

---

## 参加者への事前案内（テンプレート）

以下を参加者に事前送付してください:

```
【ネットワーク勉強会】事前準備のお願い

勉強会までに以下の準備をお願いします（所要時間: 約30分）

■ 必要なもの
- macOS（Intel または Apple Silicon）
- インターネット接続
- 約 5GB の空きディスク容量

■ 準備手順

1. Homebrew をインストール（未導入の場合）
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

2. Multipass をインストール
   brew install multipass

3. 添付の cloud-init.yaml を使って VM を作成
   multipass launch --name workshop --disk 10G --cloud-init cloud-init.yaml 22.04

4. セットアップ完了を待つ（5-10分）
   multipass exec workshop -- cat /home/ubuntu/setup-done.txt
   「Setup complete!」と表示されれば完了です。

■ 当日持参するもの
- ノートPC（上記準備済み）
- 電源アダプター

ご不明点があればお気軽にお問い合わせください。
```

---

## 次のステップ

環境構築が完了したら、Day 1 から始めましょう:

```bash
cd ~/network-workshop-vyos/day1-ip-basics
cat INSTRUCTIONS.md
```
