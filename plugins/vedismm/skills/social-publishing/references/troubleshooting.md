# Troubleshooting

- If a required tool is unavailable, stop before workflow execution and report the missing tool names with the minimum MCP contract version, `1.2.0`.
- If OAuth is required, complete the VediSMM OAuth flow for the MCP server; do not collect credentials in chat or local configuration.
- If a project or destination is missing, use `list_projects` or `list_destinations` for the current identity instead of guessing identifiers.
- If preflight reports blockers, revise the draft or media, create a new preflight, and display the new immutable summary.
- If a write is rejected because its approval is stale, consumed, or mismatched, do not retry it. Create a new preflight and request immediate confirmation for that exact result.
