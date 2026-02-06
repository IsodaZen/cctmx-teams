# Research & Design Decisions

---
**Purpose**: Phase 1（プラグイン化）における調査結果と設計判断の記録
**Usage**: design.md の背景情報として参照
---

## Summary

- **Feature**: `plugin-ification`
- **Discovery Scope**: Extension（既存実装をプラグイン構造に適合させる拡張）
- **Discovery Type**: Light Discovery
- **Key Findings**:
  - Claude Codeプラグインは `.claude-plugin/plugin.json` をマニフェストとする標準構造を持つ
  - `${CLAUDE_PLUGIN_ROOT}` 変数でポータブルなパス参照が可能
  - 全スクリプトで環境変数ベースのパス参照を徹底する必要がある
  - session-start.sh は全エラーで exit 0 を返し、セッション開始をブロックしない設計

## Research Log

### Claude Codeプラグイン仕様の調査

- **Context**: tmuxベースのリーダー・ワーカーパターンをClaude Codeプラグインとして実装するための仕様調査
- **Sources Consulted**:
  - [Claude Code Plugin Development](https://docs.claude.ai/code/plugins)
  - [plugin-dev Plugin](https://github.com/anthropics/claude-code-plugins/tree/main/plugin-dev)
- **Findings**:
  - プラグインは Skills, Commands, Hooks, Templates, Agents の5種類のコンポーネントを持てる
  - `plugin.json` にメタデータ（name, version, description, author, license等）を定義
  - スクリプトパスは `${CLAUDE_PLUGIN_ROOT}` で参照可能
  - Hookは `hooks.json` で定義し、SessionStart等のイベントに紐づけ
  - Hookのtimeout設定は hooks.json 内で指定（本プラグインは10秒）
- **Implications**: 4スキル + 1フックの構成はプラグイン仕様に直接マッピング可能

### パス設計の調査

- **Context**: プラグインスクリプトで使用するパス参照方式の調査
- **Sources Consulted**: Claude Code Plugin公式ドキュメント
- **Findings**:
  - プラグイン内スクリプトは `${CLAUDE_PLUGIN_ROOT}` で参照する
  - 一時ファイルは `${SCRATCHPAD_DIR}` を使用する
  - プロジェクト固有データは `${CLAUDE_PROJECT_DIR}/.claude/` 配下に保存する
  - worker-info ファイル: `${CLAUDE_PROJECT_DIR}/.claude/worker-info` に保存（プロジェクト固有情報のため適切）
  - 環境変数永続化は `CLAUDE_ENV_FILE` に追記する方式
- **Implications**: scratchpadパスは `${SCRATCHPAD_DIR}`、スクリプトパスは `${CLAUDE_PLUGIN_ROOT}` で統一する

### タスクID設計の検討

- **Context**: tmux-sendスキルでのタスク追跡方式の設計
- **Sources Consulted**: 構造化指示フォーマットの設計検討
- **Findings**:
  - `TASK-YYYYMMDD-XXX` 形式が明確で衝突しにくい
  - カウンターファイルは日付単位でリセットが自然
  - タスク履歴の永続化は過剰（ワーカー出力で追跡可能）
- **Implications**: シンプルなカウンターファイル方式を採用し、履歴保存は見送り

### 既存実装の構造分析

- **Context**: 設計ドキュメント生成時の既存コードベース分析
- **Sources Consulted**: プロジェクト内の全スクリプト、設定ファイル
- **Findings**:
  - 全スクリプトが `set -euo pipefail` を使用（steering準拠）
  - 環境変数は3層構造: フレームワーク層 → Hook層 → スキル層
  - ファイルベースの状態共有: worker-info（Shell export形式）、task-counter（整数テキスト）
  - session-start.sh のロール判定: ペイン番号0 = leader、それ以外 = worker
  - エラーメッセージは日本語で標準エラー出力へ
  - テスト: 29/29合格（構造、JSON、権限、構文、shellcheck、ポータビリティ）
- **Implications**: 既存実装は設計仕様に完全準拠。design.mdは実装を正確に反映。

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| プラグイン形式 | Claude Code標準プラグインとして実装 | ポータブル、再利用可能、エコシステム統合 | プラグイン仕様への依存 | 採用 |
| スタンドアロンスクリプト | 独立したシェルスクリプト集 | シンプル、依存なし | 手動セットアップ必須、ポータブル性低 | 不採用 |

## Design Decisions

### Decision: パスのポータブル化方式

- **Context**: プラグインスクリプトのパス参照方式を決定する必要がある
- **Alternatives Considered**:
  1. 相対パス — スクリプトからの相対パスで参照
  2. 環境変数 — `${CLAUDE_PLUGIN_ROOT}` 等の環境変数で参照
- **Selected Approach**: 環境変数方式（`${CLAUDE_PLUGIN_ROOT}`, `${SCRATCHPAD_DIR}`, `${CLAUDE_PROJECT_DIR}`）
- **Rationale**: Claude Codeが自動的に環境変数を設定するため、プラグイン開発者は意識せずポータブルなコードが書ける
- **Trade-offs**: Claude Code環境外では動作しないが、プラグインとしては当然の制約
- **Follow-up**: 新規スクリプト作成時は必ず環境変数を使用するルールを明文化

### Decision: タスク履歴の非保存

- **Context**: tmux-sendスキルで送信したタスクの履歴をどう扱うか
- **Alternatives Considered**:
  1. `.claude/task-history/` に全履歴を保存
  2. ワーカー出力で追跡（履歴ファイルなし）
- **Selected Approach**: ワーカー出力で追跡（履歴ファイルなし）
- **Rationale**: Phase 1はシンプルさを優先。履歴保存はPhase 2以降で検討
- **Trade-offs**: 過去タスクの参照が困難だが、初期リリースの複雑性を低減
- **Follow-up**: Phase 2で設定ファイルサポートと合わせて再検討

### Decision: shellcheckディレクティブの使用

- **Context**: 動的sourceのSC1090警告への対応方針
- **Alternatives Considered**:
  1. sourceを避けて直接ファイル読み込み
  2. shellcheckディレクティブで抑制
- **Selected Approach**: shellcheckディレクティブ（`# shellcheck source=/dev/null`）で抑制
- **Rationale**: worker-infoファイルの動的読み込みは設計上必要であり、ディレクティブで明示的に意図を示す
- **Trade-offs**: 実行時のsource先の検証はスクリプト内で自前で行う必要がある
- **Follow-up**: worker-info読み込み前の存在チェックを必ず実装

### Decision: SessionStart Hookのエラーハンドリング方式

- **Context**: session-start.sh でエラーが発生した場合の挙動
- **Alternatives Considered**:
  1. エラー時に exit 1 でセッション開始をブロック
  2. 全エラーで exit 0 を返しセッション開始を継続
- **Selected Approach**: 全エラーで exit 0（セッション開始をブロックしない）
- **Rationale**: tmux環境外でも Claude Code を正常に使用できるべき。Hookの失敗がセッション全体を止めるのは過剰
- **Trade-offs**: 設定エラーがサイレントに無視される可能性。警告メッセージで緩和。
- **Follow-up**: デバッグログ（`/tmp/cctmx-teams-hook-session-start.log`）で問題追跡可能

## Risks & Mitigations

- tmux環境外での実行 — SessionStart Hookで検出し警告メッセージ表示、exit 0で続行
- ワーカーペイン情報の破損 — 各スクリプトで読み込み前に存在チェックとバリデーション
- Claude Code環境変数の未設定 — デフォルト値のフォールバックとエラーメッセージ
- Hookタイムアウト — 10秒以内で完了する設計、重い処理を含めない

## References

- [Claude Code Plugin Development](https://docs.claude.ai/code/plugins) — プラグイン仕様の公式ドキュメント
- [plugin-dev Plugin](https://github.com/anthropics/claude-code-plugins/tree/main/plugin-dev) — プラグイン開発支援ツール
- [tmux Documentation](https://github.com/tmux/tmux/wiki) — tmuxのペイン・セッション管理
- [ShellCheck](https://www.shellcheck.net/) — シェルスクリプト静的解析ツール
