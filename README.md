# VediSMM Agent Package

VediSMM is a universal agent package: a native Codex/ChatGPT plugin plus a portable canonical skill and rendered standalone skill for compatible remote-MCP clients. It prepares social publication drafts through OAuth over Streamable HTTP at `https://mcp.vedismm.ru/mcp`; social credentials, project profiles, policies, and approval records remain server-side.

Client compatibility is documentation-based; live OAuth acceptance is still pending for each external client surface.

Local integration readiness was verified on 2026-08-25 against the VediSMM server. The bidirectional parity gate covers the exact twelve-tool catalog, MCP protocol pair, and authoritative MCP contract version; accompanying local regressions cover REST/OpenAPI independently, security/OWASP, and native MySQL races. This is not evidence of merged or deployed release state, live third-party OAuth acceptance, or catalog availability.

## Cross-repository compatibility

The public package contains a minimal [MCP contract snapshot](contracts/server-mcp-contract.json) exported from private server commit `2a58555869d2667ce77bb1e245a24d1b24698fd7`. It contains only the source anchor, authoritative MCP contract version, supported protocol versions, and public tool names. Package CI compares `compatibility.json` with that local snapshot and proves that a checked-in tool-drift mutation fails. It checks out no private repository and requires no Actions secret, so the same gate runs for public pull requests.

The private server CI remains authoritative: it checks the real `McpKernel` and production `ToolRegistry` against an exact package commit. Contract updates therefore follow this order: commit and review the private server source anchor; export only those public values into the package snapshot; run and publish the package checks; then update the private server workflow to the resulting exact package SHA. Package CI proves internal parity with the reviewed export, but cannot independently authenticate or regenerate private source; review of the source anchor plus the private server gate provides that trust boundary.

## Install

### Codex CLI

Install the public Git marketplace and the plugin on each device:

```bash
codex plugin marketplace add VediSMM/codex-plugin
codex plugin add vedismm@vedismm
```

Start a new task so Codex loads the plugin. On first use, choose VediSMM and complete the OAuth connection in the browser; do not paste an API key into the chat or repository.

### ChatGPT

Open **Plugins**, install **VediSMM** when it is available to your account or workspace, then start a new chat and complete the browser OAuth connection when prompted.

## Client guides

- [Codex and ChatGPT](clients/codex-chatgpt.md)
- [Claude Code](clients/claude.md)
- [Cursor](clients/cursor.md)
- [Other MCP clients](clients/generic-mcp.md)

## Invoke by surface

- **Codex CLI:** invoke `$social-publishing`.
- **ChatGPT:** type `@`, select **VediSMM**, then select the bundled `social-publishing` skill.
- **Claude Code or Cursor:** install and invoke the canonical skill as described in the client guide.
- **Other compatible clients:** load the canonical skill or standalone distribution using the client's documented instruction mechanism.

## What it does

The `social-publishing` skill resolves a project, reads its current server profile and constraints, prepares variants and media, creates a tracked-by-default draft, runs preflight, displays the immutable summary, requests immediate confirmation, then publishes or schedules. It can also delete an existing remote publication after its own exact confirmation and read durable job status. A draft or an old confirmation never authorizes a changed snapshot.

## Starter scenarios

The plugin UI shows the first three prompts because the manifest permits at most three visible starters. All four supported scenarios are:

1. **Project list (read-only):** “Show my VediSMM projects and their versions. Do not publish.”
2. **VediSMM news draft:** “Prepare a VediSMM news draft without publishing it.”
3. **KursHub scheduled draft:** “Prepare a scheduled KursHub draft and show its preflight.”
4. **Publication status:** “Check the status of my VediSMM publication without publishing.”

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
