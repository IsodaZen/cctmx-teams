# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) へのガイダンスを提供します。

## **IMPORTANT**: AI（Claude）の行動指針

- **不明点は質問する**: 予測や推測で判断せず、不明点がある場合は必ずユーザーに質問してください
- **AskUserQuestionの活用**: ユーザーの意図や選択肢を確認する際は、AskUserQuestionツールを積極的に使用してください
- **ファイルの事前読み込み**: プラグインを修正する前に、必ず既存のファイルを読み込んで内容を理解してください
- **cc-sddワークフローの遵守**: 新機能開発は `/kiro:spec-init` から開始し、仕様を `.kiro/specs/` に記録してください
- **一貫性の維持**: コマンド名、ドキュメント、実装の間で一貫性を保ってください
- **日本語での記述**: すべての出力、ドキュメント、コメントは日本語で記述してください

## プロジェクト概要

**cctmx-teams** は、tmux環境でClaude Codeを複数起動し、リーダー・ワーカーパターンで効率的に開発するためのClaude Codeプラグインです（MIT License）。

### 主な機能

- リーダー・ワーカーパターンによるAI役割分離
- SessionStart Hookによる自動環境判定
- 構造化指示によるタスク委譲（tmux-send）
- ワーカー成果物のレビューとエラー検知

### 開発ワークフロー

本プロジェクトでは **cc-sdd**（仕様駆動開発）を採用しています。

- **仕様書**: `.kiro/specs/<feature>/` 配下（requirements.md, design.md, tasks.md, research.md）
- **プロジェクトメモリ**: `.kiro/steering/`（product.md, structure.md, tech.md）
- **新機能開発**: `/kiro:spec-init` → `/kiro:spec-requirements` → `/kiro:spec-design` → `/kiro:spec-tasks` → `/kiro:spec-impl` の順で実施

### プロジェクト構造

- `skills/` — 4つのスキル（tmux-worker, tmux-send, tmux-review, tmux-check）
- `commands/` — コマンド（setup）
- `hooks/` — フック（SessionStart）
- `templates/` — テンプレート（cctmx-team.md）
- `tests/` — 自動テスト（`bash tests/run-tests.sh`）
- `.kiro/specs/` — cc-sdd仕様書
- `.kiro/steering/` — プロジェクトメモリ
- `docs/` — テストガイド、開発履歴アーカイブ
