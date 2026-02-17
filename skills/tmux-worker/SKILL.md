---
name: Tmux Worker Management
description: This skill should be used when the user asks to "create worker pane", "start worker", "launch worker", "ワーカーペインを作成", "ワーカーを起動". Creates a new tmux pane and launches Claude Code for worker role.
version: 1.0.0
---

# 実行指示

以下のBashスクリプトを実行してください：

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-worker/scripts/create-worker.sh
```

このスクリプトは、リーダーペインから新しいワーカーペインを作成し、ClaudeCodeを起動します。

---

# Tmux Worker Management

このスキルは、リーダーペインから新しいワーカーペインを作成し、ClaudeCodeを起動します。

## 概要

リーダー・ワーカーパターンにおいて、リーダーが新しいワーカーペインを作成し、タスクを委譲する際に使用します。

## 使用タイミング

- タスクをワーカーに委譲したいとき
- 初回セットアップ時（tmuxセッション作成後）
- ワーカーペインを再起動したいとき

## 動作

1. 現在のtmuxウィンドウを垂直分割（右側にペインを作成）
2. 新しいペイン（ワーカーペイン）でプロジェクトディレクトリに移動
3. ClaudeCodeを起動
4. ワーカーペイン番号を環境変数に保存

## 前提条件

- tmux内部でClaudeCodeが起動されていること
- SessionStart Hookによって `$CLAUDE_TMUX_SESSION` と `$CLAUDE_TMUX_PANE` が設定されていること

## 使用方法

```
/tmux-worker
```

スキルを実行すると、以下が自動的に行われます:

1. 右側にワーカーペインを作成
2. ワーカーペインでClaudeCodeを起動
3. ワーカーペイン情報（セッション名、ウィンドウ番号、ペイン番号）を `.claude/worker-info` に保存

## 実行後の作業

スキル実行後、リーダーは以下を行います:

1. **構造化指示を作成**: タスクID、目的、要件、制約、成果物、完了条件を明記
2. **ワーカーに指示を送信**: `/tmux-send` スキルを使用
3. **ワーカーの作業を監視**: 定期的に `/tmux-check` でエラー検知

## 注意事項

- このスキルはリーダーペイン専用です
- ワーカーペインを複数作成する場合は、一つのタスクが完了してから次のワーカーを作成してください
- ワーカーペインを再作成する場合は、先に `tmux kill-pane -t <ペイン番号>` でペインを削除してください

## トラブルシューティング

### ワーカーペインが作成されない

**原因**: tmux外部でClaudeCodeが起動されている

**対処法**:
1. ClaudeCodeを終了
2. tmuxセッションを作成: `tmux new-session -s claude-dev`
3. ClaudeCodeを起動: `claude`
4. `/tmux-worker` スキルを再実行

### ペイン番号がわからない

**対処法**:
```bash
cat .claude/worker-info
```

または

```bash
tmux list-panes
```

## 関連スキル

- `/tmux-send`: ワーカーに構造化指示を送信
- `/tmux-review`: ワーカーの出力を確認し、成果物をレビュー
- `/tmux-check`: ワーカーのエラーを検知

## 詳細ドキュメント

詳細は `.claude/rules/cctmx-team.md` を参照してください。
