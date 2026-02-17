#!/bin/bash
# ============================================================
# VyOS セットアップスクリプト共通ヘルパー
# ============================================================
# 使い方: source ../scripts/vyos-setup-helpers.sh

# VyOS の初期化完了を待機（systemd が起動完了するまで）
wait_for_vyos() {
  local lab_name=$1
  shift
  local nodes=("$@")

  echo "VyOS の起動を待機中..."
  for node in "${nodes[@]}"; do
    until docker exec clab-${lab_name}-${node} systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; do
      sleep 3
    done
    echo "  ${node}: ready"
  done
  echo "VyOS 起動完了"
}

# VyOS ノードに設定を投入
configure_vyos() {
  local lab_name=$1
  local node=$2
  shift 2
  local commands="$@"

  # /etc/hosts にコンテナ hostname を追加（sudo エラー回避）
  docker exec clab-${lab_name}-${node} bash -c "grep -q '${node}' /etc/hosts || echo '127.0.0.1 ${node}' >> /etc/hosts"

  echo "=== ${node} の設定を投入中 ==="
  docker exec clab-${lab_name}-${node} /bin/vbash -c "
source /opt/vyatta/etc/functions/script-template
configure
set system host-name ${node}
${commands}
commit
save
exit
"
  sleep 5
}
