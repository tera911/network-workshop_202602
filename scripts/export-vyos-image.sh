#!/bin/bash
# ============================================================
# VyOS イメージエクスポートスクリプト（講師用）
# ============================================================
#
# 使い方:
#   ./export-vyos-image.sh              # vyos-workshop.tar を作成
#   ./export-vyos-image.sh --compress   # vyos-workshop.tar.gz を作成
#

set -e

IMAGE_NAME="vyos-local:latest"
OUTPUT_FILE="vyos-workshop.tar"
COMPRESS=false

# 引数処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --compress|-c)
            COMPRESS=true
            OUTPUT_FILE="vyos-workshop.tar.gz"
            shift
            ;;
        *)
            echo "不明なオプション: $1"
            exit 1
            ;;
    esac
done

echo "=============================================="
echo " VyOS イメージエクスポート"
echo "=============================================="
echo ""

# イメージの存在確認
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "エラー: イメージ '$IMAGE_NAME' が見つかりません"
    echo ""
    echo "先にビルドを実行してください:"
    echo "  ./scripts/build-vyos-docker.sh"
    exit 1
fi

# エクスポート
echo ">>> イメージをエクスポート中..."
echo "    イメージ: $IMAGE_NAME"
echo "    出力先:   $OUTPUT_FILE"
echo ""

if [ "$COMPRESS" = true ]; then
    docker save "$IMAGE_NAME" | gzip > "$OUTPUT_FILE"
else
    docker save "$IMAGE_NAME" -o "$OUTPUT_FILE"
fi

# ファイルサイズ表示
SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
echo ""
echo "=============================================="
echo " エクスポート完了！"
echo "=============================================="
echo ""
echo "ファイル: $OUTPUT_FILE"
echo "サイズ:   $SIZE"
echo ""
echo "配布方法:"
echo "  1. USB メモリにコピー"
echo "  2. ファイル共有サービス（Google Drive 等）にアップロード"
echo "  3. 会場で簡易サーバーを立てる:"
echo "     python3 -m http.server 8000"
echo ""
echo "参加者への読み込み手順:"
if [ "$COMPRESS" = true ]; then
    echo "  gunzip -c $OUTPUT_FILE | docker load"
else
    echo "  docker load -i $OUTPUT_FILE"
fi
