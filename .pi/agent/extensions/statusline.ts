import { spawnSync } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

type UsageTotals = {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	reasoning: number;
	cost: number;
};

const emptyUsage = (): UsageTotals => ({
	input: 0,
	output: 0,
	cacheRead: 0,
	cacheWrite: 0,
	reasoning: 0,
	cost: 0,
});

function addUsage(totals: UsageTotals, usage: any): void {
	if (!usage) return;
	totals.input += usage.input ?? 0;
	totals.output += usage.output ?? 0;
	totals.cacheRead += usage.cacheRead ?? 0;
	totals.cacheWrite += usage.cacheWrite ?? 0;
	totals.reasoning += usage.reasoning ?? 0;
	totals.cost += usage.cost?.total ?? 0;
}

function getUsageTotals(ctx: ExtensionContext): UsageTotals {
	const totals = emptyUsage();
	for (const entry of ctx.sessionManager.getBranch() as any[]) {
		if (entry.type === "message" && entry.message?.role === "assistant") {
			addUsage(totals, entry.message.usage);
		} else if ((entry.type === "compaction" || entry.type === "branch_summary") && entry.usage) {
			addUsage(totals, entry.usage);
		}
	}
	return totals;
}

function statusInput(ctx: ExtensionContext): string {
	const context = ctx.getContextUsage();
	const usage = getUsageTotals(ctx);
	const model = ctx.model;

	return JSON.stringify({
		model: {
			display_name: model?.name ?? model?.id ?? "Pi",
			name: model?.name,
			id: model?.id,
			provider: model?.provider,
		},
		workspace: { current_dir: ctx.cwd },
		context_window: {
			current_usage: { input_tokens: context?.tokens ?? 0 },
			context_window_size: context?.contextWindow ?? model?.contextWindow ?? 200000,
		},
		effort: { level: ctx.thinkingLevel ?? "" },
		usage,
	});
}

function renderStatus(ctx: ExtensionContext): string | undefined {
	const result = spawnSync("/opt/homebrew/bin/fish", ["-lc", "agent-statusline pi"], {
		input: statusInput(ctx),
		encoding: "utf8",
		stdio: ["pipe", "pipe", "ignore"],
		timeout: 1500,
	});

	if (result.status !== 0) return undefined;
	return result.stdout.trim().replace(/\n/g, "  ");
}

export default function (pi: ExtensionAPI) {
	let currentStatus = "";
	let requestRender = () => {};

	function refresh(ctx: ExtensionContext): void {
		currentStatus = renderStatus(ctx) ?? currentStatus;
		requestRender();
	}

	pi.on("session_start", async (_event, ctx) => {
		refresh(ctx);
		ctx.ui.setFooter((tui, _theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsubscribeBranch = footerData.onBranchChange(() => {
				refresh(ctx);
			});

			return {
				dispose() {
					unsubscribeBranch();
					requestRender = () => {};
				},
				invalidate() {},
				render(width: number): string[] {
					return [truncateToWidth(currentStatus, width)];
				},
			};
		});
	});

	pi.on("model_select", async (_event, ctx) => refresh(ctx));
	pi.on("thinking_level_select", async (_event, ctx) => refresh(ctx));
	pi.on("turn_start", async (_event, ctx) => refresh(ctx));
	pi.on("turn_end", async (_event, ctx) => refresh(ctx));
	pi.on("agent_end", async (_event, ctx) => refresh(ctx));
	pi.on("session_shutdown", async (_event, ctx) => ctx.ui.setFooter(undefined));
}
