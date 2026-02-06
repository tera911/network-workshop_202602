#!/bin/bash
# ============================================================
# VyOS Docker イメージビルドスクリプト
# ============================================================
#
# 使い方:
#   ./build-vyos-docker.sh
#
# 所要時間: 約 30-60 分
# 必要容量: 約 10GB
#

set -e

echo "=============================================="
echo " VyOS Docker イメージビルド"
echo "=============================================="
echo ""

# 設定
WORK_DIR="$HOME/vyos-build"
IMAGE_NAME="vyos-local:latest"
BUILD_DOCKER_IMAGE="vyos/vyos-build:current"

# 必要なツールの確認
check_requirements() {
    echo ">>> 必要なツールを確認中..."

    if ! command -v docker &> /dev/null; then
        echo "エラー: Docker がインストールされていません"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        echo "エラー: Git がインストールされていません"
        exit 1
    fi

    # squashfs-tools のインストール確認
    if ! command -v unsquashfs &> /dev/null; then
        echo ">>> squashfs-tools をインストール中..."
        sudo apt-get update && sudo apt-get install -y squashfs-tools
    fi

    echo "OK"
    echo ""
}

# リポジトリのクローン
clone_repo() {
    if [ -d "$WORK_DIR" ]; then
        echo ">>> 既存のリポジトリを更新中..."
        cd "$WORK_DIR"
        git fetch origin
        git reset --hard origin/current
    else
        echo ">>> vyos-build をクローン中..."
        git clone -b current --single-branch https://github.com/vyos/vyos-build "$WORK_DIR"
        cd "$WORK_DIR"
    fi
    echo ""
}

# ビルド用Dockerイメージの取得
pull_build_image() {
    echo ">>> ビルド用 Docker イメージを取得中..."
    docker pull "$BUILD_DOCKER_IMAGE"
    echo ""
}

# ISO ビルド
build_iso() {
    echo ">>> VyOS ISO をビルド中..."
    echo "    （これには 30-60 分かかります）"
    echo ""

    cd "$WORK_DIR"

    docker run --rm \
        --privileged \
        -v "$(pwd)":/vyos \
        -w /vyos \
        "$BUILD_DOCKER_IMAGE" \
        ./build-vyos-image iso --architecture amd64

    echo ""
    echo ">>> ISO ビルド完了"
    echo ""
}

# Docker イメージ作成
create_docker_image() {
    echo ">>> Docker イメージを作成中..."

    cd "$WORK_DIR"

    # 最新の ISO を探す
    ISO_FILE=$(ls -t build/vyos-*.iso 2>/dev/null | head -1)

    if [ -z "$ISO_FILE" ]; then
        echo "エラー: ISO ファイルが見つかりません"
        exit 1
    fi

    echo "    ISO: $ISO_FILE"

    # 一時ディレクトリ
    MOUNT_DIR=$(mktemp -d)
    ROOTFS_DIR=$(mktemp -d)

    # クリーンアップ関数
    cleanup() {
        sudo umount "$MOUNT_DIR" 2>/dev/null || true
        sudo rm -rf "$MOUNT_DIR" "$ROOTFS_DIR"
    }
    trap cleanup EXIT

    # ISO をマウントして rootfs を抽出
    sudo mount -o loop "$ISO_FILE" "$MOUNT_DIR"
    sudo unsquashfs -d "$ROOTFS_DIR" "$MOUNT_DIR/live/filesystem.squashfs"

    # Docker イメージを作成
    sudo tar -C "$ROOTFS_DIR" -c . | docker import - "$IMAGE_NAME"

    echo ""
    echo ">>> Docker イメージ作成完了"
    echo ""
}

# 結果表示
show_result() {
    echo "=============================================="
    echo " ビルド完了！"
    echo "=============================================="
    echo ""
    echo "イメージ名: $IMAGE_NAME"
    echo ""
    docker images | grep vyos-local
    echo ""
    echo "次のステップ:"
    echo "  1. topology.clab.yml の image を変更:"
    echo "     image: vyos-local:latest"
    echo ""
    echo "  または一括置換:"
    echo "     cd ~/network-workshop-vyos"
    echo "     find . -name '*.clab.yml' -exec sed -i 's|ghcr.io/vyos/vyos:current|vyos-local:latest|g' {} \\;"
    echo ""
}

# メイン処理
main() {
    check_requirements
    clone_repo
    pull_build_image
    build_iso
    create_docker_image
    show_result
}

main "$@"
