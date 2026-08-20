# Immutable publication confirmation

Call `preflight_publication` before every publish or schedule action. Present the returned snapshot without silently changing copy, media, destinations, links, options, or time.

Ask for an immediate confirmation that identifies the exact current snapshot and action. A previous “publish it,” approval of a draft, or confirmation for a different time is insufficient. On any material change or expired/consumed approval token, create a new preflight and ask again.

Pass the approval token only as a write input to the matching `publish_publication` or `schedule_publication` call. It is write-only: never quote it, save it, reuse it, or treat it as user confirmation.
