#!/bin/sh
# Open a ~/work project in Rex: update or clone it, then ensure its session.
set -u

name=${1:-}
if [ -z "$name" ]; then
  echo "FAILED: no project name given (usage: /rex-open vend)"
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
  if git pull -q --ff-only origin main 2>"$err"; then
    echo "pulled: origin/main ($(git rev-parse --short HEAD))"
  else
    echo "FAILED: git pull --ff-only origin main: $(cat "$err")"
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
  echo "session: $name already exists"
elif rex session new "$name" --cwd "$dir" >/dev/null; then
  echo "session: created $name in $dir"
else
  echo "FAILED: rex session new $name"
  exit 1
fi
