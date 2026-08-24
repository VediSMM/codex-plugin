# Codex and ChatGPT

**Compatibility:** Compatible with VediSMM 0.2.0 in Codex CLI and on Codex/ChatGPT surfaces where the VediSMM plugin is available. ChatGPT web must offer the plugin to your account or workspace; if it does not, that surface cannot use this package yet.

## Prerequisites

- A supported Codex or ChatGPT plugin surface.
- A VediSMM account that can complete browser OAuth.

## Connect

For Codex CLI, preserve the package's public Git marketplace installation path:

```bash
codex plugin marketplace add VediSMM/codex-plugin
codex plugin add vedismm@vedismm
```

Start a new task after installation. In ChatGPT or the ChatGPT desktop app, open **Plugins**, install **VediSMM** if it is available to your account, and start a new chat.

The plugin supplies the Streamable HTTP endpoint `https://mcp.vedismm.ru/mcp`. When VediSMM requests authentication, choose it and complete the browser OAuth authorization-code flow. OpenAI's MCP OAuth flow uses PKCE; no OAuth secret belongs in local configuration.

The plugin loads the [canonical `social-publishing` skill](../plugins/vedismm/skills/social-publishing/SKILL.md) in the new task. Invoke `$social-publishing` explicitly if automatic selection does not occur.

## Smoke test

> Show my VediSMM projects and their versions. Do not publish.

For connection or tool failures, use [canonical troubleshooting](../plugins/vedismm/skills/social-publishing/references/troubleshooting.md).

## Official sources

Verified: 2026-08-25.

- [OpenAI plugin installation and activation](https://learn.chatgpt.com/docs/plugins)
- [OpenAI MCP transport, configuration, and OAuth](https://learn.chatgpt.com/docs/extend/mcp)
- [OpenAI plugin OAuth and PKCE contract](https://developers.openai.com/plugins/build/auth)
