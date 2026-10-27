#!/usr/bin/env python3
"""
用法：measure.py LABEL RESULTS_JSONL -- COMMAND [ARGS...]
執行指令，並把耗時、CPU 時間、子程序峰值記憶體附加到 RESULTS_JSONL（一行一筆 JSON）。
峰值記憶體是 Linux 的 ru_maxrss（單一程序的最大值，不是所有程序加總）。
"""
import json
import resource
import subprocess
import sys
import time


def main():
    if "--" not in sys.argv or len(sys.argv) < 5:
        print(__doc__)
        return 2
    sep = sys.argv.index("--")
    label, jsonl = sys.argv[1], sys.argv[2]
    cmd = sys.argv[sep + 1:]
    if not cmd:
        print("no command given")
        return 2

    t0 = time.time()
    try:
        rc = subprocess.call(cmd)
    except OSError as e:
        print(f"failed to start: {e}")
        rc = 127
    elapsed = time.time() - t0
    ru = resource.getrusage(resource.RUSAGE_CHILDREN)

    rec = {
        "label": label,
        "rc": rc,
        "elapsed_s": round(elapsed, 1),
        "peak_rss_mb": round(ru.ru_maxrss / 1024, 0),
        "cpu_user_s": round(ru.ru_utime, 1),
        "cpu_sys_s": round(ru.ru_stime, 1),
    }
    with open(jsonl, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print(f"[measure] {label}: rc={rc} {rec['elapsed_s']}s peak_rss={rec['peak_rss_mb']}MB")
    return rc


if __name__ == "__main__":
    sys.exit(main())
