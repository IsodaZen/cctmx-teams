# cctmx-teams テストガイド

**作成日**: 2026-02-06
**バージョン**: 0.1.0

このドキュメントは、cctmx-teams プラグインのテスト手順を説明します。

---

## 🎯 テスト目標

1. プラグインが正しくインストールされること
2. すべてのコンポーネントが正常に動作すること
3. エラーハンドリングが適切に機能すること
4. ドキュメントが正確であること

---

## 📋 テスト前提条件

### 必須環境

- ✅ macOS または Linux
- ✅ tmux がインストールされていること
- ✅ Claude Code がインストールされていること
- ✅ Bash 4.0 以上

### 環境確認

```bash
# tmux のバージョン確認
tmux -V
# 期待: tmux 3.x 以上

# Bash のバージョン確認
bash --version
# 期待: GNU bash, version 4.x 以上

# Claude Code の確認
which claude
# 期待: /usr/local/bin/claude または類似パス
```

---

## 🔧 Phase 1: ローカルインストール

### Step 1: プラグインディレクトリにコピー

```bash
# プラグインディレクトリを作成
mkdir -p ~/.claude/plugins

# cctmx-teams をコピー
cp -r /Users/z-isoda/private/cctmx-teams ~/.claude/plugins/

# 確認
ls -la ~/.claude/plugins/cctmx-teams/
```

**期待結果**:
- ✅ `.claude-plugin/plugin.json` が存在
- ✅ `skills/` ディレクトリが存在
- ✅ `commands/` ディレクトリが存在
- ✅ `hooks/` ディレクトリが存在

---

## 🧪 Phase 2: コンポーネント単体テスト

### Test 2-1: plugin.json の検証

```bash
# JSON の構文チェック
cat ~/.claude/plugins/cctmx-teams/.claude-plugin/plugin.json | jq .
```

**期待結果**:
- ✅ エラーなく JSON がパースされる
- ✅ name, version, description フィールドが存在

**結果**: [ ] PASS / [ ] FAIL

---

### Test 2-2: スクリプトの実行権限確認

```bash
# すべてのスクリプトの権限確認
find ~/.claude/plugins/cctmx-teams -name "*.sh" -exec ls -l {} \;
```

**期待結果**:
- ✅ すべてのスクリプトが `-rwxr-xr-x` (実行可能)

**結果**: [ ] PASS / [ ] FAIL

---

### Test 2-3: スクリプトの構文チェック

```bash
# すべてのスクリプトの構文チェック
find ~/.claude/plugins/cctmx-teams -name "*.sh" -exec bash -n {} \;
```

**期待結果**:
- ✅ エラーなし（構文エラーがない）

**結果**: [ ] PASS / [ ] FAIL

---

### Test 2-4: shellcheck による静的解析

```bash
# shellcheck によるチェック
cd ~/.claude/plugins/cctmx-teams
shellcheck skills/*/scripts/*.sh hooks/scripts/*.sh
```

**期待結果**:
- ✅ 警告・エラーなし

**結果**: [ ] PASS / [ ] FAIL

---

## 🚀 Phase 3: 統合テスト（tmux環境）

### Test 3-1: tmux セッション作成

```bash
# 新規tmuxセッションを作成
tmux new-session -s cctmx-test
```

**期待結果**:
- ✅ tmux セッションが起動
- ✅ セッション名が `cctmx-test`

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-2: Claude Code 起動（tmux内）

tmux セッション内で実行:

```bash
# Claude Code を起動
claude --plugin-dir ~/.claude/plugins
```

**期待結果**:
- ✅ Claude Code が起動
- ✅ SessionStart Hook が実行される
- ✅ システムメッセージが表示される:
  ```
  ✅ cctmx-teams: リーダーペインで起動しました
     Session: cctmx-test, Pane: 0.0

  ✅ ワーカーペインを自動作成しました
     Pane: 0.1
  ```
- ✅ ワーカーペインが自動的に作成される（右側）

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-3: 環境変数の確認

リーダーペイン（左側）で実行:

```bash
# 環境変数の確認
echo $CLAUDE_ROLE
# 期待: leader

echo $CLAUDE_TMUX_SESSION
# 期待: cctmx-test

echo $CLAUDE_TMUX_PANE
# 期待: 0.0
```

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-4: `/cctmx-teams:setup` コマンド

リーダーペインで実行:

```
/cctmx-teams:setup
```

