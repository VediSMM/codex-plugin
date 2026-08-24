# Other MCP clients

**Compatibility:** A client is compatible with VediSMM 0.2.0 only if it implements remote Streamable HTTP MCP and the MCP OAuth authorization-code flow with PKCE/S256. A client without both capabilities is **not compatible with VediSMM 0.2.0**.

## Prerequisites

Before continuing, verify those two capabilities in the client's current official documentation. A generic MCP configuration format does not exist, so use only fields that the client itself documents.

## Connect

Enter these values in the client's remote MCP setup:

- Name: `vedismm`
- Transport: Streamable HTTP
- URL: `https://mcp.vedismm.ru/mcp`
- Authentication: MCP OAuth with browser authorization and PKCE/S256

Start the client's documented connect or authenticate action and finish the OAuth flow in the browser. If the client asks for an unsupported credential field instead of launching MCP OAuth, stop: it is not compatible with VediSMM 0.2.0.

If the client supports Agent Skills, install the complete [canonical `social-publishing` skill directory](../plugins/vedismm/skills/social-publishing/SKILL.md), including its references. Otherwise, load the [standalone skill](../dist/social-publishing.md) as client instructions. Do not recreate the workflow in client configuration.

## Smoke test

> Show my VediSMM projects and their versions. Do not publish.

For connection or tool failures, use [canonical troubleshooting](../plugins/vedismm/skills/social-publishing/references/troubleshooting.md).

## Official sources

Verified: 2026-08-25.

- [MCP Streamable HTTP transport](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports)
- [MCP OAuth authorization and PKCE](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)
