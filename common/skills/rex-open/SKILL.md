---
name: rex-open
description: Open a ~/work project in Rex by name. Brings an existing clone to a fresh origin/main and reloads direnv, or clones it from teamniteo or mayetrx on GitHub and allows direnv, then makes sure a Rex session for it exists.
---

The script below has just run with the project name `$ARGUMENTS`. Do not run
it again. Report its output to the user as one short list. If a line starts
with FAILED, show it verbatim and stop; the repo is in whatever state the line
describes and the user decides what to do next.

What `rex-open.sh` (next to this file) does for a name like `vend`:
- `~/work/vend` exists: `git checkout main`, `git pull --ff-only origin main`,
  `direnv reload` when there is an `.envrc`
- it does not exist: `gh repo clone` the first of `teamniteo/vend` and
  `mayetrx/vend` that exists into `~/work/vend`, then `direnv allow`
- then creates a Rex session labelled `vend` with its terminal in that folder
  unless one already exists

```
!`sh ~/.claude/skills/rex-open/rex-open.sh $ARGUMENTS`
```
