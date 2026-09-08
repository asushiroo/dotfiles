#!/usr/bin/env python3
"""Write a note draft to its destination, preserving the user notes region.

The user region is the block between:
  <!-- USER-NOTES:START -->
and:
  <!-- USER-NOTES:END -->
(inclusive). If the destination already exists, that block is carried over
into the freshly generated draft; everything else is fully overwritten.

Exit codes: 0 success, 2 usage/IO error.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

START = "<!-- USER-NOTES:START -->"
END = "<!-- USER-NOTES:END -->"

REGION_RE = re.compile(r"<!-- USER-NOTES:START -->.*?<!-- USER-NOTES:END -->", re.S)


def extract_region(text: str) -> str:
    m = REGION_RE.search(text)
    return m.group(0) if m else ""


def splice_region(draft: str, region: str) -> str:
    if not region:
        return draft
    m = REGION_RE.search(draft)
    if not m:
        return draft.rstrip() + "\n\n" + region + "\n"
    return draft[: m.start()] + region + draft[m.end():]


def main() -> int:
    parser = argparse.ArgumentParser(description="Write a note, preserving the USER-NOTES region.")
    parser.add_argument("draft", help="path to the freshly generated note draft")
    parser.add_argument("dest", help="destination note path under paper-notes/")
    args = parser.parse_args()

    try:
        draft_path = Path(args.draft)
        dest_path = Path(args.dest)
        draft = draft_path.read_text(encoding="utf-8")

        preserved = False
        if dest_path.exists():
            old = dest_path.read_text(encoding="utf-8")
            region = extract_region(old)
            if region:
                draft = splice_region(draft, region)
                preserved = True

        dest_path.parent.mkdir(parents=True, exist_ok=True)
        dest_path.write_text(draft, encoding="utf-8")
        print(f"已写入：{dest_path}")
        print(f"保留用户批注区：{'是' if preserved else '否（首次生成或旧文件无批注区）'}")
        return 0
    except Exception as exc:  # noqa: BLE001
        sys.stderr.write(f"写入失败: {exc}\n")
        return 2


if __name__ == "__main__":
    sys.exit(main())
