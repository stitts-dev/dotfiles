# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a dotfiles management system using GNU Stow for symlinking configuration files. The repository contains modular shell configurations (zsh), git settings, and development tool configurations optimized for a macOS development environment with GitHub CLI integration.

## Essential Commands

### Stow Management
- **Apply configurations**: `cd ~/.dotfiles && stow --dir ~/.dotfiles --target ~ .`
- **Update existing symlinks**: `stow --restow .`
- **Remove symlinks**: `stow --delete .`
- **Verify symlinks**: `ls -la ~/.zshrc ~/.gitconfig`

### Shell Configuration
- **Reload zsh**: `source ~/.zshrc` or restart terminal
- **Test zsh syntax**: `zsh -n ~/.zshrc`
- **Check module paths**: `ls -la ~/.config/zsh/`

### Function Testing
- **Test all enhanced functions**: `test_all_functions`
- **Test specific function**: `feature -t "test-name"` (append `-t` flag for test mode)
- **Diagnose function issues**: `fix_function -f FUNCTION_NAME -e "error message"`

## Architecture

### Modular Zsh Configuration Structure

The `.zshrc` file is a lightweight loader that sources modular configuration files:

```
~/.zshrc (loader)
  └─→ ~/.config/zsh/
      ├── env.zsh           # Environment variables (PNPM, ASDF, PATH)
      ├── plugins.zsh       # Oh My Zsh, Powerlevel10k, autosuggestions
      ├── aliases.zsh       # General aliases (file ops, nav, package managers)
      ├── git-aliases.zsh   # Git & GitHub CLI aliases (GitLens replacement)
      ├── functions.zsh     # Developer workflow functions (see below)
      └── performance.zsh   # Tool integration & optimizations
```

**Design principle**: Modular structure allows editing specific functionality without navigating a monolithic config file. Changes to symlinked files are immediately active.

### Key Developer Functions (functions.zsh)

All functions support `-t` flag for test mode (dry-run without execution).

#### Core Workflow Functions
- **`feature <name> "<title>"`** - Create feature branch with Claude-assisted commit planning
  - Validates git environment
  - Analyzes staged/unstaged changes
  - Suggests branch names and commit strategies
  - Stores commit plan in `.claude_commit_plan.json`

- **`qcp ["message"]`** - Quick commit and push with intelligent suggestions
  - Reads commit plan from `feature()` if available
  - Uses Claude to suggest conventional commit messages
  - Offers commit splitting for large changes
  - Handles staged/unstaged changes automatically

- **`interactive_commit_split`** - Split large commits into logical groups
  - Claude analyzes files and suggests groupings by purpose
  - Interactive staging and commit workflow
  - Generates appropriate commit messages per group

#### Analysis & Context Functions
- **`cc [PR_NUMBER]`** - Lightweight code context for Claude
  - **PR mode**: `cc 123` - Analyzes PR diff, stats, and metadata
  - **Branch mode**: `cc` - Compares current branch to base (origin/main)
  - Sends context directly to Claude CLI
  - Detects base branch automatically (main/master fallback)

- **`repo_dashboard`** - AI-powered repository health analysis
  - Git statistics (commits, contributors, activity, branches)
  - AI assessment of repository health and velocity
  - Optional save to `REPO_HEALTH.md`

- **`daily_standup`** - Generate standup updates from git activity
  - Analyzes yesterday's commits and current work
  - Integrates with GitHub CLI for PR context
  - Options: copy to clipboard, edit, save, post to Slack

- **`pr_review <PR_NUMBER>`** - AI code review assistant
  - Fetches PR diff and metadata via GitHub CLI
  - Claude analyzes security, performance, quality, testing
  - Interactive posting to GitHub

#### Agent-Friendly Utilities
- **`agent_repo_op <operation>`** - Structured JSON responses for automation
  - Operations: `status`, `branch-diff`, `safe-commit`, `validate-repo`
  - Returns JSON with success/error states and context
  - Aliases: `arepo`, `arepo-test` (test mode)

