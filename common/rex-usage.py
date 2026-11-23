import datetime as dt
import fcntl
import getpass
import json
import math
from pathlib import Path
import subprocess
import sys
import time
import urllib.error
import urllib.request


CACHE = Path.home() / ".cache/rex-usage"
PROVIDERS = ("Codex", "Claude")
INTERVAL = 300


def rex(*args):
    flags = [] if args[:2] == ("window", "rename") else ["--json"]
    result = subprocess.run(
        ["rex", "--autostart=false", *args[:2], *flags, *args[2:]],
        capture_output=True, text=True, check=True, timeout=20,
    )
    return json.loads(result.stdout) if result.stdout.strip() else None


def fetch(provider):
    if provider == "Codex":
        tokens = json.loads((Path.home() / ".codex/auth.json").read_text())["tokens"]
        url = "https://chatgpt.com/backend-api/wham/usage"
        headers = {
            "Authorization": "Bearer " + tokens["access_token"],
            "ChatGPT-Account-Id": tokens["account_id"],
        }
    else:
        result = subprocess.run(
            ["/usr/bin/security", "find-generic-password", "-a", getpass.getuser(),
             "-s", "Claude Code-credentials", "-w"],
            capture_output=True, text=True, check=True, timeout=10,
        )
        token = json.loads(result.stdout)["claudeAiOauth"]["accessToken"]
        url = "https://api.anthropic.com/api/oauth/usage"
        headers = {"Authorization": "Bearer " + token, "anthropic-beta": "oauth-2025-04-20"}
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=20) as response:
        data = json.load(response)
    return weekly(provider, data)


def weekly(provider, data):
    if provider == "Codex":
        window = next(
            window for window in data["rate_limit"].values()
            if isinstance(window, dict) and window.get("limit_window_seconds") == 604800
        )
        used, reset = window["used_percent"], window["reset_at"]
    else:
        window = data["seven_day"]
        used = window["utilization"]
        reset = dt.datetime.fromisoformat(window["resets_at"]).timestamp()
    if not 0 <= used <= 100 or not math.isfinite(reset):
        raise ValueError("Invalid usage window")
    return {"used": used, "reset": reset, "updated": time.time()}


def read_cache(provider):
    try:
        return json.loads((CACHE / f"{provider}.json").read_text())
    except (FileNotFoundError, ValueError):
        return {}


def label(provider, data, now=None):
    now = time.time() if now is None else now
    if "used" not in data:
        return f"{provider} · unavailable"
    if data.get("error") or now - data["updated"] > INTERVAL * 2 or now >= data["reset"]:
        return f"{provider} · stale"
    filled = int(data["used"] / 20 + 0.5)
    bar = "▰" * filled + "▱" * (5 - filled)
    days = max(0, data["reset"] - now) / 86400
    name = "Codex\u2004" if provider == "Codex" else provider
    return f"{name} {bar} · {days:.0f}d"


def refresh(provider):
    try:
        data = fetch(provider)
    except (OSError, ValueError, KeyError, TypeError, StopIteration, subprocess.SubprocessError) as error:
        data = read_cache(provider)
        data["error"] = (
            f"HTTP {error.code}" if isinstance(error, urllib.error.HTTPError)
            else type(error).__name__
        )
    temporary = CACHE / f"{provider}.tmp"
    temporary.write_text(json.dumps(data))
    temporary.replace(CACHE / f"{provider}.json")


def sync_tabs():
    sessions = rex("session", "ls")["sessions"]
    for session in sessions:
        if session["label"] != "dotfiles":
            continue
        session_id = session["session_id"]
        view = rex("session", "inspect", session_id)
        windows = view["windows"]
        if not windows or windows[0]["label"] != "dotfiles":
            continue
        for position, provider in enumerate(PROVIDERS, 1):
            title = label(provider, read_cache(provider))
            prefixes = tuple(
                provider + padding + marker
                for padding in (" ", "\u2002 ", "\u2004 ") for marker in ("▰", "▱", "·")
            )
            window = next((w for w in windows if w["label"].startswith(prefixes)), None)
            if window is None:
                created = rex(
                    "window", "new", "-s", session_id, title, "--focus=false",
                    "--shell=none", "--", sys.executable, str(Path(__file__).resolve()),
                    "--display", provider,
                )
                window = {"window_id": created["window_id"], "label": title}
                windows.append(window)
            if window["label"] != title:
                rex("window", "rename", "-s", session_id, window["window_id"], title)
            if windows.index(window) != position:
                rex("api", "call", "session.move_window", json.dumps({
                    "session_id": session_id,
                    "window_id": window["window_id"],
                    "before_window_id": windows[position]["window_id"],
                }))
                windows.remove(window)
                windows.insert(position, window)
        return


def display(provider):
    app = "codex" if provider == "Codex" else "claude-code"
    print(f"\033]7501;state=idle:app={app}\033\\", end="", flush=True)
    while True:
        data = read_cache(provider)
        print("\033[2J\033[H" + label(provider, data), flush=True)
        print("\nWeekly usage · days until reset")
        if "updated" in data:
            print("Last successful refresh:", dt.datetime.fromtimestamp(data["updated"]).astimezone().isoformat(timespec="seconds"))
            print("Resets:", dt.datetime.fromtimestamp(data["reset"]).astimezone().isoformat(timespec="seconds"))
        if data.get("error"):
            print("\nRefresh failed:", data["error"])
            print("If authentication expired, sign in with the provider's CLI.")
        print("\nRefreshes every five minutes, even when this tab is inactive.", flush=True)
        time.sleep(30)


def main():
    CACHE.mkdir(parents=True, exist_ok=True, mode=0o700)
    if len(sys.argv) > 1 and sys.argv[1] == "--display":
        display(sys.argv[2])
        return
    with (CACHE / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        next_refresh = 0
        while True:
            if time.monotonic() >= next_refresh:
                for provider in PROVIDERS:
                    refresh(provider)
                next_refresh = time.monotonic() + INTERVAL
            try:
                sync_tabs()
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                detail = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
                print(f"Rex usage tabs: {detail}", file=sys.stderr, flush=True)
            if "--once" in sys.argv:
                return
            time.sleep(30)


if __name__ == "__main__":
    main()
