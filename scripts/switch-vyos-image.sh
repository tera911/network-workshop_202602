#!/bin/bash
# ============================================================
# VyOS イメージ切り替えスクリプト
# ============================================================
#
# 使い方:
#   ./switch-vyos-image.sh local    # ローカルビルドに切り替え
#   ./switch-vyos-image.sh remote   # 公式イメージに切り替え
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_DIR="$(dirname "$SCRIPT_DIR")"

LOCAL_IMAGE="vyos-local:latest"
REMOTE_IMAGE="ghcr.io/vyos/vyos:current"

usage() {
    echo "使い方: $0 <local|remote>"
    echo ""
    echo "  local   - ローカルビルドイメージ ($LOCAL_IMAGE) に切り替え"
    echo "  remote  - 公式イメージ ($REMOTE_IMAGE) に切り替え"
    echo ""
    exit 1
}

switch_image() {
    local from="$1"
    local to="$2"

    echo ">>> イメージを切り替え中..."
    echo "    From: $from"
    echo "    To:   $to"
    echo ""

    find "$WORKSHOP_DIR" -name "*.clab.yml" -exec sed -i "s|$from|$to|g" {} \;

    echo ">>> 切り替え完了"
    echo ""
    echo "変更されたファイル:"
    find "$WORKSHOP_DIR" -name "*.clab.yml" -exec grep -l "$to" {} \;
}

case "${1:-}" in
    local)
        switch_image "$REMOTE_IMAGE" "$LOCAL_IMAGE"
        ;;
    remote)
        switch_image "$LOCAL_IMAGE" "$REMOTE_IMAGE"
        ;;
    *)
        usage
        ;;
esac
