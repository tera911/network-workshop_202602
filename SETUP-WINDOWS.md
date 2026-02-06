# 環境構築ガイド（Windows版）

このガイドでは、Windows 上に勉強会環境を構築する手順を説明します。

---

## 前提条件

- Windows 10/11（64bit）
- 管理者権限
- インターネット接続
- 約 10GB の空きディスク容量
- BIOS で仮想化が有効（VT-x / AMD-V）

---

## 方法の選択

Windows では2つの方法があります：

| 方法 | 推奨度 | 特徴 |
|------|--------|------|
| **WSL2 + Docker** | ★★★ | 軽量、セットアップ簡単 |
| **Multipass** | ★★☆ | macOS と同じ手順 |

**推奨: WSL2 + Docker** を使う方法を説明します。

---

## WSL2 + Docker でのセットアップ

### Step 1: WSL2 を有効化

PowerShell を**管理者として実行**し、以下を実行：

```powershell
# WSL を有効化
wsl --install

# 再起動を求められたら再起動
```

再起動後、Ubuntu のセットアップ画面が表示されます。
ユーザー名とパスワードを設定してください。

### Step 2: WSL2 バージョン確認

```powershell
wsl --version
```

出力例：
```
WSL バージョン: 2.0.9.0
カーネル バージョン: 5.15.133.1-1
```

### Step 3: Docker Desktop インストール

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) をダウンロード
2. インストーラーを実行
3. インストール時に「Use WSL 2 instead of Hyper-V」にチェック
4. インストール完了後、Docker Desktop を起動

### Step 4: Docker Desktop の WSL 統合を有効化

1. Docker Desktop の設定（歯車アイコン）を開く
2. `Resources` → `WSL Integration` を選択
3. `Ubuntu` を有効化
4. `Apply & Restart` をクリック

### Step 5: Ubuntu (WSL) にログイン

スタートメニューから `Ubuntu` を起動、または PowerShell で：

```powershell
wsl
```

以降の手順は Ubuntu (WSL) 内で実行します。

### Step 6: Docker 動作確認

```bash
docker --version
docker run hello-world
```

### Step 7: Containerlab インストール

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version
```

### Step 8: VyOS イメージ取得

```bash
docker pull ghcr.io/vyos/vyos:current
docker pull alpine:latest
```

### Step 9: 教材を配置

**方法A: Windows 側からコピー**

Windows のエクスプローラーで教材ZIPを解凍し、WSL からアクセス：

```bash
# Windows の C:\Users\username\Downloads にある場合
cp -r /mnt/c/Users/username/Downloads/network-workshop-vyos ~/
cd ~/network-workshop-vyos
```

**方法B: WSL 内でダウンロード**

```bash
# 例: GitHub からダウンロードする場合
cd ~
unzip network-workshop-vyos.zip
cd network-workshop-vyos
```

### Step 10: シェルヘルパーをインストール

```bash
./scripts/install-helpers.sh
source ~/.bashrc
```

### Step 11: 動作確認

```bash
cd day1-ip-basics
vdeploy exercise.clab.yml
vlab
vrouter router1
exit
vdestroy exercise.clab.yml
```

---

## Multipass でのセットアップ（代替方法）

macOS と同じ手順で Multipass を使うこともできます。

### Step 1: Multipass インストール

[Multipass for Windows](https://multipass.run/install) からダウンロードしてインストール。

### Step 2: VM 作成

PowerShell で：

```powershell
multipass launch --name workshop --memory 4G --cpus 2 --disk 20G 22.04
```

### Step 3: 以降の手順

macOS 版の SETUP.md と同じ手順で進めてください。

---

## Windows 固有のトラブルシューティング

### WSL2 が動かない

```powershell
# WSL の状態確認
wsl --status

# WSL を更新
wsl --update

# デフォルトバージョンを WSL2 に設定
wsl --set-default-version 2
```

### Docker Desktop が起動しない

1. タスクマネージャーで Docker 関連プロセスを終了
2. Docker Desktop を再起動
3. それでもダメなら、Docker Desktop を再インストール

### BIOS で仮想化が無効

1. PC を再起動し、BIOS/UEFI 設定画面に入る（F2, F10, Del など）
2. `Intel VT-x` または `AMD-V` を有効化
3. 保存して再起動

### WSL のディスク容量が足りない

```powershell
# WSL のディスク使用量確認
wsl --system df -h

# 不要なイメージを削除
wsl docker system prune -a
```

### ファイアウォールがブロックする

Windows Defender ファイアウォールで以下を許可：
- Docker Desktop Backend
- vpnkit

### パスの問題（Windows ↔ WSL）

```bash
# Windows のパス → WSL のパス
/mnt/c/Users/username/...

# WSL のパス → Windows のパス
\\wsl$\Ubuntu\home\username\...
```

---

## Windows Terminal の推奨設定

Windows Terminal を使うと、複数のタブで作業できて便利です。

### インストール

Microsoft Store から「Windows Terminal」をインストール。

### プロファイル設定

設定 → プロファイル → Ubuntu で以下を設定：

```json
{
    "name": "Ubuntu",
    "startingDirectory": "//wsl$/Ubuntu/home/username/network-workshop-vyos"
}
```

---

## 参加者への事前案内（Windows版）

```
【ネットワーク勉強会】事前準備のお願い（Windows）

勉強会までに以下の準備をお願いします（所要時間: 約45分）

■ 必要なもの
- Windows 10/11（64bit）
- 管理者権限
- 約 10GB の空きディスク容量

■ 準備手順

1. WSL2 を有効化
   PowerShell を管理者で開き: wsl --install
   再起動後、Ubuntu のユーザー名/パスワードを設定

2. Docker Desktop をインストール
   https://www.docker.com/products/docker-desktop/
   「Use WSL 2」にチェックしてインストール

3. Docker Desktop の WSL 統合を有効化
   Settings → Resources → WSL Integration → Ubuntu を有効化

4. Ubuntu を開いて以下を実行
   bash -c "$(curl -sL https://get.containerlab.dev)"
   docker pull ghcr.io/vyos/vyos:current
   docker pull alpine:latest

5. 完了確認
   docker images でイメージが表示されれば成功

■ 当日持参するもの
- ノートPC（上記準備済み）
- 電源アダプター

ご不明点があればお気軽にお問い合わせください。
```
