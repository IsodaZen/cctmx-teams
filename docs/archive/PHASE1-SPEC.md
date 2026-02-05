# Phase 1: プラグイン化 - 詳細仕様

**作成日**: 2026-02-05
**ステータス**: 仕様確定 → 実装開始

---

## 📋 実装内容サマリー

### 基本情報
- **プラグイン名**: `cctmx-teams`
- **バージョン**: `0.1.0`
- **ライセンス**: MIT
- **作者**: IsodaZen (25547781+IsodaZen@users.noreply.github.com)

### 実装対象
- ✅ Skills: 4つ（3つ移行 + 1つ新規）
- ✅ Commands: 1つ（新規）
- ✅ Hooks: 1つ（移行）
- ✅ Templates: 1つ（移行）
- ❌ Agents: Phase 2以降
- ❌ PreToolUse Hook: Phase 2以降
- ❌ 設定ファイル: Phase 2以降

---

## 🎯 Phase 1 の目標

1. **既存実装のプラグイン化**
   - プロジェクト固有の実装を再利用可能なプラグインに変換
   - `${CLAUDE_PLUGIN_ROOT}` を使用したポータブル化

2. **基本機能の完成**
   - リーダー・ワーカーパターンの動作確認
   - セットアップコマンドによる簡単導入

3. **最小限の機能でリリース**
   - 過剰な機能追加を避け、コア機能に集中
   - Phase 2での拡張に備えた設計

---

## 📁 プラグイン構造

```
cctmx-teams/
├── .claude-plugin/
│   └── plugin.json                    # マニフェスト
├── skills/
│   ├── tmux-worker/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── create-worker.sh
│   ├── tmux-review/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── review-worker.sh
│   ├── tmux-check/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── check-errors.sh
│   └── tmux-send/                     # 🆕 新規
│       ├── SKILL.md
│       └── scripts/
│           └── send-instruction.sh
├── commands/
│   └── setup.md                       # 🆕 新規
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── session-start.sh           # 移行
├── templates/
│   └── cctmx-team.md                  # CLAUDE.local.md から移行
├── README.md                          # 🆕 新規
├── LICENSE                            # MIT
└── .gitignore
```

---

## 📦 コンポーネント詳細仕様

### 1. plugin.json

```json
{
  "name": "cctmx-teams",
  "version": "0.1.0",
  "description": "Tmux-based multi-instance Claude Code management plugin for team development patterns",
  "author": {
    "name": "IsodaZen",
    "email": "25547781+IsodaZen@users.noreply.github.com"
  },
  "license": "MIT",
  "repository": "https://github.com/IsodaZen/cctmx-teams",
  "keywords": ["tmux", "team", "multi-instance", "workflow", "leader-worker"]
}
```

---

### 2. Skills

#### 2-1. tmux-worker（移行 + 改善）

**既存**: `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/.claude/skills/tmux-worker/`

**改善点**:
1. `${CLAUDE_PROJECT_DIR}` → `${CLAUDE_PLUGIN_ROOT}` に変更
2. スクリプトパスを相対パス化
3. ワーカー情報保存先を `${CLAUDE_PROJECT_DIR}/.claude/worker-info` に統一

**SKILL.md の変更**:
```markdown
bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-worker/scripts/create-worker.sh
```

**create-worker.sh の主な変更**:
```bash
# 変更前
worker_info_file="${CLAUDE_PROJECT_DIR}/.claude/worker-info"

# 変更後（変更なし、プロジェクト固有情報なので）
worker_info_file="${CLAUDE_PROJECT_DIR}/.claude/worker-info"
```

---

#### 2-2. tmux-review（移行 + 改善）

**既存**: `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/.claude/skills/tmux-review/`

**改善点**:
1. ハードコードされた scratchpad パスを `${SCRATCHPAD_DIR}` に変更
2. スクリプトパスを相対パス化

**SKILL.md の変更**:
```markdown
bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-review/scripts/review-worker.sh
```

**review-worker.sh の主な変更**:
```bash
# 変更前（36行目）
output_file="/private/tmp/claude-1689378477/-Users-z-isoda-develop-smart-address-book-git-docker-ksa2-kddi-ne-jp/d3ec01f9-4f00-4596-9ad6-d19212773429/scratchpad/worker-output-$(date +%s).txt"

# 変更後
output_file="${SCRATCHPAD_DIR}/worker-output-$(date +%s).txt"
```

