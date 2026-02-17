#!/bin/bash
set -euo pipefail

# 環境変数の確認
if [ -z "${CLAUDE_TMUX_SESSION:-}" ] || [ -z "${CLAUDE_TMUX_PANE:-}" ]; then
  echo "❌ エラー: tmux環境変数が設定されていません" >&2
  echo "ClaudeCodeをtmux内部で起動してください" >&2
  exit 1
fi

session="${CLAUDE_TMUX_SESSION}"
current_pane="${CLAUDE_TMUX_PANE}"
window_number="${current_pane%%.*}"

# 右側に垂直分割でペインを作成
echo "🔧 ワーカーペインを作成中..." >&2
if ! tmux split-window -h -t "${session}:${window_number}"; then
  echo "❌ エラー: ペイン分割に失敗しました" >&2
  exit 1
fi

# 新しく作成されたペイン番号を取得
# 垂直分割した場合、右側のペインが作成される
# ペイン番号は動的に割り当てられるため、list-panesで確認
all_panes=$(tmux list-panes -t "${session}:${window_number}" -F '#{pane_index}')
worker_pane_index=$(echo "$all_panes" | tail -1)
# tmuxターゲット形式: session:window.pane
worker_target="${window_number}.${worker_pane_index}"

echo "📝 ワーカーペイン: ${session}:${worker_target}" >&2

# 重要: tmux split-windowは親ペインの環境変数を継承するため、
# CLAUDE_ROLE=leader が継承されてしまう。
# ClaudeCode起動前に継承された環境変数をクリアし、正しい値を設定する。
echo "🔄 ワーカーペインの環境変数を設定中..." >&2
tmux send-keys -t "${session}:${worker_target}" "unset CLAUDE_ROLE CLAUDE_TMUX_PANE CLAUDE_TMUX_SESSION CLAUDE_WORKER_PANE CLAUDE_WORKER_WINDOW" Enter
sleep 0.3

tmux send-keys -t "${session}:${worker_target}" "export CLAUDE_ROLE=worker CLAUDE_TMUX_SESSION=${session} CLAUDE_TMUX_PANE=${worker_target}" Enter
sleep 0.3

# ワーカーペインでプロジェクトディレクトリに移動
tmux send-keys -t "${session}:${worker_target}" "cd ${CLAUDE_PROJECT_DIR}" Enter

# 少し待機（ディレクトリ移動の完了を待つ）
sleep 1

# ClaudeCodeを起動
echo "🚀 ClaudeCodeを起動中..." >&2
tmux send-keys -t "${session}:${worker_target}" "claude" Enter

# ワーカーペイン情報を保存（SESSION, WINDOW, PANEを分離して保存）
worker_info_file="${CLAUDE_PROJECT_DIR}/.claude/worker-info"
{
  echo "export CLAUDE_WORKER_SESSION=${session}"
  echo "export CLAUDE_WORKER_WINDOW=${window_number}"
  echo "export CLAUDE_WORKER_PANE=${worker_pane_index}"
} > "$worker_info_file"

echo "✅ ワーカーペインを作成しました: ${session}:${worker_target}" >&2
echo "" >&2
echo "次のステップ:" >&2
echo "1. 構造化指示を作成" >&2
echo "2. /tmux-send でワーカーに指示を送信" >&2
echo "3. /tmux-check でエラー監視" >&2
echo "" >&2
echo "ワーカーペイン情報: ${worker_info_file}" >&2

exit 0
