#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
  printf '%s\n' 'usage: tests/server_compatibility_test.sh' >&2
  exit 2
fi

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
snapshot_path="$package_root/contracts/server-mcp-contract.json"
compatibility_path="$package_root/compatibility.json"
drift_path="$package_root/tests/fixtures/tool-drift/compatibility.json"

if [[ ! -f "$snapshot_path" ]]; then
  printf 'FAIL: missing public server MCP contract snapshot required for secretless package CI: %s\n' \
    "$snapshot_path" >&2
  exit 1
fi
if [[ ! -f "$compatibility_path" ]]; then
  printf 'FAIL: missing package compatibility contract: %s\n' "$compatibility_path" >&2
  exit 1
fi
if [[ ! -f "$drift_path" ]]; then
  printf 'FAIL: missing package contract drift fixture: %s\n' "$drift_path" >&2
  exit 1
fi

validate_contract() {
  local candidate_path="$1"
  python3 - "$snapshot_path" "$candidate_path" <<'PY'
import json
import re
import sys
from pathlib import Path


snapshot_path = Path(sys.argv[1])
candidate_path = Path(sys.argv[2])


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_object(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {label}: {path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {label}: {error.msg}")
    if not isinstance(value, dict):
        fail(f"{label} must contain a JSON object")
    return value


def require_string_list(value, label: str) -> list[str]:
    if not isinstance(value, list) or not value or not all(
        isinstance(item, str) and item for item in value
    ):
        fail(f"{label} must be a non-empty list of strings")
    if len(value) != len(set(value)):
        fail(f"{label} must not contain duplicates")
    return value


snapshot = read_object(snapshot_path, "public server MCP contract snapshot")
candidate = read_object(candidate_path, "package compatibility contract")

expected_snapshot_keys = {
    "source_repository",
    "source_commit",
    "mcp_contract_version",
    "protocol_versions",
    "required_tools",
}
if set(snapshot) != expected_snapshot_keys:
    fail(
        "public snapshot fields must be exactly "
        f"{sorted(expected_snapshot_keys)!r}, got {sorted(snapshot)!r}"
    )
if snapshot["source_repository"] != "VediSMM/website":
    fail("public snapshot must identify VediSMM/website as its private source")
if snapshot["source_commit"] != "2a58555869d2667ce77bb1e245a24d1b24698fd7":
    fail(
        "public snapshot must be anchored to reviewed server commit "
        "2a58555869d2667ce77bb1e245a24d1b24698fd7"
    )
if re.fullmatch(
    r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)",
    snapshot["mcp_contract_version"] or "",
) is None:
    fail("public snapshot mcp_contract_version must be semantic versioning")

snapshot_protocols = require_string_list(snapshot["protocol_versions"], "snapshot protocol_versions")
snapshot_tools = require_string_list(snapshot["required_tools"], "snapshot required_tools")
for tool in snapshot_tools:
    if re.fullmatch(r"[a-z][a-z0-9_]{0,63}", tool) is None:
        fail(f"snapshot contains an invalid MCP tool name: {tool!r}")

candidate_protocols = require_string_list(candidate.get("protocol_versions"), "package protocol_versions")
candidate_tools = require_string_list(candidate.get("required_tools"), "package required_tools")

if candidate_protocols != snapshot_protocols:
    fail(
        "protocol_versions drift: "
        + json.dumps(
            {"package": candidate_protocols, "snapshot": snapshot_protocols},
            separators=(",", ":"),
        )
    )
if candidate.get("min_mcp_contract") != snapshot["mcp_contract_version"]:
    fail(
        "min_mcp_contract drift: "
        + json.dumps(
            {
                "package": candidate.get("min_mcp_contract"),
                "snapshot": snapshot["mcp_contract_version"],
            },
            separators=(",", ":"),
        )
    )

missing = sorted(set(candidate_tools) - set(snapshot_tools))
undocumented = sorted(set(snapshot_tools) - set(candidate_tools))
if missing or undocumented:
    fail(
        "required_tools drift: "
        + json.dumps(
            {"missing": missing, "undocumented": undocumented},
            separators=(",", ":"),
        )
    )

print(
    "public MCP snapshot parity: PASS "
    f"({snapshot['source_repository']}@{snapshot['source_commit']})"
)
PY
}

validate_contract "$compatibility_path"

set +e
drift_output="$(validate_contract "$drift_path" 2>&1)"
drift_status=$?
set -e

if [[ $drift_status -eq 0 ]]; then
  printf '%s\n' 'FAIL: package contract drift fixture unexpectedly matched the public snapshot' >&2
  exit 1
fi
for expected in \
  'FAIL: required_tools drift:' \
  '"missing":["list_projects_v2"]' \
  '"undocumented":["list_projects"]'
do
  if ! grep -F "$expected" <<<"$drift_output" >/dev/null; then
    printf 'FAIL: package contract drift did not produce expected evidence: %s\n' "$expected" >&2
    printf '%s\n' "$drift_output" >&2
    exit 1
  fi
done

printf '%s\n' 'server_compatibility_test.sh: PASS (secretless snapshot parity and negative package drift)'
