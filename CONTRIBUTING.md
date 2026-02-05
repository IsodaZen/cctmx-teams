# Contributing to cctmx-teams

Thank you for your interest in contributing to cctmx-teams! This document provides guidelines for contributing to the project.

---

## 🎯 Project Overview

cctmx-teams is a Claude Code plugin that enables multi-instance Claude Code management in tmux environments using the leader-worker pattern.

**Goals:**

- Efficient task delegation between leader and worker instances
- Clear role separation for better code review
- Automation through hooks and skills
- High code quality and security

---

## 🚀 Getting Started

### Prerequisites

- macOS or Linux
- tmux 3.x or higher
- Claude Code
- Bash 4.0 or higher
- shellcheck (for development)

### Development Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/IsodaZen/cctmx-teams.git
   cd cctmx-teams
   ```

2. **Install development tools**

   ```bash
   # Install shellcheck
   brew install shellcheck

   # Install jq (for JSON validation)
   brew install jq
   ```

3. **Run tests**

   ```bash
   bash tests/run-tests.sh
   ```

4. **Test locally**

   ```bash
   # Link to Claude plugins directory
   ln -s $(pwd) ~/.claude/plugins/cctmx-teams

   # Start tmux and test
   tmux new-session -s cctmx-dev
   claude
   ```

---

## 📝 Development Guidelines

### Code Style

#### Shell Scripts

- Use `#!/bin/bash` shebang
- Always use `set -euo pipefail` for strict mode
- Quote all variables: `"${variable}"`
- Use meaningful variable names
- Add comments for complex logic
- Pass shellcheck validation with no warnings

**Example:**

```bash
#!/bin/bash
set -euo pipefail

# Function description
function_name() {
  local variable="${1}"

  if [ -z "${variable:-}" ]; then
    echo "Error message" >&2
    return 1
  fi

  # More logic here
}
```

#### Markdown

- Use ATX-style headers (`#` not `===`)
- Keep lines under 120 characters where possible
- Use fenced code blocks with language specified
- Include blank lines before and after code blocks

### Skills

**SKILL.md Structure:**

```markdown
---
name: Skill Name
description: Clear description with trigger phrases like "when to use", "トリガーフレーズ"
version: X.Y.Z
---

# 実行指示

Bash script execution instructions using ${CLAUDE_PLUGIN_ROOT}

---

# Skill Name

Detailed documentation...
```

**Requirements:**

- Clear trigger phrases in description
- Use `${CLAUDE_PLUGIN_ROOT}` for portability
- Include troubleshooting section
- Provide usage examples

### Commands

**Command Structure:**

```markdown
---
name: command-name
description: Brief description
allowed-tools: [Bash, Read, Write]
argument-hint: (hint for users)
---

# Command Name

Implementation instructions for Claude...
```

**Requirements:**

- Clear implementation instructions
- Specify allowed-tools
- Include error handling guidance
- Provide troubleshooting tips

### Hooks

**Requirements:**

- Use `${CLAUDE_PLUGIN_ROOT}` for script paths
- Include timeout
- Provide informative systemMessage
- Handle all error cases gracefully
- Test both tmux and non-tmux environments

---

## 🧪 Testing

### Running Tests

```bash
# Run automated tests
bash tests/run-tests.sh

# Run shellcheck
shellcheck skills/*/scripts/*.sh hooks/scripts/*.sh

# Validate JSON
jq . .claude-plugin/plugin.json
jq . hooks/hooks.json
```

### Manual Testing

Follow the comprehensive guide in `TESTING-GUIDE.md`:

1. Plugin structure tests
2. Component unit tests
3. Integration tests (tmux environment)
4. Error handling tests
5. Documentation validation
6. End-to-end workflow test

### Writing New Tests

When adding new features, update:

- `tests/run-tests.sh` - Add automated tests
- `TESTING-GUIDE.md` - Add manual test cases

---

## 🔧 Submitting Changes

### Before Submitting

