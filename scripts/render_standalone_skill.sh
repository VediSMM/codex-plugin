#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'usage: scripts/render_standalone_skill.sh [package-root]' >&2
  exit 2
fi

package_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
skill_dir="$package_root/plugins/vedismm/skills/social-publishing"
skill="$skill_dir/SKILL.md"
dist_dir="$package_root/dist"
dist="$dist_dir/social-publishing.md"

if [[ ! -f "$skill" ]]; then
  printf 'missing canonical skill: %s\n' "$skill" >&2
  exit 1
fi

for reference in project-policies publication-confirmation troubleshooting; do
  if [[ ! -f "$skill_dir/references/$reference.md" ]]; then
    printf 'missing required reference: %s\n' "$skill_dir/references/$reference.md" >&2
    exit 1
  fi
done

mkdir -p "$dist_dir"
tmp="$(mktemp "$dist_dir/.social-publishing.md.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

{
  awk '
    NR == 1 {
      sub(/\r$/, "")
      if ($0 != "---") {
        print "canonical skill must begin with YAML frontmatter" > "/dev/stderr"
        exit 1
      }
      in_frontmatter = 1
      next
    }
    {
      sub(/\r$/, "")
      if (in_frontmatter) {
        if ($0 == "---") {
          in_frontmatter = 0
        }
        next
      }
      print
    }
    END {
      if (in_frontmatter) {
        print "canonical skill YAML frontmatter is not closed" > "/dev/stderr"
        exit 1
      }
    }
  ' "$skill"
  for reference in project-policies publication-confirmation troubleshooting; do
    printf '\n\n---\n\n'
    awk '{ sub(/\r$/, ""); print }' "$skill_dir/references/$reference.md"
  done
} > "$tmp"

cmp -s "$tmp" "$dist" || cp "$tmp" "$dist"
