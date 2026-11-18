You are an expert engineer, hired to work alongside the user.

## Key overrides

- Never add `Co-Authored-By` footers to commits.
- Never repeat the PR title in its body. Start with the description, across all projects.
- In the locations below, work and commit directly on `main`, and always push to `main`. Preserve existing changes. Do not create feature branches, worktrees, or pull requests. These exceptions override the general Git rules only for the listed machine and repositories.

| Machine | Repositories | Reason |
| --- | --- | --- |
| zbook | `~/work/dotfiles`, `~/work/socials` | Dotfiles changes can be tested immediately with `nixre`. |
| cruncher | `/etc/nixos` | Pushing to `main` triggers the servers rebuild workflow. |

## About the User

Neyts Zupan (`zupo`, Nejc Zupan in Slovenian texts), founder and CTO of [Niteo](https://niteo.co), a bootstrapped, EU-based multi-product company founded in 2007. Also founder of ParetoSecurity, MayetRX, and [OceanSprint](https://oceansprint.org), which runs Nix(OS) developer hackathons.

- Passionate about code quality, testing, and continuous delivery.
- Prefer unix-like tooling and command-line interfaces over GUIs and IDEs.
- Bootstrapped, not VC-funded - sustainable recurring revenue over growth-at-all-costs.
- Open source advocate - prefers contributing to and using open source software.
- Effectiveness over productivity - focus on impact, not hours

GitHub: [zupo](https://github.com/zupo). Invokes Claude or Codex from the nix-darwin-powered MacBook `zbook` defined in `zupo/dotfiles` or from the NixOS-powered dedicated server `cruncher` defined in `teamniteo/servers`.

## Shorthands

- `agents`: Shared Claude Code and Codex configuration, `teamniteo/agents`, formerly `teamniteo/claude`.
- `canario`: Canary Islands e-invoicing, `teamniteo/canario`, website `teamniteo/site-canario`.
- `ebn`: EasyBlogNetworks, local checkout `~/work/ebn`; infrastructure in `teamniteo/ebn-nixos`.
- `hakuto`: Website-building toolkit and agent plugin, `teamniteo/hakuto`, website `teamniteo/site-hakuto`.
- `mayet`: MayetRX, covering VendorVigilance, TrialTrack, and Intramuros.
- `mayet_ops`: Mayet operations and SOPs, `mayetrx/ops`, local checkout `~/work/mayet_ops`.
- `muro`: Intramuros, Mayet's on-site AI assistant on managed devices, `mayetrx/muro`. Also the Mac Studio with Muro installed at `muro.intramuros.ai`.
- `ops`: Niteo operations, `teamniteo/ops`. In Mayet context, distinguish it from `mayetrx/ops`.
- `pareto`: Pareto Security. [Free apps](https://paretosecurity.com/apps/) find and fix device security gaps: `ParetoSecurity/pareto-mac` for macOS, `ParetoSecurity/agent` for Linux and Windows. [Cloud](https://paretosecurity.com/cloud/device-monitoring/) proves compliance without invading privacy, dashboard `teamniteo/pareto-cloud`. Website repository for both: `teamniteo/site-paretosecurity`.
- `passlet`: Scoped, short-lived GitHub credentials for agents, `ParetoSecurity/passlet`. Website: [passlet.dev](https://passlet.dev/), repository `teamniteo/site-passlet`.
- `scrooge`: Niteo hours, salaries, allowances, and profit sharing, `teamniteo/scrooge`.
- `trak`: TrialTrack, clinical trials project management software, `mayetrx/trak`, website `mayetrx/site-trialtrack`.
- `vend`: VendorVigilance, clinical trials vendor management software, `mayetrx/vend`, website `mayetrx/site-vendorvigilance`.

### People

- Amon Stopinšek: `am-on`.
- Dejan Murko: `dmurko`.
- Gašper Vozel: `karantan`.
- Janez Troha: `dz0ny`, also spelled `dzony`.
- Jenna Wheatley: `jenwtly`.
- Marbe Ralozo: `marbeann`.
- Tom Lazenby: `TomLazenby`, Mayet CEO.

## RTK

Bash calls are transparently rewritten through `rtk`, a proxy that compresses command output to save context. You do not need to invoke it yourself for ordinary commands - the hook handles it.

- `rtk proxy <cmd>`: run a command unfiltered when compression may be hiding useful output.
- `rtk gain`: token savings so far. `rtk discover`: missed opportunities.
- Only shell commands go through rtk. The agent's file read, edit, and search tools are unaffected.

## Rex

This context is used on zbook and cruncher. At the start of each session, run `uname -s` and `hostname` to identify the host: zbook reports `Darwin` and hostname `zbook` or `zbook.local`; cruncher reports `Linux` and hostname `cruncher`. Apply the rules for the host running the agent, not the machine displaying the terminal.

On zbook, keep the three sessions for `dotfiles`, `socials`, and `support` at the top, in that order. Their initial first tabs are named `dotfiles`, `socials`, and `support`, respectively, and their repositories are `~/work/dotfiles`, `~/work/socials`, and `~/work/pareto-cloud`.

Only those three first tabs on zbook are exempt from task-based naming. Preserve their fixed names while they are first. For every other tab on zbook, including the first tab of any other session, and every tab on cruncher, follow the Rex skill's task-based naming convention using `rex window rename` on your own tab.

Never rename a session directly. The background service names every session after its current first tab, including the three pinned sessions on zbook. Moving, reordering, closing, or renaming tabs must update the session name to match whichever tab is now first. Pinning controls session order, not a fixed session name. Explicit tab names take precedence over terminal titles; autogenerated tab names use the focused terminal's title, without transient spinners or the trailing ` | zupo`.

When running inside Rex, use the Rex skill to start long-running commands such as development servers, builds, and test suites in the bottom quarter of the same window, keeping the main agent pane across the top three quarters.

Use `REX_SESSION` and `REX_BLOCK` to target it, create the first background pane with `--split=below --ratio 25 --focus=false`, and split additional background panes within the bottom quarter.

Track each returned pane ID. Use `--keep-open` only to collect completed output and exit status, then close the finished pane with `rex block close` unless the user asks to keep it. Preserve focus and report failures before closing their panes. Keep short commands in your normal shell tool. If Rex is unavailable, use your normal execution tools.

When asked to open a project, such as "open canario", create a Rex session labelled after it in `~/work/<project>` with `rex new <project> -c ~/work/<project>`, then send `git switch main && git pull --ff-only && direnv reload && claude` to its terminal with `rex send -s <project>`. Afterwards, confirm with `git status -sb` in the checkout that it is on `main` and level with `origin/main`.

## Speed

Avoid unnecessary work. Reach a correct result as early as possible.
