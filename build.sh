#!/bin/bash
# Build the workspace image from the committed tree and push it to
# ghcr.io/gecube/workspace (a public package: no pull secret in the cluster).
# Prints the tag and digest to pin in the cluster's GitOps tree.
#
#   ./build.sh            # build and push
#   ./build.sh --no-push  # build only
#
# Push credentials: the gh CLI login (scope write:packages). The registry login
# goes into a throwaway DOCKER_CONFIG, so the token never lands in
# ~/.docker/config.json.
set -euo pipefail

IMAGE=ghcr.io/gecube/workspace
cd "$(dirname "$0")"

# The tag names a commit, so the tree must be that commit.
if [ -n "$(git status --porcelain -- .)" ]; then
  echo "images/workspace has uncommitted changes; commit first" >&2
  exit 1
fi
tag="$(date -u +%Y%m%d%H%M)-$(git rev-parse --short=7 HEAD)"

docker buildx build --platform linux/amd64 --provenance=false --load \
  --label "org.opencontainers.image.source=https://github.com/gecube/workspace" \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  -t "$IMAGE:$tag" .
[ "${1:-}" = --no-push ] && exit 0

DOCKER_CONFIG=$(mktemp -d); export DOCKER_CONFIG
trap 'rm -rf "$DOCKER_CONFIG"' EXIT
gh auth token | docker login ghcr.io -u "$(gh api user -q .login)" --password-stdin >/dev/null
docker push -q "$IMAGE:$tag" >/dev/null
digest=$(docker image inspect -f '{{range .RepoDigests}}{{println .}}{{end}}' "$IMAGE:$tag" | grep "^$IMAGE@" | cut -d@ -f2)
echo "newTag: $tag"
echo "digest: $digest"
