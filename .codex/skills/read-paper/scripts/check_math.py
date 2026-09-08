#!/usr/bin/env python3
r"""Static lint for Obsidian MathJax formulas in a Markdown note.

Checks:
  - balanced braces in every $...$ / $$...$$ math block
  - unclosed display ($$) or inline ($) delimiters
  - common constructs MathJax does not support (\bm, \label, \ref, ...)
  - \begin{env} environments outside the MathJax-supported allowlist

Usage: check_math.py <note.md>
Exit codes: 0 ok, 1 problems found, 2 usage error.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ALLOWED_ENVS = {
    "align", "align*", "aligned", "alignedat", "array", "Bmatrix", "bmatrix",
    "cases", "CD", "gather", "gather*", "gathered", "matrix", "pmatrix",
    "smallmatrix", "split", "subarray", "Vmatrix", "vmatrix", "equation",
    "equation*", "multline", "multline*", "eqnarray", "eqnarray*",
}
UNSUPPORTED_MACROS = [
    r"\bm", r"\label", r"\ref", r"\eqref", r"\pageref", r"\input",
    r"\include", r"\usepackage", r"\documentclass", r"\begin{document}",
    r"\vspace", r"\hspace", r"\medskip", r"\bigskip",
]
UNSUPPORTED_MACROS.sort(key=len, reverse=True)


def balance(text: str) -> str | None:
    """Return an error message for unbalanced braces, or None."""
    depth = 0
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\\":
            i += 2
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                return "多余的右花括号 }"
        i += 1
    if depth > 0:
        return f"缺少 {depth} 个右花括号 }}"
    return None


def lint_math(content: str) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    in_display = False
    buffer: list[str] = []
    start_line = 0

    def check_math_body(body: str, line: int, kind: str) -> None:
        msg = balance(body)
        if msg:
            errors.append(f"第 {line} 行（{kind}）：花括号不配对 —— {msg}")
        for macro in UNSUPPORTED_MACROS:
            if macro in body:
                warnings.append(f"第 {line} 行（{kind}）：疑似 MathJax 不支持的 {macro}，请改用支持写法")
        for env in re.findall(r"\\begin\{([^}]+)\}", body):
            if env not in ALLOWED_ENVS:
                warnings.append(f"第 {line} 行（{kind}）：\\begin{{{env}}} 不在 Obsidian MathJax 常用白名单内，请确认可渲染")

    for line_no, line in enumerate(content.splitlines(), 1):
        i = 0
        while i < len(line):
            if in_display:
                end = line.find("$$", i)
                if end == -1:
                    buffer.append(line[i:])
                    i = len(line)
                else:
                    buffer.append(line[i:end])
                    check_math_body("".join(buffer), start_line, "$$ 块")
                    in_display = False
                    buffer = []
                    i = end + 2
            else:
                idx = line.find("$$", i)
                if idx != -1:
                    end = line.find("$$", idx + 2)
                    if end != -1:
                        check_math_body(line[idx + 2 : end], line_no, "$$ 块")
                        i = end + 2
                    else:
                        in_display = True
                        buffer = [line[idx + 2 :]]
                        start_line = line_no
                        i = len(line)
                else:
                    dollar = line.find("$", i)
                    if dollar == -1:
                        i = len(line)
                    else:
                        end = line.find("$", dollar + 1)
                        if end == -1:
                            errors.append(f"第 {line_no} 行：行内 $ 未闭合")
                            i = len(line)
                        else:
                            body = line[dollar + 1 : end]
                            if body.strip():
                                check_math_body(body, line_no, "行内 $")
                            i = end + 1

    if in_display:
        errors.append(f"从第 {start_line} 行开始的 $$ 块未闭合")
    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint MathJax formulas in a Markdown note.")
    parser.add_argument("note", help="path to the .md note")
    args = parser.parse_args()
    path = Path(args.note)
    if not path.is_file():
        sys.stderr.write(f"文件不存在: {path}\n")
        return 2
    content = path.read_text(encoding="utf-8")
    errors, warnings = lint_math(content)
    for msg in errors:
        print(f"[ERROR] {msg}")
    for msg in warnings:
        print(f"[WARN ] {msg}")
    print(f"检查完成：{len(errors)} 个错误，{len(warnings)} 个警告。")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

