# Implementation Plan

## Tasks

- [ ] 1. (P) プラグインマニフェストと基本ファイルの作成
  - plugin.jsonにプラグインメタデータ（name, version, description, author, license, repository, keywords）を定義
  - SemVer形式のバージョン番号（0.1.0）を設定し、リポジトリURLを記載
  - LICENSEファイル（MIT）を作成
  - _Requirements: 1.1, 8.8, 9.1, 9.2_

- [ ] 2. スキルの実装
- [ ] 2.1 (P) tmux-workerスキルの実装
  - 新しいワーカーペインをtmux split-windowで作成し、worker-infoファイルにペイン情報（セッション名、ペイン番号）を保存する機能を実装
  - tmux環境変数の検証、ワーカーペインでのプロジェクトディレクトリ移動とClaude起動
  - SKILL.mdにスキル定義（使用タイミング、動作説明、前提条件、トラブルシューティング）を記載
  - 全パスを${CLAUDE_PLUGIN_ROOT}と${CLAUDE_PROJECT_DIR}ベースで記述
  - _Requirements: 1.2, 2.1, 2.6, 6.1, 6.2, 6.3, 8.9_

- [ ] 2.2 (P) tmux-sendスキルの実装
  - TASK-YYYYMMDD-XXX形式のタスクIDを自動生成し、標準入力から受け取った構造化指示をワーカーペインに送信する機能を実装
  - worker-info読み込みと検証（未存在時はエラーメッセージを表示し/tmux-workerの実行を促す）
  - 日付ベースのカウンター管理（翌日リセット、古いカウンターファイルの自動削除）
  - tmux load-buffer + paste-bufferによる指示テキスト送信とsend-keys Enterによる実行
  - SKILL.mdにトリガーフレーズとスキル定義を記載
  - _Requirements: 1.2, 2.2, 2.3, 2.6, 6.1, 6.2, 6.3, 8.9_

- [ ] 2.3 (P) tmux-reviewスキルの実装
  - ワーカーペインの出力を過去3000行キャプチャし、レビューチェックリスト（共通/機能追加/バグ修正/リファクタリング）とともに表示する機能を実装
  - worker-info読み込みと検証（未存在時はエラーメッセージを表示し/tmux-workerの実行を促す）
  - キャプチャ内容を${SCRATCHPAD_DIR}に一時保存
  - SKILL.mdにスキル定義を記載
  - _Requirements: 1.2, 2.3, 2.4, 2.6, 6.1, 6.2, 6.3, 8.9_

- [ ] 2.4 (P) tmux-checkスキルの実装
  - ワーカーペインの出力からエラーパターン（Error, エラー, 失敗, Exception, Fatal）を検索し、検出結果を表示する機能を実装
  - worker-info読み込みと検証（未存在時はエラーメッセージを表示し/tmux-workerの実行を促す）
  - エラー検出時はexit 1とエラー詳細表示、エラーなし時はexit 0と正常メッセージ表示
  - SKILL.mdにスキル定義を記載
  - _Requirements: 1.2, 2.3, 2.5, 2.6, 6.1, 6.2, 6.3, 8.9_

- [ ] 3. (P) setupコマンドの実装
  - テンプレートをプロジェクトのrulesディレクトリにコピーし、初期設定を行うコマンドを実装
  - tmux環境チェック、既存ファイルの上書き確認ダイアログ
  - .gitignoreに状態ファイルパターン（.claude/worker-info, .claude/.task-counter-*）を追記（未登録の場合のみ）
  - SessionStart Hook動作確認（CLAUDE_ROLE環境変数チェック）
  - 完了メッセージと次のステップ（tmuxセッション内でのClaude Code起動推奨、使用可能なスキル一覧）を表示
  - _Requirements: 1.3, 3.1, 3.2, 3.3, 3.4_

- [ ] 4. (P) SessionStart Hookの実装
  - セッション開始時にtmux環境を自動判定し、リーダー/ワーカーの役割を設定するフックを実装
  - hooks.jsonでフック定義（matcher: *, timeout: 10秒）
  - CLAUDE_ENV_FILEの存在確認（未定義時は警告して正常終了）
  - ペイン番号によるロール判定（ペイン0 = leader、それ以外 = worker）
  - リーダーかつペイン数1の場合のみワーカーペインを自動作成
  - tmux環境外では警告メッセージと推奨セッション名を表示し正常終了
  - 全パスを${CLAUDE_PLUGIN_ROOT}ベースで記述
  - _Requirements: 1.4, 4.1, 4.2, 4.3, 4.4, 4.5, 6.1, 6.2, 6.3_

- [ ] 5. (P) テンプレートの作成
  - リーダー・ワーカーパターンの運用ガイドテンプレートを作成
  - リーダーの責務（タスク分解・委譲・レビュー）とワーカーの責務（実装）を明確に定義
  - 禁止事項（ユーザーが直接ワーカーに指示、指示系統の崩壊につながる行動）をAIが強く認識する形式（見出し・箇条書き・強調表示）で記述
  - 構造化指示フォーマットとtmuxコマンドリファレンスを含む
  - _Requirements: 1.5, 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 6. テストスイートの実装と品質検証
- [ ] 6.1 自動テストスクリプトの実装
  - 構造テスト（ディレクトリ・ファイル存在確認）
  - JSON検証テスト（plugin.json, hooks.jsonの構文妥当性）
  - 権限テスト（全.shスクリプトの実行権限確認）
  - 構文テスト（bash -nによる全スクリプトのチェック）
  - shellcheckテスト（利用可能時のみ全スクリプトの静的解析）
  - 必須ファイル存在確認、SKILL.mdフロントマター検証
  - ポータビリティテスト（ハードコードパス不在確認）
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ] 6.2 全テスト合格の確認とshellcheck修正
  - テストスイート実行による全テスト合格の確認
  - shellcheck警告の修正（SC1090, SC2086, SC2028, SC2129等）
  - bash -nによる構文チェック合格確認
  - _Requirements: 7.1_

- [ ] 7. READMEとCHANGELOGの作成
- [ ] 7.1 (P) READMEの作成
  - インストール手順（GitHubリポジトリからのクローン、Claude Codeへのプラグイン登録、/setup実行）
  - 前提条件（tmux 3.x+, bash 4.x+, Claude Code）
  - 各スキル（tmux-worker, tmux-send, tmux-review, tmux-check）の概要と基本的な使用方法
  - トラブルシューティング（tmux環境外での実行、ワーカーペイン情報の欠如、SessionStart Hook未実行）
  - アンインストール手順（.claude/rules/cctmx-team.md、.claude/worker-info、プラグインディレクトリの削除）
  - FAQ（リーダー・ワーカーパターンの説明、複数ワーカーの制限、タスクID形式の意味）
  - 設定ファイルの詳細説明（.claude/worker-info, .claude/.task-counter-YYYYMMDDの役割と形式）
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 7.2 (P) CHANGELOGの作成
  - Keep a Changelog形式でv0.1.0の変更履歴を記載
  - 各バージョンの日付、変更種別（Added, Changed, Fixed, Removed）を明記
  - リリースプロセス（plugin.jsonバージョン更新、CHANGELOG追記、vX.Y.Z形式Gitタグ）を文書化
  - mainブランチの安定版管理方針とブランチ戦略を記載
  - _Requirements: 9.3, 9.4, 9.5, 9.6, 9.7_
