#!/usr/bin/env python3
"""Locate a paper PDF under a directory by fuzzy filename matching.

Designed for paper folders whose filenames may include a first-author
prefix, year/venue tags, spaces turned into underscores/hyphens, etc.

Exit codes:
  0  unique strong candidate found
  2  multiple candidates found (ask the user to pick)
  1  no candidate found (weak suggestions may still be listed)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

ARXIV_RE = re.compile(r"(?:arxiv\s*[:/])?\s*(\d{4}\.\d{4,5})(?:v\d+)?", re.I)
DOI_RE = re.compile(r"10\.\d{4,9}/[^\s]+", re.I)
STRONG = 0.85
WEAK_FLOOR = 0.25
GAP = 0.12


def normalize(text: str) -> str:
    """Lowercase, NFKC-normalize, drop every non-alphanumeric char."""
    text = unicodedata.normalize("NFKC", text).casefold()
    return "".join(ch for ch in text if ch.isalnum())


def split_parts(stem: str) -> list[str]:
    """Word/number tokens of a filename stem.

    'Zhu2024ChangeFormer_RS' -> ['zhu', '2024', 'changeformer', 'rs']
    """
    stem = unicodedata.normalize("NFKC", stem).casefold()
    raw_tokens = [t for t in re.split(r"[^0-9a-z\u4e00-\u9fff]+", stem) if t]
    parts: list[str] = []
    for token in raw_tokens:
        parts.extend(p for p in re.findall(r"[0-9]+|[a-z\u4e00-\u9fff]+", token) if p)
    return parts


def best_substring_score(parts: list[str], query: str, max_drop: int = 3) -> tuple[float, int]:
    """Best containment score after dropping up to max_drop leading tokens."""
    best_score, best_k = 0.0, 0
    for k in range(0, min(max_drop + 1, len(parts)) + 1):
        suffix = "".join(parts[k:])
        if suffix == query:
            score = 1.0
        elif query in suffix:
            extra = len(suffix) - len(query)
            score = max(STRONG, 0.97 - 0.004 * extra)
        else:
            score = SequenceMatcher(None, query, suffix).ratio() * 0.6
        if score > best_score:
            best_score, best_k = score, k
    return best_score, best_k


def describe_k(k: int) -> str:
    if k == 0:
        return "完整文件名包含关键词"
    return f"去除文件名前缀 {k} 个词后包含关键词"


def collect_pdfs(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(p for p in root.rglob("*.pdf") if p.is_file())


def id_needles(query: str) -> list[str]:
    """Return normalized search needles for arXiv/DOI queries, else empty."""
    needles: list[str] = []
    m = ARXIV_RE.search(query)
    if m:
        needles.append(normalize(m.group(1)))
    m = DOI_RE.search(query)
    if m:
        needles.append(normalize(m.group(0)))
    return needles


def main() -> int:
    parser = argparse.ArgumentParser(description="Fuzzy-locate a paper PDF by filename.")
    parser.add_argument("query", help="title fragment, filename fragment, arXiv ID, or DOI")
    parser.add_argument("--root", default=".", help="paper library root (recursive search)")
    parser.add_argument("--limit", type=int, default=10, help="max candidates to list")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    pdfs = collect_pdfs(root)
    query = args.query.strip()
    if not query:
        print('{"status": "error", "reason": "empty query"}' if args.json else "错误：查询为空。")
        return 1

    needles = id_needles(query)
    q_norm = normalize(query)
    results: list[dict] = []
    for pdf in pdfs:
        stem = pdf.stem
        full = "".join(split_parts(stem))
        if needles:
            if any(n in full for n in needles):
                results.append({"path": str(pdf), "score": 1.0, "matched_on": "arXiv ID / DOI 命中", "strong": True})
            continue
        parts = split_parts(stem)
        score, k = best_substring_score(parts, q_norm)
        if score >= WEAK_FLOOR:
            results.append({"path": str(pdf), "score": round(score, 3), "matched_on": describe_k(k), "strong": score >= STRONG})

    results.sort(key=lambda r: (-r["score"], r["path"]))
    strong = [r for r in results if r["strong"]]
    top = results[0] if results else None

    status: str
    if needles:
        if len(results) == 1:
            status = "unique"
        elif results:
            status = "multiple"
        else:
            status = "none"
    elif top and top["strong"] and (len(results) == 1 or results[1]["strong"] is False or top["score"] - results[1]["score"] >= GAP):
        status = "unique"
        results = [top]
    elif len([r for r in results if r["strong"]]) > 1:
        status = "multiple"
        results = strong
    else:
        status = "none"
        results = results[: args.limit]

    payload = {
        "query": query,
        "root": str(root),
        "status": status,
        "candidates": [
            {"path": r["path"], "score": r["score"], "matched_on": r["matched_on"], "strong": r["strong"]}
            for r in results
        ],
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        if status == "unique":
            print(f"唯一候选（score={results[0]['score']}）：{results[0]['path']}")
            print(f"  匹配依据：{results[0]['matched_on']}")
        elif status == "multiple":
            print("命中多个候选，需要用户指定：")
            for i, r in enumerate(results, 1):
                print(f"  {i}. (score={r['score']}) {r['path']}")
                print(f"     匹配依据：{r['matched_on']}")
        elif results:
            print("未找到足够强的匹配。相近候选如下（供用户确认）：")
            for i, r in enumerate(results, 1):
                print(f"  {i}. (score={r['score']}) {r['path']}")
        else:
            print("未找到任何匹配的 PDF。")
        if needles and status != "unique":
            print("提示：已按 arXiv ID/DOI 模式检索；若仍无结果，请确认文件名包含该标识。")

    if status == "unique":
        return 0
    if status == "multiple":
        return 2
    return 1


if __name__ == "__main__":
    sys.exit(main())
