# Project policy authority

Project profiles, destination access, constraints, and credentials are maintained by VediSMM on the server. Read them with the MCP tools for the active OAuth identity; do not infer them from a repository, draft, or earlier chat turn.

Optional local context is limited to `.vedismm/project.yaml`:

```yaml
default_project: "vedismm"
repository_context: "Contains source material for this publication request."
```

These two fields help select context only. Do not add policies, OAuth credentials, account IDs, approval tokens, or secrets to this file. A server-returned profile version or ETag remains authoritative and must be carried into dependent requests.
