#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: tests/client_guides_test.sh [package-root]' >&2
  exit 2
fi

package_root="${1:-${PACKAGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"

if [[ ! -d "$package_root" ]]; then
  printf 'FAIL: package root does not exist: %s\n' "$package_root" >&2
  exit 1
fi

python3 - "$package_root" <<'PY'
import re
import sys
from pathlib import Path


root = Path(sys.argv[1]).resolve()
guide_paths = (
    "clients/codex-chatgpt.md",
    "clients/claude.md",
    "clients/cursor.md",
    "clients/generic-mcp.md",
)


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


for relative_path in guide_paths:
    path = root / relative_path
    try:
        guide = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"missing {relative_path}")

    lower = guide.casefold()
    if "https://mcp.vedismm.ru/mcp" not in guide:
        fail(f"{relative_path} must contain the canonical MCP URL")
    if "oauth" not in lower or "pkce" not in lower:
        fail(f"{relative_path} must identify the OAuth/PKCE connection")
    if re.search(r"\bpat\b|personal access token", lower):
        fail(f"{relative_path} must not contain PAT fallback instructions")
    if not re.search(
        r"\]\(\.\./(?:plugins/vedismm/skills/social-publishing/SKILL\.md|dist/social-publishing\.md)\)",
        guide,
    ):
        fail(f"{relative_path} must link the canonical skill or standalone distribution")
    if "compatibility:" not in lower or "vedismm 0.2.0" not in lower:
        fail(f"{relative_path} must state explicit VediSMM 0.2.0 compatibility")
    if "verified: 2026-08-25" not in lower:
        fail(f"{relative_path} must record the documentation verification date")
    if "../plugins/vedismm/skills/social-publishing/references/troubleshooting.md" not in guide:
        fail(f"{relative_path} must link canonical troubleshooting")
    if "Show my VediSMM projects and their versions. Do not publish." not in guide:
        fail(f"{relative_path} must include the read-only smoke prompt")
    for forbidden_heading in ("## Required workflow", "## Tool contract", "## Confirmation boundary"):
        if forbidden_heading.casefold() in lower:
            fail(f"{relative_path} must not duplicate {forbidden_heading}")
    if re.search(r"(?m)^\|\s*`(?:list_projects|publish_publication|schedule_publication)`", guide):
        fail(f"{relative_path} must not copy the canonical tool table")
    if len(guide) > 5000:
        fail(f"{relative_path} must remain a thin client guide")

source_requirements = {
    "clients/codex-chatgpt.md": (
        "https://learn.chatgpt.com/docs/plugins",
        "https://learn.chatgpt.com/docs/extend/mcp",
    ),
    "clients/claude.md": (
        "https://code.claude.com/docs/en/mcp",
        "https://code.claude.com/docs/en/skills",
    ),
    "clients/cursor.md": (
        "https://cursor.com/docs/mcp",
        "https://cursor.com/docs/skills",
    ),
    "clients/generic-mcp.md": (
        "https://modelcontextprotocol.io/specification/2026-07-28/basic/transports",
        "https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization",
    ),
}

for relative_path, urls in source_requirements.items():
    guide = (root / relative_path).read_text(encoding="utf-8")
    for url in urls:
        if url not in guide:
            fail(f"{relative_path} must cite official source {url}")

readme = (root / "README.md").read_text(encoding="utf-8")
for relative_path in guide_paths:
    link = relative_path.removeprefix("clients/")
    if f"](clients/{link})" not in readme:
        fail(f"README must link {relative_path}")

print("client_guides_test.sh: PASS")
PY
