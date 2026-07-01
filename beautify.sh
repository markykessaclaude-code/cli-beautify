#!/usr/bin/env bash
# =============================================================================
# CLI Beautify - portable installer for Howard's terminal toolkit.
#
# Installs: starship, zoxide, eza, bat, fd, fzf, ripgrep, micro, tldr (tlrc),
#           zsh-autosuggestions, zsh-syntax-highlighting.
#
# Works on:  macOS (Homebrew)  and  Linux (any distro).
# Linux default = home-folder install into ~/.local/bin, NO sudo, NO admin.
# Optional --system uses the native package manager with sudo.
#
# Reversible: run `beautify.sh --uninstall` (removes the shell block; tells you
# how to delete the binaries). Nothing here writes secrets or touches root
# unless you pass --system.
#
# Usage:
#   bash beautify.sh              # default: brew on mac, ~/.local on linux
#   bash beautify.sh --system     # linux: use apt/dnf/pacman/apk via sudo
#   bash beautify.sh --no-rc      # install tools but do not edit .zshrc/.bashrc
#   bash beautify.sh --uninstall  # remove the shell block
# =============================================================================
set -u

MODE="user"        # user (default, no sudo) | system (native pkg mgr + sudo)
DO_RC=1
ACTION="install"

for a in "$@"; do
  case "$a" in
    --system)    MODE="system" ;;
    --no-rc)     DO_RC=0 ;;
    --uninstall) ACTION="uninstall" ;;
    --print-block) ACTION="printblock" ;;
    -h|--help)   ACTION="help" ;;
    *) echo "unknown option: $a"; ACTION="help" ;;
  esac
done

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share"
OS="$(uname -s)"

