#!/bin/bash
# ============================================================
# ネットワーク勉強会用シェルヘルパー
# ============================================================
#
# インストール方法:
#   echo 'source ~/network-workshop-vyos/scripts/shell-helpers.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# または:
#   ./scripts/install-helpers.sh
#

# ------------------------------------------------------------
# VyOS ルーターに接続
# ------------------------------------------------------------
# 使い方: vrouter <ノード名>
# 例:     vrouter router1
#         vrouter router-hq
#         vrouter router-tokyo
#
vrouter() {
    local node="$1"
    if [ -z "$node" ]; then
        echo "使い方: vrouter <ノード名>"
        echo "例:     vrouter router1"
        echo ""
        echo "現在のコンテナ一覧:"
        docker ps --format "table {{.Names}}" | grep -E "router|vyos" || echo "  (VyOSルーターなし)"
        return 1
    fi

    # コンテナ名を検索（部分一致）
    local container=$(docker ps --format "{{.Names}}" | grep -i "$node" | head -1)

    if [ -z "$container" ]; then
        echo "エラー: '$node' に一致するコンテナが見つかりません"
        echo ""
        echo "現在のコンテナ一覧:"
        docker ps --format "  {{.Names}}"
        return 1
    fi

    echo ">>> 接続中: $container"
    echo ">>> 終了するには 'exit' と入力"
    echo ""
    sudo docker exec -it "$container" /bin/vbash
}

# ------------------------------------------------------------
# Alpine ホストに接続
# ------------------------------------------------------------
# 使い方: vhost <ノード名>
# 例:     vhost host1
#         vhost host-hq
#
vhost() {
    local node="$1"
    if [ -z "$node" ]; then
        echo "使い方: vhost <ノード名>"
        echo "例:     vhost host1"
        echo ""
        echo "現在のコンテナ一覧:"
        docker ps --format "table {{.Names}}" | grep -i "host" || echo "  (ホストなし)"
        return 1
    fi

    # コンテナ名を検索（部分一致）
    local container=$(docker ps --format "{{.Names}}" | grep -i "$node" | head -1)

    if [ -z "$container" ]; then
        echo "エラー: '$node' に一致するコンテナが見つかりません"
        echo ""
        echo "現在のコンテナ一覧:"
        docker ps --format "  {{.Names}}"
        return 1
    fi

    echo ">>> 接続中: $container"
    echo ">>> 終了するには 'exit' と入力"
    echo ""
    sudo docker exec -it "$container" /bin/sh
}

# ------------------------------------------------------------
# 任意のノードに接続（自動判定）
# ------------------------------------------------------------
# 使い方: vconnect <ノード名>
# 例:     vconnect router1   → /bin/vbash で接続
#         vconnect host1     → /bin/sh で接続
#
vconnect() {
    local node="$1"
    if [ -z "$node" ]; then
        echo "使い方: vconnect <ノード名>"
        echo ""
        echo "現在のコンテナ一覧:"
        docker ps --format "  {{.Names}}"
        return 1
    fi

    # コンテナ名を検索
    local container=$(docker ps --format "{{.Names}}" | grep -i "$node" | head -1)

    if [ -z "$container" ]; then
        echo "エラー: '$node' に一致するコンテナが見つかりません"
        return 1
    fi

    # VyOS か判定してシェルを選択
    local image=$(docker inspect --format '{{.Config.Image}}' "$container")
    local shell="/bin/sh"

    if echo "$image" | grep -qi "vyos"; then
        shell="/bin/vbash"
    fi

    echo ">>> 接続中: $container ($shell)"
    sudo docker exec -it "$container" "$shell"
}

# ------------------------------------------------------------
# 現在のラボ状態を表示
# ------------------------------------------------------------
# 使い方: vlab
#
vlab() {
    echo "=== 起動中のコンテナ ==="
    echo ""
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "clab|NAME"
    echo ""
    echo "=== 接続コマンド ==="
    echo "  vrouter <ルーター名>  - VyOSルーターに接続"
    echo "  vhost <ホスト名>      - Alpineホストに接続"
    echo "  vconnect <ノード名>   - 自動判定で接続"
}

# ------------------------------------------------------------
# ラボを起動
# ------------------------------------------------------------
# 使い方: vdeploy <clab.yml>
# 例:     vdeploy topology.clab.yml
#
vdeploy() {
    local file="${1:-topology.clab.yml}"
    if [ ! -f "$file" ]; then
        echo "エラー: $file が見つかりません"
        echo ""
        echo "利用可能な .clab.yml ファイル:"
        ls -1 *.clab.yml 2>/dev/null || echo "  (なし)"
        return 1
    fi
    echo ">>> ラボを起動: $file"
    sudo containerlab deploy -t "$file"
}

# ------------------------------------------------------------
# ラボを破棄
# ------------------------------------------------------------
# 使い方: vdestroy <clab.yml>
# 例:     vdestroy topology.clab.yml
#
vdestroy() {
    local file="${1:-topology.clab.yml}"
    if [ ! -f "$file" ]; then
        echo "エラー: $file が見つかりません"
        return 1
    fi
    echo ">>> ラボを破棄: $file"
    sudo containerlab destroy -t "$file"
}

# ------------------------------------------------------------
# ping を簡略化（ホストからホストへ）
# ------------------------------------------------------------
# 使い方: vping <送信元> <宛先IP>
# 例:     vping host1 192.168.2.10
#
vping() {
    local src="$1"
    local dst="$2"

    if [ -z "$src" ] || [ -z "$dst" ]; then
        echo "使い方: vping <送信元ノード> <宛先IP>"
        echo "例:     vping host1 192.168.2.10"
        return 1
    fi

    local container=$(docker ps --format "{{.Names}}" | grep -i "$src" | head -1)

    if [ -z "$container" ]; then
        echo "エラー: '$src' に一致するコンテナが見つかりません"
        return 1
    fi

    echo ">>> $container から $dst へ ping"
    sudo docker exec "$container" ping -c 3 "$dst"
}

# ------------------------------------------------------------
# ヘルプ表示
# ------------------------------------------------------------
vhelp() {
    cat << 'EOF'
=== ネットワーク勉強会 シェルヘルパー ===

【接続コマンド】
  vrouter <名前>     VyOSルーターに接続
  vhost <名前>       Alpineホストに接続
  vconnect <名前>    自動判定で接続

【ラボ管理】
  vdeploy [file]     ラボを起動（デフォルト: topology.clab.yml）
  vdestroy [file]    ラボを破棄
  vlab               現在のラボ状態を表示

【便利コマンド】
  vping <src> <ip>   ホスト間でping
  vhelp              このヘルプを表示

【例】
  vdeploy                    # topology.clab.yml を起動
  vrouter router1            # router1 に接続
  vping host1 192.168.2.10   # host1 から ping
  vdestroy                   # ラボを破棄

EOF
}

# 読み込み完了メッセージ
echo "シェルヘルパーを読み込みました。'vhelp' でコマンド一覧を表示"
