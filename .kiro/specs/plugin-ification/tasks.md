# Implementation Plan: plugin-ification

## Status: COMPLETED (2026-02-06)

全タスクが完了済み。品質スコア: 100/100、テスト合格率: 29/29 (100%)

## Tasks

- [x] 1. プラグイン基本構造の作成 (P)
  - `.claude-plugin/plugin.json` マニフェスト作成
  - `README.md` 作成（インストール手順、使用方法、トラブルシューティング）
  - `LICENSE`（MIT）作成
  - `.gitignore` 作成
  - _Requirements: 1_

- [x] 2. 基本Skillsの実装とポータブル化
- [x] 2.1 tmux-worker の実装
  - SKILL.md: スクリプトパスを `${CLAUDE_PLUGIN_ROOT}` に変更
  - create-worker.sh: 実行権限付与（755）
  - _Requirements: 2, 3_
- [x] 2.2 tmux-review の実装
  - SKILL.md: スクリプトパスを `${CLAUDE_PLUGIN_ROOT}` に変更
  - review-worker.sh: scratchpadパスを `${SCRATCHPAD_DIR}` に変更、実行権限付与（755）
  - _Requirements: 2, 3_
- [x] 2.3 tmux-check の実装
  - SKILL.md: スクリプトパスを `${CLAUDE_PLUGIN_ROOT}` に変更
  - check-errors.sh: 実行権限付与（755）
  - _Requirements: 2, 3_

- [x] 3. tmux-send スキルの新規実装
  - SKILL.md: トリガーフレーズ定義（"send instruction to worker", "ワーカーに指示を送る", "タスクを送信"）
  - send-instruction.sh: タスクID自動生成（TASK-YYYYMMDD-XXX）、標準入力読み込み、tmux送信
  - 実行権限付与（755）
  - _Requirements: 4_

- [x] 4. setup コマンドの実装
  - commands/setup.md: tmux環境チェック、テンプレートコピー、環境変数確認、完了メッセージ
  - _Requirements: 5_

- [x] 5. SessionStart Hookの実装
  - hooks/hooks.json: Hook定義（matcher: *, timeout: 10）
  - hooks/scripts/session-start.sh: ポータブルパスで実装
  - _Requirements: 6_

- [x] 6. テンプレートの作成
  - templates/cctmx-team.md: リーダー・ワーカーパターンガイドを作成
  - _Requirements: 7_

- [x] 7. 品質チェックと修正
- [x] 7.1 shellcheck静的解析
  - SC1090: 動的source警告 → shellcheckディレクティブ追加（3ファイル）
  - SC2086: 変数クォート → ダブルクォート追加（1ファイル）
  - SC2028: echo → printf変換（5箇所）
  - SC2129: リダイレクトグループ化（1箇所）
- [x] 7.2 スクリプト構文チェック（bash -n）

- [x] 8. テストの実施
- [x] 8.1 自動テストスクリプト作成（tests/run-tests.sh）
  - 構造確認、JSON検証、権限確認、構文チェック、shellcheck、ファイル確認、frontmatter検証、ポータビリティ
- [x] 8.2 自動テスト実行 → 29/29合格 (100%)
- [x] 8.3 テストガイド作成（docs/TESTING-GUIDE.md）

- [x] 9. 最終ドキュメントの整備 (P)
  - CHANGELOG.md: Keep a Changelog形式、v0.1.0の全機能リスト
  - CONTRIBUTING.md: 開発環境セットアップ、コードスタイル、PRプロセス
  - docs/development/README.md: 開発ドキュメントインデックス
