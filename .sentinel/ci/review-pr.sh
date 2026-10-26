#!/usr/bin/env bash
# Review a pull request from a fork and print the review.
#
# Usage: review-pr.sh <pull-request-number> [age-identity-file]
#
# Run it inside the repo's checkout. It starts fast.yml's review-pr job from
# the default branch, the same as `gh workflow run fast.yml -f pr=<number>`,
# waits for that run to finish, and prints the review with read-review.sh,
# which takes the age identity the same way. Each run is a paid review.
set -euo pipefail

[[ $# -ge 1 && $# -le 2 ]] || { echo "usage: $(basename "$0") <pull-request-number> [age-identity-file]" >&2; exit 2; }
pr=$1
[[ $pr =~ ^[0-9]+$ ]] || { echo "review-pr.sh: $pr is not a pull request number" >&2; exit 2; }
command -v gh >/dev/null || { echo "review-pr.sh: gh not found on PATH" >&2; exit 2; }

main=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
me=$(gh api user --jq .login)
# gh workflow run prints no run id, so the run it starts is the one that was
# not in the list before it.
list() {
    gh run list --workflow fast.yml --event workflow_dispatch --user "$me" --limit 20 --json databaseId -q '.[].databaseId'
}
before=$(list)
gh workflow run fast.yml --ref "$main" -f pr="$pr"
run=
for _ in $(seq 30); do
    run=$(list | grep -vxF -e "$before" | tail -n 1 || true)
    [[ -n $run ]] && break
    sleep 2
done
[[ -n $run ]] || { echo "review-pr.sh: the review run for pull request $pr did not show up; look with gh run list --workflow fast.yml" >&2; exit 1; }

echo "review-pr.sh: reviewing pull request $pr in run $run" >&2
gh run watch "$run" --exit-status >&2 || { echo "review-pr.sh: run $run failed; gh run view $run --log-failed shows why" >&2; exit 1; }

if [[ -z $(gh variable get SENTINEL_REVIEW_AGE_RECIPIENT 2>/dev/null || true) ]]; then
    echo "review-pr.sh: the review is posted on the pull request: gh pr view $pr --comments" >&2
    exit 0
fi
exec "$(dirname "$0")/read-review.sh" "$pr" ${2:+"$2"}
