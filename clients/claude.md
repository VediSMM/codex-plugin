# Claude Code

**Compatibility:** Claude Code is compatible with VediSMM 0.2.0. Anthropic documents remote HTTP MCP servers and browser OAuth; the MCP authorization contract requires PKCE.

## Prerequisites

- A current Claude Code installation.
- A VediSMM account that can complete browser OAuth.

## Connect

Add the remote server using Anthropic's documented HTTP transport form:

```bash
claude mcp add --transport http vedismm https://mcp.vedismm.ru/mcp
```

Start Claude Code, run `/mcp`, select `vedismm`, and follow the browser authentication steps. This is the MCP OAuth authorization-code flow with PKCE; keep credentials out of the project configuration.

Copy the complete [canonical `social-publishing` skill directory](../plugins/vedismm/skills/social-publishing/SKILL.md), including its `references/` directory, to `.claude/skills/social-publishing/`. Claude Code discovers that skill and exposes it as `/social-publishing`.

## Smoke test

> Show my VediSMM projects and their versions. Do not publish.

For connection or tool failures, use [canonical troubleshooting](../plugins/vedismm/skills/social-publishing/references/troubleshooting.md).

## Official sources

Verified: 2026-08-25.

- [Anthropic: connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)
- [Anthropic: extend Claude Code with skills](https://code.claude.com/docs/en/skills)
- [MCP authorization and PKCE](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)
