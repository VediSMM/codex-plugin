# VediSMM Codex Plugin

VediSMM prepares social publication drafts through the VediSMM MCP server. It uses OAuth over Streamable HTTP at `https://mcp.vedismm.ru/mcp`; social credentials, project profiles, policies, and approval records remain server-side.

## Install

Install the public Git marketplace and the plugin on each device:

```bash
codex plugin marketplace add VediSMM/codex-plugin
codex plugin add vedismm@vedismm
```

Start a new task so Codex loads the plugin. On first use, choose VediSMM and complete the OAuth connection in the browser; do not paste an API key into the chat or repository.

## Client guides

- [Codex and ChatGPT](clients/codex-chatgpt.md)
- [Claude Code](clients/claude.md)
- [Cursor](clients/cursor.md)
- [Other MCP clients](clients/generic-mcp.md)

## What it does

The `social-publishing` skill resolves a project, reads its current server profile and constraints, prepares variants and media, creates a tracked-by-default draft, runs preflight, displays the immutable summary, requests immediate confirmation, then publishes or schedules. It can also delete an existing remote publication after its own exact confirmation and read durable job status. A draft or an old confirmation never authorizes a changed snapshot.

## Starter scenarios

The plugin UI shows the first three prompts because the manifest permits at most three visible starters. All four supported scenarios are:

1. **Project list (read-only):** “Show my VediSMM projects and their versions. Do not publish.”
2. **VediSMM news draft:** “Prepare a VediSMM news draft without publishing it.”
3. **KursHub scheduled draft:** “Prepare a scheduled KursHub draft and show its preflight.”
4. **Publication status:** “Use $social-publishing to check the status of my VediSMM publication without publishing.”

## Local context

`.vedismm/project.yaml` is optional and may contain only `default_project` and `repository_context`. It must not contain policy documents, OAuth credentials, account IDs, approval tokens, or other secrets. Current project policy, profile version, destinations, and constraints always come from the VediSMM server.

## Safety

Before `publish_publication`, `schedule_publication`, or `delete_publication_everywhere`, the skill obtains and displays an immutable preflight snapshot. A delete preflight includes both deletable targets and any excluded targets with safe reasons. The skill asks for an immediate confirmation of that exact snapshot and uses the corresponding approval token only as a one-time write input. Delete and replacement publish use separate confirmations and fresh preflights. It never uses a personal access token, `request_api`, or a generic API proxy.

## Links

- Website: https://vedismm.ru
- Privacy: https://vedismm.ru/privacy
- Terms: https://vedismm.ru/terms
- Support: support@vedismm.ru
- Source: https://github.com/VediSMM/codex-plugin
