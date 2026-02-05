---
name: Tmux Send Instruction
description: This skill should be used when the leader wants to "send instruction to worker", "ワーカーに指示を送る", "タスクを送信", "delegate task to worker". Sends structured task instruction to worker pane.
version: 1.0.0
---

# 実行指示

以下のBashスクリプトを実行してください：

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-send/scripts/send-instruction.sh
```

このスクリプトは、リーダーがワーカーに構造化指示を送信します。

---

# Tmux Send Instruction

このスキルは、リーダー（AI）がワーカー（AI）に構造化指示を送信します。

## 概要

リーダーがタスクを分解し、ワーカーに実行指示を送る際に使用します。

## 使用タイミング

- マネージャー（人間）からタスクを受けたとき
- タスクを分解してワーカーに委譲するとき
- ワーカーに修正指示を出すとき

## 動作

1. タスクIDを自動生成（`TASK-YYYYMMDD-XXX` 形式）
2. 標準入力から構造化指示を読み込み
3. tmux send-keys でワーカーペインに送信

## 前提条件

- `/tmux-worker` スキルでワーカーペインが作成されていること
- `.claude/worker-info` にワーカーペイン情報が保存されていること

## 使用方法

リーダー（AI）は以下のように使用します：

```bash
# 構造化指示をechoでパイプして送信
echo "目的: ユーザープロフィール表示コンポーネントの作成

要件:
- ユーザー名、メールアドレス、アバター画像を表示
- プロップスで User 型オブジェクトを受け取る

制約:
- Material-UI コンポーネントを使用
- 既存の User 型定義を変更しない

成果物:
- src/components/UserProfile.tsx

完了条件:
- TypeScript型エラーがない
- ESLintエラーがない
- ビルドが成功する" | bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-send/scripts/send-instruction.sh
```

## 構造化指示フォーマット

以下のフォーマットに従ってください:

```
目的: [このタスクで達成したいこと]

要件:
- [要件1]
- [要件2]
- [要件3]

制約:
- [制約1]
- [制約2]

成果物:
- [成果物1]
- [成果物2]

完了条件:
- [条件1]
- [条件2]
- [条件3]
```

**注意**: タスクIDは自動生成されるため、入力不要です。

## タスクID生成

- 形式: `TASK-YYYYMMDD-XXX`
- 自動採番: 日付ごとに001から開始
- カウンターファイル: `.claude/.task-counter-YYYYMMDD`

## 実行例

```bash
# リーダーAIが実行
echo "目的: ログイン画面のバリデーション追加

要件:
- メールアドレス形式チェック
- パスワード最小8文字チェック

制約:
- 既存のフォームコンポーネントを使用
- react-hook-formを使用

成果物:
- src/pages/Login.tsx の更新

完了条件:
- バリデーションエラーが表示される
- テストが通る" | bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-send/scripts/send-instruction.sh

# 出力例:
# 📤 ワーカーに指示を送信中...
# セッション: claude-dev
# ペイン: 0.1
# タスクID: TASK-20260205-001
#
# ✅ 指示を送信しました
```

## 注意事項

- 構造化指示フォーマットに従ってください
- タスクIDは自動生成されます（手動入力不要）
- タスク履歴は保存されません（ワーカーの出力で追跡）
- 標準入力から指示内容を読み込みます

## トラブルシューティング

### ワーカーペイン情報が見つからない

**原因**: `/tmux-worker` スキルを実行していない

**対処法**:
1. `/tmux-worker` スキルを実行
2. ワーカーペイン情報が `.claude/worker-info` に保存される
3. `/tmux-send` スキルを再実行

### 指示が送信されない

**原因**: 標準入力が空

**対処法**:
- echoまたはヒアドキュメントで指示内容をパイプしてください

## 関連スキル

- `/tmux-worker`: ワーカーペインを作成
- `/tmux-review`: ワーカーの出力を確認し、成果物をレビュー
- `/tmux-check`: ワーカーのエラーを検知

## 詳細ドキュメント

詳細は `.claude/rules/cctmx-team.md` を参照してください。
