# cctmx-teams プラグイン改善提案

**更新日**: 2026-02-05

## 📊 現在の実装状況

### ✅ 実装済み

- リーダー・ワーカーパターンの完全なドキュメント (CLAUDE.local.md)
- SessionStart Hook による自動環境判定
- ワーカーペイン自動作成機能
- `/tmux-worker` スキル
- `/tmux-review` スキル
- `/tmux-check` スキル
- 構造化指示フォーマット定義
- レビューチェックリスト

## 🚀 改善提案（優先度順）

### **最優先: プラグイン化** ⭐

**現状**: プロジェクト固有の実装
**目標**: 再利用可能なプラグイン

**必要な作業**:
1. プラグイン構造の作成
   - `plugin.json` マニフェスト
   - 適切なディレクトリ構造
   - `.claude-plugin/` ディレクトリ
2. `${CLAUDE_PLUGIN_ROOT}` を使用したポータブル化
   - Hooks スクリプトのパス修正
   - Skills スクリプトのパス修正
3. README.md とインストール手順の追加
4. .gitignore の追加

**成果物**:
```
cctmx-teams/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── tmux-worker/
│   ├── tmux-review/
│   ├── tmux-check/
│   └── tmux-send/
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── session-start-tmux.sh
├── README.md
└── .gitignore
```

---

### **優先度1: 未実装スキルの追加**

#### ✅ `/tmux-review` - ワーカー出力レビュー
**ステータス**: 実装済み（確認中）

**機能**:
- ワーカーペインの出力をキャプチャ
- 一時ファイルに保存
- レビューチェックリストを表示
- 成果物ファイルの自動読み込み

#### ✅ `/tmux-check` - エラー検知
**ステータス**: 実装済み（確認中）

**機能**:
- ワーカーの出力からエラーパターンを検索
- エラー内容、発生箇所、推定原因を分析
- タイムアウト検知（5分以上応答なし）

#### 🔲 `/tmux-send` - 構造化指示送信
**ステータス**: 未実装

**機能**:
- 対話形式で構造化指示を作成
  - AskUserQuestion を使用
  - タスクID、目的、要件、制約、成果物、完了条件を入力
- 入力内容を構造化指示フォーマットに整形
- tmux send-keys で自動送信
- 送信履歴の保存（`.claude/task-history/`）

**実装方針**:
1. SKILL.md でトリガーフレーズを定義
2. scripts/send-instruction.sh でロジックを実装
3. AskUserQuestion で対話形式の入力
4. テンプレートファイルの活用

---

### **優先度2: Commands の追加**

#### 🔲 `/cctmx-teams:setup` - 初期セットアップ
**機能**:
- tmuxセッション作成ガイド
- プロジェクトディレクトリ設定確認
- リーダー・ワーカー構成の構築
- プラグイン動作確認

**実装内容**:
```yaml
---
name: setup
description: Setup tmux environment for Claude Code teams
allowed-tools: [Bash, Read, Write]
---

# Setup Guide
...
```

#### 🔲 `/cctmx-teams:switch-pane` - ペイン切り替え
**機能**:
- リーダー/ワーカーペイン間の簡単切り替え
- 現在のペイン情報表示
- tmux select-pane を使用

#### 🔲 `/cctmx-teams:worker-status` - ワーカー状態確認
**機能**:
- 全ワーカーの状態を表示（ペイン一覧）
- 実行中のタスク確認（最後の出力）
- エラー状態の検知
- ワーカー情報ファイルの読み込み

---

### **優先度3: Hooks の強化**

#### 🔲 PreToolUse Hook - ワーカーの禁止操作検知

**目的**: ワーカーが禁止された操作を実行しようとしたら警告

**検知する操作**:
- Git操作: `git commit`, `git push`, `git merge`, `git rebase`, `git reset`, `git checkout`, `git add`, `git stash apply`, `git cherry-pick`, `git config`
- 管理業務: `EnterPlanMode`, `TaskCreate`, `TaskUpdate`, `TaskGet`, `TaskList`
- ヒアリング: `AskUserQuestion`

