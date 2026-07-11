#!/bin/bash
# --ask: instead of hard-blocking, defer to the user with a permission prompt
# (agents that support the PreToolUse JSON decision protocol, e.g. Claude Code)
MODE="block"
[ "$1" = "--ask" ] && MODE="ask"

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')
CWD=$(echo "$INPUT" | jq -r '.cwd')

REASON=""

# privileged/system-wrecking commands
if echo "$CMD" | grep -qE '(^|[;&|[:space:]])(sudo|diskutil|mkfs)\b'; then
  REASON="Blocked: privileged command"
# destructive commands that reference paths outside the project
elif echo "$CMD" | grep -qE '\b(rm|mv|rsync|shred)\b'; then
  if echo "$CMD" | grep -qE '(~|\$HOME|/Users/|/etc|/var|/usr)'; then
    if ! echo "$CMD" | grep -qF "$CWD"; then
      REASON="Blocked: destructive command targeting path outside $CWD"
    fi
  fi
fi

[ -z "$REASON" ] && exit 0

if [ "$MODE" = "ask" ]; then
  # exit 0 with an "ask" decision: the agent pauses and the user approves or denies
  jq -n --arg reason "$REASON (approve to run anyway)" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
  exit 0
fi

echo "$REASON" >&2
exit 2
