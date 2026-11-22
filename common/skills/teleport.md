# Teleport a conversation and its work

Run both skills on zbook. Push the current local conversation to cruncher, or pull a selected conversation from cruncher to zbook, preserving the agent, its native conversation, Git commit, staged and unstaged edits, and untracked project files. Resume in a persistent Rex terminal on the destination. Invocation authorizes this transfer and launch. Preview the concrete changes, then proceed unless a conflict or missing identity needs the user's decision. Do not switch agent or substitute a summary-only session without asking.

Use the Nix-pinned `hopsesh` for native transcript migration and path mapping. Do not install its upstream skill, hooks, login service, or updates: dotfiles manages its configuration. Its normal Git synchronization does not transfer dirty files. The workflow below prepares the checkout separately and uses `--no-sync`. No hopsesh daemon is installed or needed. Push starts a temporary helper on cruncher over SSH; pull reads cruncher over SSH. Every SSH, scp and rsync connection originates on zbook. Never enable Remote Login, inbound Rex access, or a receiver on the Mac. Source protection hooks are disabled because both agents' hooks are managed by Nix. After success, leave the source conversation idle.

## Identify and preflight

1. Run `uname -s`, `hostname`, and `pwd`. Read the Rex skill and use `rex whoami --json` to verify the inherited pane IDs. A Rex pane ID is not an agent conversation ID. If those IDs are stale, do not pick the user's focused pane as a substitute.
2. In push mode, identify the current local native conversation exactly. For Codex, use `CODEX_THREAD_ID` when present and verify it against the local session. For Claude, use the session ID from its hook/runtime context or correlate the current process and transcript with this conversation. `hopsesh ls --host local --agent codex --json` (or `claude`) and `hopsesh show <agent>/<full-id> --json` help verify the project and conversation. Never select the newest transcript merely by timestamp. Ask if multiple candidates remain. In pull mode, list `hopsesh ls --host cruncher --json`, narrow by the project or session the user named, and inspect `hopsesh show cruncher:AGENT/FULL_ID --json`. Ask the user to choose when ambiguous; never use the local coordinator's `CODEX_THREAD_ID` as the remote session ID.
3. Verify SSH with `ssh -o BatchMode=yes -o ConnectTimeout=10 cruncher 'hostname; printf "%s\n" "$HOME"; command -v hopsesh; command -v rex; command -v claude; command -v codex'`. Verify the destination agent is authenticated using its status command, without printing credentials. The destination needs its own login, tools, MCPs and browser. Never copy auth files, Passlet grants, shell snapshots, or entire agent configuration directories. Obtain any necessary GitHub grant on the destination before the Mac goes offline, following the Passlet skill.
4. Map paths under the source home to the same relative location under the verified destination home. For paths outside home, including `/etc/nixos`, inspect the destination checkout and establish the actual mapping. Record repo root, working directory relative to it, branch, HEAD, origin, staged/unstaged diffs and untracked paths. Inspect submodules and linked worktrees; their `.git` files refer to host-specific paths and must not be copied as ordinary directories.
5. Check `hopsesh hosts --json` and the host's SSH trust. Dotfiles declares only cruncher as a remote host and enables receiving only on Linux. If hopsesh needs its separate host-key record, compare the offered fingerprint with an already trusted SSH/Tailscale identity before `hopsesh trust cruncher --yes`. A new or changed identity needs the user's verification. Do not disable host-key checking. Missing `hopsesh` requires applying the dotfiles configuration, not running an installer.

## Prepare a matching checkout

Finish or stop this task's file-writing commands before snapshotting. In pull mode, inspect the selected remote Rex pane and agent state. Wait for its turn and background writers to finish; if it keeps working, ask the user to pause that specific session. Do not send arbitrary commands into an agent prompt. Do not interrupt unrelated processes. Write a private handoff note outside the repo with the objective, decisions, next step, tests, unresolved problems, source/destination paths and services that need restarting. Exclude secrets. Mark the teleport request as completed so the destination does not repeat it. Keep source files intact until destination verification succeeds. For a pull, read the selected remote conversation and task artifacts to write the note, not the unrelated local coordinator's history.

