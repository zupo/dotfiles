# SLOW.md — Claude Code burns CPU when idle

**STATUS: back as of 2026-08-29, different mechanism.** The 2.1.241 fix was
real and still holds — the directory-walk storm has not returned. What is
biting now is the *heap*: sessions reach 6–14 GB (peak 28 GB), exhaust 16 GB
of RAM, and the resulting swap thrash burns 250–350% CPU. Our own
`BUN_JSC_gcMaxHeapSize` cap was making it strictly worse and has been removed.

History: original investigation 2026-08-23 on `zbook` (M-series, 8 cores, 16 GB)
against 2.1.233; clean re-measurement 2026-08-24 against 2.1.241; regression
found 2026-08-30. Kept in full because the measurement traps below cost real
time and keep costing it.

## 2026-08-30 — it came back, and our own tuning was half of it

Symptom: machine unusable, `claude` had to be killed every ~5 minutes. Still
2.1.241 — **the version did not change**. Uptime 8 d 19 h, load average 13.4.

| Metric | 2026-08-24 (good) | 2026-08-30 (bad) |
|---|---|---|
| `phys_footprint`, fresh session | 350–500 MB | **11 GB** (peak 14 GB) |
| `phys_footprint`, `--resume` session | not tested | **14 GB, peak 28 GB** |
| Idle/working CPU | 0.6–0.8% | **250–350%** |
| Threads above 1% CPU | 0 | **13** |
| Swap used | not recorded | **20.5 / 22 GB** |
| Pageouts | 734 k (2026-08-23) | **4.47 M** |
| `kernel_task` | — | **95%** |

### The chain

1. Session heaps reach 6–14 GB. This is upstream's bug ([#86202][i4]) and
   nothing here fixes it.
2. On 16 GB that exhausts RAM. macOS compresses and swaps; swap fills to
   20.5/22 GB and stays there.
3. Every GC mark now has to fault the heap back out of the compressor. The
   thread split is the 2.1.233 table again, but for a completely different
   reason — swap, not `getConfig()`:

   | Threads | sys | user | Identity | Cost |
   |---|---|---|---|---|
   | 5 | 0:06 | **0:46** | `Heap Helper Thread` — JSC GC marking | ~130% |
   | 8 | **0:43** | 0:02 | `Bun Pool 0-7` — page faults, not a dir walk | ~130% |

4. Kill `claude`, swap frees, the next session re-balloons in ~5 minutes. That
   is the loop.

The `atime` test still exonerates the directory walk: `plugins` and `projects`
were last read two days before the process started, `sessions`/`backups` only at
startup. **The 2.1.241 fix held. Do not go looking for the walk again.**

### Our own `BUN_JSC_*` caps were making it worse — removed

```
BUN_JSC_gcMaxHeapSize=1500000000      # 1.5 GB cap ... live heap 11 GB
BUN_JSC_smallHeapRAMFraction=0.05     # 800 MB on a 16 GB machine
BUN_JSC_mediumHeapRAMFraction=0.15    # 2.4 GB
```

JSC cannot collect its way under a 1.5 GB cap when the live set is 11 GB, so it
collects continuously and never converges — a memory problem converted into a
permanent CPU problem.

**Why the 2026-08-24 A/B could not see this:** the heap was 350–500 MB then,
i.e. *under* the cap, so the cap was inert. These vars are harmless right up
until the heap crosses them, and then they are actively harmful. An A/B run in
the healthy state cannot detect a lever that only engages in the sick state —
worth remembering for the next "measured at no improvement" conclusion.

The mimalloc pair was kept: purge is visibly returning pages (RSS oscillated
2450 → 1731 → 1031 MB while the footprint stayed at 11 GB, i.e. it is feeding
the compressor). Never A/B'd on its own.

### What actually changed between the 24th and the 29th

Not the version, not the model (`claude-opus-5` throughout). Transcript sizes:

```
Aug 20-25:   1-5 MB typical
Aug 27:      9.3 MB
Aug 28:     20.9 MB   <- largest ever recorded here
```

Plus 8+ days of uptime with swap never reclaimed. Both push the same way.

**Open question, not answered:** why a *fresh* session with a 154 KB transcript
reached 11 GB when the 2026-08-24 baseline was 350–500 MB at 131 KB. Caveat on
that comparison — the 11 GB session was actively running tool calls, the
baseline was idle. Not apples to apples, but 20–30x is not explained by that
either.

## 2026-08-24 — re-measurement on 2.1.241

Arrived via the `flake.lock` bump of `numtide/llm-agents.nix`
(`b4a6459` → `46e6a01`). 2.1.233 → 2.1.241.

