#!/bin/bash
set -euo pipefail

# cctmx-teams 自動テストスクリプト
# このスクリプトは、tmux環境を必要としないテストを実行します

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_RESULTS_DIR="${PLUGIN_DIR}/test-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${TEST_RESULTS_DIR}/test-report-${TIMESTAMP}.txt"

# カラー出力
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# テスト結果カウンター
PASSED=0
FAILED=0
TOTAL=0

# ディレクトリ作成
mkdir -p "$TEST_RESULTS_DIR"

# ログ関数
log() {
  echo "$1" | tee -a "$REPORT_FILE"
}

log_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1" | tee -a "$REPORT_FILE"
  PASSED=$((PASSED + 1))
  TOTAL=$((TOTAL + 1))
}

log_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1" | tee -a "$REPORT_FILE"
  FAILED=$((FAILED + 1))
  TOTAL=$((TOTAL + 1))
}

log_info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1" | tee -a "$REPORT_FILE"
}

# テスト開始
log "================================================"
log "cctmx-teams 自動テスト"
log "開始時刻: $(date)"
log "================================================"
log ""

# Test 1: プラグイン構造の確認
log "Test 1: プラグイン構造の確認"
log "----------------------------------------"

if [ -f "${PLUGIN_DIR}/.claude-plugin/plugin.json" ]; then
  log_pass "plugin.json が存在"
else
  log_fail "plugin.json が存在しない"
fi

if [ -d "${PLUGIN_DIR}/skills" ]; then
  log_pass "skills/ ディレクトリが存在"
else
  log_fail "skills/ ディレクトリが存在しない"
fi

if [ -d "${PLUGIN_DIR}/commands" ]; then
  log_pass "commands/ ディレクトリが存在"
else
  log_fail "commands/ ディレクトリが存在しない"
fi

if [ -d "${PLUGIN_DIR}/hooks" ]; then
  log_pass "hooks/ ディレクトリが存在"
else
  log_fail "hooks/ ディレクトリが存在しない"
fi

log ""

# Test 2: plugin.json の検証
log "Test 2: plugin.json の検証"
log "----------------------------------------"

if command -v jq &> /dev/null; then
  if jq . "${PLUGIN_DIR}/.claude-plugin/plugin.json" > /dev/null 2>&1; then
    log_pass "plugin.json は有効なJSON"
  else
    log_fail "plugin.json のJSON構文が無効"
  fi

  # 必須フィールドの確認
  name=$(jq -r '.name' "${PLUGIN_DIR}/.claude-plugin/plugin.json")
  if [ "$name" = "cctmx-teams" ]; then
    log_pass "name フィールドが正しい: ${name}"
  else
    log_fail "name フィールドが不正: ${name}"
  fi

  version=$(jq -r '.version' "${PLUGIN_DIR}/.claude-plugin/plugin.json")
  if [ "$version" = "0.1.0" ]; then
    log_pass "version フィールドが正しい: ${version}"
  else
    log_fail "version フィールドが不正: ${version}"
  fi
else
  log_info "jq が未インストール、JSON検証をスキップ"
fi

log ""

# Test 3: スクリプトの実行権限確認
log "Test 3: スクリプトの実行権限確認"
log "----------------------------------------"

script_count=0
executable_count=0

while IFS= read -r script; do
  script_count=$((script_count + 1))
  if [ -x "$script" ]; then
    executable_count=$((executable_count + 1))
  else
    log_fail "実行権限なし: ${script}"
  fi
done < <(find "${PLUGIN_DIR}" -name "*.sh")

if [ $script_count -eq $executable_count ]; then
  log_pass "すべてのスクリプトに実行権限あり (${executable_count}/${script_count})"
else
  log_fail "実行権限のないスクリプトあり (${executable_count}/${script_count})"
fi

log ""

# Test 4: Bash構文チェック
log "Test 4: Bash構文チェック"
log "----------------------------------------"

syntax_errors=0

while IFS= read -r script; do
  if bash -n "$script" 2>/dev/null; then
    : # 構文OK
  else
    log_fail "構文エラー: ${script}"
    syntax_errors=$((syntax_errors + 1))
  fi
done < <(find "${PLUGIN_DIR}" -name "*.sh")

if [ $syntax_errors -eq 0 ]; then
  log_pass "すべてのスクリプトの構文が正しい"
else
  log_fail "構文エラーのあるスクリプトが ${syntax_errors} 件"
fi

log ""

# Test 5: shellcheck による静的解析
log "Test 5: shellcheck による静的解析"
log "----------------------------------------"