**期待結果**:
- ✅ セットアップが実行される
- ✅ `.claude/rules/cctmx-team.md` が作成される
- ✅ 完了メッセージが表示される

**確認**:
```bash
# ルールファイルの確認
ls -la .claude/rules/cctmx-team.md
```

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-5: `/tmux-worker` スキル

リーダーペインで実行:

```
/tmux-worker
```

**期待結果**:
- ✅ エラーが表示される（既にワーカーペインが存在する場合）
  - または、新しいワーカーペインが作成される

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-6: `/tmux-check` スキル

リーダーペインで実行:

```
/tmux-check
```

**期待結果**:
- ✅ ワーカーの出力がチェックされる
- ✅ 「エラーは検出されませんでした」が表示される（正常時）

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-7: `/tmux-review` スキル

リーダーペインで実行:

```
/tmux-review
```

**期待結果**:
- ✅ ワーカーの出力がキャプチャされる
- ✅ 出力が表示される
- ✅ レビューチェックリストが表示される

**結果**: [ ] PASS / [ ] FAIL

---

### Test 3-8: `/tmux-send` スキル

リーダーペインで実行:

```bash
# 構造化指示をワーカーに送信
echo "目的: テスト用のファイル作成

要件:
- test.txt ファイルを作成
- 内容: Hello from worker

成果物:
- test.txt

完了条件:
- ファイルが存在する" | bash ~/.claude/plugins/cctmx-teams/skills/tmux-send/scripts/send-instruction.sh
```

**期待結果**:
- ✅ タスクIDが自動生成される（例: TASK-20260206-001）
- ✅ ワーカーペインに指示が送信される
- ✅ 「✅ 指示を送信しました」が表示される

**ワーカーペインで確認**:
- ✅ 送信された指示が表示される

**結果**: [ ] PASS / [ ] FAIL

---

## 🔍 Phase 4: エラーハンドリングテスト

### Test 4-1: tmux 外での起動

通常のターミナル（tmux外）で実行:

```bash
# tmux外でClaude Code起動
claude --plugin-dir ~/.claude/plugins
```

**期待結果**:
- ✅ システムメッセージが表示される:
  ```
  ⚠️ cctmx-teams: Claude Codeはtmux外部で起動されました。

  tmuxセッション内で起動することを推奨します:
    tmux new-session -s claude-dev
    claude
  ```
- ✅ Claude Code は正常に起動する（エラーにならない）

**結果**: [ ] PASS / [ ] FAIL

---

### Test 4-2: ワーカーペイン情報がない場合

リーダーペインで、ワーカー情報ファイルを削除してテスト:

```bash
# ワーカー情報を削除
rm .claude/worker-info

# /tmux-review を実行
/tmux-review
```

**期待結果**:
- ✅ エラーメッセージが表示される:
  ```
  ❌ エラー: ワーカーペイン情報が見つかりません
  /tmux-worker スキルを先に実行してください
  ```

**結果**: [ ] PASS / [ ] FAIL

---

### Test 4-3: 存在しないワーカーペインへのアクセス

ワーカーペインを削除してからテスト:

```bash
# ワーカーペインを削除（tmuxコマンド）
tmux kill-pane -t cctmx-test:0.1

# /tmux-check を実行
/tmux-check
```

**期待結果**:
- ✅ エラーメッセージが表示される:
  ```
  ❌ エラー: ワーカーペインの出力を取得できませんでした
  ```

**結果**: [ ] PASS / [ ] FAIL

---

## 📚 Phase 5: ドキュメント検証

### Test 5-1: README.md の確認

```bash
# README.md を表示
cat ~/.claude/plugins/cctmx-teams/README.md
```

**確認項目**:
- [ ] 概要が明確
- [ ] インストール手順が正確
- [ ] 使用方法が説明されている
- [ ] スキル一覧が正確
- [ ] トラブルシューティングが含まれている

**結果**: [ ] PASS / [ ] FAIL

---

### Test 5-2: SKILL.md の確認

各スキルの SKILL.md を確認:

```bash
# tmux-worker
cat ~/.claude/plugins/cctmx-teams/skills/tmux-worker/SKILL.md

# tmux-send
cat ~/.claude/plugins/cctmx-teams/skills/tmux-send/SKILL.md

# tmux-review
cat ~/.claude/plugins/cctmx-teams/skills/tmux-review/SKILL.md

# tmux-check
cat ~/.claude/plugins/cctmx-teams/skills/tmux-check/SKILL.md
```