| Metric | 2.1.233 | 2.1.241 |
|---|---|---|
| Idle CPU, steady state | 150–450% | **0.6–0.8%** |
| Threads above 1% CPU | 13 | **0** |
| Busiest thread | ~33% | 0.1% (`0:00.32` user / `0:00.06` sys, lifetime) |
| RSS, fresh session | 492 MB | 351–501 MB, oscillating, **returns to baseline** |
| RSS, resumed 2.5 MB transcript | 3002 MB at 96 s | **not retested — see Still untested** |

Idle trend, session age 4 → 15 min, 131 KB transcript, one sample/min:

```
t+ 1m  RSS= 495MB  CPU=3.6%      <- startup still settling
t+ 3m  RSS= 367MB  CPU=0.4%
t+ 6m  RSS= 500MB  CPU=0.7%      <- plateau
t+10m  RSS= 499MB  CPU=0.7%
t+11m  RSS= 416MB  CPU=0.8%      <- pages actually returned to the OS
t+12m  RSS= 351MB  CPU=0.5%
```

The oscillation matters: the old signature was *monotonic* growth. This is a
heap breathing normally, and the drops at t+11m/t+12m are `MIMALLOC_PURGE_DELAY=0`
doing its job.

### The directory walk is gone — atime-proven

Process started 10:37:40, checked at ~10:42 on trees nothing else had touched:

```
plugins          atime=2026-08-23 22:08:46   <- yesterday. Never read this run.
plugins/cache    atime=2026-05-05 11:51:09   <- months ago
sessions         atime=2026-08-24 10:37:44   <- startup only, once
backups          atime=2026-08-24 10:40:08   <- mtime==atime, a write, not a walk
```

