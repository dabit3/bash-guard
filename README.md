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

## Usage

Bash Guard runs automatically before each shell command. Allowed commands continue normally. Blocked commands are rejected with an explanation.

Test it directly by passing a hook payload:

```bash
echo '{"tool_input":{"command":"sudo rm -rf /tmp/example"},"cwd":"/path/to/project"}' \
  | "$HOME/.local/share/bash-guard/bash-guard.sh"
```

A blocked command exits with status `2`. An allowed command exits with status `0`. Other agents can use Bash Guard if their command hooks pass `tool_input.command` and `cwd` as JSON on standard input and treat exit status `2` as a block.
