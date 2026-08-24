#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: tests/server_compatibility_test.sh [server-root]' >&2
  exit 2
fi

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
server_input="${1:-${VEDISMM_SERVER_DIR:-}}"
php_bin="${PHP_BIN:-php}"

if [[ -z "$server_input" || ! -d "$server_input" ]]; then
  printf '%s\n' 'FAIL: provide the checked-out VediSMM server root' >&2
  exit 1
fi
server_root="$(cd "$server_input" && pwd)"
server_test="$server_root/tests/mcp_package_compatibility_test.php"
drift_root="$package_root/tests/fixtures/tool-drift"

if [[ ! -f "$server_test" ]]; then
  printf 'FAIL: server checkout does not contain compatibility test: %s\n' "$server_test" >&2
  exit 1
fi
if [[ ! -f "$drift_root/compatibility.json" ]]; then
  printf '%s\n' 'FAIL: missing package contract drift fixture' >&2
  exit 1
fi
if ! command -v "$php_bin" >/dev/null 2>&1; then
  printf 'FAIL: PHP runtime is unavailable: %s\n' "$php_bin" >&2
  exit 1
fi

VEDISMM_AGENT_PACKAGE_DIR="$package_root" "$php_bin" "$server_test"

set +e
drift_output="$(VEDISMM_AGENT_PACKAGE_DIR="$drift_root" "$php_bin" "$server_test" 2>&1)"
drift_status=$?
set -e

if [[ $drift_status -eq 0 ]]; then
  printf '%s\n' 'FAIL: package contract drift fixture unexpectedly passed server parity' >&2
  exit 1
fi
for expected in \
  'Passed: 6, Failed: 1' \
  '"missing":["list_projects_v2"]' \
  '"undocumented":["list_projects"]'
do
  if ! grep -F "$expected" <<<"$drift_output" >/dev/null; then
    printf 'FAIL: package contract drift did not produce expected evidence: %s\n' "$expected" >&2
    printf '%s\n' "$drift_output" >&2
    exit 1
  fi
done

printf '%s\n' 'server_compatibility_test.sh: PASS (positive parity and negative package drift)'
