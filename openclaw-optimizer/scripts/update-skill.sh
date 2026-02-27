#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# OpenClaw Optimizer — Update Tool
#
# Checks for OpenClaw version drift, fetches the changelog, identifies
# affected skill sections via keyword matching, and optionally bumps
# version numbers across metadata files.
#
# Usage:
#   bash update-skill.sh              # check drift and show report
#   bash update-skill.sh --apply      # bump version numbers in metadata
#   bash update-skill.sh --commit     # apply + commit + push
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_CHECK="$SKILL_DIR/scripts/version-check.py"
KMAP="$SKILL_DIR/metadata/knowledge-map.json"
SKILL_MD="$SKILL_DIR/SKILL.md"
UPDATE_LOG="$SKILL_DIR/metadata/update-log.md"
LATEST_VER_FILE="$SKILL_DIR/metadata/latest-version.txt"

APPLY=false
COMMIT=false

for arg in "$@"; do
  case "$arg" in
    --apply)  APPLY=true ;;
    --commit) APPLY=true; COMMIT=true ;;
    --help|-h)
      echo "Usage: update-skill.sh [--apply] [--commit]"
      echo ""
      echo "  (no flags)  Check for drift and show what changed"
      echo "  --apply     Bump version numbers in metadata files"
      echo "  --commit    Apply + commit + push to origin"
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg (use --help)" >&2
      exit 1
      ;;
  esac
done

# ── Read current skill version ──────────────────────────────────────────────

