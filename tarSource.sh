#!/bin/sh
set -eu

base=${PWD##*/}
out="$HOME/outgoing/$base.tar.gz"
exclude_file="$(mktemp)"

mkdir -p "$HOME/outgoing"

cat > "$exclude_file" <<'EOF'
./.git
./.gitignore
./.gitattributes
./.settings
./.classpath
./.project
./bin
./build
./out
./target
./dist
./node_modules
./.gradle
./.idea
./.vscode
*/__pycache__
*/__pycache__/*
*.pyc
*/.pytest_cache
*/.pytest_cache/*
*/.mypy_cache
*/.mypy_cache/*
*/.ruff_cache
*/.ruff_cache/*
./.venv
*/.venv
*/.venv/*
./checkpoints
./checkpoints/*
./plots
./plots/*
./tmp
./tmp/*
./runs/*/checkpoints
./runs/*/checkpoints/*
./runs/*/plots
./runs/*/plots/*
.coverage
./.claude
./.claude/*
./src/tinyllm.egg-info
./src/tinyllm.egg-info/*



EOF

tar -czf "$out" \
  --exclude-vcs \
  --exclude-from="$exclude_file" \
  .

rm -f "$exclude_file"

echo "Wrote $out"

