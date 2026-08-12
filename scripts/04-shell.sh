#!/usr/bin/env bash
set -euo pipefail

echo "==> [4/4] Setting up Fish shell environment..."

FISH_PATH="$(command -v fish || true)"
CURRENT_USER="${USER:-$(id -un)}"
CURRENT_SHELL="${SHELL:-}"

if [ -n "$FISH_PATH" ]; then
    if ! grep -q "^$FISH_PATH$" /etc/shells; then
        echo "--> Adding $FISH_PATH to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
        echo "--> Changing default shell to $FISH_PATH..."
        chsh -s "$FISH_PATH" "$CURRENT_USER" 2>/dev/null || echo "Note: Run 'chsh -s $FISH_PATH' manually if password was required."
    fi
fi

echo "==> Shell configuration complete."
