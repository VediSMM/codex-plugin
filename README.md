# VediSMM Codex Plugin

VediSMM prepares social publication drafts through the VediSMM MCP server. It uses OAuth over Streamable HTTP at `https://mcp.vedismm.ru/mcp`; social credentials, project profiles, policies, and approval records remain server-side.

## What it does

The `social-publishing` skill resolves a project, reads its current server profile and constraints, prepares variants and media, creates a draft, runs preflight, displays the immutable summary, requests immediate confirmation, then publishes or schedules. It can also read durable publication status. A draft or an old confirmation never authorizes a changed snapshot.

## Starter scenarios

The plugin UI shows the first three prompts because the manifest permits at most three visible starters. All four supported scenarios are:

1. **Project list (read-only):** “Show my VediSMM projects and their versions. Do not publish.”
2. **VediSMM news draft:** “Prepare a VediSMM news draft without publishing it.”
3. **KursHub scheduled draft:** “Prepare a scheduled KursHub draft and show its preflight.”
4. **Publication status:** “Use $social-publishing to check the status of my VediSMM publication without publishing.”

## Local context

`.vedismm/project.yaml` is optional and may contain only `default_project` and `repository_context`. It must not contain policy documents, OAuth credentials, account IDs, approval tokens, or other secrets. Current project policy, profile version, destinations, and constraints always come from the VediSMM server.

## Safety

Before `publish_publication` or `schedule_publication`, the skill obtains and displays an immutable preflight snapshot. It asks for an immediate confirmation of that exact snapshot and uses the corresponding approval token only as a one-time write input. It never uses a personal access token, `request_api`, or a generic API proxy.

## Links

- Website: https://vedismm.ru
- Privacy: https://vedismm.ru/privacy
- Terms: https://vedismm.ru/terms
- Support: support@vedismm.ru
- Source: https://github.com/VediSMM/codex-plugin
