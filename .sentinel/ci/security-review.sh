#!/usr/bin/env bash
# Stub: no Claude, no key. Proves where and on what it ran.
set -eu
echo "STUB script=$0 pwd=$PWD head=$(git rev-parse HEAD) base=$1"
git diff --merge-base "$1" HEAD --stat
printf '## No findings\n\nstub reviewed %s in %s\n' "$(git rev-parse --short HEAD)" "$PWD" > security-review.md
