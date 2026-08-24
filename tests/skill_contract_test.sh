#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: tests/skill_contract_test.sh [package-root]' >&2
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
skill_path = root / "plugins/vedismm/skills/social-publishing/SKILL.md"
confirmation_reference_path = root / "plugins/vedismm/skills/social-publishing/references/publication-confirmation.md"
expected_tools = {
    "list_projects",
    "get_project_profile",
    "save_project_profile",
    "upload_project_asset",
    "list_destinations",
    "get_publication_constraints",
    "create_publication_draft",
    "preflight_publication",
    "publish_publication",
    "schedule_publication",
    "delete_publication_everywhere",
    "get_publication_status",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    skill = skill_path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail("missing social-publishing SKILL.md")
try:
    confirmation_reference = confirmation_reference_path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail("missing publication confirmation reference")


def section(heading: str) -> str:
    match = re.search(rf"(?ms)^## {re.escape(heading)}\n(.*?)(?=^## |\Z)", skill)
    if match is None:
        fail(f"missing {heading!r} section")
    return match.group(1)


workflow = section("Required workflow")
tool_contract = section("Tool contract")
confirmation_boundary = section("Confirmation boundary")
tool_rows = []
for line in tool_contract.splitlines():
    cells = [cell.strip() for cell in line.split("|")]
    if len(cells) < 3:
        continue
    first_cell = cells[1]
    match = re.fullmatch(r"`([a-z_]+)`", first_cell)
    if match is not None:
        tool_rows.append(match.group(1))

if set(tool_rows) != expected_tools or len(tool_rows) != len(expected_tools):
    fail(f"tool contract must contain exactly the 12 domain tools, got {tool_rows!r}")

def ordered_after(start: int, text: str, label: str) -> int:
    index = workflow.casefold().find(text.casefold(), start)
    if index == -1:
        fail(f"workflow must include {label}")
    return index


draft_index = ordered_after(0, "create_publication_draft", "draft creation")
preflight_index = ordered_after(draft_index + 1, "preflight_publication", "preflight after draft creation")
confirmation_index = ordered_after(preflight_index + 1, "immediate confirmation", "immediate confirmation after preflight")
ordered_after(confirmation_index + 1, "publish_publication", "publish after confirmation")
ordered_after(confirmation_index + 1, "schedule_publication", "schedule after confirmation")

for phrase, label in (
    ("tracking_plan", "approved tracking plan"),
    ("default", "default-on tracking behavior"),
    ("explicit opt-out", "explicit tracking opt-out"),
    ("delete_publication_everywhere", "delete-everywhere tool"),
    ("separate", "separate delete and replacement confirmations"),
):
    if phrase not in workflow.casefold():
        fail(f"workflow must include {label}")

workflow_lower = workflow.casefold()
for phrase, label in (
    ("get_project_profile", "server project profile"),
    ("get_publication_constraints", "server constraints"),
    ("server policy", "server policy authority"),
    ("immutable", "immutable preflight snapshot"),
    ("requires a new preflight", "fresh preflight after material change"),
    ("write-only approval token", "write-only approval token"),
    ("never display, persist, reuse", "one-time approval-token boundary"),
):
    if phrase not in workflow_lower:
        fail(f"workflow must preserve {label}")

if "request immediate confirmation for that exact snapshot" not in workflow_lower:
    fail("workflow must require immediate confirmation for the exact current snapshot")

confirmation_boundary_lower = confirmation_boundary.casefold()
for phrase, label in (
    ("immediate, unambiguous response", "immediate confirmation"),
    ("exact snapshot", "exact snapshot binding"),
    ("publish snapshot `<id>` now", "exact publish action"),
    ("schedule this exact snapshot for `<time>`", "exact schedule action and time"),
):
    if phrase not in confirmation_boundary_lower:
        fail(f"confirmation boundary must preserve {label}")

confirmation_reference_lower = confirmation_reference.casefold()
for phrase, label in (
    ("immediate confirmation that identifies the exact current snapshot and action", "exact current snapshot and action"),
    ("confirmation for a different time is insufficient", "exact schedule time"),
    ("delete_everywhere", "delete preflight action"),
    ("separate immediate confirmation", "separate delete confirmation"),
    ("fresh preflight", "fresh replacement preflight"),
):
    if phrase not in confirmation_reference_lower:
        fail(f"publication confirmation reference must preserve {label}")

skill_lower = skill.casefold()
required_prohibition = "never use a pat, `request_api`, or a generic api proxy"
if required_prohibition not in skill_lower:
    fail("skill must prohibit PAT, request_api, and generic API proxy fallbacks")
if "never ask for or copy oauth credentials" not in skill_lower:
    fail("skill must prohibit credential fallback")
if skill_lower.count("`request_api`") != 1:
    fail("request_api may appear only in the explicit prohibition")
if skill_lower.count("generic api proxy") != 1:
    fail("generic API proxy may appear only in the explicit prohibition")
if skill_lower.count("pat") != 1:
    fail("PAT may appear only in the explicit prohibition")

print("skill_contract_test.sh: PASS")
PY
