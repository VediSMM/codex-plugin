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
import json
import re
import sys
from pathlib import Path


root = Path(sys.argv[1]).resolve()
compatibility = json.loads((root / "compatibility.json").read_text(encoding="utf-8"))
canonical_tools = compatibility.get("required_tools")
if not isinstance(canonical_tools, list) or not all(isinstance(tool, str) for tool in canonical_tools):
    raise SystemExit("FAIL: compatibility.json must define required_tools as a list of names")
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
    section_headings = re.findall(r"(?m)^## (.+)$", guide)
    expected_headings = ["Prerequisites", "Connect", "Smoke test", "Official sources"]
    if section_headings != expected_headings:
        fail(f"{relative_path} must use only the thin guide section shape, got {section_headings!r}")
    tool_mentions = [tool for tool in canonical_tools if re.search(rf"\b{re.escape(tool)}\b", guide)]
    if tool_mentions:
        fail(f"{relative_path} must not duplicate a partial workflow or tool catalog: {tool_mentions!r}")
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
readme_lower = readme.casefold()
for relative_path in guide_paths:
    link = relative_path.removeprefix("clients/")
    if f"](clients/{link})" not in readme:
        fail(f"README must link {relative_path}")

codex_guide = (root / "clients/codex-chatgpt.md").read_text(encoding="utf-8")
if not re.search(r"Codex CLI[^\n]*`\$social-publishing`", codex_guide):
    fail("Codex/ChatGPT guide must label $social-publishing as Codex CLI invocation")
if not re.search(r"ChatGPT[^\n]*`@`[^\n]*VediSMM[^\n]*social-publishing", codex_guide):
    fail("Codex/ChatGPT guide must document ChatGPT @ selection separately")

for phrase, label in (
    ("native codex/chatgpt plugin", "native OpenAI plugin overview"),
    ("portable canonical skill", "portable canonical skill overview"),
    ("standalone skill", "standalone distribution overview"),
    ("compatible remote-mcp clients", "compatible remote MCP client overview"),
    ("documentation-based", "documentation-based compatibility qualifier"),
    ("live oauth acceptance is still pending", "pending live OAuth qualifier"),
):
    if phrase not in readme_lower:
        fail(f"README must include {label}")

if "publication status (codex cli)" in readme_lower:
    fail("README must not present a Codex-only status prompt as a universal scenario")
if not re.search(r"Codex CLI[^\n]*`\$social-publishing`", readme):
    fail("README must label $social-publishing as Codex CLI invocation")
if not re.search(r"ChatGPT[^\n]*`@`[^\n]*VediSMM[^\n]*social-publishing", readme):
    fail("README must label ChatGPT @ plugin/skill selection")

repository_url = "https://github.com/VediSMM/codex-plugin"
if readme.count(repository_url) != 1:
    fail(f"README must contain the exact repository URL once: {repository_url}")
install_match = re.search(r"(?ms)^## Install\n(.*?)(?=^## |\Z)", readme)
if install_match is None:
    fail("README must contain an Install section")
install = install_match.group(1)
install_commands = (
    "codex plugin marketplace add VediSMM/codex-plugin",
    "codex plugin add vedismm@vedismm",
)
command_positions = []
for command in install_commands:
    if install.count(command) != 1:
        fail(f"README Install must contain the exact command once: {command}")
    command_positions.append(install.index(command))
if command_positions != sorted(command_positions):
    fail("README Install must add the VediSMM marketplace before installing vedismm@vedismm")

print("client_guides_test.sh: PASS")
PY
