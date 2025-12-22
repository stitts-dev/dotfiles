# ===== Task-Master CLI =====
# Intuitive Task-Master CLI aliases

# ----- Core Commands -----
alias tm='task-master'
alias tasks='task-master list'
alias task='task-master show'           # Usage: task <id>
alias next-task='task-master next'

# ----- Status Commands -----
start-task() { task-master set-status "$1" in-progress; }
done-task()  { task-master set-status "$1" done; }
block-task() { task-master set-status "$1" blocked; }

# ----- Analysis & Breakdown -----
alias analyze-tasks='task-master analyze-complexity'
alias complexity='task-master complexity-report'
alias expand-all='task-master expand --all'

expand-task() {
  if [[ -z "$1" ]]; then
    echo "Usage: expand-task <task-id> [--num=5] [--research]"
    return 1
  fi
  task-master expand --id="$1" "${@:2}"
}

research() {
  task-master research "$@"
}

# ----- Workstream Navigation -----
ILX_SERVICING_ROOT="${HOME}/Documents/repos/ilx-servicing"

alias ws-aws='cd ${ILX_SERVICING_ROOT}/workstreams/aws-connect-infrastructure && tasks'
alias ws-lambda='cd ${ILX_SERVICING_ROOT}/workstreams/lambda-bridge && tasks'
alias ws-portal='cd ${ILX_SERVICING_ROOT}/workstreams/staff-portal && tasks'
alias ws-sf='cd ${ILX_SERVICING_ROOT}/workstreams/salesforce-migration && tasks'

# ----- Workflow Helpers -----

# Start working on a task (set in-progress + show details)
work-on() {
  if [[ -z "$1" ]]; then
    echo "Usage: work-on <task-id>"
    return 1
  fi
  task-master set-status "$1" in-progress
  task-master show "$1"
}

# Complete a task and show next
finish() {
  if [[ -z "$1" ]]; then
    echo "Usage: finish <task-id>"
    return 1
  fi
  task-master set-status "$1" done
  echo "Task $1 marked done\n"
  task-master next
}

# Show all available aliases
tm-help() {
  cat << 'EOF'
Task-Master Aliases
===================

CORE COMMANDS
  tm              Base task-master command
  tasks           List all tasks
  task <id>       Show task details
  next-task       Show next task by dependencies

STATUS COMMANDS
  start-task <id> Mark task as in-progress
  done-task <id>  Mark task as done
  block-task <id> Mark task as blocked

ANALYSIS & BREAKDOWN
  analyze-tasks       Analyze complexity, recommend expansions
  complexity          View complexity report
  expand-task <id>    Break down task into subtasks
  expand-all          Expand all pending tasks
  research "prompt"   AI-powered research query

WORKSTREAM NAVIGATION
  ws-aws          Go to AWS Connect workstream
  ws-lambda       Go to Lambda Bridge workstream
  ws-portal       Go to Staff Portal workstream
  ws-sf           Go to Salesforce Migration workstream

WORKFLOW HELPERS
  work-on <id>    Start task (in-progress + show details)
  finish <id>     Complete task (done + show next)
  tm-help         Show this help

EXAMPLES
  tasks                    # List all tasks
  task 5                   # Show task 5 details
  work-on 5                # Start working on task 5
  finish 5                 # Mark task 5 done, show next
  ws-aws                   # Switch to AWS workstream
EOF
}
