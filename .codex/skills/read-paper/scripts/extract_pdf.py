#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pymupdf>=1.24.0"]
# ///
"""Extract per-page text from a paper PDF, keyed by physical page number.

Examples:
  uv run --no-project extract_pdf.py paper.pdf --pages 1-3
  uv run --no-project extract_pdf.py paper.pdf --pages 5-12 --out pages.txt
  uv run --no-project extract_pdf.py scanned.pdf --ocr --tesseract C:/path/tesseract.exe

The default marker format is:
  <<<PAGE 5>>>
  <text of physical page 5>

Exit codes:
  0  success (scanned pages may still be reported on stderr)
  5  OCR requested but Tesseract is unavailable
  2  argument / file error
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

try:
    import pymupdf as fitz  # PyMuPDF >= 1.24
except ImportError:
    try:
        import fitz  # older PyMuPDF
    except ImportError:
        sys.stderr.write("缺少 pymupdf。请通过 `uv run --no-project <本脚本> ...` 运行，uv 会自动安装依赖。\n")
        sys.exit(2)

MIN_TEXT_CHARS = 10


def parse_pages(spec: str | None, total: int) -> list[int]:
    if not spec:
        return list(range(1, total + 1))
    pages: list[int] = []
    for chunk in spec.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        m = re.fullmatch(r"(\d+)(?:\s*-\s*(\d+))?", chunk)
        if not m:
            raise SystemExit(f"错误的 --pages 片段: {chunk!r}")
        start = int(m.group(1))
        end = int(m.group(2) or start)
        if start < 1 or end > total or start > end:
            raise SystemExit(f"页码越界: {chunk!r}（PDF 共 {total} 页）")
        pages.extend(range(start, end + 1))
    if not pages:
        raise SystemExit("--pages 未解析出任何页码")
    return pages


def ocr_page(page, tesseract_path: str | None) -> str:
    exe = tesseract_path or shutil.which("tesseract")
    if not exe:
        sys.stderr.write("OCR 需要本机安装 Tesseract（或用 --tesseract 指定路径），当前不可用。\n")
        sys.exit(5)
    tp = page.get_textpage_ocr(language="eng", dpi=150, full=True)
    return page.get_text("text", textpage=tp) or ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract per-page text from a PDF.")
    parser.add_argument("pdf", help="path to the PDF")
    parser.add_argument("--pages", help='page ranges, e.g. "1-3,5,7-9"')
    parser.add_argument("--out", help="write extracted text to this file instead of stdout")
    parser.add_argument("--ocr", action="store_true", help="OCR pages that have no text layer")
    parser.add_argument("--tesseract", help="explicit path to tesseract executable")
    parser.add_argument("--min-chars", type=int, default=MIN_TEXT_CHARS, help="scanned-page text threshold")
    args = parser.parse_args()

    pdf_path = Path(args.pdf)
    if not pdf_path.is_file():
        sys.stderr.write(f"文件不存在: {pdf_path}\n")
        return 2
    try:
        doc = fitz.open(pdf_path)
    except Exception as exc:  # noqa: BLE001
        sys.stderr.write(f"无法打开 PDF: {exc}\n")
        return 2
    try:
        total = doc.page_count
        want = parse_pages(args.pages, total)
        scanned: list[int] = []
        blocks: list[str] = []
        for number in want:
            page = doc.load_page(number - 1)
            text = page.get_text("text") or ""
            if len(text.strip()) < args.min_chars:
                if args.ocr:
                    text = ocr_page(page, args.tesseract)
                else:
                    scanned.append(number)
            blocks.append(f"<<<PAGE {number}>>>\n{text.rstrip()}")
        doc.close()

        output = "\n\n".join(blocks) + ("\n" if blocks else "")
        if args.out:
            out_path = Path(args.out)
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(output, encoding="utf-8")
        else:
            print(output)
        if scanned:
            sys.stderr.write(f"以下页面无文本层（疑似扫描页）：{scanned}。可加 --ocr 尝试 OCR。\n")
        else:
            sys.stderr.write(f"共抽取 {len(want)} 页。\n")
        return 0
    except SystemExit:
        doc.close()
        raise
    except Exception as exc:  # noqa: BLE001
        doc.close()
        sys.stderr.write(f"抽取失败: {exc}\n")
        return 2


if __name__ == "__main__":
    sys.exit(main())
