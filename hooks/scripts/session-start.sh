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

# CLAUDE_ENV_FILEの存在確認（未定義または空文字列をチェック）
if [ -z "${CLAUDE_ENV_FILE:-}" ]; then
  log "エラー: CLAUDE_ENV_FILEが未定義です"
  printf '{"systemMessage": "⚠️ cctmx-teams SessionStart Hook: CLAUDE_ENV_FILEが未定義です。\\n環境変数の永続化はスキップされます。"}\n' >&2
  # exit 0で続行（エラーでも処理を継続）
  exit 0
fi

# CLAUDE_ENV_FILEが空文字列の場合もエラー
if [ "${CLAUDE_ENV_FILE}" = "" ]; then
  log "エラー: CLAUDE_ENV_FILEが空文字列です"
  printf '{"systemMessage": "⚠️ cctmx-teams SessionStart Hook: CLAUDE_ENV_FILEが空文字列です。\\n環境変数の永続化はスキップされます。"}\n' >&2
  exit 0
fi

log "CLAUDE_ENV_FILEの確認OK: ${CLAUDE_ENV_FILE}"

# tmux内で実行されているか判定
if [ -z "${TMUX:-}" ]; then
  # tmux外部で起動された場合
  log "tmux外部で起動"

  # セッション名を提案
  suggested_session="claude-dev"

  printf '{"systemMessage": "⚠️ cctmx-teams: Claude Codeはtmux外部で起動されました。\\n\\ntmuxセッション内で起動することを推奨します:\\n  tmux new-session -s %s\\n  claude"}\n' "${suggested_session}" >&2

  # CLAUDE_ENV_FILEに環境変数を書き込み
  echo "export CLAUDE_TMUX_SESSION=${suggested_session}" >> "$CLAUDE_ENV_FILE"
  log "環境変数を永続化: CLAUDE_TMUX_SESSION=${suggested_session}"
  log "=== SessionStart Hook完了（tmux外部） ==="

  exit 0
fi

# tmux内部で起動された場合
log "tmux内部で起動"

tmux_session=$(tmux display-message -p '#S')
tmux_pane=$(tmux display-message -p '#I.#P')
tmux_window=$(tmux display-message -p '#I')

log "tmuxセッション: ${tmux_session}, ペイン: ${tmux_pane}"

# 現在のウィンドウのペイン数を取得
pane_count=$(tmux list-panes -t "${tmux_session}:${tmux_window}" | wc -l | tr -d ' ')
log "現在のウィンドウのペイン数: ${pane_count}"

# 現在のペイン番号を取得（#P = pane index）
current_pane_index=$(tmux display-message -p '#P')
log "現在のペイン番号: ${current_pane_index}"

# ペイン番号0（最初のペイン）ならleader、それ以外はworker
if [ "$current_pane_index" = "0" ]; then
  claude_role="leader"
else
  claude_role="worker"
fi

# CLAUDE_ENV_FILEに環境変数を書き込み
{
  echo "export CLAUDE_TMUX_SESSION=${tmux_session}"
  echo "export CLAUDE_TMUX_PANE=${tmux_pane}"
  echo "export CLAUDE_ROLE=${claude_role}"
} >> "$CLAUDE_ENV_FILE"

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

  # ワーカーペイン番号を環境変数に保存
  echo "export CLAUDE_WORKER_PANE=${worker_pane_full}" >> "$CLAUDE_ENV_FILE"
  log "環境変数を永続化: CLAUDE_WORKER_PANE=${worker_pane_full}"

  # ワーカーペインでClaudeCodeを起動
  sleep 0.5  # ペイン作成の完了を待つ
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
  printf '{"systemMessage": "✅ cctmx-teams: リーダーペインで起動しました\\n   Session: %s, Pane: %s, Role: %s\\n\\nℹ️ 既に%d個のペインが存在するため、ワーカーペインの自動作成をスキップしました"}\n' "${tmux_session}" "${tmux_pane}" "${claude_role}" "${pane_count}" >&2
fi

log "=== SessionStart Hook完了（tmux内部） ==="
exit 0