if command -v shellcheck &> /dev/null; then
  if shellcheck skills/*/scripts/*.sh hooks/scripts/*.sh 2>&1 | tee -a "$REPORT_FILE" | grep -q .; then
    log_fail "shellcheck で警告またはエラーが検出された"
  else
    log_pass "shellcheck で警告・エラーなし"
  fi
else
  log_info "shellcheck が未インストール、静的解析をスキップ"
fi

log ""

# Test 6: 必須ファイルの存在確認
log "Test 6: 必須ファイルの存在確認"
log "----------------------------------------"

required_files=(
  ".claude-plugin/plugin.json"
  "README.md"
  "LICENSE"
  ".gitignore"
  "skills/tmux-worker/SKILL.md"
  "skills/tmux-worker/scripts/create-worker.sh"
  "skills/tmux-send/SKILL.md"
  "skills/tmux-send/scripts/send-instruction.sh"
  "skills/tmux-review/SKILL.md"
  "skills/tmux-review/scripts/review-worker.sh"
  "skills/tmux-check/SKILL.md"
  "skills/tmux-check/scripts/check-errors.sh"
  "commands/setup.md"
  "hooks/hooks.json"
  "hooks/scripts/session-start.sh"
  "templates/cctmx-team.md"
)

for file in "${required_files[@]}"; do
  if [ -f "${PLUGIN_DIR}/${file}" ]; then
    : # ファイル存在、ログは詳細表示しない
  else
    log_fail "必須ファイルが存在しない: ${file}"
  fi
done

log_pass "すべての必須ファイルが存在"

log ""

# Test 7: Skill frontmatter の検証
log "Test 7: Skill frontmatter の検証"
log "----------------------------------------"

skill_errors=0

for skill_md in "${PLUGIN_DIR}"/skills/*/SKILL.md; do
  skill_name=$(basename "$(dirname "$skill_md")")

  # frontmatter の存在確認
  if grep -q "^---$" "$skill_md"; then
    : # frontmatter 存在
  else
    log_fail "${skill_name}: frontmatter が存在しない"
    skill_errors=$((skill_errors + 1))
    continue
  fi

  # name フィールドの確認
  if grep -q "^name:" "$skill_md"; then
    : # name フィールド存在
  else
    log_fail "${skill_name}: name フィールドが存在しない"
    skill_errors=$((skill_errors + 1))
  fi

  # description フィールドの確認
  if grep -q "^description:" "$skill_md"; then
    : # description フィールド存在
  else
    log_fail "${skill_name}: description フィールドが存在しない"
    skill_errors=$((skill_errors + 1))
  fi
done

if [ $skill_errors -eq 0 ]; then
  log_pass "すべての Skill の frontmatter が正しい"
else
  log_fail "Skill の frontmatter エラーが ${skill_errors} 件"
fi

log ""

# Test 8: ${CLAUDE_PLUGIN_ROOT} の使用確認
log "Test 8: \${CLAUDE_PLUGIN_ROOT} の使用確認"
log "----------------------------------------"

plugin_root_missing=0

for skill_md in "${PLUGIN_DIR}"/skills/*/SKILL.md; do
  skill_name=$(basename "$(dirname "$skill_md")")

  if grep -q "\${CLAUDE_PLUGIN_ROOT}" "$skill_md"; then
    : # ${CLAUDE_PLUGIN_ROOT} 使用
  else
    log_fail "${skill_name}: \${CLAUDE_PLUGIN_ROOT} を使用していない"
    plugin_root_missing=$((plugin_root_missing + 1))
  fi
done

if [ $plugin_root_missing -eq 0 ]; then
  log_pass "すべての Skill で \${CLAUDE_PLUGIN_ROOT} を使用"
else
  log_fail "\${CLAUDE_PLUGIN_ROOT} を使用していない Skill が ${plugin_root_missing} 件"
fi

log ""

# Test 9: hooks.json の検証
log "Test 9: hooks.json の検証"
log "----------------------------------------"

if [ -f "${PLUGIN_DIR}/hooks/hooks.json" ]; then
  if command -v jq &> /dev/null; then
    if jq . "${PLUGIN_DIR}/hooks/hooks.json" > /dev/null 2>&1; then
      log_pass "hooks.json は有効なJSON"
    else
      log_fail "hooks.json のJSON構文が無効"
    fi

    # SessionStart の確認
    if jq -e '.hooks.SessionStart // .SessionStart' "${PLUGIN_DIR}/hooks/hooks.json" > /dev/null 2>&1; then
      log_pass "SessionStart フックが定義されている"
    else
      log_fail "SessionStart フックが定義されていない"
    fi
  else
    log_info "jq が未インストール、hooks.json検証をスキップ"
  fi
else
  log_fail "hooks.json が存在しない"
fi

log ""

# Test 10: ドキュメントの確認
log "Test 10: ドキュメントの確認"
log "----------------------------------------"

if [ -f "${PLUGIN_DIR}/README.md" ]; then
  readme_lines=$(wc -l < "${PLUGIN_DIR}/README.md")
  if [ "$readme_lines" -gt 50 ]; then
    log_pass "README.md が十分な内容を含んでいる (${readme_lines} 行)"
  else
    log_fail "README.md の内容が不足している (${readme_lines} 行)"
  fi
else
  log_fail "README.md が存在しない"
fi

log ""

# テスト結果サマリー
log "================================================"
log "テスト結果サマリー"
log "================================================"
log "合計: ${TOTAL} テスト"
log "成功: ${GREEN}${PASSED}${NC} テスト"
log "失敗: ${RED}${FAILED}${NC} テスト"
log ""

if [ $FAILED -eq 0 ]; then
  log "✅ すべてのテストが成功しました！"
  log ""
  log "次のステップ:"
  log "1. tmux環境での統合テストを実施してください"
  log "2. TESTING-GUIDE.md の Phase 3 以降を実行してください"
  exit_code=0
else
  log "❌ いくつかのテストが失敗しました"
  log ""
  log "失敗したテストを確認し、修正してください"
  exit_code=1
fi

log ""
log "詳細レポート: ${REPORT_FILE}"
log "完了時刻: $(date)"
log "================================================"

exit $exit_code
