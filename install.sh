#!/usr/bin/env bash
#
# install.sh — link this dotfiles repository into $HOME.
#
# Safe to run repeatedly (idempotent). Never uses sudo.
# Existing files are moved to ~/.dotfiles-backup/<timestamp>/ before
# being replaced with symlinks; nothing is deleted.
#
# Usage:
#   ./install.sh              create/repair symlinks
#   ./install.sh --dry-run    show what would happen, change nothing
#   ./install.sh --help       show help

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$SCRIPT_DIR"
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
BACKUP_ROOT="$HOME_DIR/.dotfiles-backup"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"

DRY_RUN=0
BACKED_UP=0
LINKED=0
ALREADY=0
SKIPPED=0
ERRORS=0

# Source path (relative to the repo) -> destination path (relative to $HOME).
MAPPINGS=(
  "config/.config/hypr|.config/hypr"
  "config/.config/waybar|.config/waybar"
  "config/.config/kitty|.config/kitty"
  "config/.config/nvim|.config/nvim"
  "config/.config/zellij|.config/zellij"
  "shell/.bashrc|.bashrc"
  "shell/.zshrc|.zshrc"
  "git/.gitconfig|.gitconfig"
)

if [ -t 1 ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; RESET=''
fi

info()  { printf '%s[info]%s  %s\n'  "$BLUE"   "$RESET" "$*"; }
ok()    { printf '%s[ ok ]%s  %s\n'  "$GREEN"  "$RESET" "$*"; }
warn()  { printf '%s[warn]%s  %s\n'  "$YELLOW" "$RESET" "$*"; }
err()   { printf '%s[error]%s %s\n'  "$RED"    "$RESET" "$*" >&2; }

usage() {
  sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)    usage; exit 0 ;;
    *)            err "unknown option: $arg"; usage; exit 2 ;;
  esac
done

# ---- preflight -------------------------------------------------------------
if [ -z "${HOME_DIR:-}" ] || [ ! -d "$HOME_DIR" ]; then
  err "cannot determine a valid home directory"
  exit 1
fi
if [ ! -f "$REPO_DIR/install.sh" ]; then
  err "repository not found at $REPO_DIR"
  exit 1
fi

info "repository: $REPO_DIR"
info "home:       $HOME_DIR"
[ "$DRY_RUN" -eq 1 ] && warn "dry-run mode: no changes will be made"
echo

# ---- helpers ---------------------------------------------------------------
same_target() {
  # true when $1 is a symlink that already resolves to $2
  [ -L "$1" ] && [ -e "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]
}

backup_dest() {
  local dest="$1" rel="${1#"$HOME_DIR"/}" target
  if [ "$DRY_RUN" -eq 1 ]; then
    warn "would back up $dest -> $BACKUP_DIR/$rel"
    return
  fi
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  target="$BACKUP_DIR/$rel"
  # If a backup of the same name already exists, make it unique.
  if [ -e "$target" ] || [ -L "$target" ]; then
    target="$target.$RANDOM"
  fi
  mv "$dest" "$target"
  BACKED_UP=$((BACKED_UP + 1))
  warn "backed up $dest -> $target"
}

# ---- main loop -------------------------------------------------------------
for mapping in "${MAPPINGS[@]}"; do
  src_rel="${mapping%%|*}"
  dest_rel="${mapping#*|}"
  src="$REPO_DIR/$src_rel"
  dest="$HOME_DIR/$dest_rel"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    warn "source missing, skipping: $src_rel"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if same_target "$dest" "$src"; then
    ok "already linked: $dest"
    ALREADY=$((ALREADY + 1))
    continue
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup_dest "$dest"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    info "would link: $dest -> $src"
    LINKED=$((LINKED + 1))
    continue
  fi

  if ! mkdir -p "$(dirname "$dest")"; then
    err "cannot create parent directory for $dest"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ln -s "$src" "$dest"; then
    ok "linked: $dest -> $src"
    LINKED=$((LINKED + 1))
  else
    err "failed to link $dest"
    ERRORS=$((ERRORS + 1))
  fi
done

# ---- verify ----------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
  echo
  info "verifying links..."
  for mapping in "${MAPPINGS[@]}"; do
    src_rel="${mapping%%|*}"
    dest_rel="${mapping#*|}"
    src="$REPO_DIR/$src_rel"
    dest="$HOME_DIR/$dest_rel"
    [ ! -e "$src" ] && [ ! -L "$src" ] && continue
    if [ -L "$dest" ] && [ ! -e "$dest" ]; then
      err "broken symlink: $dest"
      ERRORS=$((ERRORS + 1))
    elif ! same_target "$dest" "$src"; then
      err "not correctly linked: $dest"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

# ---- summary ---------------------------------------------------------------
echo
printf '%sSummary%s\n' "$BLUE" "$RESET"
printf '  linked:      %d\n' "$LINKED"
printf '  already ok:  %d\n' "$ALREADY"
printf '  skipped:     %d\n' "$SKIPPED"
printf '  backed up:   %d\n' "$BACKED_UP"
printf '  errors:      %d\n' "$ERRORS"
if [ "$BACKED_UP" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  printf '  backup dir:  %s\n' "$BACKUP_DIR"
fi

if [ "$ERRORS" -gt 0 ]; then
  err "finished with $ERRORS error(s)"
  exit 1
fi
ok "done"
