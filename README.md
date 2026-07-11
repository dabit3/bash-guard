# Bash Guard

A small command hook that blocks risky shell commands before local coding agents run them. It works with agents that support `PreToolUse` hooks, including Claude Code, Codex CLI, and Devin CLI.

It blocks:

- Commands using `sudo`, `diskutil`, or `mkfs`
- Destructive commands such as `rm`, `mv`, `rsync`, or `shred` when they target paths outside the current project

## Requirements

- Bash
- `jq`

## Install

```bash
mkdir -p "$HOME/.local/share/bash-guard"
cp bash-guard.sh "$HOME/.local/share/bash-guard/bash-guard.sh"
chmod +x "$HOME/.local/share/bash-guard/bash-guard.sh"
```

## Configure your agent

Merge this hook into your agent's JSON configuration, replacing `<matcher>` with the value below:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "<matcher>",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.local/share/bash-guard/bash-guard.sh"
          }
        ]
      }
    ]
  }
}
```

| Agent | User configuration | Project configuration | Matcher |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/settings.json` | `.claude/settings.json` | `^Bash$` |
| Codex CLI | `~/.codex/hooks.json` | `.codex/hooks.json` | `^Bash$` |
| Devin CLI | `~/.config/devin/config.json` | `.devin/config.json` | `^exec$` |

Restart the agent after updating its configuration. In Codex CLI, open `/hooks` and trust the new hook. Use `/hooks` in Codex or Devin to confirm that it loaded.

### oh-my-pi

oh-my-pi (`omp`) doesn't read JSON hook configs; it loads TypeScript hook modules instead. This repo ships a ready-made one in [`oh-my-pi/bash-guard.ts`](oh-my-pi/bash-guard.ts) that shells out to the same guard script:

```bash
mkdir -p ~/.omp/agent/hooks/pre
cp oh-my-pi/bash-guard.ts ~/.omp/agent/hooks/pre/
```

Hooks are only auto-discovered from the `hooks/pre/` and `hooks/post/` subdirectories, so don't drop the file in `hooks/` directly. On a guard hit the hook prompts the user to block or allow the command once; in non-interactive mode (`-p`) it blocks by default.

## Usage

Bash Guard runs automatically before each shell command. Allowed commands continue normally. Blocked commands are rejected with an explanation.

Test it directly by passing a hook payload:

```bash
echo '{"tool_input":{"command":"sudo rm -rf /tmp/example"},"cwd":"/path/to/project"}' \
  | "$HOME/.local/share/bash-guard/bash-guard.sh"
```

A blocked command exits with status `2`. An allowed command exits with status `0`. Other agents can use Bash Guard if their command hooks pass `tool_input.command` and `cwd` as JSON on standard input and treat exit status `2` as a block.

## Ask mode: let the user override a block

Because the guard matches on the whole command string, it can catch false positives, for example a command that only mentions `sudo` inside an `echo`, a commit message, or a heredoc. If you would rather make that call yourself than have the command rejected outright, add `--ask` to the hook command:

```json
{
  "type": "command",
  "command": "$HOME/.local/share/bash-guard/bash-guard.sh --ask"
}
```

With `--ask`, a guard hit no longer exits with status `2`. Instead the script exits `0` and prints a `PreToolUse` decision:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Blocked: privileged command (approve to run anyway)"
  }
}
```

The agent pauses and shows the user a permission prompt with the reason. The user can approve the command or deny it; the agent cannot answer the prompt itself. Allowed commands still pass through silently, and the default (no flag) behavior is unchanged.

Ask mode works in Claude Code. Codex CLI currently rejects `permissionDecision: "ask"` as unsupported, and Devin CLI only understands exit codes, so keep the default block mode for those two.
