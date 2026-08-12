#!/usr/bin/env bash
# Push captured screenshots to the screenshot-archive branch and upsert a
# gallery comment on the PR. Runs inside GitHub Actions (needs GH_TOKEN,
# PR_NUMBER, HEAD_SHA, GITHUB_REPOSITORY, GITHUB_RUN_ID).
set -euo pipefail

BRANCH="screenshot-archive"
DEST="pr-${PR_NUMBER}/${GITHUB_RUN_ID}"
REPO="${GITHUB_REPOSITORY}"
MARKER="<!-- preview-screenshots -->"
CLONE_URL="https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git"
ARCHIVE_DIR="$(mktemp -d)"

shopt -s nullglob
shots=(screenshots/*.png)
if [ ${#shots[@]} -eq 0 ]; then
  echo "No screenshots found, nothing to publish."
  exit 1
fi

if git clone --depth 1 --branch "$BRANCH" "$CLONE_URL" "$ARCHIVE_DIR" 2>/dev/null; then
  echo "Cloned existing $BRANCH branch."
else
  git init -b "$BRANCH" "$ARCHIVE_DIR"
  git -C "$ARCHIVE_DIR" remote add origin "$CLONE_URL"
fi

mkdir -p "$ARCHIVE_DIR/$DEST"
cp "${shots[@]}" "$ARCHIVE_DIR/$DEST/"

git -C "$ARCHIVE_DIR" add .
git -C "$ARCHIVE_DIR" \
  -c user.name="github-actions[bot]" \
  -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit -m "screenshots: PR #${PR_NUMBER} run ${GITHUB_RUN_ID}"
git -C "$ARCHIVE_DIR" push origin "$BRANCH"

RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${DEST}"

BODY="${MARKER}
## 📱 Preview screenshots

Android emulator (API 34) · commit \`${HEAD_SHA:0:7}\` · [run](${GITHUB_SERVER_URL:-https://github.com}/${REPO}/actions/runs/${GITHUB_RUN_ID})

| Step | Android |
|---|---|"

for shot in "${shots[@]}"; do
  name="$(basename "$shot" .png)"
  BODY="${BODY}
| \`${name}\` | <img src=\"${RAW_BASE}/${name}.png\" width=\"250\"> |"
done

BODY="${BODY}

_Flow: \`.maestro/preview/login-flow.yaml\` · iOS column coming later._"

EXISTING_ID="$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"${MARKER}\")) | .id" | head -n1 || true)"

if [ -n "$EXISTING_ID" ]; then
  gh api -X PATCH "repos/${REPO}/issues/comments/${EXISTING_ID}" -f body="$BODY" >/dev/null
  echo "Updated existing gallery comment ${EXISTING_ID}."
else
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" -f body="$BODY" >/dev/null
  echo "Posted new gallery comment."
fi
