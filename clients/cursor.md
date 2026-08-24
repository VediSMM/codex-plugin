# Cursor

**Compatibility:** Cursor is compatible with VediSMM 0.2.0. Cursor documents remote Streamable HTTP MCP with OAuth; the MCP authorization contract requires PKCE.

## Prerequisites

- A current Cursor installation with MCP enabled.
- A VediSMM account that can complete browser OAuth.

## Connect

Add VediSMM to the global `~/.cursor/mcp.json` file, or use `.cursor/mcp.json` for one project:

```json
{
  "mcpServers": {
    "vedismm": {
      "url": "https://mcp.vedismm.ru/mcp"
    }
  }
}
```

Open **Customize** → **MCP**, enable `vedismm`, and follow Cursor's browser OAuth prompt. This is the MCP authorization-code flow with PKCE; no static credential fields are needed for VediSMM.

Copy the complete [canonical `social-publishing` skill directory](../plugins/vedismm/skills/social-publishing/SKILL.md), including its `references/` directory, to `.cursor/skills/social-publishing/`. Cursor discovers it as an Agent Skill.

## Smoke test

> Show my VediSMM projects and their versions. Do not publish.

For connection or tool failures, use [canonical troubleshooting](../plugins/vedismm/skills/social-publishing/references/troubleshooting.md).

## Official sources

Verified: 2026-08-25.

- [Cursor MCP transports, configuration, and OAuth](https://cursor.com/docs/mcp)
- [Cursor Agent Skills](https://cursor.com/docs/skills)
- [MCP authorization and PKCE](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)
