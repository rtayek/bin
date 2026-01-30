#!/bin/sh
set -eu

base=${PWD##*/}
out="$HOME/outgoing/$base.tar.gz"

tar -czf "$out" \
  --exclude='./.git' \
  --exclude='./.gitignore' \
  --exclude='./.gitattributes' \
  --exclude='./.settings' \
  --exclude='./.classpath' \
  --exclude='./.project' \
  --exclude='./bin' \
  --exclude='./build' \
  --exclude='./*/bin' \
  --exclude='./*/build' \
  --exclude='./out' \
  --exclude='./target' \
  --exclude='./dist' \
  --exclude='./node_modules' \
  --exclude='./.gradle/' \
  --exclude='./.gradle/**' \
  --exclude='./.idea' \
  --exclude='./.vscode' \
  --exclude='./__pycache__' \
  --exclude='./.pytest_cache' \
  --exclude='./.mypy_cache' \
  --exclude='./.ruff_cache' \
  --exclude='./.venv' \
  --exclude-vcs   \
  .
echo "Wrote $out"
