"""Install codex's config.toml as a writable file.

Home Manager would symlink it into /nix/store, but codex writes to this file at
runtime - directory trust, `codex features enable`, `/model` - and a read-only
symlink makes that fail with "failed to persist config at /nix/store/...".

So Nix owns the content and this script installs a real copy, carrying forward
the state codex writes for itself: `[projects]` trust entries and `[hooks.state]`
hook-trust records (`/hooks`). Entries declared in Nix win over the ones codex
wrote.
"""

import os
import shutil
import sys
import tomllib


def load(path):
    """Return the parsed TOML file, or {} if unreadable."""
    try:
        with open(path, "rb") as handle:
            return tomllib.load(handle)
    except (FileNotFoundError, IsADirectoryError, tomllib.TOMLDecodeError):
        return {}


def projects(path):
    """Return the `[projects]` table of a TOML file, or {} if unreadable."""
    return load(path).get("projects", {})


def hook_state(path):
    """Return the `[hooks.state]` table of a TOML file, or {} if unreadable."""
    hooks = load(path).get("hooks", {})
    return hooks.get("state", {}) if isinstance(hooks, dict) else {}


def toml_scalar(value):
    """Render a scalar as TOML, or None for anything this script won't emit."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str) and '"' not in value and "\\" not in value and "\n" not in value:
        return '"%s"' % value
    return None


def main():
    generated, target = sys.argv[1], sys.argv[2]

    declared = projects(generated)
    carried = {
        path: table
        for path, table in projects(target).items()
        if path not in declared
    }
    declared_state = hook_state(generated)
    carried_state = {
        key: table
        for key, table in hook_state(target).items()
        if key not in declared_state and isinstance(table, dict)
    }

    # Written alongside the target and renamed, so a failure part-way through
    # cannot leave codex without a config.
    scratch = target + ".new"
    os.makedirs(os.path.dirname(target), exist_ok=True)
    shutil.copyfile(generated, scratch)

    with open(scratch, "a") as handle:
        for path, table in sorted(carried.items()):
            level = table.get("trust_level")
            # Appending is only valid TOML while the paths stay unique and
            # quotable; anything unexpected is dropped rather than corrupting
            # the file.
            if not isinstance(level, str) or '"' in path or '"' in level:
                continue
            handle.write('\n[projects."%s"]\ntrust_level = "%s"\n' % (path, level))

        for key, table in sorted(carried_state.items()):
            if '"' in key:
                continue
            rows = [(k, toml_scalar(v)) for k, v in table.items()]
            # A record with a value this script cannot render safely is dropped
            # whole rather than written half; codex will just ask to trust again.
            if not rows or any(r is None for _, r in rows) or any('"' in k for k, _ in rows):
                continue
            handle.write('\n[hooks.state."%s"]\n' % key)
            for k, rendered in rows:
                handle.write("%s = %s\n" % (k, rendered))

    os.chmod(scratch, 0o644)
    os.replace(scratch, target)


main()
