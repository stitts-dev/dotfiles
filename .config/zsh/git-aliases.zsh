# ===== GitHub CLI & Git Aliases for Enhanced Development =====
# Replaces GitLens functionality with powerful CLI commands

# ----- Commit History & Visualization -----
alias glog='git log --graph --pretty=format:"%C(auto)%h%d %s %C(black)%C(bold)<%an> %cr" --abbrev-commit --all'
alias glog1='git log --graph --pretty=oneline --abbrev-commit --all --decorate'
alias glogme='git log --graph --pretty=format:"%C(auto)%h%d %s %C(black)%C(bold)%cr" --abbrev-commit --author="$(git config user.name)"'
alias glogf='git log --follow --graph --pretty=format:"%C(auto)%h%d %s %C(black)%C(bold)<%an> %cr" --abbrev-commit --'
alias grecent='git log --pretty=format:"%C(yellow)%h %C(blue)%ad %C(green)%an%C(auto)%d%n%C(white)%s%n" --date=short -10'

# ----- Blame & File History -----
alias gblame='git blame -w -M -C'
alias ghistory='git log -p --follow --'
alias gchanges='git log --oneline --follow --stat --'

# ----- Branch Management & Comparison -----
alias gbranches='git for-each-ref --sort=-committerdate refs/heads/ --format="%(color:yellow)%(refname:short)%(color:reset) - %(color:green)%(committerdate:relative)%(color:reset) - %(contents:subject) - %(authorname)"'
alias gcompare='git log --graph --pretty=format:"%C(auto)%h%d %s %C(black)%C(bold)%cr" --abbrev-commit HEAD..$(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")'
alias gdiffbranch='git diff --name-status'

# ----- PR & GitHub Integration -----
alias gprs='gh pr list --limit 20 --json number,title,author,state,createdAt,updatedAt'
alias gprdetail='gh pr view --json number,title,body,author,state,createdAt,updatedAt,labels,files,commits'
alias gprdiff='gh pr diff'
alias gprcomments='gh pr view --comments'
alias gprstatus='gh pr checks'

# ----- My PR Status (for Claude bulk processing) -----
# Uses -R flag to work from anywhere without needing git repo context
alias gmyprs='gh pr list -R iralogix/unified-portal --author "@me" --state open --limit 30 --json number,title,headRefName,baseRefName,mergeable,reviewDecision,statusCheckRollup,additions,deletions,changedFiles,url'
alias gprconflicts='gh pr list -R iralogix/unified-portal --author "@me" --state open --json number,title,headRefName,mergeable,url | jq -r ".[] | select(.mergeable == \"CONFLICTING\") | \"#\(.number) \(.title) [\(.headRefName)]\n  \(.url)\""'
alias gprfailing='gh pr list -R iralogix/unified-portal --author "@me" --state open --json number,title,headRefName,statusCheckRollup,url | jq -r ".[] | select(.statusCheckRollup != null) | select(.statusCheckRollup | any(.conclusion == \"FAILURE\")) | \"#\(.number) \(.title) [\(.headRefName)]\n  \(.url)\""'
alias gprpending='gh pr list -R iralogix/unified-portal --author "@me" --state open --json number,title,reviewDecision,url | jq -r ".[] | select(.reviewDecision == null or .reviewDecision == \"REVIEW_REQUIRED\") | \"#\(.number) \(.title)\n  \(.url)\""'

# ----- Commit & Change Details -----
alias gshow='git show --stat --format=fuller'
alias glastfiles='git diff-tree --no-commit-id --name-only -r HEAD'
alias gstats='git show --stat'

# ----- Author & Contribution Analysis -----
alias gauthors='git shortlog -sn --all --no-merges'
alias gcontribs='git log --author="$1" --pretty=format:"%h - %an, %ar : %s" --stat'
alias gactivity='git log --all --since="1 week ago" --oneline --graph --decorate'

# ----- File & Directory Analysis -----
alias gfind='git ls-files | grep'
alias gfilesize='git log --follow --pretty=format:"%h %ad" --date=short -- "$1" | while read hash date; do echo -n "$date $hash "; git show $hash:"$1" | wc -c; done'
alias ghotfiles='git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -20'

# ----- Stash Management -----
alias gstashes='git stash list --pretty=format:"%C(yellow)%h %C(blue)%gs %C(green)(%cr)"'

# ----- Quick Status Commands -----
alias gs='git status -sb'
alias gbranch='git rev-parse --abbrev-ref HEAD'
alias gremotes='git remote -v'

# ----- AI Context Helpers -----
alias gcontext='echo "=== Current Branch ===" && git rev-parse --abbrev-ref HEAD && echo "\n=== Recent Commits ===" && git log --oneline -10 && echo "\n=== Changed Files ===" && git diff --name-status HEAD~5'
alias gpatch='git format-patch -1 HEAD'
alias gbase='git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")'

# ----- Quick Navigation -----
alias groot='cd $(git rev-parse --show-toplevel)'

# ----- Configuration Helpers -----
alias gconfig='git config --list --show-origin'