- **`validate_git_environment <function_name>`** - Validation helper
  - Checks git repository context
  - Verifies remote connectivity
  - Returns structured JSON with actionable errors

#### Self-Healing System
- **`fix_function -f FUNC -e "error" -u "usage" -x "expected" -a "actual"`**
  - Diagnoses function issues with pattern matching
  - Suggests fixes for common errors (paths, git, permissions)
  - Creates backups before applying fixes
  - Aliases: `ffix`, `qfix`, `afix`

#### Java/Spring Boot Development
- **`start-rk [debug_port] [profile]`** - Start IRA Recordkeeper with Maven
  - Default debug port: 65108, profile: local
  - Cleans up port 9000 conflicts automatically
  - Graceful shutdown with Ctrl+C trap
  - Fork=false for proper signal handling

- **`start-rk-custom [debug_port] [profile] [neo4j_conf] [neo4j_prod]`**
  - Custom Neo4j credentials support
  - Same graceful shutdown behavior

### GitHub CLI Integration (git-aliases.zsh)

This replaces GitLens functionality with CLI-based workflows:

**Commit Visualization**:
- `glog` - Graph with author and relative time
- `glogme` - Graph filtered to current user
- `grecent` - Last 10 commits with dates

**File Analysis**:
- `gblame` - Enhanced blame (ignoring whitespace/moves)
- `ghistory <file>` - Full file history with diffs
- `ghotfiles` - Top 20 most-changed files

**Branch Management**:
- `gbranches` - All branches sorted by commit date
- `gcompare` - Compare current branch to origin HEAD
- `gdiffbranch` - File changes between branches

**PR Workflows** (requires `gh` CLI):
- `gprs` - List PRs with metadata
- `gprdetail` - Full PR details JSON
- `gprdiff <PR>` - PR diff view
- `gprcomments <PR>` - PR comment thread

## Important Patterns

### Stow Ignore Rules (.stow-local-ignore)
Files matching these patterns are NOT symlinked:
- Documentation: `README.*`, `*.md`, `LICENSE.*`
- Version control: `.git`, `.gitignore`, `.gitmodules`
- Setup scripts: `setup.sh`, `install.sh`, `bootstrap.sh`
- Editor/OS: `.vscode/`, `.idea/`, `.DS_Store`

### Git Configuration (.gitconfig)
- User: Jaden Stittsworth (jstittsworth+irx@iralogix.com)
- GPG signing via SSH (ssh-keygen)
- GitHub credential helper via `gh auth git-credential`
- LFS enabled

### Environment-Specific Notes
- Repository location: `/Users/jstittsworth/Documents/repos/`
- Functions assume repos are under `~/Documents/repos/`
- Claude CLI integration expected (`claude` command available)
- GitHub CLI required for PR/issue functions (`gh`)

## Common Development Tasks

### Adding New Configuration Files
1. Add file to `.dotfiles/` directory (e.g., `.dotfiles/.new-config`)
2. Update `.stow-local-ignore` if file should NOT be symlinked
3. Run `stow --restow .` to apply changes
4. Verify with `ls -la ~/.new-config`

### Modifying Zsh Configuration
**DO**: Edit specific modules in `.config/zsh/` for targeted changes
**DON'T**: Edit `.zshrc` directly (it's just a loader)

Examples:
- New alias → `.config/zsh/aliases.zsh` or `.config/zsh/git-aliases.zsh`
- New function → `.config/zsh/functions.zsh`
- Environment variable → `.config/zsh/env.zsh`
- Plugin configuration → `.config/zsh/plugins.zsh`

Changes are immediately available via symlinks (no re-stow needed).

### Testing Function Changes
```bash
# Test function in dry-run mode
feature -t "test-branch" "Test Feature"
qcp -t "test commit message"
repo_dashboard -t

# Run comprehensive function test suite
test_all_functions

# Diagnose specific function issue
fix_function -f feature -e "no such directory" -u 'feature "auth"' -x "create branch" -a "path error"
```

