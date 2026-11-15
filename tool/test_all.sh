#!/usr/bin/env bash
# workspace 全体のテストを実行する。リポジトリルートで実行すること。
# test/ を持つ packages/* のみ dart test を実行し、無いものはスキップする。
# 最初の失敗で即終了する（fail-fast）。
set -euo pipefail

for dir in packages/*/; do
  if [ -d "${dir}test" ]; then
    echo "==> ${dir}"
    (cd "$dir" && dart test)
  else
    echo "skip ${dir} (no test/)"
  fi
done
