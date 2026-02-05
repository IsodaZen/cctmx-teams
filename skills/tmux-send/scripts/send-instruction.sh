#!/bin/bash
set -euo pipefail

# ワーカーペイン情報の確認
worker_info_file="${CLAUDE_PROJECT_DIR}/.claude/worker-info"
if [ ! -f "$worker_info_file" ]; then
  echo "❌ エラー: ワーカーペイン情報が見つかりません" >&2
  echo "/tmux-worker スキルを先に実行してください" >&2
  exit 1
fi

# ワーカーペイン情報を読み込み
# shellcheck source=/dev/null
source "$worker_info_file"

if [ -z "${CLAUDE_WORKER_PANE:-}" ] || [ -z "${CLAUDE_WORKER_SESSION:-}" ]; then
  echo "❌ エラー: ワーカーペイン情報が不正です" >&2
  exit 1
fi

session="${CLAUDE_WORKER_SESSION}"
worker_pane="${CLAUDE_WORKER_PANE}"

# .claudeディレクトリの作成（存在しない場合）
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"

# タスクIDを自動生成
task_date=$(date +%Y%m%d)
task_counter_file="${CLAUDE_PROJECT_DIR}/.claude/.task-counter-${task_date}"

# カウンターファイルが存在しない場合は1から開始
if [ ! -f "$task_counter_file" ]; then
  echo "1" > "$task_counter_file"
  task_number="001"
else
  # カウンターをインクリメント
  current_count=$(cat "$task_counter_file")
  next_count=$((current_count + 1))
  echo "$next_count" > "$task_counter_file"
  task_number=$(printf "%03d" "$next_count")
fi

task_id="TASK-${task_date}-${task_number}"

echo "📤 ワーカーに指示を送信中..." >&2
echo "セッション: ${session}" >&2
echo "ペイン: ${worker_pane}" >&2
echo "タスクID: ${task_id}" >&2
echo "" >&2

# 標準入力から指示内容を読み込み
instruction=$(cat)

# 指示が空でないか確認
if [ -z "$instruction" ]; then
  echo "❌ エラー: 指示内容が空です" >&2
  echo "標準入力から構造化指示を入力してください" >&2
  exit 1
fi

# タスクIDを先頭に追加
full_instruction="タスクID: ${task_id}
${instruction}"

# ワーカーに送信（tmux load-buffer + paste-bufferを使用）
echo "$full_instruction" | tmux load-buffer -
tmux paste-buffer -t "${session}:${worker_pane}"
tmux send-keys -t "${session}:${worker_pane}" Enter

echo "" >&2
echo "✅ 指示を送信しました" >&2
echo "" >&2
echo "次のステップ:" >&2
echo "- ワーカーの作業を監視" >&2
echo "- 定期的に /tmux-check でエラー検知" >&2
echo "- 完了後に /tmux-review でレビュー" >&2
echo "" >&2

exit 0
