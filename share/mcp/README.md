# MCP servers

Shared MCP server specs for the coding agents. The canonical machine-readable
spec is [`playwright.json`](playwright.json); this file is the human wiring guide.

## playwright — headless browser for agents

Gives agents a real browser to **drive and verify web apps they build**:
navigate to a local dev server, click, fill, assert the DOM, screenshot — all
**headless**, so it works on a box with no monitor (kratos). It drives via the
accessibility tree (deterministic, token-cheap), not screenshot-guessing.

> `claude --chrome` and Anthropic "computer use" both need a **visible display**
> and won't run on a headless server — this MCP server is the headless path.

**Server command:** `playwright-mcp --headless --browser chromium --isolated`
(package `@playwright/mcp`; browser via `playwright install chromium`).

### Install (kratos)

```bash
just -f ~/.dotfiles/kratos/justfile playwright-mcp
```

That installs `@playwright/mcp` + Chromium and registers the server with Claude
Code. Verify with `claude mcp list`.

### Register per agent

**Claude Code** *(verified — done by `playwright-mcp`)*. Manual equivalent, user scope:

```bash
claude mcp add playwright -s user -- \
  "$(mise exec -- pnpm bin -g)/playwright-mcp" --headless --browser chromium --isolated
```

Registering with an **absolute** path avoids PATH surprises when the agent spawns
the server. (User scope is written to `~/.claude.json`, which also holds other
state — always register via the CLI, never hand-overwrite that file.)

**Other agents** (codex, cursor, opencode, pi) each have their own MCP config
file and schema — **check the agent's current docs**, they drift. The server to
add is always the same command + args as above. Most accept the standard
`mcpServers` shape straight from `playwright.json`; e.g. Cursor's
`~/.cursor/mcp.json` and project `.mcp.json` files use exactly that shape. Codex
uses TOML (`~/.codex/config.toml`):

```toml
[mcp_servers.playwright]
command = "playwright-mcp"
args = ["--headless", "--browser", "chromium", "--isolated"]
```

### Requirements / gotchas

- **`node` and the pnpm global bin must be on the agent's runtime PATH.**
  `playwright-mcp` is a Node script; if the agent is launched from a context
  without mise's node on PATH, the server fails to spawn. Launching agents from
  your normal login shell (mise-activated) satisfies this.
- **Headless only.** Default is *headed*; the `--headless` flag is required on a
  monitor-less box.
- **`--isolated`** keeps the browser profile in memory — clean per-run state,
  ideal for tests, but no persistent logins. Drop it if an agent needs a
  persistent profile.
- Verified working headless (served localhost app → click → DOM assert →
  screenshot) with `@playwright/mcp` 0.0.78 on Node 24.
