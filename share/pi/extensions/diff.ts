import path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const commandName = "diff";

function getStringPath(input: unknown) {
    if (!input || typeof input !== "object" || !("path" in input)) return undefined;
    return typeof input.path === "string" ? input.path : undefined;
}

function toAbsolute(cwd: string, filePath: string) {
    return path.isAbsolute(filePath) ? path.normalize(filePath) : path.resolve(cwd, filePath);
}

function toRelative(cwd: string, filePath: string) {
    const relative = path.relative(cwd, filePath);
    return relative && !relative.startsWith("..") && !path.isAbsolute(relative) ? relative : filePath;
}

function parseGitStatus(output: string, cwd: string) {
    const files = new Set<string>();

    for (const line of output.split("\n")) {
        if (line.length < 4) continue;

        // `git status --porcelain` format is two status columns, a space, then path.
        // Rename/copy entries look like `old -> new`; the destination is what we want to open.
        const rawPath = line.slice(3).trim();
        if (!rawPath) continue;

        const targetPath = rawPath.includes(" -> ") ? rawPath.split(" -> ").at(-1) : rawPath;
        if (!targetPath) continue;

        files.add(toAbsolute(cwd, targetPath.replace(/^"|"$/g, "")));
    }

    return files;
}

async function getJjChangedFiles(pi: ExtensionAPI, cwd: string): Promise<Set<string> | undefined> {
    const rootResult = await pi.exec("jj", ["root"], { cwd, timeout: 5000 });
    if (rootResult.code !== 0) return undefined;

    const root = rootResult.stdout.trim();
    const result = await pi.exec("jj", ["diff", "--name-only", "-r", "@"], { cwd, timeout: 5000 });
    if (result.code !== 0) return new Set<string>();

    return new Set(result.stdout.split("\n").filter(Boolean).map((file: string) => toAbsolute(root, file)));
}

async function getGitChangedFiles(pi: ExtensionAPI, cwd: string): Promise<Set<string>> {
    const result = await pi.exec(
        "git",
        ["status", "--porcelain", "--untracked-files=all"],
        { cwd, timeout: 5000 },
    );

    if (result.code !== 0) return new Set<string>();
    return parseGitStatus(result.stdout, cwd);
}

async function getChangedFiles(pi: ExtensionAPI, cwd: string): Promise<Set<string>> {
    return (await getJjChangedFiles(pi, cwd)) ?? getGitChangedFiles(pi, cwd);
}

function difference(current: Set<string>, baseline: Set<string>) {
    return new Set([...current].filter((file) => !baseline.has(file)));
}

export default function(pi: ExtensionAPI) {
    let baseline = new Set<string>();
    let changedFiles = new Set<string>();
    let toolTouchedFiles = new Set<string>();

    pi.on("agent_start", async (_event, ctx) => {
        toolTouchedFiles = new Set();
        changedFiles = new Set();
        baseline = await getChangedFiles(pi, ctx.cwd);
    });

    pi.on("tool_result", (event, ctx) => {
        if (event.toolName !== "edit" && event.toolName !== "write") return;

        const filePath = getStringPath(event.input);
        if (!filePath) return;

        toolTouchedFiles.add(toAbsolute(ctx.cwd, filePath));
    });

    pi.on("agent_end", async (_event, ctx) => {
        const currentChanged = await getChangedFiles(pi, ctx.cwd);
        changedFiles = new Set([...difference(currentChanged, baseline), ...toolTouchedFiles]);

        if (changedFiles.size > 0) {
            ctx.ui.notify(`${changedFiles.size} changed file(s). Run /${commandName} to view/open in Zed.`, "info");
        }
    });

    pi.registerCommand(commandName, {
        description: "Show files changed by the last agent run and open one in Zed",
        handler: async (args, ctx) => {
            await ctx.waitForIdle();

            const arg = args.trim();
            if (arg === "clear") {
                changedFiles = new Set();
                toolTouchedFiles = new Set();
                baseline = await getChangedFiles(pi, ctx.cwd);
                ctx.ui.notify("Cleared changed file list", "info");
                return;
            }

            const files = [...changedFiles].sort((a, b) => toRelative(ctx.cwd, a).localeCompare(toRelative(ctx.cwd, b)));
            if (files.length === 0) {
                ctx.ui.notify("No changed files tracked from the last agent run", "info");
                return;
            }

            if (arg === "list") {
                ctx.ui.notify(`Changed files:\n${files.map((file) => `- ${toRelative(ctx.cwd, file)}`).join("\n")}`, "info");
                return;
            }

            if (arg) {
                ctx.ui.notify(`Unknown /${commandName} argument: ${arg}. Try /${commandName}, /${commandName} list, or /${commandName} clear.`, "warning");
                return;
            }

            const labels = files.map((file) => toRelative(ctx.cwd, file));
            const selected = await ctx.ui.select("Open changed file in Zed", labels);
            if (!selected) return;

            const selectedIndex = labels.indexOf(selected);
            const file = files[selectedIndex];
            if (!file) return;

            const result = await pi.exec("zed", ["-e", file], { cwd: ctx.cwd, timeout: 5000 });
            if (result.code === 0) {
                ctx.ui.notify(`Opened ${selected} in Zed`, "info");
            } else {
                ctx.ui.notify(result.stderr.trim() || `Failed to open ${selected} in Zed`, "error");
            }
        },
    });
}