No ~10 s timer, no `getdirentries64` storm. The `getConfig()` syscall problem in
[#22509][i1] is fixed.

### Attribution is clean — it was the version, not our mitigations

Both mitigations were **already live during the bad 2.1.233 readings** and are
still live now (verified against the running process, not just the config):

- env from the `claudeTuned` wrapper: `MIMALLOC_PURGE_DELAY=0`,
  `BUN_JSC_gcMaxHeapSize=1500000000`, `BUN_GC_TIMER_INTERVAL=300`, …
- `settings.json`: `syntaxHighlightingDisabled: true`, `tui: "fullscreen"`

So the only variable that changed is the version. `claudeTuned` did not fix
this; upstream did — though the mimalloc purge is visibly working, so the
wrapper is not inert either.

> **Superseded 2026-08-30.** The conclusion "the `BUN_JSC_*` caps are inert"
> was correct *for this reading* and wrong as a general claim. They were inert
> because the heap was 350–500 MB, i.e. under the 1.5 GB cap. At an 11 GB heap
> the same vars cause permanent emergency GC. They have been removed from
> `common/ai.nix`. See the 2026-08-30 section.

## Symptom (2.1.233 — historical)

An idle `claude` session sat at **150–450% CPU** (8 cores, so 100% = one core)
and grew to **2–3.7 GB RSS**. Got worse the longer the session lived. Machine
started swapping (`memory_pressure` showed 734k pageouts) and went unresponsive.

The process shows in Activity Monitor as `.claude-wrapped`, because the Nix
wrapper does `exec -a "$0"` and the real binary is the `.claude-wrapped` file.
It is Claude Code itself, not a daemon or a stray MCP server.

## If it comes back, do this first

0. **Look at `phys_footprint`, not RSS.** `footprint -p <pid>`. RSS lies by an
   order of magnitude once the heap is in the compressor — see the traps below.
1. **Check swap first:** `sysctl vm.swapusage`. If it is near-full, the CPU
   burn is a *symptom*; no amount of Claude tuning fixes a full swap. Reboot.
2. **`/clear`.** Best-confirmed fix upstream: 98% → 0.0% CPU, 2.0 GB → 160 MB
   ([#22509][i1]). The heap is dominated by the resumed transcript.
3. Avoid `--continue` / `--resume` into a huge transcript. Check the size:
   `du -sh ~/.claude/projects/<project>/*.jsonl`
4. Don't let a session's transcript balloon — big tool outputs (store listings,
   `sample` dumps, 300 KB file reads) all live in the JS heap for the whole
   session.

## What the evidence pointed to (2.1.233)

Thread split from `sample` on an idle session, which is the single most useful
measurement:

| Threads | CPU each | sys | user | Identity | 2.1.241 |
|---|---|---|---|---|---|
| 5 | ~33% | 0:02.8 | **0:41** | `Heap Helper Thread` — JSC GC marking | quiet at small transcript |
| 8 | 8–30% | **0:47** | 0:03 | `Bun Pool 0-7` — `getdirentries64`, `lstat` | **resolved** |

Two independent problems, and they needed different fixes:

- **GC threads (user time)** collecting over a large live heap. RSS tracked
  transcript size, not workload:

  | Session | Transcript | RSS |
  |---|---|---|
  | empty dir, fresh | none | 492 MB |
  | resumed | 2.5 MB | 3002 MB at 96 s old |

- **Bun Pool threads (sys time)** doing a directory walk on a ~10 s timer.
  `atime` testing located it in `~/.claude/{plugins,projects,sessions,backups}`.
  Upstream traced a `getConfig()` that does `existsSync()` + `statSync()` on
  *every* React render — ~438 call sites bypassing the settings store, measured
  at **638 syscalls/sec idle** ([#22509][i1]). Render-driven, which is why it was
  independent of cwd.

## Already ruled out — don't redo these

| Theory | How it died |
|---|---|
| VS Code state churning in the repo (`~/Library/Application Support/Code/User` → `vscode/`) | `atime` test: **0 of 2430** repo dirs read while walking. Not the cwd. |
| `.gitignore` not covering `vscode/globalStorage` etc. | Committed anyway (`17c155e`), harmless, changed nothing. |
| `--plugin-dir` from home-manager | 4 entries total. |
| `~/.claude/plugins` symlinking into big `/nix/store` closures | **0** store symlinks; 1947 entries either way. |
| MCP child processes | All at 0.0% CPU. |
| git / statusLine / hooks | `git status -uall` = 20 ms; no statusLine configured; hooks are fire-and-forget. |
| `tui = "fullscreen"` | Still untested as an A/B, and now moot. Was live during both the bad and the good readings. |
| The `claudeTuned` env vars in `common/ai.nix` | ~420% CPU before **and** after — but this verdict was WRONG, see 2026-08-30. The `BUN_JSC_*` caps were inert at a 500 MB heap and harmful at 11 GB. Removed. |
| `syntaxHighlightingDisabled` | No measurable difference. Live during both readings, so not the fix. |
| Reinstalling via npm / native installer | Upstream repros on **both** Node/V8 and Bun/JSC ([#86202][i4]). Nix was not implicated. |

## Measurement traps (each of these cost me time)

- **`ps -o rss=` is not the memory number.** Once pages are compressed or
  swapped, RSS collapses while the process still owns the memory. Measured on
  the same process, same second: `ps` said **326 MB**, `footprint` said
  **14 GB**. Use `footprint -p <pid>` (gives `phys_footprint` *and*
  `phys_footprint_peak`, which is how the 28 GB peak was found) or
  `top -l 1 -stats pid,command,mem,cmprs`. A process whose `CMPRS` ≈ its `MEM`
  is entirely in swap, and RSS will make it look idle and innocent.
- **`ps -o %cpu` is a lifetime average, not instantaneous.** On a 24-second-old
  process it is almost entirely startup cost. Always use a CPU-time delta.
- **A 30 s window is not steady state.** On a young process it still catches
  startup, plus the render work caused by your own probing. A 30 s window read
  **8%** on the same session that read **0.7%** over ten 1-minute samples.
  Sample 1/min for 10+ min before believing a number.
- **`ps -o time=` returns fractional seconds here** (`MM:SS.ss`), so feeding it
  to bash `$(( ))` dies with `arithmetic syntax error (error token is ".71")`.
  Do the arithmetic in `awk`.
- **`pgrep claude` finds nothing** — the Nix wrapper rewrites argv0. Match on
  `comm`: `ps -eo pid=,comm= | awk '$2=="claude"{print $1}'`
- **Identify *your own* session by walking up from `$$`.** Stale `claude`
  processes from earlier probes hang around and will silently poison a reading.
- **`ps -M` columns:** thread rows have 6 fields (`pid %cpu stat pri stime
  utime`), the process summary row has 9. Filter `NF==6`, then cpu=`$2`,
  sys=`$5`, user=`$6`. Getting this wrong produces convincing garbage.
- **`find` updates directory atime**, so the atime trick is single-use. Run it
  once, before anything else touches the tree — a stray `du -sh ~/.claude/projects`
  burns that tree for the rest of the session.
- **`lsof` cannot catch the walker's fds** — they are far shorter-lived than a
  `fork`+`exec` of lsof. 40 back-to-back snapshots returned identical results.
- **`stat` here is GNU stat** (from nix), so `-f` means "filesystem status", not
  BSD's format string. `stat -c '%n atime=%x'` is the atime one-liner.
- **`sample` output is address-only** (stripped binary). The *thread names* are
  the payload — `Heap Helper Thread` vs `Bun Pool N` vs `mi-scavenger`.
- `sudo fs_usage -w -f filesys <pid>` names the exact paths, but needs root, so
  it has to be run by hand. Never got run; was still the fastest way to settle
  "which tree is being walked".

## Probe scripts

Point-in-time. Note the awk arithmetic — see the traps above.

```bash
pid=$(ps -eo pid=,comm= | awk '$2=="claude"{print $1}' | head -1)
cput() { ps -o time= -p "$1" | tr -d ' ' \
  | awk -F: '{n=NF;s=$n;if(n>1)s+=$(n-1)*60;if(n>2)s+=$(n-2)*3600;printf "%.2f",s}'; }
a=$(cput $pid); sleep 30; b=$(cput $pid)
awk -v a="$a" -v b="$b" 'BEGIN{printf "CPU=%.1f%%\n",(b-a)/30*100}'
echo "RSS=$(( $(ps -o rss= -p $pid)/1024 ))MB  hot=$(ps -M -p $pid | awk 'NF==6 && $2+0>1' | wc -l)"
```

Trend — this is the one that actually settles it:

```bash
pid=$(ps -eo pid=,comm= | awk '$2=="claude"{print $1}' | head -1)
prev=$(cput $pid)
for i in $(seq 1 12); do
  sleep 60
  now=$(cput $pid); rss=$(ps -o rss= -p $pid) || break
  awk -v i="$i" -v p="$prev" -v n="$now" -v r="$rss" \
    'BEGIN{printf "t+%2dm  RSS=%4dMB  CPU=%.1f%%\n", i, r/1024, (n-p)/60*100}'
  prev=$now
done
```

Walk detection, single-use per tree:

```bash
cd ~/.claude && for d in plugins sessions backups todos shell-snapshots; do
  stat -c '%n  atime=%x  mtime=%y' "$d"
done; ps -o lstart= -p "$pid"
```

## Gotcha: settings.json is read-only

`~/.claude/settings.json` is a symlink into `/nix/store` (home-manager writes
it), so anything Claude Code tries to persist at runtime fails:

```
Failed to save setting: EACCES: permission denied, open '/nix/store/...-home-manager-files/.claude/settings.json.tmp...'
```

That breaks `/tui`, `/model`, theme selection and onboarding state. **Change
those in `common/ai.nix` and rebuild**, not in the TUI. If this becomes
annoying, the fix is to stop having home-manager manage `settings.json` and
have it write a copy at activation instead of a symlink — not investigated yet.

For a no-rebuild A/B, `claude --settings <file>` takes a copy of live settings
with one key changed.

## Upstream issues

| Issue | What it adds |
|---|---|
| [#22509][i1] | The deep one. `getConfig()` syscall storm, mimalloc/JSC analysis, `/clear` fix, `syntaxHighlightingDisabled`. macOS, `high-priority`. Symptoms gone as of 2.1.241. |
| [#17148][i2] | Oldest macOS idle-CPU report, has repro. |
| [#19393][i3] | 27 comments, several partial diagnoses. |
| [#86202][i4] | Runaway anon-memory growth; **repros on both Bun/JSC and Node/V8**. |

All were open as of 2026-08-23; not re-checked upstream on 2026-08-24, only
re-measured locally.

Nothing relevant in `numtide/llm-agents.nix` (searched all 200 issues) — it is a
packaging repo shipping the same upstream artifact, so bugs land upstream.

[i1]: https://github.com/anthropics/claude-code/issues/22509
[i2]: https://github.com/anthropics/claude-code/issues/17148
[i3]: https://github.com/anthropics/claude-code/issues/19393
[i4]: https://github.com/anthropics/claude-code/issues/86202

## Still untested

- ~~The resumed-transcript case.~~ **Confirmed 2026-08-30**: a `--resume`
  session in `~/work/servers` hit `phys_footprint` 14 GB with a 28 GB peak. It
  is the single worst offender. Don't resume into anything large.
- Whether `MIMALLOC_PURGE_DELAY=0` helps or hurts under memory pressure. It
  returns pages promptly, but under a full compressor that may just mean
  purge → compress → re-fault churn, which is where the `Bun Pool` sys time
  goes. Never A/B'd alone. **This is now the top open item.**
- Why a fresh 154 KB session reaches 11 GB at all (see 2026-08-30).
- Whether `syntaxHighlightingDisabled` earns its place. Never shown to help
  here.
- `CLAUDE_CODE_DISABLE_MEMORY_PERIODIC_RESYNC`, `_DISABLE_DIR_SYNC`,
  `_DISABLE_WORKING_SYNC`, `_DISABLE_FILE_CHECKPOINTING` — undocumented env
  switches scraped from the binary's strings. Bisect one at a time. Probably
  moot now.