1. **Run all tests**

   ```bash
   bash tests/run-tests.sh
   shellcheck skills/*/scripts/*.sh hooks/scripts/*.sh
   ```

2. **Update documentation**
   - Update README.md if adding user-facing features
   - Update CHANGELOG.md with your changes
   - Add/update comments in code

3. **Check code quality**
   - No shellcheck warnings
   - Proper error handling
   - Clear variable names
   - Comments for complex logic

### Pull Request Process

1. **Fork the repository**

   ```bash
   # Fork on GitHub, then clone
   git clone https://github.com/YOUR-USERNAME/cctmx-teams.git
   cd cctmx-teams
   git remote add upstream https://github.com/IsodaZen/cctmx-teams.git
   ```

2. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make your changes**
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation

4. **Commit your changes**

   ```bash
   git add .
   git commit -m "feat: add new feature"
   # or
   git commit -m "fix: resolve issue with worker detection"
   ```

   **Commit message format:**
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `test:` Test additions/changes
   - `refactor:` Code refactoring
   - `chore:` Maintenance tasks

5. **Push to your fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Go to GitHub and create a PR
   - Fill out the PR template
   - Link related issues
   - Request review

### PR Checklist

- [ ] Tests pass (`bash tests/run-tests.sh`)
- [ ] shellcheck validation passes
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow convention
- [ ] PR description is clear and complete

---

## 🐛 Reporting Issues

### Before Reporting

1. Check [existing issues](https://github.com/IsodaZen/cctmx-teams/issues)
2. Test with latest version
3. Gather necessary information

### Issue Template

```markdown
## Bug Report

**Description:**
Brief description of the issue

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Environment:**
- OS: macOS/Linux
- tmux version: X.Y.Z
- Claude Code version: X.Y.Z
- cctmx-teams version: X.Y.Z

**Logs/Errors:**
```

Paste logs or error messages

```

**Screenshots:**
If applicable, add screenshots
```

---

## 💡 Feature Requests

We welcome feature requests! Please:

1. Check if already requested
2. Clearly describe the feature
3. Explain the use case
4. Provide examples if possible

**Template:**

```markdown
## Feature Request

**Feature Description:**
Clear description of the proposed feature

**Use Case:**
Why is this feature needed?

**Proposed Implementation:**
Ideas for how it could be implemented (optional)

**Alternatives Considered:**
Other approaches you've thought about
```

---

## 📚 Documentation

### Areas to Document

- User-facing features in README.md
- Technical details in code comments
- Development process in docs/
- Testing procedures in TESTING-GUIDE.md
- API changes in CHANGELOG.md

### Documentation Style

- Use clear, concise language
- Provide examples
- Include troubleshooting tips
- Keep line length reasonable
- Use proper markdown formatting

---

## 🏗️ Architecture

### Plugin Structure

```
cctmx-teams/
├── .claude-plugin/     # Plugin manifest
├── skills/             # Skill definitions
├── commands/           # Command definitions
├── hooks/              # Hook configurations and scripts
├── templates/          # Template files
├── tests/              # Test scripts
└── docs/               # Documentation
```

### Key Concepts

1. **Leader-Worker Pattern**: Clear separation of roles
2. **Portability**: Use `${CLAUDE_PLUGIN_ROOT}` for paths
3. **Error Handling**: Graceful degradation
4. **Security**: No hardcoded credentials, safe command execution
5. **Testability**: Comprehensive automated tests

---

## 📞 Communication

- **Issues**: [GitHub Issues](https://github.com/IsodaZen/cctmx-teams/issues)
- **Discussions**: [GitHub Discussions](https://github.com/IsodaZen/cctmx-teams/discussions)
- **Security**: Report security issues privately to the maintainer

---

## 📜 License

By contributing to cctmx-teams, you agree that your contributions will be licensed under the MIT License.

---

## 🙏 Thank You

Thank you for contributing to cctmx-teams! Your contributions help make tmux-based Claude Code development more efficient for everyone.

---

**Questions?** Open an issue or start a discussion on GitHub.
