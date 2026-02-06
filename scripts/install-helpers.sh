#!/bin/bash
# ============================================================
# シェルヘルパーのインストールスクリプト
# ============================================================
#
# このスクリプトは、勉強会用のショートカットコマンドを
# .bashrc に追加します。
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_FILE="$SCRIPT_DIR/shell-helpers.sh"
BASHRC="$HOME/.bashrc"

echo "=== シェルヘルパーのインストール ==="
echo ""

# ヘルパーファイルの存在確認
if [ ! -f "$HELPER_FILE" ]; then
    echo "エラー: $HELPER_FILE が見つかりません"
    exit 1
fi

# すでにインストール済みか確認
if grep -q "shell-helpers.sh" "$BASHRC" 2>/dev/null; then
    echo "すでにインストール済みです。"
    echo ""
    echo "再読み込みするには:"
    echo "  source ~/.bashrc"
    exit 0
fi

# .bashrc に追加
echo "" >> "$BASHRC"
echo "# ネットワーク勉強会用シェルヘルパー" >> "$BASHRC"
echo "if [ -f \"$HELPER_FILE\" ]; then" >> "$BASHRC"
echo "    source \"$HELPER_FILE\"" >> "$BASHRC"
echo "fi" >> "$BASHRC"

echo "インストール完了！"
echo ""
echo "以下のコマンドで有効化してください:"
echo "  source ~/.bashrc"
echo ""
echo "または新しいターミナルを開いてください。"
echo ""
echo "利用可能なコマンド:"
echo "  vrouter   - VyOSルーターに接続"
echo "  vhost     - Alpineホストに接続"
echo "  vdeploy   - ラボを起動"
echo "  vdestroy  - ラボを破棄"
echo "  vlab      - ラボ状態を表示"
echo "  vping     - ホスト間でping"
echo "  vhelp     - ヘルプを表示"
