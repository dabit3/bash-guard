/**
 * Bash Guard hook for oh-my-pi (https://github.com/badlogic/pi-mono / omp).
 *
 * omp doesn't read JSON hook configs. Instead it loads TypeScript hook modules,
 * so this file wraps bash-guard.sh in omp's HookAPI. Install:
 *
 *   mkdir -p ~/.omp/agent/hooks/pre
 *   cp oh-my-pi/bash-guard.ts ~/.omp/agent/hooks/pre/
 *
 * Note: hooks are only auto-discovered from the hooks/pre/ and hooks/post/
 * subdirectories, not from hooks/ itself.
 *
 * On a guard hit this prompts the user to block or allow the command once
 * (the model can't answer the prompt). In non-interactive mode (-p) there is
 * no one to ask, so it blocks by default.
 */
import { spawnSync } from "node:child_process";
import type { HookAPI } from "@oh-my-pi/pi-coding-agent";

const GUARD_SCRIPT = `${process.env.HOME}/.local/share/bash-guard/bash-guard.sh`;

export default function (pi: HookAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string | undefined;
		if (!command) return undefined;

		const payload = JSON.stringify({
			tool_input: { command },
			cwd: process.cwd(),
		});

		const result = spawnSync(GUARD_SCRIPT, {
			input: payload,
			encoding: "utf8",
			timeout: 10_000,
		});

		if (result.status !== 2) return undefined;

		const reason = (result.stderr || "Blocked by bash-guard").trim();

		if (!ctx.hasUI) {
			return { block: true, reason: `${reason} (non-interactive mode, blocked by default)` };
		}

		const choice = await ctx.ui.select(`bash-guard: ${reason}\n\n  ${command}\n\nAllow this command?`, [
			"Block",
			"Allow once",
		]);

		if (choice !== "Allow once") {
			return { block: true, reason: `${reason} (denied by user)` };
		}

		return undefined;
	});
}
