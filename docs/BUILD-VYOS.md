# VyOS Docker イメージの取得方法

VyOS の公式 Docker イメージが直接取得できない場合の対処法です。

---

## 方法1: 講師から配布されたイメージを使う（推奨）

勉強会では、講師が事前にビルドしたイメージを配布します。

### イメージファイルの読み込み

```bash
# 配布された tar ファイルを読み込み
docker load -i vyos-workshop.tar

# 確認
docker images | grep vyos
```

出力例:
```
vyos-local    latest    xxxxxxxxxxxx    1 hour ago    512MB
```

### 教材のイメージ参照を切り替え

```bash
cd ~/network-workshop-vyos
./scripts/switch-vyos-image.sh local
```

これで完了です！以下のビルド手順は不要です。

---

## 方法2: 自分でビルドする

講師からイメージを受け取れない場合や、最新版が必要な場合はビルドしてください。

## 前提条件

- Docker がインストール済み
- Git がインストール済み
- 約 10GB の空きディスク容量
- ビルド時間: 約 30-60 分

---

## ビルド手順

### Step 1: vyos-build リポジトリをクローン

```bash
cd ~
git clone -b current --single-branch https://github.com/vyos/vyos-build
cd vyos-build
```

### Step 2: ビルド用 Docker コンテナを起動

```bash
# ビルド環境のDockerイメージを取得
docker pull vyos/vyos-build:current

# ビルドコンテナを起動
docker run --rm -it \
  --privileged \
  -v $(pwd):/vyos \
  -w /vyos \
  vyos/vyos-build:current \
  bash
```

### Step 3: VyOS ISO をビルド（コンテナ内）

```bash
# ビルドコンテナ内で実行
./build-vyos-image iso --architecture amd64
```

ビルドには 30-60 分かかります。完了すると `build/` ディレクトリに ISO が生成されます。

### Step 4: Docker イメージを作成

ISO から Docker イメージを作成します。

```bash
# ビルドコンテナから exit
exit

# ISO をマウントして rootfs を抽出
mkdir -p /tmp/vyos-iso /tmp/vyos-rootfs
sudo mount -o loop build/vyos-*.iso /tmp/vyos-iso
sudo unsquashfs -d /tmp/vyos-rootfs /tmp/vyos-iso/live/filesystem.squashfs

# Docker イメージを作成
sudo tar -C /tmp/vyos-rootfs -c . | docker import - vyos-local:latest

# クリーンアップ
sudo umount /tmp/vyos-iso
sudo rm -rf /tmp/vyos-iso /tmp/vyos-rootfs
```

### Step 5: イメージの確認

```bash
docker images | grep vyos
```

出力例:
```
vyos-local    latest    xxxxxxxxxxxx    1 minute ago    512MB
```

---

## 簡易ビルドスクリプト

上記の手順をスクリプト化したものです：

```bash
#!/bin/bash
# build-vyos-docker.sh
# VyOS Docker イメージをビルドするスクリプト

set -e

echo "=== VyOS Docker イメージビルド ==="

# 作業ディレクトリ
WORK_DIR="$HOME/vyos-build"
IMAGE_NAME="vyos-local:latest"

# Step 1: リポジトリをクローン
if [ ! -d "$WORK_DIR" ]; then
    echo ">>> vyos-build をクローン中..."
    git clone -b current --single-branch https://github.com/vyos/vyos-build "$WORK_DIR"
fi

cd "$WORK_DIR"

# Step 2-3: ビルド実行
echo ">>> ISO をビルド中（30-60分かかります）..."
docker run --rm \
  --privileged \
  -v $(pwd):/vyos \
  -w /vyos \
  vyos/vyos-build:current \
  ./build-vyos-image iso --architecture amd64

# Step 4: Docker イメージ作成
echo ">>> Docker イメージを作成中..."
ISO_FILE=$(ls build/vyos-*.iso | head -1)

mkdir -p /tmp/vyos-iso /tmp/vyos-rootfs
sudo mount -o loop "$ISO_FILE" /tmp/vyos-iso
sudo unsquashfs -d /tmp/vyos-rootfs /tmp/vyos-iso/live/filesystem.squashfs
sudo tar -C /tmp/vyos-rootfs -c . | docker import - "$IMAGE_NAME"

# クリーンアップ
sudo umount /tmp/vyos-iso
sudo rm -rf /tmp/vyos-iso /tmp/vyos-rootfs

echo ""
echo "=== ビルド完了 ==="
echo "イメージ名: $IMAGE_NAME"
echo ""
echo "Containerlab で使用するには、topology.clab.yml の image を変更してください:"
echo "  image: vyos-local:latest"
```

