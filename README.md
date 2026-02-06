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

- tmux 3.x 以上
- bash 4.x 以上
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

## 開発ワークフロー

本プロジェクトでは [cc-sdd](https://github.com/gotalab/cc-sdd)（仕様駆動開発）を採用しています。

新機能の開発フロー:

```
/kiro:steering              # プロジェクトコンテキストの確認
/kiro:spec-init <機能名>    # 仕様の初期化
/kiro:spec-requirements     # 要件定義
/kiro:spec-design           # 技術設計
/kiro:spec-tasks            # タスク分解
/kiro:spec-impl             # 実装
```

仕様書は `.kiro/specs/<feature>/` 配下で管理されます。

## 詳細ドキュメント

| ドキュメント | 場所 |
|------------|------|
| リーダー・ワーカーガイド | 導入後 `.claude/rules/cctmx-team.md` に配置 |
| テストガイド | `docs/TESTING-GUIDE.md` |
| 機能仕様 | `.kiro/specs/` 配下 |
| プロジェクトメモリ | `.kiro/steering/` 配下 |
| 開発履歴アーカイブ | `docs/archive/` |

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

### ワーカーペイン情報が見つからない

**原因**: `/tmux-worker` を実行せずに `/tmux-send`、`/tmux-review`、`/tmux-check` を実行した

**対処法**:
1. `/tmux-worker` を先に実行してワーカーペインを作成
2. `.claude/worker-info` ファイルが生成されたことを確認

## 設定ファイル

プラグインが使用する設定ファイルの詳細です。

### `.claude/worker-info`

ワーカーペインの接続情報を保持するファイルです。`/tmux-worker` 実行時に自動生成されます。

- **形式**: Shell export文（sourceで読み込み可能）
- **フィールド**:
  - `CLAUDE_WORKER_PANE`: ワーカーペインの識別子（`<window>.<pane>`形式）
  - `CLAUDE_WORKER_SESSION`: tmuxセッション名
- **用途**: `/tmux-send`、`/tmux-review`、`/tmux-check` がワーカーペインを特定するために使用

### `.claude/.task-counter-YYYYMMDD`

タスクIDの採番カウンターファイルです。`/tmux-send` 実行時に自動管理されます。

- **形式**: 整数テキスト（1行）
- **ライフサイクル**: 日付単位で生成、翌日は001からリセット
- **自動クリーンアップ**: 当日以外の古いカウンターファイルは自動削除

## FAQ（よくある質問）

### リーダー・ワーカーパターンとは？

リーダーAIがタスクを分解・委譲し、ワーカーAIが並行実装、リーダーAIがレビューするという人間のチーム開発に近いワークフローをAIで実現するパターンです。

### 複数のワーカーを同時に使用できますか？

現在のバージョン（v0.1.0）では、1リーダー + 1ワーカーの構成のみサポートしています。複数ワーカーサポートは将来のバージョンで予定しています。

### タスクID（TASK-YYYYMMDD-XXX）の形式は何を意味しますか？

`TASK-YYYYMMDD-XXX` は `/tmux-send` で自動生成されるタスク識別子です。`YYYYMMDD` は日付、`XXX` は当日の連番（001から開始、翌日リセット）を表します。

## アンインストール

プラグインを完全に削除するには、以下のファイルとディレクトリを削除してください。

```bash
# 1. プロジェクトに展開されたルールファイルを削除
rm -f .claude/rules/cctmx-team.md

# 2. ワーカーペイン情報を削除
rm -f .claude/worker-info

# 3. タスクカウンターファイルを削除
rm -f .claude/.task-counter-*

# 4. プラグインディレクトリを削除
rm -rf ~/.claude/plugins/cctmx-teams
```

## ライセンス

MIT License

## 作者

IsodaZen (25547781+IsodaZen@users.noreply.github.com)

## リポジトリ

https://github.com/IsodaZen/cctmx-teams
