#!/usr/bin/env bash
# Brings the local main up to date after a pull request merged, and deletes
# the local branches that are already merged into it.
#
#   scripts/sync-main.sh
#
# It never discards work: it stops when the working tree has changes, updates
# main only by fast-forward, and deletes only branches that git reports as
# merged (git branch -d, not -D).
set -euo pipefail

remote="${REMOTE:-origin}"
main="${MAIN_BRANCH:-main}"

cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
	echo "error: the working tree has changes; commit or stash them first." >&2
	exit 1
fi

git fetch --prune "$remote"
git switch "$main"
git merge --ff-only "$remote/$main"

git for-each-ref --format='%(refname:short)' --merged "$main" refs/heads/ |
	while read -r branch; do
		[ "$branch" = "$main" ] && continue
		git branch -d "$branch"
	done

echo "$main is at $(git rev-parse --short HEAD)."