Preview the destination repository's identity, HEAD, branch, dirty status and running agents before changing it. Do not overwrite local edits, switch a checkout another agent is using, reset a branch, stash someone else's work, or run `rsync --delete`. Ask which checkout to use when work conflicts. Observe the main-only exceptions for dotfiles/socials on zbook and `/etc/nixos` on cruncher.

All commands run locally or through outbound `ssh cruncher`. For push, create bundles/patches locally and copy to `cruncher:PATH`; for pull, create them on cruncher over SSH and copy from `cruncher:PATH`. Run rsync locally in both directions. Never run SSH back to zbook from cruncher.

Save a private transfer receipt on zbook recording the source/destination session IDs, paths, HEAD, branch, separate patches, untracked manifest/hashes and handoff note. On a return, an unchanged outgoing checkout can still contain the edits left there. Compare it against the receipt byte for byte and confirm no agent is using it. Only if it exactly matches the recorded outgoing state, back it up, reverse the recorded unstaged patch, run `git update-index --refresh` to refresh matching worktree metadata, then reverse the staged patch (`git apply --reverse`, with `--index` for the staged patch), and move the recorded untracked files into the backup before restoring the incoming state. Never erase changes that differ from the receipt. Without an exact match, ask how to handle the conflict. Keep the backup until the returned session is verified.

For a Git project:

- Transfer committed history directly over SSH using a private `git bundle` containing HEAD and the needed branch, then clone or fetch it on the destination. Match the exact source commit and branch, including unpublished commits. Preserve the real origin URL when cloning a bundle. Existing branches may only move by a clean fast-forward. GitHub access, if necessary instead, goes through Passlet. Do not commit or push just to teleport.
- Export staged changes with `git diff --cached --binary --full-index` and unstaged changes with `git diff --binary --full-index` into separate private files. On a clean destination at the matching HEAD, preflight and apply the staged patch with `git apply --check --index` followed by `git apply --index`. Then check and apply the unstaged patch without `--index`. Skip empty patches. This preserves staged and unstaged versions of the same file, binary edits, modes and deletions. Handle failures before resuming an agent, preserve the patches and report any already-applied part instead of resetting it.
- Transfer untracked files from an explicit NUL-delimited `git ls-files --others --exclude-standard -z` manifest using a tool that supports NUL paths, such as `rsync --from0 --files-from`. Check for destination collisions before copying. Do not dereference symlinks. Check path and symlink targets so no transfer writes outside the intended checkout.
- Inspect ignored files separately. Recreate dependencies and build products on the destination OS. Report required ignored inputs that are absent, and ask before copying credentials, `.env` files or large runtime data. Handle submodule changes as their own repositories. If a file or process cannot be moved, report it rather than claiming a complete transfer.
- Verify matching HEAD and branch, both binary diffs, and the untracked-file inventory and hashes. Compare bytes without echoing file contents into the chat. Confirm the working directory exists and project setup succeeds there. Do not launch if the transferred work differs unexpectedly.

For non-Git work, preview an explicit file manifest and copy only task files into an empty or verified matching destination directory. Ask before replacing differing files.

## Move the native conversation

Use the exact source agent/id and destination cwd. In push mode, run and inspect:

```sh
hopsesh push AGENT/SESSION_ID cruncher --to DESTINATION_CWD --worktree main --no-sync --notify=false --dry-run --json
```

In pull mode, run and inspect:

```sh
hopsesh pull cruncher:AGENT/SESSION_ID --to DESTINATION_CWD --worktree main --no-sync --notify=false --dry-run --json
```

`--worktree main` uses the checkout already prepared above, including an explicitly prepared worktree, without letting hopsesh choose another path. Confirm the plan's actual target path. Explain the destination, files, conversation and anything left behind. Resolve blockers before proceeding. Do not pass `--replace`, `--keep-both`, `--new-session`, `--stop-local`, `--go`, or `--rc` to get around a conflict. For return trips, stop if the destination conversation is still open or both histories diverged; ask which history to retain.

