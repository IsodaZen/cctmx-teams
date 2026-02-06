# cctmx-teams プロジェクト構造

## 構成方針

Claude Codeプラグイン仕様に準拠し、各コンポーネント（Skills, Commands, Hooks, Templates）を独立したディレクトリで管理する。スクリプトは全て `${CLAUDE_PLUGIN_ROOT}` を起点としたポータブルパスを使用する。

## ディレクトリパターン

| 場所 | 目的 | 例 |
|------|------|-----|
| `.claude-plugin/` | プラグインマニフェスト | `plugin.json` |
| `skills/<skill-name>/` | 各スキルの定義とスクリプト | `SKILL.md`, `scripts/*.sh` |
| `commands/` | スラッシュコマンド定義 | `setup.md` |
| `hooks/` | フック定義とスクリプト | `hooks.json`, `scripts/*.sh` |
| `templates/` | プロジェクトに展開するテンプレート | `cctmx-team.md` |
| `tests/` | 自動テストスクリプト | `run-tests.sh` |
| `.kiro/specs/` | cc-sdd仕様書（機能単位） | `<feature>/requirements.md` 等 |
| `.kiro/steering/` | プロジェクトメモリ | `product.md`, `tech.md` 等 |
| `docs/` | テストガイド・アーカイブ | `TESTING-GUIDE.md` |

## 命名規約

- **スキルディレクトリ**: `tmux-<動詞>` 形式（例: `tmux-worker`, `tmux-send`）
- **シェルスクリプト**: `<動詞>-<名詞>.sh` 形式（例: `create-worker.sh`, `check-errors.sh`）
- **仕様書ディレクトリ**: `.kiro/specs/<feature-name>/` でケバブケースを使用

## コード構成の原則

- 各スキルは `SKILL.md`（トリガー定義）+ `scripts/`（実行ロジック）の2層構造
- スクリプトは全て `set -euo pipefail` で始め、shellcheckに準拠
- ハードコードパスを禁止し、`${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PROJECT_DIR}`, `${SCRATCHPAD_DIR}` を使用
