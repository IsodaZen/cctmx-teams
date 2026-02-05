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
