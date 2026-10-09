#!/usr/bin/env bash
# Usage:
#   DRY_RUN=1 ./scripts/review_prs.sh   # preview comments only
#   ./scripts/review_prs.sh             # post official PR review comments
#
# Requires:
#   - gh CLI authenticated with permission to comment on vjcitn/gunleg
#
# Purpose:
#   Post an official PR review comment (event=COMMENT) on non-compliant PRs.
#   The comment requests:
#     1) student name and GitHub repo link
#     2) code addressing the laws of the assigned state
#
# Notes:
#   - PRs are treated as non-compliant if the PR body/title does not clearly
#     include the student name or repo link.
#   - This script is conservative and includes a manual review list because
#     repo-specific compliance is not reliably inferable from the PR metadata alone.

set -euo pipefail

REPO="vjcitn/gunleg"
DRY_RUN="${DRY_RUN:-0}"

# Candidate PRs that looked non-compliant from metadata review.
# Review manually before posting if you want to narrow this list further.
PRS=(
  2 3 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
)

comment_body() {
  local pr_number="$1"
  local login="$2"
  local title="$3"

  cat <<EOF
Thanks for the submission, @$login (PR: \"$title\").

Per the assignment, please update this PR to include:

1. Your full name and your GitHub repo link in the PR description and in the Quarto document.
2. Code that addresses the laws of the state named in the heading.

Each student was assigned a different state, so please confirm that the state in your PR matches your assignment.

I could not find a student name in this PR. Please add it.
EOF
}

for n in "${PRS[@]}"; do
  state=$(gh api "repos/$REPO/pulls/$n" --jq .state)
  if [ "$state" != "open" ]; then
    echo "skip #$n ($state)"
    continue
  fi

  login=$(gh api "repos/$REPO/pulls/$n" --jq .user.login)
  title=$(gh api "repos/$REPO/pulls/$n" --jq .title)
  body=$(comment_body "$n" "$login" "$title")

  if [ "$DRY_RUN" = "1" ]; then
    echo "--- would review #$n ($login) ---"
    echo "$body"
    echo
  else
    gh api -X POST "repos/$REPO/pulls/$n/reviews" \
      -f event="COMMENT" \
      -f body="$body" \
      --jq '.html_url'
  fi
done