CURRENT_VERSION=$(python3 -c "
import sys
with open('$SKILL_MD') as f:
    for line in f:
        if line.startswith('version:'):
            print(line.split(':', 1)[1].strip())
            sys.exit(0)
sys.exit(1)
") || { echo "ERROR: Could not read version from SKILL.md" >&2; exit 1; }

# ── Check for drift ─────────────────────────────────────────────────────────

echo ""
echo "  OpenClaw Optimizer — Update Tool"
echo "  ─────────────────────────────────────"
echo ""
echo "  Checking for version drift..."

CHECK_OUTPUT=$(python3 "$VERSION_CHECK" --force 2>&1)

if echo "$CHECK_OUTPUT" | grep -q "^CURRENT"; then
  echo "  Skill v$CURRENT_VERSION is current with OpenClaw. Nothing to do."
  exit 0
fi

if echo "$CHECK_OUTPUT" | grep -q "^UNCHECKED"; then
  echo "  Could not reach GitHub API. Try again later." >&2
  exit 1
fi

NEW_VERSION=$(echo "$CHECK_OUTPUT" | grep "^STALE:" | cut -d: -f2)

if [ -z "$NEW_VERSION" ]; then
  echo "  Unexpected output: $CHECK_OUTPUT" >&2
  exit 1
fi

echo "  Current skill version : v$CURRENT_VERSION"
echo "  Latest OpenClaw       : v$NEW_VERSION"
echo ""

# ── Fetch changelog ──────────────────────────────────────────────────────────

echo "  Fetching changelog for v$NEW_VERSION..."

CHANGELOG_FILE=$(mktemp)
trap 'rm -f "$CHANGELOG_FILE"' EXIT

curl -sf \
  -H "User-Agent: openclaw-optimizer/$CURRENT_VERSION" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/openclaw/openclaw/releases/tags/v$NEW_VERSION" \
  | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('body', 'No changelog found.'))
except Exception:
    print('Failed to parse response.')
" > "$CHANGELOG_FILE" 2>/dev/null || echo "Failed to fetch changelog." > "$CHANGELOG_FILE"

echo ""
echo "  Changelog for v$NEW_VERSION"
echo "  ─────────────────────────────────────"
while IFS= read -r line; do
  echo "  $line"
done < "$CHANGELOG_FILE"
echo "  ─────────────────────────────────────"
echo ""

# ── Identify affected sections ───────────────────────────────────────────────

echo "  Affected sections (keyword match):"
echo ""

python3 - "$KMAP" < "$CHANGELOG_FILE" << 'PYEOF'
import sys, json

kmap_path = sys.argv[1]
changelog = sys.stdin.read().lower()

with open(kmap_path) as f:
    kmap = json.load(f)

affected = []
for section_id, section in kmap.get("sections", {}).items():
    keywords = section.get("changelog_keywords", [])
    hits = [kw for kw in keywords if kw.lower() in changelog]
    if hits:
        affected.append((section_id, section["title"], hits))

if affected:
    for sid, title, hits in sorted(affected, key=lambda x: -len(x[2])):
        matched = ", ".join(hits[:5])
        extra = f" (+{len(hits)-5} more)" if len(hits) > 5 else ""
        print(f"    [{sid}] {title}")
        print(f"      matched: {matched}{extra}")
        print()
else:
    print("    No keyword matches. Manual review recommended.")
    print()
PYEOF

# ── Report or apply ──────────────────────────────────────────────────────────

if [ "$APPLY" = false ]; then
  echo "  Next steps:"
  echo "    1. Review the changelog above"
  echo "    2. Update affected sections in SKILL.md and references/"
  echo "    3. Run with --apply to bump version numbers"
  echo "    4. Run with --commit to bump + commit + push"
  echo ""
  exit 0
fi

# ── Bump version numbers ────────────────────────────────────────────────────

echo "  Bumping version to v$NEW_VERSION..."

# Update SKILL.md version references
python3 - "$SKILL_MD" "$CURRENT_VERSION" "$NEW_VERSION" << 'PYEOF'
import sys, re

path, old_ver, new_ver = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    content = f.read()

content = re.sub(
    r'^version: .*$',
    f'version: {new_ver}',
    content, count=1, flags=re.MULTILINE,
)
content = re.sub(
    r'Aligned with: OpenClaw v[^\s*|]+',
    f'Aligned with: OpenClaw v{new_ver}',
    content, count=1,
)

with open(path, 'w') as f:
    f.write(content)
PYEOF

# Update knowledge-map.json
python3 - "$KMAP" "$NEW_VERSION" << 'PYEOF'
import sys, json
from datetime import date

path, new_ver = sys.argv[1], sys.argv[2]
with open(path) as f:
    kmap = json.load(f)

kmap["skill_version"] = new_ver
kmap["last_updated"] = str(date.today())

with open(path, "w") as f:
    json.dump(kmap, f, indent=2)
    f.write("\n")
PYEOF

# Update latest-version.txt
echo "$NEW_VERSION" > "$LATEST_VER_FILE"

# Update reference file headers
for ref in "$SKILL_DIR"/references/*.md; do
  if [ -f "$ref" ]; then
    python3 -c "
import sys, re
path = sys.argv[1]
new_ver = sys.argv[2]
with open(path) as f:
    content = f.read()
content = re.sub(
    r'Aligned with OpenClaw v[^\s|]+',
    f'Aligned with OpenClaw v{new_ver}',
    content, count=1,
)
with open(path, 'w') as f:
    f.write(content)
" "$ref" "$NEW_VERSION"
  fi
done

# Append to update log
TODAY=$(date +%Y-%m-%d)
cat >> "$UPDATE_LOG" << EOF

## $NEW_VERSION — $TODAY
- Updated from: v$CURRENT_VERSION
- Files updated: [fill in after content updates]
- Key changes: [fill in from changelog]
EOF

echo ""
echo "  Updated:"
echo "    - SKILL.md (version + aligned-with)"
echo "    - metadata/knowledge-map.json"
echo "    - metadata/latest-version.txt"
echo "    - references/*.md headers"
echo "    - metadata/update-log.md (entry appended)"
echo ""

if [ "$COMMIT" = false ]; then
  echo "  Review changes, then commit manually or re-run with --commit."
  exit 0
fi

# ── Commit and push ──────────────────────────────────────────────────────────

echo "  Committing and pushing..."
cd "$SKILL_DIR"
git add SKILL.md metadata/ references/
git commit -m "Update to OpenClaw v$NEW_VERSION"
git push origin main

echo "  Pushed to origin/main."
echo ""
