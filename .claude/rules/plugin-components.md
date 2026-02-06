---
paths:
  - "skills/**/*"
  - "commands/**/*"
  - "hooks/**/*"
---

# プラグインコンポーネント 構造ガイド

このドキュメントは、cctmx-teamsプラグインのスキル、コマンド、フックの構造ルールを定義します。

## スキル

### SKILL.md構造

```markdown
---
name: スキル名
description: トリガーフレーズを含む明確な説明
version: X.Y.Z
---

# 実行指示

${CLAUDE_PLUGIN_ROOT}を使用したBashスクリプト実行指示

---

# スキル名

詳細なドキュメント...
```

### 要件

- **name**: スキルの一意な名前
- **description**: トリガーフレーズを含む明確な説明（ユーザーが何を言ったときにこのスキルが呼ばれるべきか）
- **version**: セマンティックバージョニング（X.Y.Z）
- **実行指示**: Claudeがどのようにスクリプトを実行すべきか
- **ドキュメント**: ユーザー向けの詳細な説明
- **${CLAUDE_PLUGIN_ROOT}**: ポータビリティのため、パスには必ずこれを使用
- **トラブルシューティング**: よくある問題と解決方法を含める
- **使用例**: 具体的な使用例を提供

## コマンド

### コマンド構造

```markdown
---
name: コマンド名
description: 簡潔な説明
allowed-tools: [Bash, Read, Write]
argument-hint: (ユーザー向けヒント)
---

# コマンド名

Claudeへの実装指示...
```

### 要件

- **name**: コマンドの一意な名前（スラッシュコマンドとして使用: `/command-name`）
- **description**: コマンドの簡潔な説明（1行）
- **allowed-tools**: Claudeが使用できるツールのリスト
- **argument-hint**: コマンド引数のヒント（オプション）
- **実装指示**: Claudeがコマンドをどのように実装すべきか
- **エラーハンドリング**: エラー処理のガイダンス
- **トラブルシューティング**: よくある問題と解決方法

## フック

### フック構造（hooks.json）

```json
{
  "hooks": [
    {
      "event": "PreToolUse",
      "prompt": "${CLAUDE_PLUGIN_ROOT}/hooks/prompts/example.md",
      "timeout": 5000,
      "systemMessage": "情報的なメッセージ"
    }
  ]
}
```

### 要件

- **event**: フックイベント名（PreToolUse, PostToolUse, Stop など）
- **prompt**: プロンプトファイルへのパス（`${CLAUDE_PLUGIN_ROOT}` を使用）
- **timeout**: タイムアウト時間（ミリ秒）
- **systemMessage**: ユーザーに表示される情報メッセージ
- **エラーハンドリング**: すべてのエラーケースを適切に処理
- **環境対応**: tmux環境と非tmux環境の両方で動作すること

### プロンプトファイル構造

```markdown
# フック名

フックの説明

## 実行指示

Claudeへの指示...
```

## 共通ルール

### ポータビリティ

- すべてのパス参照に `${CLAUDE_PLUGIN_ROOT}` を使用
- ハードコードされたパスは使用しない

### ドキュメント

- すべてのコンポーネントに明確なドキュメントを提供
- トラブルシューティングセクションを含める
- 使用例を提供

### テスト

- 新しいコンポーネントには対応するテストを追加
- `tests/run-tests.sh` を更新
- `TESTING-GUIDE.md` に手動テストケースを追加

### バージョニング

- セマンティックバージョニングを使用
- 変更時は `CHANGELOG.md` を更新