Inspect `kind`, `placement.otherAccount`, and `continue.report` before transferring. Hopsesh 0.9.0 can choose portable history across machine profiles even when both Claude logins report the same email and organization. A `continue` plan may omit signed/encrypted reasoning, shorten tool outputs, or summarize older turns. Explain the actual loss report and get the user's explicit choice before using that path for a working conversation. Never describe it as an exact native-history transfer or override the account checks to force replay. Preserve the source if the user requires exact history.

Run the same command with `--yes` instead of `--dry-run`, adding a freshly generated `--operation-id` and retaining it. Inspect the JSON result, journal ID, warnings and resume command. If a connection fails, inspect the journal/destination before retrying; reuse the operation ID for the same transfer. Do not recopy changing transcripts or hand-edit Codex SQLite files. Copy the handoff note to a private destination path.

## Resume and verify in Rex

For a pull, use local `rex` on zbook. For a push, use `rex hosts` to discover cruncher's Rex endpoint; its label may be a Tailscale FQDN rather than the SSH alias. Use `rex -S ENDPOINT` or invoke the destination's `rex` over SSH. Verify `whoami` on that endpoint before creating anything. Launching an agent under an SSH command alone does not make it persistent; the destination Rex server must own its terminal.

Reuse the appropriate project session or create one. On zbook preserve the pinned dotfiles/socials/support sessions and their first tab names. Give the new tab a task name with `rex window new`, and pass `--focus=false`, `-c DESTINATION_CWD` and `--json`. Use the resumed ID from the migration result, which may differ from the source ID:

- Claude: `claude --resume RESUMED_ID PROMPT`
- Codex: `codex resume RESUMED_ID -C DESTINATION_CWD PROMPT`

The prompt must say the transfer has finished, identify the new host and paths, direct the agent to read the private handoff note and current local instructions, verify checkout state, discard stale Rex IDs/OS assumptions, and continue the original task. Use the destination's login environment/direnv. Preserve the source model and effort where supported by both installations; do not copy permission-bypass flags. Pass command arguments separately, or quote them with a proper shell-quoting function when crossing SSH.

Save returned Rex session/window/block IDs. Capture the destination pane and inspect its process. Confirm native history loaded and the resumed agent acknowledged the handoff on the intended host. Authentication/trust prompts, missing models, startup errors or an empty session mean the transfer is not verified. Leave the source intact and report the exact blocker. Do not claim that processes, in-memory tools or browser sessions moved.

After verification, report destination host, project, Rex tab and native session ID, plus anything that still needs attention. For push, end the source turn without further task edits. For pull, end the local coordinator turn and leave the remote source idle. Leave the source pane and transcript as recovery copies; do not terminate your own pane from inside it. Warn that sending more work to the old conversation will fork progress. A verified transfer can continue while the source is offline, provided the destination's own required network access and credentials remain available.

## Research

- [hopsesh](https://github.com/roeehrl/hopsesh): Claude and Codex native migration, path mapping, round-trip conflict checks and undo journals. Version 0.9.0 is pinned in dotfiles. Its undo covers conversation migration, not the separately transferred Git changes.
- [Sheprd Teleport](https://github.com/sheprd-labs/sheprd/blob/main/crates/sheprd-gpui/README.md#teleport): integrated worktree, tab and agent migration for Herdr, rather than Rex.
- [session-migrate](https://github.com/mkiiim/session-migrate): portable Claude/Codex bundles, with repository restoration left to the caller.
- [claude-session-teleport](https://github.com/superbereza/claude-session-teleport): Claude-specific transfer with tmux and Remote Control defaults.
- [parcels](https://github.com/0xSero/parcels): repository/session shipping with tmux, including `.env` files by default.

Rex supplies the persistent destination terminal. Reconnecting to the source's terminal is not migration and will not survive the source going offline.