**実装方針**:
```json
{
  "PreToolUse": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "prompt",
          "systemPrompt": "If $CLAUDE_ROLE is 'worker', check if the tool being used is in the forbidden list. If yes, return {\"block\": true, \"blockMessage\": \"⚠️ ワーカーは [tool] を実行できません。リーダーの承認が必要です。\"}"
        }
      ]
    }
  ]
}
```

#### 🔲 PostToolUse Hook - タスク完了通知

**目的**: ワーカーがタスク完了後、リーダーに自動通知

**実装方針**:
- ワーカーの最後の出力に「完了」「完了しました」などのキーワードを検知
- リーダーペインに通知を送信（tmux display-message）

---

### **優先度4: Agents の追加**

#### 🔲 `task-decomposer` - タスク分解支援

**目的**:
- マネージャーからの指示を受け、実行可能な単位に分解
- 構造化指示フォーマットを自動生成
- 不明点を自動検出してヒアリング項目をリストアップ

**トリガー条件**:
- ユーザーが「タスクを分解して」「ワーカーに指示を作成」などと言及
- リーダーが複雑なタスクを受けたとき

**ツール**:
- Read: CLAUDE.local.md の読み込み
- Write: 構造化指示の一時ファイル作成
- AskUserQuestion: 不明点のヒアリング

**出力形式**:
```
タスクID: TASK-YYYYMMDD-XXX
目的: ...
要件:
- ...
制約:
- ...
成果物:
- ...
完了条件:
- ...
```

#### 🔲 `code-reviewer` - 自動レビュー

**目的**:
- レビューチェックリストを自動適用
- 成果物を分析して問題点を指摘
- 修正指示を自動生成

**トリガー条件**:
- ユーザーが「レビューして」「成果物を確認」などと言及
- `/tmux-review` スキル実行後

**ツール**:
- Read: 成果物ファイル、CLAUDE.local.md
- Bash: ビルドコマンド、テストコマンド
- Grep: エラーパターン検索

**出力形式**:
- チェックリスト結果
- 問題点リスト
- 修正提案

---

### **優先度5: 設定ファイルのサポート**

#### 🔲 `.claude/cctmx-teams.local.md` - プラグイン設定

**設定項目**:
```yaml
---
# tmux設定
tmux_session_name: claude-dev
auto_create_worker: true
worker_count: 1

# エラー検知設定
error_check_interval: 300  # 5分
error_patterns:
  - error
  - エラー
  - 失敗
  - exception
  - fatal

# ログ設定
log_level: info
log_file: /tmp/cctmx-teams.log

# タスク設定
task_id_format: "TASK-YYYYMMDD-XXX"
task_history_dir: .claude/task-history

# レビュー設定
review_checklist: default  # または custom
custom_checklist_path: .claude/custom-review-checklist.md
---

# カスタムタスクテンプレート

タスクID: {task_id}
目的: {purpose}
...
```

**実装方針**:
1. plugin-settings skill を使用
2. Hooks/Skills でこの設定ファイルを読み込み
3. デフォルト値の提供
4. 設定検証機能

---

### **優先度6: セッション管理機能**

#### 🔲 複数ワーカーのサポート

**機能**:
- 複数ワーカーの起動・管理
- タスクキューの実装
- ワーカー間の負荷分散
- ワーカーIDの管理（worker-1, worker-2, ...）

**実装内容**:
1. `/tmux-worker` に `--count` オプション追加
2. ワーカー情報ファイルの拡張
   ```json
   {
     "workers": [
       {"id": "worker-1", "pane": "0.1", "status": "idle", "task": null},
       {"id": "worker-2", "pane": "0.2", "status": "busy", "task": "TASK-20260205-001"}
     ]
   }
   ```
3. タスクキュー管理
4. ワーカーステータス監視

#### 🔲 `/cctmx-teams:worker-list` - ワーカー一覧表示

**機能**:
- すべてのワーカーの状態を一覧表示
- 実行中のタスク
- 最後の活動時刻

