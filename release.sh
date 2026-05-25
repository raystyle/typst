#!/usr/bin/env bash
set -euo pipefail

# ── 配置 ──
REPO="raystyle/typst"
TAG="v0.14.3-beta"
TITLE="Typst 0.14.3-beta"
BINARY="target/release/typst.exe"
NOTES="# Typst 0.14.3-beta

Based on upstream \`typst/typst\` main branch, 572 commits ahead of v0.14.2.

- Commit: \`07f5f1af\`
- Built with Rust 1.95 (edition 2024)
- Platform: Windows x86_64"

# ── 前置检查 ──
if ! command -v gh &>/dev/null; then
  echo "error: gh CLI not installed" >&2; exit 1
fi
if ! gh auth status &>/dev/null; then
  echo "error: gh not authenticated. Run: gh auth login" >&2; exit 1
fi
if [ ! -f "$BINARY" ]; then
  echo "error: $BINARY not found. Run: cargo build --release -p typst-cli" >&2; exit 1
fi

# ── 计算哈希 ──
if command -v sha256sum &>/dev/null; then
  SHA=$(sha256sum "$BINARY" | awk '{print $1}')
elif command -v certutil &>/dev/null; then
  # Windows
  SHA=$(certutil -hashfile "$BINARY" SHA256 | grep -E '^[0-9a-fA-F]{64}$' | head -1)
else
  echo "error: no sha256sum or certutil found" >&2; exit 1
fi

SIZE=$(wc -c < "$BINARY")

echo "Tag:       $TAG"
echo "Binary:    $BINARY"
echo "Size:      $(( SIZE / 1024 / 1024 )) MB"
echo "SHA256:    $SHA"
echo ""

# ── 推送 tag（如果远程不存在） ──
if ! git tag -l "$TAG" | grep -q "$TAG"; then
  echo "Creating local tag $TAG ..."
  git tag "$TAG"
fi

if git ls-remote --tags origin "$TAG" | grep -q "$TAG"; then
  echo "Tag $TAG already exists on remote."
else
  echo "Pushing tag $TAG ..."
  git push origin "$TAG"
fi

# ── 写 SHA256 到文件 ──
HASH_FILE="target/release/typst.exe.sha256"
echo "$SHA  typst.exe" > "$HASH_FILE"

# ── 创建 release 并上传 ──
echo "Creating GitHub release ..."
gh release create "$TAG" \
  --repo "$REPO" \
  --title "$TITLE" \
  --notes "$NOTES" \
  --exclude-source \
  "$BINARY#typst.exe" \
  "$HASH_FILE#typst.exe.sha256"

echo ""
echo "Done! Release published at:"
echo "  https://github.com/$REPO/releases/tag/$TAG"
