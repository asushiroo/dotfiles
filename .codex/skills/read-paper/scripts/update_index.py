#!/usr/bin/env python3
"""Rebuild paper-notes/index.md from the front matter of note files.

Scans *.md files directly inside the target directory (skips index.md),
reads a small YAML-ish front matter subset, and writes a Markdown table
sorted by year (newest first).

Usage: update_index.py --dir <paper-notes>
Exit codes: 0 ok, 2 usage error.
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path


def parse_front_matter(text: str) -> dict[str, str]:
    meta: dict[str, str] = {}
    if not text.startswith("---"):
        return meta
    lines = text.splitlines()
    if len(lines) < 2:
        return meta
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return meta
    current_key: str | None = None
    for line in lines[1:end]:
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)
        if m:
            current_key = m.group(1)
            value = m.group(2).strip()
            if value:
                meta[current_key] = value
        elif current_key and re.match(r"^\s*-\s+", line):
            item = re.sub(r"^\s*-\s+", "", line).strip()
            if current_key in ("tags", "authors"):
                prev = meta.get(current_key, "")
                meta[current_key] = (prev + "," + item) if prev else item
    return meta


def clean(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]
    return value


def first_author(authors_value: str) -> str:
    raw = clean(authors_value or "")
    if not raw:
        return ""
    raw = raw.strip("[]")
    parts = [p.strip().strip("\"'") for p in raw.split(",") if p.strip()]
    if not parts:
        return ""
    name = parts[0]
    if len(parts) > 1:
        name += " 等"
    return name


def entry_from_file(path: Path) -> tuple[str, int, str, str, str] | None:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    meta = parse_front_matter(text)
    title = clean(meta.get("title", path.stem))
    if not title:
        return None
    try:
        year = int(clean(meta.get("year", "0")))
    except ValueError:
        year = 0
    venue = clean(meta.get("venue", ""))
    authors = first_author(meta.get("authors", ""))
    note = path.stem
    return (title, year, venue, authors, note)


def main() -> int:
    parser = argparse.ArgumentParser(description="Rebuild paper-notes/index.md.")
    parser.add_argument("--dir", default="paper-notes", help="paper-notes directory")
    args = parser.parse_args()

    notes_dir = Path(args.dir).resolve()
    if not notes_dir.is_dir():
        sys.stderr.write(f"目录不存在: {notes_dir}\n")
        return 2

    entries: list[tuple[str, int, str, str, str]] = []
    for md in sorted(notes_dir.glob("*.md")):
        if md.stem == "index":
            continue
        entry = entry_from_file(md)
        if entry:
            entries.append(entry)

    entries.sort(key=lambda e: (-e[1], e[0].casefold()))
    today = date.today().isoformat()
    lines = [
        "# 论文笔记索引",
        "",
        f"> 共 {len(entries)} 篇。自动生成于 {today}，由 read-paper 维护；不要手改本文件。",
        "",
        "| 论文 | 年份 | 期刊/会议 | 作者 | 笔记 |",
        "| --- | --- | --- | --- | --- |",
    ]
    for title, year, venue, authors, note in entries:
        safe_title = title.replace("|", "\\|")
        safe_venue = venue.replace("|", "\\|")
        safe_authors = authors.replace("|", "\\|")
        year_text = str(year) if year else ""
        lines.append(f"| [[{note}|{safe_title}]] | {year_text} | {safe_venue} | {safe_authors} | [[{note}]] |")

    index_path = notes_dir / "index.md"
    index_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"已更新：{index_path}（{len(entries)} 篇笔记）")
    return 0


if __name__ == "__main__":
    sys.exit(main())