---

## topology.clab.yml の修正

ビルドしたイメージを使用する場合、各 `topology.clab.yml` の image を変更します：

**Before（公式イメージ）:**
```yaml
router-hq:
  kind: linux
  image: ghcr.io/vyos/vyos:current
```

**After（ローカルビルド）:**
```yaml
router-hq:
  kind: linux
  image: vyos-local:latest
```

### 一括置換スクリプト

```bash
# すべての topology.clab.yml を一括置換
cd ~/network-workshop-vyos
find . -name "*.clab.yml" -exec sed -i 's|ghcr.io/vyos/vyos:current|vyos-local:latest|g' {} \;
```

---

## 代替案: 古いイメージを試す

以下のタグが利用可能な場合があります（時期により異なる）：

```bash
# いくつかのタグを試す
docker pull ghcr.io/vyos/vyos:1.4-rolling-202401010317
docker pull ghcr.io/vyos/vyos:1.3.6
docker pull ghcr.io/vyos/vyos:1.3-epa2
```

---

## トラブルシューティング

### ビルドが失敗する

```bash
# ビルドキャッシュをクリア
cd ~/vyos-build
git clean -fdx
git checkout .

# 最新のビルドイメージを取得
docker pull vyos/vyos-build:current
```

### squashfs-tools がない

```bash
sudo apt-get install squashfs-tools
```

### ISO マウントでエラー

```bash
# loop デバイスの確認
sudo losetup -f

# 強制アンマウント
sudo umount -f /tmp/vyos-iso
```

### ディスク容量不足

```bash
# Docker のクリーンアップ
docker system prune -af

# 古いビルド成果物を削除
cd ~/vyos-build
rm -rf build/
```

---

## 参考情報

- [VyOS Build Documentation](https://docs.vyos.io/en/latest/contributing/build-vyos.html)
- [vyos-build GitHub](https://github.com/vyos/vyos-build)

---

---

## 講師向け: イメージの配布準備

ビルドしたイメージを参加者に配布する手順です。

### イメージをファイルにエクスポート

```bash
# tar ファイルとして保存（約 500MB）
docker save vyos-local:latest -o vyos-workshop.tar

# 圧縮する場合（約 200MB）
docker save vyos-local:latest | gzip > vyos-workshop.tar.gz
```

### 配布方法

| 方法 | 適した状況 |
|------|-----------|
| **USB メモリ** | 会場でネット接続が不安定な場合 |
| **ファイル共有** | Google Drive, Dropbox 等で事前配布 |
| **ローカルサーバー** | 会場に簡易HTTPサーバーを立てる |

### ローカルHTTPサーバーで配布（会場向け）

```bash
# Python の簡易サーバーで配布
cd /path/to/files
python3 -m http.server 8000

# 参加者は以下でダウンロード
# curl -O http://<講師のIP>:8000/vyos-workshop.tar
```

### 参加者への案内文

```
【VyOS イメージの取得】

以下のコマンドでイメージを取得してください：

# ダウンロード
curl -O http://192.168.1.100:8000/vyos-workshop.tar

# 読み込み
docker load -i vyos-workshop.tar

# 確認
docker images | grep vyos
```

---

## 注意事項

- VyOS Rolling Release は開発版であり、本番環境での使用は推奨されません
- ビルドには時間とリソースが必要なため、勉強会前に事前にビルドしておくことを推奨
- ビルドしたイメージは参加者に配布するか、共有ストレージに置いておくと効率的
- 勉強会内での配布は教育目的として問題ありませんが、公開配布はライセンス確認が必要
