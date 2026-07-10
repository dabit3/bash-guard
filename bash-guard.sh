#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')
CWD=$(echo "$INPUT" | jq -r '.cwd')

# hard-block privileged/system-wrecking commands
if echo "$CMD" | grep -qE '(^|[;&|[:space:]])(sudo|diskutil|mkfs)\b'; then
  echo "Blocked: privileged command" >&2
  exit 2
fi

# block destructive commands that reference paths outside the project
if echo "$CMD" | grep -qE '\b(rm|mv|rsync|shred)\b'; then
  if echo "$CMD" | grep -qE '(~|\$HOME|/Users/|/etc|/var|/usr)'; then
    if ! echo "$CMD" | grep -qF "$CWD"; then
      echo "Blocked: destructive command targeting path outside $CWD" >&2
      exit 2
    fi
  fi
fi

exit 0