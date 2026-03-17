#!/usr/bin/env bash
set -euo pipefail

FOUNDATION_LINE='export PATH="$HOME/.foundry/bin:$PATH"'

curl -L https://foundry.paradigm.xyz | bash

if [ -f "$HOME/.bashrc" ]; then
  if ! grep -qxF "$FOUNDATION_LINE" "$HOME/.bashrc"; then
    printf '%s\n' "$FOUNDATION_LINE" >> "$HOME/.bashrc"
  fi
else
  printf '%s\n' "$FOUNDATION_LINE" > "$HOME/.bashrc"
fi

export PATH="$HOME/.foundry/bin:$PATH"

foundryup -v 1.6.0-nightly

forge --version
forge test
