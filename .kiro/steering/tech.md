# cctmx-teams 技術スタック

## アーキテクチャ

Claude Codeプラグインとして動作し、tmuxのセッション・ペイン管理機能を活用してAIインスタンス間の通信と役割分離を実現する。フック・スキル・コマンドの3層で構成される。

## コア技術

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Bash | 4.x+ | 全スクリプトの実行基盤 |
| tmux | 3.x+ | セッション・ペイン管理、AI間通信 |
| Claude Code | - | プラグインホスト環境 |

## 主要ライブラリ・ツール

- **shellcheck**: シェルスクリプト静的解析
- **jq**: JSON検証（plugin.json等）

## 開発標準

### コード品質

- 全スクリプトに `set -euo pipefail` を適用
- 変数は必ずダブルクォートで囲む（SC2086準拠）
- `echo` ではなく `printf` でエスケープシーケンスを処理（SC2028準拠）
- shellcheck警告ゼロを維持

### テスト

- `tests/run-tests.sh` で自動テスト（構造、JSON、権限、構文、shellcheck、ポータビリティ）
- tmux環境での手動テストは `docs/TESTING-GUIDE.md` に従う

## 開発環境

- **必須ツール**: tmux, bash, Claude Code
- **推奨ツール**: shellcheck, jq
- **テスト実行**: `bash tests/run-tests.sh`

## 主要な技術判断

- タスク履歴はファイルに保存しない（ワーカー出力で追跡する方針）
- カウンターファイル（`.task-counter-YYYYMMDD`）は日付ベースで自動リセット
- `source` で動的にワーカー情報を読み込む設計（SC1090対応済み）
