"""Install codex's config.toml as a writable file.

Home Manager would symlink it into /nix/store, but codex writes to this file at
runtime - directory trust, `codex features enable`, `/model` - and a read-only
symlink makes that fail with "failed to persist config at /nix/store/...".

So Nix owns the content and this script installs a real copy, carrying forward
the `[projects]` trust entries codex added for itself. Entries declared in Nix
win over the ones codex wrote.
"""

import os
import shutil
import sys
import tomllib


def projects(path):
    """Return the `[projects]` table of a TOML file, or {} if unreadable."""
    try:
        with open(path, "rb") as handle:
            return tomllib.load(handle).get("projects", {})
    except (FileNotFoundError, IsADirectoryError, tomllib.TOMLDecodeError):
        return {}


def main():
    generated, target = sys.argv[1], sys.argv[2]

    declared = projects(generated)
    carried = {
        path: table
        for path, table in projects(target).items()
        if path not in declared
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

    os.chmod(scratch, 0o644)
    os.replace(scratch, target)


main()
