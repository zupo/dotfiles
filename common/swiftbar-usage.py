import base64
import datetime as dt
import getpass
import json
import math
from pathlib import Path
import subprocess
import sys
import time
import urllib.error
import urllib.request


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


def label(data):
    reset = dt.datetime.fromtimestamp(data["reset"]).astimezone()
    return f"{100 - data['used']:.0f}%\\n{reset:%a}"


def template_image(provider, data):
    percent, day = label(data).split("\\n")
    widths = {"%": 889, "F": 611, "M": 833, "S": 667, "T": 611, "W": 944,
              "d": 611, "h": 611, "i": 278, "n": 611, "o": 611, "r": 389, "t": 333, "u": 611}
    def text_width(text):
        return sum(widths.get(char, 556) for char in text) * 9 / 1000
    column_width = max(text_width(percent), text_width(day))
    width = 21 + column_width
    icons = {
        "Claude": "q 0.75 0 0 -0.75 0 20 cm 4.7144 15.9555 m 9.4318 13.3084 l 9.5108 13.0777 l 9.4318 12.9502 l 9.2011 12.9502 l 8.4118 12.9016 l 5.7162 12.8287 l 3.3787 12.7316 l 1.1141 12.6102 l 0.5434 12.4887 l 0.0091 11.7845 l 0.0637 11.4323 l 0.5434 11.1105 l 1.2294 11.1713 l 2.7473 11.2745 l 5.024 11.4323 l 6.6754 11.5295 l 9.1222 11.7845 l 9.5108 11.7845 l 9.5654 11.6266 l 9.4318 11.5295 l 9.3286 11.4323 l 6.973 9.8356 l 4.423 8.1477 l 3.0874 7.1763 l 2.3649 6.6845 l 2.0006 6.2231 l 1.8428 5.2153 l 2.4985 4.4928 l 3.3788 4.5535 l 3.6034 4.6142 l 4.4959 5.3002 l 6.4023 6.7756 l 8.8916 8.6092 l 9.2559 8.9127 l 9.4016 8.8095 l 9.4198 8.7367 l 9.2558 8.4634 l 7.9019 6.0167 l 6.4569 3.5274 l 5.8134 2.4954 l 5.6434 1.876 l 5.5827 1.621 5.5402 1.4086 5.5402 1.1475 c 6.287 0.1335 l 6.6997 0 l 7.6954 0.1336 l 8.1144 0.4978 l 8.7336 1.9125 l 9.7354 4.1407 l 11.2897 7.1703 l 11.745 8.0688 l 11.9879 8.9006 l 12.0789 9.1556 l 12.2368 9.1556 l 12.2368 9.0099 l 12.3643 7.3039 l 12.6011 5.2092 l 12.8318 2.5135 l 12.9107 1.7546 l 13.2871 0.8439 l 14.0339 0.3521 l 14.6167 0.6314 l 15.0964 1.3174 l 15.0296 1.7607 l 14.7443 3.6124 l 14.1857 6.5145 l 13.8214 8.4574 l 14.0339 8.4574 l 14.2768 8.2145 l 15.2603 6.9092 l 16.9117 4.8449 l 17.6403 4.0253 l 18.4903 3.1207 l 19.0367 2.6896 l 20.0688 2.6896 l 20.8278 3.8189 l 20.4878 4.9846 l 19.4253 6.3324 l 18.5449 7.4738 l 17.2821 9.1738 l 16.4928 10.5338 l 16.5657 10.6431 l 16.7539 10.6248 l 19.6074 10.0178 l 21.1495 9.7384 l 22.9891 9.4227 l 23.8209 9.8113 l 23.9119 10.2059 l 23.5841 11.0134 l 21.6171 11.4991 l 19.3099 11.9605 l 15.8735 12.7741 l 15.831 12.8045 l 15.8796 12.8652 l 17.4278 13.0109 l 18.0896 13.0473 l 19.7106 13.0473 l 22.7281 13.272 l 23.5173 13.794 l 23.9909 14.4316 l 23.9119 14.9173 l 22.6977 15.5366 l 21.0584 15.148 l 17.2334 14.2373 l 15.9221 13.9094 l 15.7399 13.9094 l 15.7399 14.0187 l 16.8328 15.0873 l 18.8363 16.8965 l 21.3438 19.2279 l 21.4713 19.8047 l 21.1495 20.2601 l 20.8095 20.2115 l 18.6056 18.554 l 17.7556 17.8072 l 15.831 16.1862 l 15.7035 16.1862 l 15.7035 16.3562 l 16.1467 17.0058 l 18.4903 20.5272 l 18.6117 21.6079 l 18.4417 21.96 l 17.8346 22.1725 l 17.1667 22.0511 l 15.7946 20.1265 l 14.38 17.959 l 13.2386 16.0162 l 13.0989 16.0952 l 12.4249 23.3504 l 12.1093 23.7207 l 11.3807 24 l 10.7736 23.5386 l 10.4518 22.7918 l 10.7736 21.3165 l 11.1622 19.3919 l 11.4779 17.8619 l 11.7632 15.9615 l 11.9332 15.3301 l 11.9211 15.2876 l 11.7814 15.3058 l 10.3486 17.273 l 8.169 20.2176 l 6.4447 22.0632 l 6.0319 22.2272 l 5.3155 21.8568 l 5.3822 21.195 l 5.783 20.6061 l 8.169 17.5704 l 9.6079 15.6884 l 10.5369 14.6016 l 10.5307 14.4437 l 10.4761 14.4437 l 4.1376 18.5601 l 3.0083 18.7058 l 2.5226 18.2504 l 2.5834 17.5037 l 2.8141 17.2608 l 4.7205 15.9494 l 4.7144 15.9555 l h f Q",
        "Codex": "q 0.75 0 0 -0.75 0 20 cm 22.2819 9.8211 m 22.8248 8.1862 22.6369 6.3967 21.7662 4.9103 c 20.4571 2.6316 17.826 1.4595 15.2564 2.0103 c 13.8083 0.3995 11.6112 -0.3168 9.492 0.1311 c 7.3728 0.5789 5.6533 2.1229 4.9807 4.1818 c 3.2928 4.5279 1.836 5.5847 0.983 7.0818 c -0.3404 9.3568 -0.0401 12.2267 1.7257 14.1784 c 1.1808 15.8125 1.367 17.6022 2.2367 19.0891 c 3.5475 21.3686 6.1803 22.5406 8.7513 21.9892 c 9.8948 23.277 11.5377 24.0097 13.2599 24 c 15.8937 24.0024 18.2271 22.3021 19.0317 19.7942 c 20.7194 19.4475 22.176 18.3908 23.0294 16.8941 c 24.3368 14.6231 24.0351 11.7688 22.2819 9.8212 c 22.2819 9.8211 l h 13.2599 22.4292 m 12.2086 22.4309 11.1903 22.0624 10.3835 21.3884 c 10.5254 21.308 l 15.3037 18.5498 l 15.5456 18.4079 15.6949 18.149 15.6964 17.8685 c 15.6964 11.1316 l 17.7164 12.3002 l 17.7367 12.3105 17.7508 12.3298 17.7544 12.3522 c 17.7544 17.9348 l 17.7491 20.4148 15.7399 22.424 13.2599 22.4292 c h 3.5992 18.3038 m 3.072 17.3934 2.8827 16.3263 3.0646 15.2901 c 3.2066 15.3753 l 7.9896 18.1335 l 8.2306 18.2749 8.5292 18.2749 8.7702 18.1335 c 14.613 14.765 l 14.613 17.0974 l 14.6119 17.1219 14.5997 17.1445 14.5798 17.1589 c 9.74 19.9502 l 7.5893 21.1891 4.8416 20.4525 3.5992 18.3038 c h 2.3408 7.8956 m 2.8717 6.9794 3.7096 6.2805 4.7063 5.9228 c 4.7063 11.6 l 4.7026 11.8793 4.8513 12.1386 5.0942 12.2765 c 10.9086 15.6308 l 8.8885 16.7993 l 8.8663 16.8111 8.8397 16.8111 8.8175 16.7993 c 3.9872 14.0128 l 1.8408 12.7686 1.1047 10.023 2.3408 7.872 c 2.3408 7.8956 l h 18.9371 11.7514 m 13.1038 8.364 l 15.1192 7.2 l 15.1414 7.1882 15.168 7.1882 15.1902 7.2 c 20.0205 9.9913 l 21.5281 10.8612 22.3979 12.5234 22.2531 14.258 c 22.1083 15.9926 20.975 17.4876 19.344 18.0955 c 19.344 12.4183 l 19.3355 12.1397 19.1808 11.8863 18.937 11.7513 c 18.9371 11.7514 l h 20.9478 8.7283 m 20.8058 8.6431 l 16.0323 5.8613 l 15.7898 5.719 15.4894 5.719 15.2469 5.8613 c 9.409 9.2297 l 9.409 6.8974 l 9.4065 6.8732 9.4174 6.8496 9.4374 6.8359 c 14.2677 4.0493 l 15.779 3.1787 17.6573 3.2599 19.0877 4.2578 c 20.5182 5.2556 21.2431 6.9903 20.9479 8.7093 c 20.9478 8.7283 l h 8.3065 12.863 m 6.2865 11.6992 l 6.266 11.6869 6.2521 11.6661 6.2485 11.6425 c 6.2485 6.0742 l 6.2508 4.3304 7.2605 2.7449 8.8397 2.0054 c 10.419 1.2659 12.2833 1.5056 13.6242 2.6205 c 13.4822 2.701 l 8.704 5.459 l 8.4621 5.6009 8.3128 5.8598 8.3113 6.1403 c 8.3065 12.863 l h 9.4041 10.4976 m 12.0061 8.9978 l 14.613 10.4976 l 14.613 13.497 l 12.0156 14.9967 l 9.4089 13.497 l 9.4041 10.4976 l h f Q",
    }
    drawing = f"0 G 0 g {icons[provider]}\n"
    for text, baseline in ((percent, 12), (day, 2)):
        x = 21 + (column_width - text_width(text)) / 2
        drawing += f"BT /F1 9 Tf {x} {baseline} Td ({text}) Tj ET\n"
    stream = drawing.encode("ascii")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {width} 22] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>".encode(),
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>",
        f"<< /Length {len(stream)} >>\nstream\n".encode() + stream + b"endstream",
    ]
    pdf = b"%PDF-1.4\n"
    offsets = []
    for number, obj in enumerate(objects, 1):
        offsets.append(len(pdf))
        pdf += f"{number} 0 obj\n".encode() + obj + b"\nendobj\n"
    xref = len(pdf)
    pdf += b"xref\n0 6\n0000000000 65535 f \n"
    pdf += b"".join(f"{offset:010} 00000 n \n".encode() for offset in offsets)
    pdf += f"trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode()
    return base64.b64encode(pdf).decode()


def main():
    provider = sys.argv[1]
    symbol = {"Claude": "asterisk", "Codex": "terminal"}[provider]
    try:
        data = fetch(provider)
        if data["reset"] <= time.time():
            raise ValueError("Expired usage window")
    except (OSError, ValueError, KeyError, TypeError, StopIteration, subprocess.SubprocessError) as error:
        detail = f"HTTP {error.code}" if isinstance(error, urllib.error.HTTPError) else type(error).__name__
        print(f"unavailable | sfimage={symbol}")
        print("---")
        print(f"{provider}: refresh failed ({detail})")
        print("If authentication expired, sign in with the provider's CLI.")
    else:
        print(f' | templateImage={template_image(provider, data)} tooltip="{provider} weekly remaining"')
        print("---")
        print(f"{provider} · weekly remaining: {100 - data['used']:.0f}%")
        reset = dt.datetime.fromtimestamp(data["reset"]).astimezone()
        updated = dt.datetime.fromtimestamp(data["updated"]).astimezone()
        print(f"Resets: {reset:%A, %d %B at %H:%M %Z}")
        print(f"Updated: {updated:%H:%M %Z}")
    print("---")
    print("Refresh | refresh=true")


if __name__ == "__main__":
    main()
