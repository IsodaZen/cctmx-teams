---
name: setup
description: Setup cctmx-teams plugin for the current project
allowed-tools: [Bash, Read, Write]
argument-hint: (no arguments required)
---

# cctmx-teams セットアップ

このコマンドは、cctmx-teams プラグインを現在のプロジェクトに導入します。

## 実行内容

1. **tmux環境チェック**: tmux内で実行されているか確認
2. **ルールファイルのコピー**: `templates/cctmx-team.md` を `.claude/rules/cctmx-team.md` にコピー
3. **環境変数の確認**: SessionStart Hook が正しく動作しているか確認
4. **セットアップ完了メッセージ**: 次のステップを案内

---

## 実装指示

以下の手順でセットアップを実行してください：

### 1. tmux環境チェック

```bash
if [ -z "${TMUX:-}" ]; then
  echo "❌ エラー: tmux内でClaude Codeを起動してください"
  echo ""
  echo "セットアップ手順:"
  echo "1. tmuxセッションを作成: tmux new-session -s claude-dev"
  echo "2. Claude Codeを起動: claude"
  echo "3. このコマンドを再実行: /cctmx-teams:setup"
  exit 1
fi
```

### 2. ディレクトリ作成

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/rules"
```

### 3. テンプレートファイルのコピー

```bash
template_file="${CLAUDE_PLUGIN_ROOT}/templates/cctmx-team.md"
target_file="${CLAUDE_PROJECT_DIR}/.claude/rules/cctmx-team.md"

# ファイルが既に存在する場合の確認
if [ -f "$target_file" ]; then
  echo "⚠️ 警告: .claude/rules/cctmx-team.md は既に存在します"
  echo ""
  read -p "上書きしますか？ (y/N): " answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "セットアップをキャンセルしました"
    exit 0
  fi
fi

# テンプレートをコピー
cp "$template_file" "$target_file"
echo "✅ ルールファイルをコピーしました: ${target_file}"
```

### 4. 環境変数の確認

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "環境変数の確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "${CLAUDE_ROLE:-}" ]; then
  echo "✅ SessionStart Hookが正常に動作しています"
  echo ""
  echo "  CLAUDE_ROLE: ${CLAUDE_ROLE}"
  echo "  CLAUDE_TMUX_SESSION: ${CLAUDE_TMUX_SESSION:-<未設定>}"
  echo "  CLAUDE_TMUX_PANE: ${CLAUDE_TMUX_PANE:-<未設定>}"
else
  echo "⚠️ 警告: SessionStart Hookがまだ実行されていません"
  echo ""
  echo "Claude Codeを再起動することで、SessionStart Hookが実行されます。"
fi
```

### 5. 完了メッセージ

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ cctmx-teams のセットアップが完了しました！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "## 次のステップ"
echo ""
echo "1. **Claude Codeを再起動** (SessionStart Hookを有効化)"
echo "   \`\`\`bash"
echo "   exit"
echo "   claude"
echo "   \`\`\`"
echo ""
echo "2. **ワーカーペインの確認**"
echo "   - SessionStart Hookで自動作成されます"
echo "   - 手動で作成する場合: /tmux-worker"
echo ""
echo "3. **使用可能なスキル**:"
echo "   - /tmux-worker: ワーカーペインを作成"
echo "   - /tmux-send: ワーカーに構造化指示を送信"
echo "   - /tmux-review: ワーカーの出力をレビュー"
echo "   - /tmux-check: ワーカーのエラーを検知"
echo ""
echo "## 詳細ドキュメント"
echo ""
echo ".claude/rules/cctmx-team.md を参照してください。"
echo ""
```

---

## 注意事項

- このコマンドはリーダーペインで実行してください
- tmux外で実行するとエラーになります
- ワーカーペインはSessionStart Hookで自動作成されます

## トラブルシューティング

### tmux外で実行してエラーが出る

**対処法**:
1. Claude Codeを終了
2. tmuxセッションを作成: `tmux new-session -s claude-dev`
3. Claude Codeを起動: `claude`
4. セットアップコマンドを再実行: `/cctmx-teams:setup`

### ルールファイルが反映されない

**原因**: Claude Codeが.claude/rules/を読み込んでいない

**対処法**:
1. Claude Codeを再起動
2. `.claude/rules/cctmx-team.md` が正しく配置されているか確認