say(){ printf '  %s\n' "$*"; }
hr(){ printf '\n== %s ==\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
warn(){ printf '  ! %s\n' "$*" >&2; }

TOOLS="starship zoxide eza bat fd fzf ripgrep micro tldr autosuggestions highlighting"

# ----------------------------------------------------------------------------
# help
# ----------------------------------------------------------------------------
show_help(){
  cat <<'H'
CLI Beautify installer
  Installs: starship zoxide eza bat fd fzf ripgrep micro tldr
            zsh-autosuggestions zsh-syntax-highlighting
  macOS uses Homebrew; Linux defaults to a no-sudo ~/.local install.

  bash beautify.sh              default (brew on mac, ~/.local on linux)
  bash beautify.sh --system     linux: native package manager via sudo
  bash beautify.sh --no-rc      install tools, do not edit shell files
  bash beautify.sh --uninstall  remove the shell block
H
  exit 0
}

# ----------------------------------------------------------------------------
# eget: one small helper binary that grabs prebuilt releases from GitHub.
# Used for the no-sudo Linux path so we never need root or build tools.
# ----------------------------------------------------------------------------
ensure_eget(){
  have "$BIN/eget" && return 0
  mkdir -p "$BIN"
  say "installing eget (release fetcher) into ~/.local/bin"
  ( cd "$BIN" && curl -fsSL https://zyedidia.github.io/eget.sh | sh ) >/dev/null 2>&1 \
    || { warn "could not install eget"; return 1; }
}

eget_get(){ # eget_get <repo> [extra args]
  "$BIN/eget" "$1" --to "$BIN" ${2:-} >/dev/null 2>&1 && say "ok  $1" || warn "failed $1"
}

# ----------------------------------------------------------------------------
# zsh plugins (git clone into ~/.local/share) - used when not from a pkg manager
# ----------------------------------------------------------------------------
clone_plugins(){
  mkdir -p "$SHARE"
  [ -d "$SHARE/zsh-autosuggestions" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$SHARE/zsh-autosuggestions" >/dev/null 2>&1 \
      && say "ok  zsh-autosuggestions" || warn "zsh-autosuggestions clone"
  [ -d "$SHARE/zsh-syntax-highlighting" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$SHARE/zsh-syntax-highlighting" >/dev/null 2>&1 \
      && say "ok  zsh-syntax-highlighting" || warn "zsh-syntax-highlighting clone"
}

# ----------------------------------------------------------------------------
# macOS: Homebrew
# ----------------------------------------------------------------------------
install_mac(){
  if ! have brew; then
    say "Homebrew not found. Installing it (needs your password once)."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      warn "Homebrew install failed"; return 1; }
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  say "brew install the toolkit"
  brew install starship zoxide eza bat fd fzf ripgrep micro tlrc \
               zsh-autosuggestions zsh-syntax-highlighting
}

# ----------------------------------------------------------------------------
# Linux, no sudo: everything into ~/.local/bin via eget + git-clone plugins
# ----------------------------------------------------------------------------
install_linux_user(){
  mkdir -p "$BIN" "$SHARE"
  ensure_eget || return 1
  say "fetching prebuilt binaries into ~/.local/bin"
  eget_get starship/starship
  eget_get ajeetdsouza/zoxide
  eget_get eza-community/eza
  eget_get sharkdp/bat
  eget_get sharkdp/fd
  eget_get junegunn/fzf
  eget_get BurntSushi/ripgrep
  eget_get zyedidia/micro
  eget_get tldr-pages/tlrc
  clone_plugins
}

# ----------------------------------------------------------------------------
# Linux, --system: use the native package manager for what it has, then fill
# any gaps (starship, eza, micro, tldr often missing) with eget into ~/.local.
# ----------------------------------------------------------------------------
install_linux_system(){
  local S=""; [ "$(id -u)" -ne 0 ] && S="sudo"
  if   have apt-get; then
    $S apt-get update -y
    $S apt-get install -y bat fd-find ripgrep fzf zoxide micro \
         zsh-autosuggestions zsh-syntax-highlighting || true
    # Debian/Ubuntu name them batcat/fdfind; give them their real names in ~/.local/bin
    mkdir -p "$BIN"
    have batcat && ln -sf "$(command -v batcat)" "$BIN/bat"
    have fdfind && ln -sf "$(command -v fdfind)" "$BIN/fd"
  elif have dnf; then
    $S dnf install -y bat fd-find ripgrep fzf zoxide micro \
         zsh-autosuggestions zsh-syntax-highlighting || true
  elif have pacman; then
    $S pacman -Sy --noconfirm starship zoxide eza bat fd fzf ripgrep micro tealdeer \
         zsh-autosuggestions zsh-syntax-highlighting || true
  elif have apk; then
    $S apk add starship zoxide eza bat fd fzf ripgrep micro \
         zsh-autosuggestions zsh-syntax-highlighting || true
  else
    warn "no known package manager; falling back to the home-folder method"
    install_linux_user; return $?
  fi
  # Fill gaps with eget (only for tools still missing)
  ensure_eget || return 0
  have starship || eget_get starship/starship
  have eza      || eget_get eza-community/eza
  have tldr     || eget_get tldr-pages/tlrc
  have micro    || eget_get zyedidia/micro
  [ -d "$SHARE/zsh-autosuggestions" ] || [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] || clone_plugins
}

# ----------------------------------------------------------------------------
# Shell wiring. Idempotent: bracketed by markers, re-running replaces the block.
# ----------------------------------------------------------------------------
MARK_A="# >>> cli-beautify >>>"
MARK_B="# <<< cli-beautify <<<"

emit_block(){ # emit_block <zsh|bash>
  local sh="$1"
  cat <<EOF
$MARK_A
# Added by CLI Beautify installer. Safe to delete this whole block.
case ":\$PATH:" in *":\$HOME/.local/bin:"*) ;; *) export PATH="\$HOME/.local/bin:\$PATH" ;; esac
[ -x /opt/homebrew/bin/brew ] && eval "\$(/opt/homebrew/bin/brew shellenv)"
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
command -v starship >/dev/null && eval "\$(starship init $sh)"
command -v zoxide   >/dev/null && eval "\$(zoxide init $sh)"
command -v fzf      >/dev/null && source <(fzf --$sh) 2>/dev/null
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -l --icons=auto --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons=auto'
fi
command -v bat >/dev/null && { alias cat='bat'; export BAT_THEME="GitHub"; }
EOF
  if [ "$sh" = "zsh" ]; then
    cat <<'EOF'
for f in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "$HOME/.local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  [ -f "$f" ] && source "$f" && break
done
for f in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "$HOME/.local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  [ -f "$f" ] && source "$f" && break
done
EOF
  fi
  echo "$MARK_B"
}

unwire_one(){ # unwire_one <rcfile>
  local rc="$1"; [ -f "$rc" ] || return 0
  grep -q "$MARK_A" "$rc" || return 0
  local tmp; tmp="$(mktemp)"
  awk -v a="$MARK_A" -v b="$MARK_B" '
    $0 ~ a {skip=1}
    skip==0 {print}
    $0 ~ b {skip=0}
  ' "$rc" > "$tmp" && mv "$tmp" "$rc"
}

wire_one(){ # wire_one <rcfile> <shell>
  local rc="$1" sh="$2"
  touch "$rc"
  cp "$rc" "$rc.bak.cli-beautify-$(date +%Y%m%d%H%M%S)"
  unwire_one "$rc"                 # remove any previous block first (idempotent)
  printf '\n%s\n' "$(emit_block "$sh")" >> "$rc"
  say "wired $rc"
}

wire_rc(){
  [ "$DO_RC" -eq 1 ] || { say "skipping shell wiring (--no-rc)"; return 0; }
  wire_one "$HOME/.zshrc" zsh
  have bash && wire_one "$HOME/.bashrc" bash
}

unwire_rc(){
  unwire_one "$HOME/.zshrc"
  unwire_one "$HOME/.bashrc"
  say "removed the CLI Beautify block from your shell files"
}

# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------
[ "$ACTION" = "help" ] && show_help
[ "$ACTION" = "printblock" ] && { emit_block zsh; echo; emit_block bash; exit 0; }

if [ "$ACTION" = "uninstall" ]; then
  hr "CLI Beautify uninstall"
  unwire_rc
  echo
  say "The shell block is gone. To also remove the programs:"
  if [ "$OS" = "Darwin" ]; then
    say "  brew uninstall starship zoxide eza bat fd fzf ripgrep micro tlrc zsh-autosuggestions zsh-syntax-highlighting"
  else
    say "  rm -f ~/.local/bin/{starship,zoxide,eza,bat,fd,fzf,rg,micro,tldr,eget}"
    say "  rm -rf ~/.local/share/zsh-autosuggestions ~/.local/share/zsh-syntax-highlighting"
    say "  (or use your package manager if you installed with --system)"
  fi
  exit 0
fi

hr "CLI Beautify installer  (mode: $MODE, os: $OS)"
case "$OS" in
  Darwin) install_mac ;;
  Linux)  [ "$MODE" = "system" ] && install_linux_system || install_linux_user ;;
  *) warn "unsupported OS: $OS (this script is for macOS and Linux; use beautify.ps1 on Windows)"; exit 1 ;;
esac

wire_rc

hr "Done"
say "Installed what it could. Open a NEW terminal, or run:  exec \$SHELL -l"
say "Check versions:  starship --version; eza --version; bat --version; tldr --version"
say "Remove later with:  bash beautify.sh --uninstall"
