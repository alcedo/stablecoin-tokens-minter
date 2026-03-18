#!/usr/bin/env bash
set -euo pipefail

FOUNDRY_LINE='export PATH="$HOME/.foundry/bin:$PATH"'
FOUNDRY_BIN="$HOME/.foundry/bin"
FOUNDRY_TAG="stable"
FOUNDRY_CHANNEL="stable"

case "$(uname -s)" in
  Linux)
    FOUNDRY_PLATFORM="linux"
    ;;
  Darwin)
    FOUNDRY_PLATFORM="darwin"
    ;;
  *)
    printf 'Unsupported platform for Codex Cloud setup: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64|amd64)
    FOUNDRY_ARCH="amd64"
    ;;
  arm64|aarch64)
    FOUNDRY_ARCH="arm64"
    ;;
  *)
    printf 'Unsupported CPU architecture for Codex Cloud setup: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

FOUNDRY_ARCHIVE="foundry_${FOUNDRY_CHANNEL}_${FOUNDRY_PLATFORM}_${FOUNDRY_ARCH}.tar.gz"
FOUNDRY_RELEASE_URL="https://github.com/foundry-rs/foundry/releases/download/${FOUNDRY_TAG}/${FOUNDRY_ARCHIVE}"

if [ -f "$HOME/.bashrc" ]; then
  if [ -w "$HOME/.bashrc" ]; then
    if ! grep -qxF "$FOUNDRY_LINE" "$HOME/.bashrc"; then
      printf '%s\n' "$FOUNDRY_LINE" >> "$HOME/.bashrc"
    fi
  else
    printf 'Skipping PATH persistence because %s is not writable.\n' "$HOME/.bashrc" >&2
  fi
elif [ -w "$HOME" ]; then
  printf '%s\n' "$FOUNDRY_LINE" > "$HOME/.bashrc"
else
  printf 'Skipping PATH persistence because %s is not writable.\n' "$HOME" >&2
fi

mkdir -p "$FOUNDRY_BIN"
export PATH="$FOUNDRY_BIN:$PATH"

# Download the stable Foundry build.
curl -fsSL "$FOUNDRY_RELEASE_URL" | tar -xzC "$FOUNDRY_BIN"

"$FOUNDRY_BIN/forge" --version
"$FOUNDRY_BIN/forge" test
