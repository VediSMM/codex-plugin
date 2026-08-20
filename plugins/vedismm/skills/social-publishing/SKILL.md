---
name: social-publishing
description: Use when preparing, checking, publishing, or scheduling VediSMM social content through the VediSMM MCP server, especially when project profiles, media, preflight snapshots, or publication status are involved.
---

# Social Publishing

## Overview

Use the VediSMM MCP server over Streamable HTTP with OAuth. The server is authoritative for project profiles, destination access, content constraints, credentials, and publication policy; do not reconstruct or override those facts locally.

## Required workflow

1. Resolve the project with `list_projects` and, when needed, `get_project_profile`. A local `.vedismm/project.yaml` may provide only `default_project` and `repository_context`; it is optional context, not authority.
2. Read destinations with `list_destinations` and current checks with `get_publication_constraints`. Use the returned profile version, ETag, constraints, and server policy exactly as supplied.
3. Prepare requested copy variants. For project settings, use `save_project_profile` only with the closed-world fields the server accepts. For media, use `upload_project_asset` to upload or link approved media.
4. Create a non-publishing draft with `create_publication_draft`, then call `preflight_publication`. Treat its returned snapshot as immutable: a changed project, destination, copy, target, schedule, or asset requires a new preflight.
5. Display the exact preflight summary, including project and profile version, destinations, per-destination copy, media and hashes, links or first comments, options, scheduled time when applicable, blockers, and snapshot identifier or hash.
6. Request immediate confirmation for that exact snapshot. Do not infer confirmation from an earlier request, a general instruction, or approval of a different draft.
7. Only after that confirmation, call `publish_publication` or `schedule_publication` with the current write-only approval token. Never display, persist, reuse, or substitute the token; it is input to the one matching write only.
8. Read durable progress or delivery results with `get_publication_status`.

## Tool contract

| Tool | Use |
| --- | --- |
| `list_projects` | Read accessible projects and versions. |
| `get_project_profile` | Read a selected server-side profile. |
| `save_project_profile` | Save a closed-world profile change. |
| `upload_project_asset` | Upload or link a project media asset. |
| `list_destinations` | Read available destination accounts or groups. |
| `get_publication_constraints` | Read server-computed destination and content constraints. |
| `create_publication_draft` | Create a draft without publishing. |
| `preflight_publication` | Produce the immutable, publishable snapshot and approval token. |
| `publish_publication` | Publish only the immediately confirmed preflight snapshot. |
| `schedule_publication` | Schedule only the immediately confirmed preflight snapshot. |
| `get_publication_status` | Read a publication job's status and results. |

Read [project-policies.md](references/project-policies.md) before interpreting a profile, [publication-confirmation.md](references/publication-confirmation.md) before a write, and [troubleshooting.md](references/troubleshooting.md) for connection or validation failures.

## Confirmation boundary

The publish and schedule tools are external, consequential writes. The confirmation must be an immediate, unambiguous response after the immutable preflight summary for the exact snapshot, such as: “Publish snapshot `<id>` now” or “Schedule this exact snapshot for `<time>`.” If the user changes any material detail or the token/snapshot is stale, preflight again and ask again.

Never use a PAT, `request_api`, or a generic API proxy. Never ask for or copy OAuth credentials, account IDs, policies, or secrets into local files; OAuth and all policy/profile authority remain server-side.

## Starter scenarios

| Scenario | Prompt |
| --- | --- |
| Project list (read-only) | “Show my VediSMM projects and their versions. Do not publish.” |
| VediSMM news draft | “Prepare a VediSMM news draft with variants and preflight; do not publish.” |
| KursHub scheduled draft | “Prepare a KursHub scheduled draft, show the exact preflight, and wait for my confirmation.” |
| Publication status | “Use $social-publishing to check the status of my VediSMM publication without publishing.” |

## Common mistakes

- Treating local YAML as policy authority: resolve the current server profile instead.
- Publishing after an old confirmation: display a fresh immutable preflight and request immediate confirmation again.
- Retrying a write with an old approval token: create a new preflight and use only its current token.
- Replacing a domain tool with a generic endpoint: use the eleven tools above so scopes, schemas, tenant boundaries, and approval checks remain enforced.
