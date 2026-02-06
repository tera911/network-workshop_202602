#!/bin/bash
# ============================================================
# VyOS イメージインポートスクリプト（参加者用）
# ============================================================
#
# 使い方:
#   ./import-vyos-image.sh vyos-workshop.tar
#   ./import-vyos-image.sh vyos-workshop.tar.gz
#   ./import-vyos-image.sh http://192.168.1.100:8000/vyos-workshop.tar
#

set -e

INPUT="$1"

usage() {
    echo "使い方: $0 <ファイルまたはURL>"
    echo ""
    echo "例:"
    echo "  $0 vyos-workshop.tar"
    echo "  $0 vyos-workshop.tar.gz"
    echo "  $0 http://192.168.1.100:8000/vyos-workshop.tar"
    exit 1
}

if [ -z "$INPUT" ]; then
    usage
fi

echo "=============================================="
echo " VyOS イメージインポート"
echo "=============================================="
echo ""

# URL の場合はダウンロード
if [[ "$INPUT" == http* ]]; then
    echo ">>> ダウンロード中: $INPUT"
    FILENAME=$(basename "$INPUT")
    curl -# -O "$INPUT"
    INPUT="$FILENAME"
    echo ""
fi

# ファイルの存在確認
if [ ! -f "$INPUT" ]; then
    echo "エラー: ファイル '$INPUT' が見つかりません"
    exit 1
fi

# 読み込み
echo ">>> イメージを読み込み中: $INPUT"
echo ""

if [[ "$INPUT" == *.gz ]]; then
    gunzip -c "$INPUT" | docker load
else
    docker load -i "$INPUT"
fi

echo ""
echo "=============================================="
echo " インポート完了！"
echo "=============================================="
echo ""

# イメージ確認
echo "読み込まれたイメージ:"
docker images | grep -E "vyos|REPOSITORY"
echo ""

# 教材のイメージ参照を切り替え
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCH_SCRIPT="$SCRIPT_DIR/switch-vyos-image.sh"

if [ -f "$SWITCH_SCRIPT" ]; then
    echo ">>> 教材のイメージ参照を切り替え中..."
    "$SWITCH_SCRIPT" local
    echo ""
fi

echo "準備完了！Day 1 から始めましょう:"
echo "  cd day1-ip-basics"
echo "  vdeploy exercise.clab.yml"
