#!/usr/bin/env bash
set -euo pipefail

AUTHOR_FILTER="${1:-}"  # 可选：作者过滤（不传=全部）
MODE="${2:-dry}"   # dry | run

echo "🔍 scanning full history (HEAD)"
echo "🧪 mode : $MODE"
echo "👤 filter: ${AUTHOR_FILTER:-ALL}"
echo ""

COMMITS=$(git rev-list --reverse HEAD)

found=0

for c in $COMMITS; do
  author=$(git show -s --format=%ae "$c")

  # 如果指定了作者才过滤
  if [ -n "$AUTHOR_FILTER" ] && [ "$author" != "$AUTHOR_FILTER" ]; then
    continue
  fi

  # 判断是否签名（唯一可靠）
  if git cat-file commit "$c" | grep -q "^gpgsig"; then
    echo "✔ SIGNED   $c  $author"
  else
    echo "✍ UNSIGNED $c  $author"
    found=1
  fi
done

echo ""

# =========================
# DRY RUN
# =========================
if [ "$MODE" = "dry" ]; then
  echo "🧪 dry-run finished"
  exit 0
fi

if [ "$found" -eq 0 ]; then
  echo "⚠️ no unsigned commits found"
  exit 0
fi

echo "🚀 starting rebase..."

# =========================
# 关键：exec 只做一件事（不写逻辑）
# =========================
cat > /tmp/git-autosign.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

author=$(git show -s --format=%ae HEAD)

if git cat-file commit HEAD | grep -q "^gpgsig"; then
  exit 0
fi

git commit --amend --no-edit -S
EOF

chmod +x /tmp/git-autosign.sh

git rebase -i --root --exec /tmp/git-autosign.sh

rm -f /tmp/git-autosign.sh

echo ""
echo "🎉 done"
echo "⚠️ if pushed: git push --force-with-lease"
