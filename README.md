# Dotfiles Configuration

A comprehensive dotfiles management system using GNU Stow for a streamlined development environment.

## Overview

This repository contains modular configuration files for zsh, git, and various development tools. The configuration is optimized for performance and developer productivity, featuring advanced GitHub CLI workflows that replace traditional GitLens functionality.

## Structure

```
.dotfiles/
├── README.md                    # This file
├── .stow-local-ignore          # Files to ignore during stow
├── .zshrc                      # Main zsh config (sources modules)
├── .config/
│   └── zsh/
│       ├── env.zsh             # Environment variables & exports
│       ├── aliases.zsh         # General aliases
│       ├── git-aliases.zsh     # Git & GitHub CLI aliases
│       ├── functions.zsh       # Custom functions
│       ├── plugins.zsh         # Plugin loading & configuration
│       └── performance.zsh     # Performance optimizations
├── .gitconfig                  # Git configuration
├── .npmrc                      # NPM configuration
├── .p10k.zsh                   # Powerlevel10k theme configuration
├── .tool-versions              # ASDF version manager
├── .editorconfig               # Editor configuration
├── .yarnrc                     # Yarn configuration
├── .bashrc                     # Bash fallback configuration
└── .zprofile                   # Zsh profile
```

## Features

### Modular Zsh Configuration
- **env.zsh**: Environment setup (PNPM, ASDF, PATH management)
- **aliases.zsh**: File operations, navigation, package managers
- **git-aliases.zsh**: Comprehensive Git and GitHub CLI aliases
- **functions.zsh**: Developer workflow functions
- **plugins.zsh**: Oh My Zsh, Powerlevel10k, autosuggestions
- **performance.zsh**: Tool integration and optimizations

### GitHub CLI Integration
Replaces GitLens with powerful command-line workflows:
- **Commit Visualization**: `glog`, `glog1`, `glogme`, `grecent`
- **Branch Management**: `gbranches`, `gcompare`, `gdiffbranch`
- **PR Workflows**: `gprs`, `gprdetail`, `gprdiff`, `gprcomments`
- **File Analysis**: `gblame`, `ghistory`, `ghotfiles`
- **Developer Functions**: `feature()`, `qcp()`, `repo_dashboard()`

### Key Developer Functions
- `feature <name> "<title>"` - Create feature branch and draft PR
- `qcp "<message>"` - Quick commit, push, and PR comment
- `repo_dashboard` - Repository statistics and activity
- `daily_standup` - Daily overview of PRs, issues, and reviews

## Installation

### Prerequisites
- GNU Stow: `brew install stow`
- Oh My Zsh: [Installation Guide](https://ohmyz.sh/#install)
- Powerlevel10k: `brew install powerlevel10k`
- GitHub CLI: `brew install gh`

### Setup
1. Clone or move this directory to `~/.dotfiles`
2. Remove existing dotfiles that will be managed:
   ```bash
   rm ~/.zshrc ~/.gitconfig ~/.npmrc ~/.p10k.zsh ~/.tool-versions ~/.editorconfig ~/.yarnrc ~/.bashrc ~/.zprofile
   ```
3. Apply stow configuration:
   ```bash
   cd ~/.dotfiles
   stow --dir ~/.dotfiles --target ~ .
   ```
4. Verify symlinks:
   ```bash
   ls -la ~/.zshrc ~/.gitconfig
   ```

## Usage

### Adding New Configurations
1. Add new dotfiles to the `.dotfiles` directory
2. Update `.stow-local-ignore` if needed
3. Re-run stow: `stow --restow .`

### Modifying Zsh Configuration
Edit specific modules in `.config/zsh/` instead of the main `.zshrc` file:
- Environment changes: `.config/zsh/env.zsh`
- New aliases: `.config/zsh/aliases.zsh` or `.config/zsh/git-aliases.zsh`
- Custom functions: `.config/zsh/functions.zsh`

### Git Workflow Examples
```bash
# Create feature branch with PR
feature "user-auth" "Add user authentication system"

# Quick commit and update PR
qcp "Fix validation error handling"

# View repository dashboard
repo_dashboard

# Check daily status
daily_standup

# Search code with preview
rg_preview "function.*auth"
```

## Tools Integration

### Optional Enhancements
- **fzf**: Fuzzy finder for enhanced search
- **bat**: Better cat with syntax highlighting
- **ripgrep**: Fast text search
- **delta**: Better git diffs

Install with: `brew install fzf bat ripgrep git-delta`

### Performance Features
- Conditional loading of heavy tools
- Error suppression for missing dependencies
- Modular sourcing for faster startup
- GitHub CLI alias management

## Maintenance

### Updating Configurations
```bash
# Navigate to dotfiles
cd ~/.dotfiles

# Edit configurations
nano .config/zsh/aliases.zsh

# No need to re-stow for existing files
# Changes are immediately available via symlinks
```

### Backup and Version Control
This dotfiles setup is designed to be version controlled. Consider:
- Initializing git repository: `git init`
- Adding sensitive files to `.gitignore`
- Regular commits of configuration changes

## Troubleshooting

### Stow Conflicts
If stow reports conflicts, remove the conflicting files:
```bash
rm ~/.conflicting-file
stow --restow .
```

### Missing Commands
The configuration gracefully handles missing commands. Install recommended tools:
```bash
brew install gh fzf bat ripgrep git-delta powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
```

### Zsh Modules Not Loading
Verify module paths and permissions:
```bash
ls -la ~/.config/zsh/
zsh -n ~/.zshrc  # Syntax check
```

## Contributing

When adding new features:
1. Follow the modular structure
2. Add conditional loading for optional dependencies
3. Update this README with new functionality
4. Test configurations before committing

---

**Note**: This configuration includes company-specific NPM registry settings in `.npmrc`. Review and modify as needed for your environment.