#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: tests/workflow_contract_test.sh [package-root]' >&2
  exit 2
fi

package_root="${1:-${PACKAGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
workflow_path="$package_root/.github/workflows/contract.yml"

python3 - "$workflow_path" <<'PY'
import re
import sys
from pathlib import Path


workflow_path = Path(sys.argv[1])


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    workflow = workflow_path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail(f"missing package contract workflow: {workflow_path}")

external_checkouts = re.findall(r"(?m)^\s+repository:\s*([^#\n]+)", workflow)
if external_checkouts:
    fail(
        "public package CI must not check out external repositories: "
        f"{[value.strip() for value in external_checkouts]!r}"
    )
if re.search(r"\$\{\{\s*secrets\.", workflow, flags=re.IGNORECASE):
    fail("public package CI must not reference Actions secrets")
if "VEDISMM_SERVER_DIR" in workflow:
    fail("public package CI must not require a private server directory")
if workflow.count("run: bash tests/server_compatibility_test.sh") != 1:
    fail("public package CI must run the local public-snapshot compatibility test exactly once")

print("workflow_contract_test.sh: PASS (public PR workflow is self-contained and secretless)")
PY
