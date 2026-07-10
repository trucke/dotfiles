import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const DEFAULT_FIRECRAWL_BASE_URL = "https://api.firecrawl.dev/v1";

type EnvMap = Record<string, string>;

function parseDotEnv(contents: string): EnvMap {
	const env: EnvMap = {};

	for (const rawLine of contents.split(/\r?\n/)) {
		const line = rawLine.trim();
		if (!line || line.startsWith("#")) continue;

		const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
		if (!match) continue;

		const key = match[1];
		let value = match[2].trim();

		if (
			(value.startsWith('"') && value.endsWith('"')) ||
			(value.startsWith("'") && value.endsWith("'"))
		) {
			value = value.slice(1, -1);
		}

		env[key] = value;
	}

	return env;
}

function loadEnv(cwd: string): EnvMap {
	// Later files override earlier files. process.env overrides all of them.
	const files = [
		join(homedir(), ".pi", "agent", ".env"),
		join(homedir(), ".pi", "agent", "extensions", ".env"),
		join(cwd, ".env"),
	];

	const env: EnvMap = {};
	for (const file of files) {
		if (!existsSync(file)) continue;
		Object.assign(env, parseDotEnv(readFileSync(file, "utf8")));
	}

	return { ...env, ...process.env } as EnvMap;
}

function getConfig(cwd: string) {
	const env = loadEnv(cwd);
	const apiKey = env.FIRECRAWL_API_KEY;
	const baseUrl = (env.FIRECRAWL_BASE_URL || DEFAULT_FIRECRAWL_BASE_URL).replace(/\/$/, "");

	if (!apiKey) {
		throw new Error(
			"Missing FIRECRAWL_API_KEY. Add it to .env, for example: FIRECRAWL_API_KEY=fc-your-key",
		);
	}

	return { apiKey, baseUrl };
}

async function firecrawl(cwd: string, path: string, body: unknown, signal?: AbortSignal) {
	const { apiKey, baseUrl } = getConfig(cwd);

	const response = await fetch(`${baseUrl}${path}`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${apiKey}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(body),
		signal,
	});

	const text = await response.text();
	let data: unknown = text;
	try {
		data = text ? JSON.parse(text) : undefined;
	} catch {
		// Keep raw text when Firecrawl does not return JSON.
	}

	if (!response.ok) {
		throw new Error(`Firecrawl request failed (${response.status}): ${JSON.stringify(data)}`);
	}

	return data;
}

export default function firecrawlExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "firecrawl_search",
		label: "Firecrawl Search",
		description: "Search the internet using Firecrawl and return web results.",
		promptSnippet: "Search the web using Firecrawl.",
		promptGuidelines: [
			"Use firecrawl_search when the user asks for current web information, internet search, recent docs, or external pages.",
		],
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			limit: Type.Optional(Type.Number({ description: "Maximum number of results", default: 5 })),
			scrape: Type.Optional(
				Type.Boolean({ description: "Whether to scrape result pages as markdown", default: false }),
			),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			onUpdate?.({ content: [{ type: "text", text: `Searching Firecrawl for: ${params.query}` }] });

			const result = await firecrawl(
				ctx.cwd,
				"/search",
				{
					query: params.query,
					limit: params.limit ?? 5,
					...(params.scrape ? { scrapeOptions: { formats: ["markdown"] } } : {}),
				},
				signal,
			);

			return {
				content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
				details: result,
			};
		},
	});

	pi.registerTool({
		name: "firecrawl_scrape",
		label: "Firecrawl Scrape",
		description: "Scrape a URL using Firecrawl and return clean page content.",
		promptSnippet: "Scrape a webpage using Firecrawl.",
		promptGuidelines: ["Use firecrawl_scrape when the user provides a URL and wants its page contents."],
		parameters: Type.Object({
			url: Type.String({ description: "URL to scrape" }),
			formats: Type.Optional(
				Type.Array(Type.String(), { description: "Output formats, for example markdown, html, links" }),
			),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			onUpdate?.({ content: [{ type: "text", text: `Scraping with Firecrawl: ${params.url}` }] });

			const result = await firecrawl(
				ctx.cwd,
				"/scrape",
				{
					url: params.url,
					formats: params.formats ?? ["markdown"],
				},
				signal,
			);

			return {
				content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
				details: result,
			};
		},
	});
}