---

### **優先度7: ドキュメントとテスト**

#### 🔲 README.md の充実化

**内容**:
1. プラグイン概要
2. インストール方法
   - 手動インストール
   - Marketplace からのインストール（将来）
3. クイックスタート
4. 使用例
   - 基本的なワークフロー
   - スクリーンショット/GIF
5. 設定方法
6. トラブルシューティング
7. FAQ
8. ライセンス

#### 🔲 使用例の追加

**examples/ ディレクトリ**:
- `basic-workflow.md`: 基本的な使用例
- `multi-worker.md`: 複数ワーカーの使用例
- `custom-config.md`: カスタム設定の例
- `integration-with-git.md`: Gitワークフローとの統合

#### 🔲 トラブルシューティングガイド

**troubleshooting.md**:
- よくある問題と解決方法
- デバッグ方法
- ログの確認方法
- サポート情報

#### 🔲 Hook/Skill のテストスクリプト

**tests/ ディレクトリ**:
- `test-hooks.sh`: Hooks の動作確認
- `test-skills.sh`: Skills の動作確認
- `test-session-start.sh`: SessionStart Hook のテスト
- `test-worker-creation.sh`: ワーカーペイン作成のテスト

---

## 📝 実装優先順位まとめ

### Phase 1: プラグイン化（最優先）
- [ ] プラグイン構造作成
- [ ] `plugin.json` マニフェスト
- [ ] `${CLAUDE_PLUGIN_ROOT}` 対応
- [ ] 既存実装の移行と改善
- [ ] README.md 作成

### Phase 2: 基本機能の完成
- [ ] `/tmux-review`, `/tmux-check` の確認と改善
- [ ] `/tmux-send` スキルの実装
- [ ] PreToolUse Hook（ワーカー禁止操作検知）
- [ ] Commands 追加（setup, switch-pane, worker-status）

### Phase 3: 高度な機能
- [ ] Agents 追加（task-decomposer, code-reviewer）
- [ ] 設定ファイルサポート
- [ ] PostToolUse Hook（タスク完了通知）

### Phase 4: スケーリング
- [ ] 複数ワーカーサポート
- [ ] タスクキュー管理
- [ ] ワーカー負荷分散

### Phase 5: ドキュメントとテスト
- [ ] README.md 充実化
- [ ] 使用例追加
- [ ] トラブルシューティングガイド
- [ ] テストスクリプト作成

---

## 🔄 実装状況の追跡

### 完了済み
- ✅ CLAUDE.local.md（ドキュメント）
- ✅ SessionStart Hook
- ✅ `/tmux-worker` スキル

### 進行中
- 🔄 プラグイン化

### 未着手
- ⏳ その他すべての項目

---

## 📌 メモ

### プラグイン名
- 決定: `cctmx-teams`
- フルネーム: Claude Code Tmux Teams

### 既存実装の場所
- `/Users/z-isoda/develop/smart-address-book/git/docker.ksa2.kddi.ne.jp/.claude/`

### プラグイン作成場所
- `/Users/z-isoda/private/cctmx-teams/`

---

## 🤔 検討事項

### 1. Marketplace への公開
- プラグインを Claude Code Marketplace に公開するか？
- ライセンスの選択（MIT推奨）
- バージョニング戦略

### 2. 互換性
- macOS/Linux 対応（Windows は tmux がないため非対応）
- Claude Code のバージョン互換性

### 3. パフォーマンス
- 複数ワーカー実行時のパフォーマンス
- Hook 実行のオーバーヘッド最小化

### 4. セキュリティ
- シェルスクリプトのサニタイゼーション
- 環境変数の適切な管理
- 機密情報の保護

---

## 📚 参考資料

- [Claude Code Plugin Development](https://docs.claude.ai/code/plugins)
- [plugin-dev Plugin](https://github.com/anthropics/claude-code-plugins/tree/main/plugin-dev)
- [tmux Documentation](https://github.com/tmux/tmux/wiki)

---

**最終更新**: 2026-02-05
