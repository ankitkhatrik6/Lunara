#!/usr/bin/env bash
# Bootstraps the PUBLIC repo (ankitkhatrik6/lunara-releases) from this private checkout.
# Run once, from the repo root, after creating the empty public repo on GitHub:
#
#   ./public-repo-starter/bootstrap.sh
#
# It copies this starter kit plus the GPL text into a fresh git repo and pushes it as main.
# Needs: git, gh (logged in) or push access to the public repo.
set -euo pipefail
PUB=ankitkhatrik6/lunara-releases
TMP=$(mktemp -d)
git clone --depth 1 "https://github.com/${PUB}.git" "$TMP" 2>/dev/null || {
  mkdir -p "$TMP" && cd "$TMP" && git init -b main && git remote add origin "https://github.com/${PUB}.git" && cd - >/dev/null
}
cp public-repo-starter/README.md "$TMP/README.md"
cp LICENSE "$TMP/LICENSE"
mkdir -p "$TMP/docs" "$TMP/notes"
cp public-repo-starter/docs/*.md "$TMP/docs/"
cp public-repo-starter/notes/README.md "$TMP/notes/README.md"
cd "$TMP"
git add -A
git commit -m "Public releases home: docs, license, notes" || true
git push -u origin main
echo "Public repo bootstrapped."
