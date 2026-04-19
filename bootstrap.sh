#!/usr/bin/env bash
# bootstrap.sh — set up dotfiles on a new machine
# Usage: bash bootstrap.sh

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles: $DOTFILES"

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "==> Homebrew already installed, skipping."
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
echo "==> Installing dependencies..."
brew install neovim tmux node ripgrep fd stow

# ── Symlinks via stow ─────────────────────────────────────────────────────────
echo "==> Symlinking configs..."
cd "$DOTFILES"
stow nvim
stow tmux
stow ghostty

# ── Oh My Zsh plugins ─────────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$HOME/.oh-my-zsh" ]; then
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "==> Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    echo "==> zsh-autosuggestions already installed, skipping."
  fi

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "==> Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    echo "==> zsh-syntax-highlighting already installed, skipping."
  fi
else
  echo "==> Oh My Zsh not found, skipping zsh plugins."
  echo "    Install it first: https://ohmyz.sh"
fi

# ── Neovim plugins ────────────────────────────────────────────────────────────
echo "==> Bootstrapping Neovim plugins (headless)..."
nvim --headless "+Lazy! sync" +qa

echo ""
echo "✓ Done! A few manual steps remaining:"
echo "  1. Install MesloLGS Nerd Font: https://github.com/ryanoasis/nerd-fonts"
echo "  2. Set MesloLGS Nerd Font in Ghostty (already in config)"
echo "  3. Restart your shell: exec zsh"