---

#### 2-3. tmux-check（移行 + 改善）

**既存**: `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/.claude/skills/tmux-check/`

**改善点**:
1. スクリプトパスを相対パス化

**SKILL.md の変更**:
```markdown
bash ${CLAUDE_PLUGIN_ROOT}/skills/tmux-check/scripts/check-errors.sh
```

**check-errors.sh の変更**:
- パスのポータブル化のみ（既存ロジックは維持）

---

#### 2-4. tmux-send（🆕 新規実装）

**目的**: リーダー（AI）がワーカー（AI）に構造化指示を送信

**トリガーフレーズ**:
- "send instruction to worker"
- "ワーカーに指示を送る"
- "タスクを送信"

**SKILL.md**:
```markdown
---
name: Tmux Send Instruction
description: This skill should be used when the leader wants to "send instruction to worker", "ワーカーに指示を送る", "タスクを送信". Sends structured task instruction to worker pane.
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

リーダー（AI）は以下のフォーマットで指示を準備し、このスキルを実行します：

```
タスクID: TASK-20260205-001
目的: ユーザープロフィール表示コンポーネントの作成

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
- ビルドが成功する
```

## 注意事項

- タスクIDは自動生成されます
- タスク履歴は保存されません（ワーカーの出力で追跡）
- 構造化指示フォーマットに従ってください
```

**send-instruction.sh の仕様**:

```bash
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
source "$worker_info_file"

if [ -z "${CLAUDE_WORKER_PANE:-}" ] || [ -z "${CLAUDE_WORKER_SESSION:-}" ]; then
  echo "❌ エラー: ワーカーペイン情報が不正です" >&2
  exit 1
fi

session="${CLAUDE_WORKER_SESSION}"
worker_pane="${CLAUDE_WORKER_PANE}"

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
echo "構造化指示を入力してください（Ctrl+D で終了）:" >&2
instruction=$(cat)

# タスクIDを先頭に追加
full_instruction="タスクID: ${task_id}
${instruction}"

# ワーカーに送信
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
```

**特記事項**:
- タスクIDは日付ベースで自動採番（`TASK-YYYYMMDD-XXX`）
- カウンターファイルは `.claude/.task-counter-YYYYMMDD` に保存
- タスク履歴は保存しない（設計決定）
- 標準入力から指示内容を読み込み（AI が echo などで渡す）

---

### 3. Commands

#### 3-1. setup（🆕 新規実装）

**コマンド名**: `/cctmx-teams:setup`

**目的**:
1. tmux環境のチェック
2. `templates/cctmx-team.md` を `.claude/rules/cctmx-team.md` にコピー
3. プラグイン動作確認

**setup.md の仕様**:

```markdown
---
name: setup
description: Setup cctmx-teams plugin for the current project
allowed-tools: [Bash, Read, Write]
argument-hint: (no arguments required)
---

# cctmx-teams セットアップ

このコマンドは、cctmx-teams プラグインを現在のプロジェクトに導入します。

## 実行内容

1. **tmux環境チェック**: tmux内で実行されているか確認
2. **ルールファイルのコピー**: `templates/cctmx-team.md` を `.claude/rules/cctmx-team.md` にコピー
3. **環境変数の確認**: SessionStart Hook が正しく動作しているか確認
4. **セットアップ完了メッセージ**: 次のステップを案内

## 実行手順

### 1. tmux環境チェック

```bash
if [ -z "${TMUX:-}" ]; then
  echo "❌ エラー: tmux内でClaudeCodeを起動してください"
  exit 1
fi
```

### 2. ディレクトリ作成

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/rules"
```

### 3. テンプレートファイルのコピー

```bash
template_file="${CLAUDE_PLUGIN_ROOT}/templates/cctmx-team.md"
target_file="${CLAUDE_PROJECT_DIR}/.claude/rules/cctmx-team.md"

if [ -f "$target_file" ]; then
  echo "⚠️ 警告: .claude/rules/cctmx-team.md は既に存在します"
  echo "上書きしますか？ (y/N)"
  read -r answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "セットアップをキャンセルしました"
    exit 0
  fi
fi

cp "$template_file" "$target_file"
echo "✅ ルールファイルをコピーしました: ${target_file}"
```