### Setting Up Claude Code Commands
```bash
# Initialize Claude commands for current project
init_claude_project

# Creates:
# - CLAUDE.md (project context)
# - .claude/commands/analyze-commit.md
# - .claude/commands/prep-pr.md
```

## Claude Code Setup (New Machine)

To reproduce the full Claude Code AI configuration on another machine:

```bash
# 1. Clone dotfiles
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles

# 2. Apply symlinks (agents, commands, hooks, skills, CLAUDE.md)
stow --restow --target ~ .

# 3. Bootstrap plugins, MCP servers, and merge settings
bash setup-claude.sh

# Dry run first to see what would change:
bash setup-claude.sh --dry-run
```

The setup script is additive -- it merges config into existing settings without clobbering. Override the repos directory with `REPOS_DIR=/your/path bash setup-claude.sh`.

**What gets synced**: 14 agents, 10 commands, 5 hooks, skills, CLAUDE.md, 12 plugins, MCP servers (github, filesystem), portable settings (env, hooks config, deny rules).

**What stays machine-specific**: `permissions.allow` (accumulated grants), `mcpServers` (added by CLI), `enabledPlugins` (set by plugin install), `settings.local.json`.

## Dependencies

### Required
- GNU Stow: `brew install stow`
- Zsh shell (default on macOS)
- Git

### Optional but Recommended
- Oh My Zsh: [ohmyz.sh](https://ohmyz.sh/#install)
- Powerlevel10k: `brew install powerlevel10k`
- GitHub CLI: `brew install gh` (for PR functions)
- Claude CLI: Required for AI-assisted functions
- fzf: `brew install fzf` (fuzzy finder)
- bat: `brew install bat` (syntax highlighting)
- ripgrep: `brew install ripgrep` (fast search)
- git-delta: `brew install git-delta` (better diffs)

### Java Development (for start-rk functions)
- Maven (mvn)
- JDK 11+
- IRA Recordkeeper repository at `/Users/jstittsworth/Documents/repos/ilx-core/ira-recordkeeper/`

## Troubleshooting

### Stow Conflicts
```bash
# Remove conflicting files
rm ~/.conflicting-file

# Re-apply stow
cd ~/.dotfiles && stow --restow .
```

### Zsh Module Not Loading
```bash
# Check module exists and has correct permissions
ls -la ~/.config/zsh/
zsh -n ~/.zshrc  # Syntax check

# Manually source to test
source ~/.config/zsh/MODULE.zsh
```

### Function Errors
Use the self-healing system:
```bash
# Quick diagnosis of last command
quick_fix "feature 'test'" "error: not a git repository"

# Agent-friendly fix with JSON error context
agent_fix "qcp" '{"status":"error","message":"No changes to commit"}'
```

### GitHub CLI Not Working
```bash
# Install and authenticate
brew install gh
gh auth login

# Verify
gh auth status
```

## Special Considerations for Claude Code

### When Modifying Functions
1. **Always backup first**: Functions file is critical to developer workflow
2. **Test in test mode**: Use `-t` flag before applying changes
3. **Preserve JSON error format**: Functions use structured error responses
4. **Maintain validation**: All functions should call `validate_git_environment()`
5. **Keep test mode support**: All functions should handle `-t` flag

### When Working with Stow
- Changes to files in `.dotfiles/` are immediately reflected (they're symlinked)
- No need to re-run stow unless adding NEW files
- Always check `.stow-local-ignore` before adding files

### Repository Assumptions
- Developer works in `/Users/jstittsworth/Documents/repos/`
- Main branch is `origin/main` or `origin/master` (auto-detected)
- Claude CLI is available and configured
- GitHub CLI is authenticated

### Performance Considerations
- Heavy tools (fzf, bat) use conditional loading in `performance.zsh`
- Error suppression for missing optional dependencies
- Modular sourcing reduces startup time
