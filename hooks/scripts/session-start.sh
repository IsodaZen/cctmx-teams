#!/bin/bash
set -eo pipefail

# デバッグログファイル
LOGGING=""
LOG_FILE="/tmp/cctmx-teams-hook-session-start.log"

# ログ記録関数
log() {
  [ -z "$LOGGING" ] || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "=== SessionStart Hook開始 ==="
log "CLAUDE_ENV_FILE=${CLAUDE_ENV_FILE:-<未定義>}"
log "CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-<未定義>}"
log "TMUX=${TMUX:-<未定義>}"
log "TMUX_PANE=${TMUX_PANE:-<未定義>}"

# CLAUDE_ENV_FILEの利用可否を判定（空でも処理は継続する）
env_file_available=""
if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ "${CLAUDE_ENV_FILE}" != "" ]; then
  env_file_available="1"
  log "CLAUDE_ENV_FILEの確認OK: ${CLAUDE_ENV_FILE}"
else
  log "警告: CLAUDE_ENV_FILEが未定義または空文字列です（Issue #15840）。環境変数の永続化はスキップし、処理を継続します。"
fi

# 環境変数をCLAUDE_ENV_FILEに書き込むヘルパー関数
write_env() {
  if [ -n "$env_file_available" ]; then
    echo "$1" >> "$CLAUDE_ENV_FILE"
  fi
}

# tmux内で実行されているか判定
if [ -z "${TMUX:-}" ]; then
  # tmux外部で起動された場合
  log "tmux外部で起動"

  # セッション名を提案
  suggested_session="claude-dev"

  printf '{"systemMessage": "⚠️ cctmx-teams: Claude Codeはtmux外部で起動されました。\\n\\ntmuxセッション内で起動することを推奨します:\\n  tmux new-session -s %s\\n  claude"}\n' "${suggested_session}" >&2

  write_env "export CLAUDE_TMUX_SESSION=${suggested_session}"
  log "環境変数を永続化: CLAUDE_TMUX_SESSION=${suggested_session}"
  log "=== SessionStart Hook完了（tmux外部） ==="

  exit 0
fi

# tmux内部で起動された場合
log "tmux内部で起動"

tmux_session=$(tmux display-message -p '#S')
tmux_pane=$(tmux display-message -p '#I.#P')
tmux_window=$(tmux display-message -p '#I')

# ペイン番号の取得: TMUX_PANE環境変数を使って正確なペインを特定
# tmux display-message -p '#P' はアクティブペインの番号を返すため、
# フック実行元ペインと異なる場合がある（Issue: ペイン番号の誤認識）
if [ -n "${TMUX_PANE:-}" ]; then
  # TMUX_PANE（例: %0, %1）を使い、該当ペインのインデックスを取得
  current_pane_index=$(tmux display-message -t "${TMUX_PANE}" -p '#P')
  tmux_pane=$(tmux display-message -t "${TMUX_PANE}" -p '#I.#P')
  log "ペイン番号をTMUX_PANEから取得: TMUX_PANE=${TMUX_PANE}, index=${current_pane_index}"
else
  # フォールバック: TMUX_PANEが利用不可の場合
  current_pane_index=$(tmux display-message -p '#P')
  log "ペイン番号をdisplay-messageから取得（フォールバック）: index=${current_pane_index}"
fi

log "tmuxセッション: ${tmux_session}, ペイン: ${tmux_pane}, ペインインデックス: ${current_pane_index}"

# 現在のウィンドウのペイン数を取得
pane_count=$(tmux list-panes -t "${tmux_session}:${tmux_window}" | wc -l | tr -d ' ')
log "現在のウィンドウのペイン数: ${pane_count}"

# ペイン番号0（最初のペイン）ならleader、それ以外はworker
if [ "$current_pane_index" = "0" ]; then
  claude_role="leader"
else
  claude_role="worker"
fi

# CLAUDE_ENV_FILEに環境変数を書き込み
write_env "export CLAUDE_TMUX_SESSION=${tmux_session}"
write_env "export CLAUDE_TMUX_PANE=${tmux_pane}"
write_env "export CLAUDE_ROLE=${claude_role}"

log "環境変数を永続化: CLAUDE_TMUX_SESSION=${tmux_session}, CLAUDE_TMUX_PANE=${tmux_pane}, CLAUDE_ROLE=${claude_role}"