**確認項目**:
- [ ] description にトリガーフレーズが含まれている
- [ ] 使用方法が説明されている
- [ ] トラブルシューティングが含まれている
- [ ] ${CLAUDE_PLUGIN_ROOT} が使用されている

**結果**: [ ] PASS / [ ] FAIL

---

### Test 5-3: setup.md の確認

```bash
cat ~/.claude/plugins/cctmx-teams/commands/setup.md
```

**確認項目**:
- [ ] frontmatter が正しい
- [ ] allowed-tools が定義されている
- [ ] 実装指示が明確

**結果**: [ ] PASS / [ ] FAIL

---

## 🎯 Phase 6: 実践的なワークフローテスト

### Test 6-1: 完全なワークフローの実行

以下の手順を順番に実行:

1. **tmux セッションを作成**
   ```bash
   tmux new-session -s cctmx-workflow-test
   ```

2. **Claude Code を起動**
   ```bash
   claude --plugin-dir ~/.claude/plugins
   ```

3. **セットアップを実行**
   ```
   /cctmx-teams:setup
   ```

4. **ワーカーに簡単なタスクを送信**
   ```
   # リーダーペインで実行
   /tmux-send

   # プロンプトに以下を入力:
   目的: test.txt ファイルを作成

   要件:
   - ファイル名: test.txt
   - 内容: "Hello from cctmx-teams"

   成果物:
   - test.txt

   完了条件:
   - ファイルが作成されていること
   ```

5. **ワーカーの作業を確認**
   - ワーカーペイン（右側）を確認
   - タスクが表示されているか確認

6. **エラーチェック**
   ```
   /tmux-check
   ```

7. **レビュー実行**
   ```
   /tmux-review
   ```

8. **成果物の確認**
   ```bash
   cat test.txt
   # 期待: "Hello from cctmx-teams"
   ```

**期待結果**:
- ✅ すべてのステップがエラーなく実行される
- ✅ ワーカーがタスクを完了する
- ✅ 成果物が正しく作成される

**結果**: [ ] PASS / [ ] FAIL

---

## 📊 テスト結果サマリー

### Phase 1: ローカルインストール
- [ ] Test 1: インストール確認

### Phase 2: コンポーネント単体テスト
- [ ] Test 2-1: plugin.json 検証
- [ ] Test 2-2: 実行権限確認
- [ ] Test 2-3: 構文チェック
- [ ] Test 2-4: shellcheck 検証

### Phase 3: 統合テスト
- [ ] Test 3-1: tmux セッション作成
- [ ] Test 3-2: Claude Code 起動
- [ ] Test 3-3: 環境変数確認
- [ ] Test 3-4: setup コマンド
- [ ] Test 3-5: tmux-worker スキル
- [ ] Test 3-6: tmux-check スキル
- [ ] Test 3-7: tmux-review スキル
- [ ] Test 3-8: tmux-send スキル

### Phase 4: エラーハンドリング
- [ ] Test 4-1: tmux外での起動
- [ ] Test 4-2: ワーカー情報なし
- [ ] Test 4-3: 存在しないペイン

### Phase 5: ドキュメント検証
- [ ] Test 5-1: README.md
- [ ] Test 5-2: SKILL.md
- [ ] Test 5-3: setup.md

### Phase 6: 実践的ワークフロー
- [ ] Test 6-1: 完全なワークフロー

---

## 🐛 問題が見つかった場合

### バグレポートテンプレート

```markdown
## バグレポート

**テスト番号**: Test X-Y

**期待される動作**:
<期待される動作を記述>

**実際の動作**:
<実際の動作を記述>

**再現手順**:
1. <ステップ1>
2. <ステップ2>
3. <ステップ3>

**環境情報**:
- OS: <macOS/Linux>
- tmux バージョン: <バージョン>
- Claude Code バージョン: <バージョン>

**ログ・エラーメッセージ**:
```
<ログやエラーメッセージを貼り付け>
```

**スクリーンショット**:
<可能であれば添付>
```

---

## ✅ テスト完了後

すべてのテストが PASS した場合:

1. テスト結果をドキュメント化
2. Phase 8 (Documentation & Next Steps) に進む
3. GitHub リポジトリへの公開を検討

---

**テストガイド作成日**: 2026-02-06
**バージョン**: 0.1.0