### 4. 環境変数の確認

```bash
if [ -n "${CLAUDE_ROLE:-}" ]; then
  echo "✅ 環境変数が設定されています"
  echo "   CLAUDE_ROLE: ${CLAUDE_ROLE}"
  echo "   CLAUDE_TMUX_SESSION: ${CLAUDE_TMUX_SESSION:-<未設定>}"
  echo "   CLAUDE_TMUX_PANE: ${CLAUDE_TMUX_PANE:-<未設定>}"
else
  echo "⚠️ 警告: CLAUDE_ROLE が設定されていません"
  echo "ClaudeCodeを再起動してください"
fi
```

### 5. 完了メッセージ

```markdown
✅ cctmx-teams のセットアップが完了しました！

## 次のステップ

1. **ClaudeCodeを再起動** (SessionStart Hookを有効化)
   ```bash
   exit
   claude
   ```

2. **ワーカーペインの作成** (SessionStart Hookで自動作成されます)
   - 自動作成されない場合: `/tmux-worker` を実行

3. **使用可能なスキル**:
   - `/tmux-worker`: ワーカーペインを作成
   - `/tmux-review`: ワーカーの出力をレビュー
   - `/tmux-check`: ワーカーのエラーを検知
   - `/tmux-send`: ワーカーに構造化指示を送信

## 詳細ドキュメント

`.claude/rules/cctmx-team.md` を参照してください。
```

## 注意事項

