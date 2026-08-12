#!/bin/sh
  set -euo pipefail

  workspace="${1:-$HOME/eclipse-workspace}"

  cd "$workspace"

  for p in .metadata/.plugins/org.eclipse.core.resources/.projects/*; do
    name="$(basename "$p")"
    if [ -f "$p/.location" ]; then
      echo "EXTERNAL  $name"
    else
      echo "WORKSPACE $name"
    fi
  done
  