# ペイン数が1つの場合のみワーカーペインを自動作成
if [ "$pane_count" -eq 1 ]; then
  log "ペイン数が1つのため、ワーカーペインを自動作成"

  # 右側に垂直分割でワーカーペインを作成（ウィンドウ全体を指定）
  log "tmux split-window -h -t ${tmux_session}:${tmux_window} を実行"
  tmux split-window -h -t "${tmux_session}:${tmux_window}"

  log "split-window 実行完了"

  # 新しく作成されたペイン番号を取得（通常は0.1）
  worker_pane=$(tmux list-panes -t "${tmux_session}:${tmux_window}" -F '#{pane_index}' | tail -n 1)
  worker_pane_full="${tmux_window}.${worker_pane}"

  log "ワーカーペインを作成: ${worker_pane_full}"

  # ワーカーペイン番号を環境変数に保存（SESSION, WINDOW, PANEを分離）
  write_env "export CLAUDE_WORKER_SESSION=${tmux_session}"
  write_env "export CLAUDE_WORKER_WINDOW=${tmux_window}"
  write_env "export CLAUDE_WORKER_PANE=${worker_pane}"
  log "環境変数を永続化: CLAUDE_WORKER_SESSION=${tmux_session}, CLAUDE_WORKER_WINDOW=${tmux_window}, CLAUDE_WORKER_PANE=${worker_pane}"

  # worker-infoファイルを作成（tmux-send等のスキルが参照する）
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    worker_info_dir="${CLAUDE_PROJECT_DIR}/.claude"
    mkdir -p "$worker_info_dir"
    {
      echo "export CLAUDE_WORKER_SESSION=${tmux_session}"
      echo "export CLAUDE_WORKER_WINDOW=${tmux_window}"
      echo "export CLAUDE_WORKER_PANE=${worker_pane}"
    } > "${worker_info_dir}/worker-info"
    log "worker-infoファイルを作成: ${worker_info_dir}/worker-info"
  else
    log "警告: CLAUDE_PROJECT_DIRが未定義のため、worker-infoファイルを作成できません"
  fi

  # ワーカーペインでClaudeCodeを起動
  # 重要: tmux split-windowは親ペインの環境変数を継承するため、
  # CLAUDE_ROLE=leader が継承されてしまう。
  # ClaudeCode起動前に継承された環境変数をクリアし、正しい値を設定する。
  sleep 0.5  # ペイン作成の完了を待つ

  log "ワーカーペインで継承された環境変数をクリア"
  tmux send-keys -t "${tmux_session}:${worker_pane_full}" "unset CLAUDE_ROLE CLAUDE_TMUX_PANE CLAUDE_TMUX_SESSION CLAUDE_WORKER_PANE CLAUDE_WORKER_WINDOW" Enter
  sleep 0.3

  log "ワーカーペインに正しい環境変数を設定"
  tmux send-keys -t "${tmux_session}:${worker_pane_full}" "export CLAUDE_ROLE=worker CLAUDE_TMUX_SESSION=${tmux_session} CLAUDE_TMUX_PANE=${worker_pane_full}" Enter
  sleep 0.3

  log "ワーカーペインでClaudeCodeを起動: cd ${CLAUDE_PROJECT_DIR}"
  tmux send-keys -t "${tmux_session}:${worker_pane_full}" "cd \"${CLAUDE_PROJECT_DIR}\"" Enter
  sleep 0.5
  log "ワーカーペインでClaudeCodeを起動: claude"
  tmux send-keys -t "${tmux_session}:${worker_pane_full}" "claude" Enter

  log "ワーカーペインでClaudeCode起動コマンド送信完了"

  # リーダーペインにフォーカスを戻す
  tmux select-pane -t "${tmux_session}:${tmux_pane}"
  log "リーダーペインにフォーカスを戻す"

  printf '{"systemMessage": "✅ cctmx-teams: リーダーペインで起動しました\\n   Session: %s, Pane: %s\\n\\n✅ ワーカーペインを自動作成しました\\n   Pane: %s"}\n' "${tmux_session}" "${tmux_pane}" "${worker_pane_full}" >&2
else
  log "ペイン数が${pane_count}個のため、ワーカーペインの自動作成をスキップ"
  printf '{"systemMessage": "✅ cctmx-teams: %sペインで起動しました\\n   Session: %s, Pane: %s, Role: %s\\n\\nℹ️ 既に%d個のペインが存在するため、ワーカーペインの自動作成をスキップしました"}\n' "${claude_role}" "${tmux_session}" "${tmux_pane}" "${claude_role}" "${pane_count}" >&2
fi

log "=== SessionStart Hook完了（tmux内部） ==="
exit 0