- このコマンドはリーダーペインで実行してください
- tmux外で実行するとエラーになります
- ワーカーペインは自動作成されません（SessionStart Hookに任せる）
```

---

### 4. Hooks

#### 4-1. SessionStart Hook（移行 + 改善）

**既存**: `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/.claude/hooks/`

**hooks.json の仕様**:

```json
{
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-start.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

**session-start.sh の主な変更**:
- `${CLAUDE_PROJECT_DIR}/.claude/hooks/scripts/session-start-tmux.sh` → `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-start.sh`
- ファイル名を `session-start.sh` に変更（tmux は冗長）
- ロジックは既存を維持

---

### 5. Templates

#### 5-1. cctmx-team.md（移行）

**既存**: `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/CLAUDE.local.md`

**配置先**: `templates/cctmx-team.md`

**変更点**:
- タイトルを「tmuxを使ったClaudeCode多重起動開発ガイド」に変更
- Phase 2, Phase 3 の記述を削除（まだ実装されていないため）
- `/cctmx-teams:setup` コマンドでコピーされることを明記

---

### 6. Documentation

#### 6-1. README.md（🆕 新規）

**内容**:

```markdown
# cctmx-teams

Tmux-based multi-instance Claude Code management plugin for team development patterns.

## 概要

**cctmx-teams** は、tmux環境でClaude Codeを複数起動し、リーダー・ワーカーパターンで効率的に開発するためのClaude Codeプラグインです。

### 主な機能

- **リーダー・ワーカーパターン**: 指示・レビューを行うリーダーと、実装を行うワーカーに役割を分離
- **自動環境判定**: SessionStart Hookで自動的にtmux環境を判定・設定
- **構造化指示**: 明確なフォーマットでタスクを委譲
- **レビュー機能**: ワーカーの成果物を批判的にレビュー
- **エラー検知**: ワーカーのエラーを早期検知

## インストール

### 前提条件

- tmux がインストールされていること
- Claude Code がインストールされていること
- macOS または Linux

### 手動インストール

```bash
# 1. プラグインディレクトリを作成
mkdir -p ~/.claude/plugins

# 2. このリポジトリをクローン
cd ~/.claude/plugins
git clone https://github.com/IsodaZen/cctmx-teams.git

# 3. tmuxセッションを作成
tmux new-session -s claude-dev

# 4. Claude Codeを起動
claude

# 5. セットアップコマンドを実行
/cctmx-teams:setup
```

## 使用方法

### クイックスタート

1. **tmuxセッション内でClaude Codeを起動**
   ```bash
   tmux new-session -s claude-dev
   claude
   ```

2. **セットアップコマンドを実行**
   ```
   /cctmx-teams:setup
   ```

3. **Claude Codeを再起動** (SessionStart Hookを有効化)
   ```bash
   exit
   claude
   ```

4. **ワーカーペインが自動作成される**
   - リーダー（左ペイン）: 指示・レビュー担当
   - ワーカー（右ペイン）: 実装担当

### 基本的なワークフロー

1. **マネージャー（人間）がリーダーにタスクを依頼**
   ```
   「ユーザープロフィール表示機能を追加してほしい」
   ```

2. **リーダーがタスクを分解**
   - 不明点をヒアリング
   - 構造化指示を作成

3. **リーダーがワーカーに指示を送信**
   ```
   /tmux-send
   ```

4. **ワーカーが作業実行**
   - コード実装
   - テスト
   - ビルド確認

5. **リーダーがレビュー**
   ```
   /tmux-review
   ```

6. **エラーチェック**
   ```
   /tmux-check
   ```

7. **マネージャーに報告**

## スキル一覧

- **`/tmux-worker`**: ワーカーペインを作成
- **`/tmux-review`**: ワーカーの出力をレビュー
- **`/tmux-check`**: ワーカーのエラーを検知
- **`/tmux-send`**: ワーカーに構造化指示を送信

## コマンド一覧

- **`/cctmx-teams:setup`**: プラグインのセットアップ

## 詳細ドキュメント

プロジェクトに導入後、`.claude/rules/cctmx-team.md` に完全なガイドが生成されます。

## トラブルシューティング

### ワーカーペインが作成されない

**原因**: tmux外でClaude Codeが起動されている

**対処法**:
1. Claude Codeを終了
2. tmuxセッションを作成: `tmux new-session -s claude-dev`
3. Claude Codeを起動: `claude`

### SessionStart Hookが動作しない

**原因**: Hook設定が読み込まれていない

**対処法**:
1. `/cctmx-teams:setup` を実行
2. Claude Codeを再起動

## ライセンス

MIT License

## 作者

IsodaZen (25547781+IsodaZen@users.noreply.github.com)

## リポジトリ

https://github.com/IsodaZen/cctmx-teams
```

---

#### 6-2. LICENSE（🆕 新規）

```
MIT License

Copyright (c) 2026 IsodaZen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

#### 6-3. .gitignore（🆕 新規）

```
# Claude Code settings
.claude/*.local.md
.claude/*.local.json
.claude/worker-info
.claude/.task-counter-*

# Logs
*.log

# macOS
.DS_Store

# Editor
.vscode/
.idea/
```

---

## 🔧 実装手順

### Step 1: プラグイン構造の作成
1. ディレクトリ作成
2. plugin.json作成
3. README.md作成
4. LICENSE作成
5. .gitignore作成

### Step 2: 既存Skills の移行
1. tmux-worker の移行 + パスのポータブル化
2. tmux-review の移行 + パスのポータブル化
3. tmux-check の移行 + パスのポータブル化

### Step 3: 新規Skills の実装
1. tmux-send の実装

### Step 4: Commands の実装
1. setup コマンドの実装

### Step 5: Hooks の移行
1. SessionStart Hook の移行
2. hooks.json の作成

### Step 6: Templates の移行
1. CLAUDE.local.md → templates/cctmx-team.md

### Step 7: テストと検証
1. ローカルでのテスト
2. 動作確認
3. ドキュメントの最終確認

---

## ✅ 完了基準

- [ ] すべてのファイルが正しい場所に配置されている
- [ ] `${CLAUDE_PLUGIN_ROOT}` が正しく使用されている
- [ ] ハードコードされたパスが存在しない
- [ ] `/cctmx-teams:setup` コマンドが動作する
- [ ] SessionStart Hook が動作する
- [ ] すべてのスキルが動作する
- [ ] README.md が完成している
- [ ] LICENSE が含まれている

---

## 📌 Phase 2 以降の TODO

- PreToolUse Hook の実装
- 設定ファイルのサポート
- `/cctmx-teams:switch-pane` コマンド
- `/cctmx-teams:worker-status` コマンド
- Agents の追加（task-decomposer, code-reviewer）
- 複数ワーカーのサポート
- スクリプトの共通化（scripts/lib/common.sh）
- エラーハンドリングの強化

---

**次のステップ**: Phase 4（実装）に進む
