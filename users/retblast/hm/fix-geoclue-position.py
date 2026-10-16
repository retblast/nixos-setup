"""fix-geoclue-position: correct BeaconDB's knowledge of the WiFi APs
visible from here.

    fix-geoclue-position --check       what BeaconDB thinks right now
    fix-geoclue-position <lat> <lon>   submit ground truth (source: manual)

After a submission is processed, geoclue's fixes land where the user
actually is instead of wherever an AP's stale registration sits.
"""
import json
import subprocess
import sys
import time

GEOLOCATE = "https://api.beacondb.net/v1/geolocate"
GEOSUBMIT = "https://api.beacondb.net/v2/geosubmit"


def collect_aps():
    out = subprocess.run(
        ["nmcli", "-t", "-f", "BSSID,SIGNAL,CHAN", "dev", "wifi", "list"],
        capture_output=True, text=True, check=True,
    ).stdout
    aps = []
    for line in out.splitlines():
        fields, cur = [], ""
        i = 0
        while i <= len(line):
            if i < len(line) and line[i] == "\\" and i + 1 < len(line):
                cur += line[i:i + 2]
                i += 2
                continue
            if i == len(line) or line[i] == ":":
                fields.append(cur)
                cur = ""
                i += 1
                continue
            cur += line[i]
            i += 1
        if len(fields) < 3:
            continue
        bssid = fields[0].replace("\\:", ":").upper()
        try:
            signal, chan = int(fields[1]), int(fields[2])
        except ValueError:
            continue
        if len(bssid) != 17:
            continue
        aps.append({"macAddress": bssid,
                    "signalStrength": signal // 2 - 100,
                    "channel": chan})
    return aps


def post(url, body):
    import urllib.request
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.read().decode()


def main() -> int:
    argv = sys.argv[1:]
    aps = collect_aps()
    print(f"{len(aps)} APs visible", file=sys.stderr)
    if not aps:
        return 1

    if argv and argv[0] == "--check":
        print(post(GEOLOCATE, {"wifiAccessPoints": aps}))
        return 0

    if len(argv) < 2:
        print(__doc__)
        return 1
    lat, lon = float(argv[0]), float(argv[1])

    body = {"items": [{
        "timestamp": int(time.time() * 1000),
        "position": {"latitude": lat, "longitude": lon,
                     "accuracy": 30.0, "source": "manual"},
        "wifiAccessPoints": aps,
    }]}
    print("submit response:", post(GEOSUBMIT, body))
    return 0


if __name__ == "__main__":
    sys.exit(main())
