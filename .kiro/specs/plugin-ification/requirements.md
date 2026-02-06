# Requirements Document

## Introduction

cctmx-teamsプラグインのPhase 1（プラグイン化）における要件定義。tmuxベースのリーダー・ワーカーパターンを、再利用可能なClaude Codeプラグインとして実装する。

## Requirements

### Requirement 1: プラグイン構造の作成

**Objective:** 開発者として、tmuxベース多重起動の仕組みを標準的なClaude Codeプラグインとして実装したい。他のプロジェクトでも再利用可能にするために。

#### Acceptance Criteria

1. `.claude-plugin/plugin.json` マニフェストが存在し、name, version, description, author, license, repository, keywords を含むこと
2. Skills, Commands, Hooks, Templates の各ディレクトリが正しい構造で配置されていること
3. `README.md`, `LICENSE`（MIT）, `.gitignore` が含まれていること
4. プラグインバージョンは `0.1.0` であること

### Requirement 2: ポータブルパスの実装

**Objective:** 開発者として、プラグインが任意のプロジェクトで動作するようにしたい。環境に依存しないインストールを可能にするために。

#### Acceptance Criteria

1. 全てのスキル・フックスクリプトが `${CLAUDE_PLUGIN_ROOT}` を使用してプラグインルートを参照すること
2. ハードコードされたパスが一切存在しないこと
3. scratchpadパスは `${SCRATCHPAD_DIR}` 経由でアクセスすること
4. プロジェクト固有データは `${CLAUDE_PROJECT_DIR}/.claude/` 配下に保存すること

### Requirement 3: 基本Skills（3つ）の実装

**Objective:** 開発者として、3つのスキル（tmux-worker, tmux-review, tmux-check）をプラグイン形式で実装したい。ポータブルなスキルとして提供するために。

#### Acceptance Criteria

1. `tmux-worker`: ワーカーペイン作成機能が動作し、`${CLAUDE_PLUGIN_ROOT}` パスを使用すること
2. `tmux-review`: ワーカー出力キャプチャとレビュー機能が動作し、scratchpadパスが `${SCRATCHPAD_DIR}` を使用すること
3. `tmux-check`: エラーパターン検索とタイムアウト検知が動作すること
4. 全スクリプトに実行権限（755）が付与されていること
5. 全スクリプトがshellcheck警告ゼロであること

### Requirement 4: 新規tmux-sendスキルの実装

**Objective:** リーダーAIとして、ワーカーAIに構造化指示を送信したい。明確なフォーマットでタスクを委譲するために。

#### Acceptance Criteria

1. タスクIDが `TASK-YYYYMMDD-XXX` 形式で自動生成されること
2. カウンターファイル（`.claude/.task-counter-YYYYMMDD`）で日付ベースの採番を管理すること
3. 標準入力から指示内容を読み込み、tmux send-keysでワーカーペインに送信すること
4. ワーカーペイン情報（`.claude/worker-info`）が存在しない場合はエラーメッセージを表示すること

### Requirement 5: setupコマンドの実装

**Objective:** 開発者として、プラグインを簡単にプロジェクトに導入したい。ワンコマンドでセットアップを完了するために。

#### Acceptance Criteria

1. tmux環境外で実行された場合はエラーメッセージを表示すること
2. `templates/cctmx-team.md` を `.claude/rules/cctmx-team.md` にコピーすること
3. 環境変数（CLAUDE_ROLE等）の設定状態を確認・表示すること
4. セットアップ完了後、次のステップを案内すること

### Requirement 6: SessionStart Hookの実装

**Objective:** 開発者として、Claude Code起動時にtmux環境を自動判定したい。手動設定なしでリーダー・ワーカーの役割を自動設定するために。

#### Acceptance Criteria

1. tmux環境を検出し、CLAUDE_ROLE, CLAUDE_TMUX_SESSION, CLAUDE_TMUX_PANE を設定すること
2. リーダーペインの場合、ワーカーペインを自動作成すること
3. スクリプトパスが `${CLAUDE_PLUGIN_ROOT}` を使用すること
4. hookのタイムアウトが10秒以内であること

### Requirement 7: テンプレートの作成

**Objective:** 開発者として、リーダー・ワーカーパターンの完全なガイドをプロジェクトに展開したい。setupコマンドで自動配置されるようにするために。

#### Acceptance Criteria

1. `templates/cctmx-team.md` にリーダー・ワーカーパターンのガイドが含まれていること
2. タイトルが適切に変更されていること
3. 未実装機能（Phase 2以降）の記述が削除されていること
