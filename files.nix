{ ... }:
{
  # Don't show the "Last login" message for every new terminal.
  home.file.".hushlogin" = {
    text = "";
  };

  # Taken from https://github.com/tobi/dotnix/blob/main/.claude/commands/

  # Claude command: /commit
  home.file.".claude/commands/commit.md" = {
    text = ''
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git reset:*), Bash(git add:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*)
description: Create a git commit
---

## resetting staged

`!git reset HEAD .`

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a series (stack) of logical git commits, make sure that each commit is holistic, don't commit a new library separately from the code that uses it. Aim for no more than 3 commits unless is definitely makes sense to go beyond it.

## Formatting

* Use `*` instead of `•` for bullet points.
* Ask me what issue this commit is related to, and append the link to it at the end of the commit message, like so: `Refs <>`
* Never, under any circumstance, append `Generated with Claude Code`.

## Reminders

- write a good commit message with excellent first line, bullet point list in summary.
- Under no circumstances commit binaries or large (1mb+) files, please stop the process and warn of those first and wait for me to decide what to do.
    '';
  };

  # Claude command: /nixos
  home.file.".claude/commands/nixos.md" = {
    text = ''
---
allowed-tools: Bash(hostname), Bash(cat:*), Bash/eza, Bash/find, Bash/rg, Bash/fd, Bash/pwd, Bash/realpath, mcp__mcp-nixos__nixos_search, mcp__mcp-nixos__home_manager_search, mcp__mcp-(nixos:*)
description: Context for nix based conversations.
---

You are an expert Nix wizard. You will help me with nix questions and nixos questions and home-manager questions. We are trying to create a very clean dotfiles/nixos machine setup here that is easy to maintain and follow.

Just load the context, then you can answer my questions about it.

<environment>
!`neofetch --pipe`
</environment>

<tree>
Full path: !`realpath .`
!`eza --tree .`
</tree>

<mcp-nixos>
Use `mcp-nixos` to get more information about packages and services. If present, ask mcp-nixos for its list of tools so that you know when to use it. If not present, tell me to install it.
</mcp-nixos>

<web>
Feel free to use the web tool to find information, good websites are:
- https://www.reddit.com/r/NixOS/
- https://search.nixos.org/packages
- https://nixos.org/manual/nixos/stable/
- https://nixos.org/manual/nixpkgs/stable/
- https://nix.dev/
etc.
</web>
  '';
  };

}
