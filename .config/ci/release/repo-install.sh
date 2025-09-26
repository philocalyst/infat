nix develop --command gh release download "$TAG_NAME" \
  --repo "$GITHUB_REPOSITORY" \
  --pattern '*' \
  --dir dist
