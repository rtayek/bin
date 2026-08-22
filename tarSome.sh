#!/bin/sh
set -eu

base=${PWD##*/}
out="$HOME/outgoing/$base.tar.gz"

tar -czf "$out" \
    src \
    tst \
    handoffs \
    build.* \
    *.md

echo "Wrote $out"
