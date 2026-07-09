#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://chatgpt.com/codex/install.sh | sh
curl -fsSL https://claude.ai/install.sh | bash
curl https://cursor.com/install -fsS | bash
curl -fsSL https://opencode.ai/install | bash

pnpm add -g @earendil-works/pi-coding-agent
pnpm add -g t3@latest

codex --version
claude --version
agent --version
opencode --version
pi --version
t3 --version
herdr --version
