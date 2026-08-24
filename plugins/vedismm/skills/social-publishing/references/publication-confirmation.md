# Immutable publication confirmation

Call `preflight_publication` before every publish or schedule action. Present the returned snapshot without silently changing copy, media, destinations, links, options, or time.

Ask for an immediate confirmation that identifies the exact current snapshot and action. A previous “publish it,” approval of a draft, or confirmation for a different time is insufficient. On any material change or expired/consumed approval token, create a new preflight and ask again.

Pass the approval token only as a write input to the matching `publish_publication` or `schedule_publication` call. It is write-only: never quote it, save it, reuse it, or treat it as user confirmation.

For remote deletion, call `preflight_publication` with action `delete_everywhere`, present the exact deletion targets, and ask for a separate immediate confirmation before calling `delete_publication_everywhere`. Wait until the durable deletion job succeeds before preparing the replacement publication. Then obtain a fresh preflight for the replacement and ask for a second, separate immediate confirmation. Never reuse the delete approval token or infer publish approval from the deletion confirmation.

Tracked preflight includes the approved `tracking_plan`. Treat its targets and destination digests as immutable snapshot data. New MCP drafts use `shorten_links=true` and `add_source=true` by default; set both to `false` only for an explicit opt-out.
