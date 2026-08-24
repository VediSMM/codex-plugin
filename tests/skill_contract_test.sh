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
import json
import re
import sys
from pathlib import Path


root = Path(sys.argv[1]).resolve()
skill_path = root / "plugins/vedismm/skills/social-publishing/SKILL.md"
confirmation_reference_path = root / "plugins/vedismm/skills/social-publishing/references/publication-confirmation.md"
readme_path = root / "README.md"
compatibility_path = root / "compatibility.json"


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
try:
    readme = readme_path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail("missing README.md")
try:
    compatibility = json.loads(compatibility_path.read_text(encoding="utf-8"))
except FileNotFoundError:
    fail("missing compatibility.json")
except json.JSONDecodeError as error:
    fail(f"invalid compatibility.json: {error}")

expected_tools = compatibility.get("required_tools")
if not isinstance(expected_tools, list) or not all(isinstance(tool, str) for tool in expected_tools):
    fail("compatibility.json must define required_tools as a list of names")

install_block = re.search(r"(?ms)^## Install\n(.*?)(?=^## |\Z)", readme)
if install_block is None:
    fail("README must contain a self-contained Install section")
install = install_block.group(1)
for command in (
    "codex plugin marketplace add VediSMM/codex-plugin",
    "codex plugin add vedismm@vedismm",
):
    if install.count(command) != 1:
        fail(f"README Install must contain the exact supported command once: {command}")
for phrase, label in (
    ("start a new task", "new-task activation boundary"),
    ("oauth", "first-use OAuth connection"),
):
    if phrase not in install.casefold():
        fail(f"README Install must explain {label}")

frontmatter = re.match(r"(?s)\A---\n(.*?)\n---\n", skill)
if frontmatter is None:
    fail("skill must contain YAML frontmatter")
description_match = re.search(r"(?m)^description:\s*(.+)$", frontmatter.group(1))
if description_match is None:
    fail("skill frontmatter must contain a description")
description = description_match.group(1).casefold()
for phrase, label in (
    ("deleting", "direct remote deletion discoverability"),
    ("replacing", "direct remote replacement discoverability"),
    ("remote publications", "remote publication intent"),
):
    if phrase not in description:
        fail(f"skill description must include {label}")


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

if set(tool_rows) != set(expected_tools) or len(tool_rows) != len(expected_tools):
    fail(f"tool contract must contain every required tool exactly once, got {tool_rows!r}")

for client_specific_assumption in (
    "codex must",
    "chatgpt must",
    "codex plugin",
    "chatgpt plugin",
):
    if client_specific_assumption in workflow.casefold():
        fail(f"workflow must be client-neutral, not assume: {client_specific_assumption}")

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
    ("excluded targets", "safe excluded deletion targets"),
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
    ("excluded targets and their safe reasons", "safe excluded deletion target summary"),
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

PY

COMPAT="$package_root/compatibility.json"
SKILL="$package_root/plugins/vedismm/skills/social-publishing/SKILL.md"
RENDERER="$package_root/scripts/render_standalone_skill.sh"
DIST="$package_root/dist/social-publishing.md"
diff -u \
  <(jq -r '.required_tools[]' "$COMPAT" | sort) \
  <(sed -n 's/^| `\([^`]*\)` |.*$/\1/p' "$SKILL" | sort)

if [[ ! -f "$DIST" ]]; then
  printf 'FAIL: missing standalone distribution: %s\n' "$DIST" >&2
  exit 1
fi

if [[ ! -f "$RENDERER" ]]; then
  printf 'FAIL: missing standalone renderer: %s\n' "$RENDERER" >&2
  exit 1
fi

before_sha="$(shasum -a 256 "$DIST" | awk '{print $1}')"
bash "$RENDERER" "$package_root"
first_sha="$(shasum -a 256 "$DIST" | awk '{print $1}')"
if [[ "$before_sha" != "$first_sha" ]]; then
  printf '%s\n' 'FAIL: standalone distribution changed when regenerated' >&2
  exit 1
fi

bash "$RENDERER" "$package_root"
second_sha="$(shasum -a 256 "$DIST" | awk '{print $1}')"
if [[ "$first_sha" != "$second_sha" ]]; then
  printf '%s\n' 'FAIL: standalone distribution is not deterministic across renders' >&2
  exit 1
fi

printf '%s\n' 'skill_contract_test.sh: PASS'
