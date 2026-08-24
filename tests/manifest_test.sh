#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: tests/manifest_test.sh [package-root]' >&2
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


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_json(relative_path: str) -> dict:
    path = root / relative_path
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {relative_path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {relative_path}: {error.msg}")
    if not isinstance(value, dict):
        fail(f"{relative_path} must contain an object")
    return value


def assert_equal(actual, expected, label: str) -> None:
    if actual != expected:
        fail(f"{label} must be {expected!r}, got {actual!r}")


def assert_allowed_keys(value: dict, allowed: set[str], label: str) -> None:
    unknown = set(value) - allowed
    if unknown:
        fail(f"{label} contains unsupported fields: {sorted(unknown)!r}")


def assert_no_out_of_package_paths(value, label: str) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            assert_no_out_of_package_paths(child, f"{label}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            assert_no_out_of_package_paths(child, f"{label}[{index}]")
    elif isinstance(value, str):
        is_windows_absolute = re.match(r"^[A-Za-z]:[\\/]", value) is not None
        if value.startswith("/") or value.startswith("file://") or is_windows_absolute:
            fail(f"{label} must not contain a local absolute path")
        if ".." in value.replace("\\", "/").split("/"):
            fail(f"{label} must not contain an out-of-package traversal path")


manifest = read_json("plugins/vedismm/.codex-plugin/plugin.json")
mcp = read_json("plugins/vedismm/.mcp.json")
app = read_json("plugins/vedismm/.app.json")
marketplace = read_json(".agents/plugins/marketplace.json")

assert_allowed_keys(
    manifest,
    {"id", "name", "version", "description", "skills", "apps", "mcpServers", "interface", "author", "homepage", "repository", "license", "keywords"},
    "plugin manifest",
)
assert_allowed_keys(mcp, {"mcpServers"}, "MCP manifest")
assert_allowed_keys(app, {"apps"}, "app manifest")
assert_allowed_keys(marketplace, {"name", "interface", "plugins"}, "marketplace")

for label, value in (("plugin manifest", manifest), ("MCP manifest", mcp), ("app manifest", app), ("marketplace", marketplace)):
    assert_no_out_of_package_paths(value, label)

assert_equal(manifest.get("name"), "vedismm", "plugin name")
version = manifest.get("version")
if not isinstance(version, str) or re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?", version) is None:
    fail("plugin version must be semantic versioning")
assert_equal(version, "0.1.1", "plugin version")
assert_equal(manifest.get("homepage"), "https://github.com/VediSMM/codex-plugin", "homepage")
assert_equal(manifest.get("repository"), "https://github.com/VediSMM/codex-plugin", "repository")
assert_equal(manifest.get("license"), "MIT", "license")
assert_equal(manifest.get("skills"), "./skills/", "skills path")
assert_equal(manifest.get("mcpServers"), "./.mcp.json", "MCP manifest path")
assert_equal(manifest.get("apps"), "./.app.json", "app manifest path")

author = manifest.get("author")
if not isinstance(author, dict):
    fail("author must be an object")
assert_allowed_keys(author, {"name", "email", "url"}, "author")
assert_equal(author.get("name"), "VediSMM", "author name")
assert_equal(author.get("email"), "support@vedismm.ru", "support email")
assert_equal(author.get("url"), "https://vedismm.ru", "author website")

interface = manifest.get("interface")
if not isinstance(interface, dict):
    fail("interface must be an object")
assert_allowed_keys(
    interface,
    {"displayName", "shortDescription", "longDescription", "developerName", "category", "capabilities", "websiteURL", "privacyPolicyURL", "termsOfServiceURL", "brandColor", "composerIcon", "logo", "logoDark", "screenshots", "defaultPrompt", "default_prompt"},
    "plugin interface",
)
assert_equal(interface.get("websiteURL"), "https://vedismm.ru", "website URL")
assert_equal(interface.get("privacyPolicyURL"), "https://vedismm.ru/privacy", "privacy URL")
assert_equal(interface.get("termsOfServiceURL"), "https://vedismm.ru/terms", "terms URL")

servers = mcp.get("mcpServers")
if not isinstance(servers, dict):
    fail("MCP servers must be an object")
assert_equal(set(servers), {"vedismm"}, "MCP server names")
if not isinstance(servers.get("vedismm"), dict):
    fail("VediSMM MCP server must be an object")
assert_allowed_keys(servers["vedismm"], {"type", "url", "oauth_resource"}, "VediSMM MCP server")
assert_equal(
    servers.get("vedismm"),
    {
        "type": "http",
        "url": "https://mcp.vedismm.ru/mcp",
        "oauth_resource": "https://mcp.vedismm.ru/mcp",
    },
    "VediSMM Streamable HTTP OAuth MCP server",
)
apps = app.get("apps")
if not isinstance(apps, dict):
    fail("apps must be an object")
for app_name, app_entry in apps.items():
    if not isinstance(app_entry, dict):
        fail(f"app {app_name!r} must be an object")
    assert_allowed_keys(app_entry, {"id", "category"}, f"app {app_name!r}")
assert_equal(app, {"apps": {}}, "empty app manifest")

assert_equal(marketplace.get("name"), "vedismm", "marketplace name")
marketplace_interface = marketplace.get("interface")
if not isinstance(marketplace_interface, dict):
    fail("marketplace interface must be an object")
assert_allowed_keys(marketplace_interface, {"displayName"}, "marketplace interface")
assert_equal(marketplace_interface.get("displayName"), "VediSMM", "marketplace display name")
plugins = marketplace.get("plugins")
if not isinstance(plugins, list):
    fail("marketplace plugins must be an array")
assert_equal([plugin.get("name") for plugin in plugins if isinstance(plugin, dict)], ["vedismm"], "marketplace plugin order")
assert_equal(len(plugins), 1, "marketplace plugin count")
plugin = plugins[0]
if not isinstance(plugin, dict):
    fail("marketplace plugin must be an object")
assert_allowed_keys(plugin, {"name", "source", "policy", "category"}, "marketplace plugin")
source = plugin.get("source")
if not isinstance(source, dict):
    fail("marketplace source must be an object")
assert_allowed_keys(source, {"source", "path"}, "marketplace source")
policy = plugin.get("policy")
if not isinstance(policy, dict):
    fail("marketplace policy must be an object")
assert_allowed_keys(policy, {"installation", "authentication"}, "marketplace policy")
assert_equal(plugin.get("source"), {"source": "local", "path": "./plugins/vedismm"}, "marketplace source")
assert_equal(plugin.get("policy"), {"installation": "AVAILABLE", "authentication": "ON_INSTALL"}, "marketplace policy")
assert_equal(plugin.get("category"), "Productivity", "marketplace category")

print("manifest_test.sh: PASS")
PY
