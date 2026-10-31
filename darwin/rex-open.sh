# Open a ~/work project in the current Rex session: update or clone it, name
# this session after it, then cd into it and start claude in this terminal.
# Installed as `rex-open` via writeShellApplication (darwin/home.nix), which
# runs it under `set -euo pipefail`; `rex` itself comes from the Rex terminal.

name=${1:-}
if [ -z "$name" ]; then
  echo "usage: rex-open <project>   (a ~/work folder or a teamniteo/mayetrx repo)"
  exit 1
fi
if ! command -v rex >/dev/null || [ -z "${REX_SESSION:-}" ] || [ -z "${REX_BLOCK:-}" ]; then
  echo "FAILED: not inside a Rex terminal (need rex on PATH, REX_SESSION and REX_BLOCK)"
  exit 1
fi
dir="$HOME/work/$name"
err=$(mktemp)
trap 'rm -f "$err"' EXIT

if [ -d "$dir" ]; then
  cd "$dir" || { echo "FAILED: cannot cd into $dir"; exit 1; }
  if ! git checkout -q main 2>"$err"; then
    echo "FAILED: git checkout main in $dir: $(cat "$err")"
    echo "on branch: $(git rev-parse --abbrev-ref HEAD)"
    exit 1
  fi
  echo "checked out: main"
  # fetch + merge rather than `pull`, so pull.rebase in gitconfig cannot
  # turn this into a rebase that balks at unrelated local changes.
  if git fetch -q origin main 2>"$err" && git merge -q --ff-only origin/main 2>"$err"; then
    echo "pulled: origin/main ($(git rev-parse --short HEAD))"
  else
    echo "FAILED: fast-forward to origin/main: $(cat "$err")"
    exit 1
  fi
  if [ -f .envrc ]; then
    direnv reload >/dev/null 2>&1 && echo "direnv: reloaded" || echo "FAILED: direnv reload"
  fi
else
  cloned=""
  for owner in teamniteo mayetrx; do
    gh repo view "$owner/$name" >/dev/null 2>&1 || continue
    if gh repo clone "$owner/$name" "$dir" -- -q 2>"$err"; then
      echo "cloned: $owner/$name -> $dir"
      cloned=1
    else
      echo "FAILED: gh repo clone $owner/$name: $(cat "$err")"
      exit 1
    fi
    break
  done
  if [ -z "$cloned" ]; then
    echo "FAILED: no repo named $name under teamniteo or mayetrx on GitHub"
    exit 1
  fi
  cd "$dir" || exit 1
  if [ -f .envrc ]; then
    direnv allow >/dev/null 2>&1 && echo "direnv: allowed" || echo "FAILED: direnv allow"
  fi
fi

if rex session ls --json | jq -e --arg l "$name" 'any(.sessions[]; .label == $l)' >/dev/null; then
  echo "note: another session is already labelled $name"
fi
if rex session rename "$REX_SESSION" "$name" >/dev/null; then
  echo "session: renamed this session to $name"
else
  echo "FAILED: rex session rename $REX_SESSION $name"
  exit 1
fi

# A script cannot cd its parent shell, so type the last step into this very
# terminal; it runs as soon as this script exits.
rex send -b "$REX_BLOCK" "cd $(printf %q "$dir") && claude"$'\n'
