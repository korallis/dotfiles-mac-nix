#!/bin/bash

set -euo pipefail

DOTFILES_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd )

# Fail early if placeholder values have not been customized yet
if grep -R -n -E 'yourname|/Users/yourname|Your Name|you@example.com' \
  "$DOTFILES_DIR/flake.nix" \
  "$DOTFILES_DIR/nix" >/dev/null 2>&1; then
  echo "Placeholder values are still present in the repo."
  echo "Please replace values like 'yourname', '/Users/yourname', 'Your Name', and 'you@example.com' before running setup/mac.sh."
  exit 1
fi

# Install Nix via Determinate if missing
if ! command -v nix &> /dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.sh/nix | sh -s -- install
fi

# Install Homebrew if missing
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apply the Nix configuration
if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
  sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$DOTFILES_DIR#mac"
else
  sudo nix run github:nix-darwin/nix-darwin -- switch --flake "$DOTFILES_DIR#mac"
fi

# --- Workflow CLIs not packaged in Nix (each installs only if missing) ---------
# Make the just-applied Nix profile (node, npm, gh, …) and the per-user bin dirs
# visible to the installers below.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$PATH"

# Claude Code — official Anthropic installer (NOT Homebrew).
command -v claude >/dev/null 2>&1 || { curl -fsSL https://claude.ai/install.sh | bash; } || echo "warning: claude install failed"
# treehouse — reusable git worktrees for parallel agents (-> ~/.local/bin).
command -v treehouse >/dev/null 2>&1 || { curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh; } || echo "warning: treehouse install failed"
# no-mistakes — local pre-push validation gate (-> ~/.local/bin).
command -v no-mistakes >/dev/null 2>&1 || { curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh; } || echo "warning: no-mistakes install failed"
# AXI CLIs — agent-ergonomic wrappers, published on npm (-> ~/.local so Nix node runs them).
for axi in gh-axi chrome-devtools-axi lavish-axi; do
  command -v "$axi" >/dev/null 2>&1 || npm install -g --prefix "$HOME/.local" "$axi" || echo "warning: $axi install failed"
done

# Install nvm and a default Node.js if missing
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
fi

echo "Bootstrap complete. Restart your shell if needed, then use 'rebuild' or darwin-rebuild for future config changes."
