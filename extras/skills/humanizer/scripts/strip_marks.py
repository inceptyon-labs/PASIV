#!/usr/bin/env python3
"""
Strip invisible Unicode marks and chatbot copy-paste residue from text.

Deterministic and stdlib-only. It removes characters a reader cannot see and
tokens a chatbot UI leaves behind; it never rewords anything.

Usage:
    strip_marks.py draft.md                 # cleaned text to stdout, summary to stderr
    strip_marks.py draft.md --in-place      # overwrite the file
    strip_marks.py draft.md --report        # list findings, change nothing
    cat draft.md | strip_marks.py -         # stdin
    strip_marks.py draft.md --straight-quotes --in-place

Exit status: 0 on success, 2 on usage or read errors.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

# Zero-width and other default-ignorable format characters.
INVISIBLE = {
    0x00AD,  # soft hyphen
    0x034F,  # combining grapheme joiner
    0x180E,  # Mongolian vowel separator
    0x200B,  # zero width space
    0x200C,  # zero width non-joiner
    0x200D,  # zero width joiner
    0x2060,  # word joiner
    0x2061, 0x2062, 0x2063, 0x2064,  # invisible math operators
    0x206A, 0x206B, 0x206C, 0x206D, 0x206E, 0x206F,  # deprecated format controls
    0x3164,  # Hangul filler
    0xFEFF,  # zero width no-break space / BOM
    0xFFA0,  # halfwidth Hangul filler
    0xFFF9, 0xFFFA, 0xFFFB,  # interlinear annotation
}
BIDI = {0x061C, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068, 0x2069}
EXOTIC_SPACES = {0x00A0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007,
                 0x2008, 0x2009, 0x200A, 0x202F, 0x205F, 0x3000}
LINE_SEPARATORS = {0x2028, 0x2029}
QUOTES = {"\u2018": "'", "\u2019": "'", "\u201A": "'", "\u201B": "'",
          "\u201C": '"', "\u201D": '"', "\u201E": '"', "\u201F": '"', "\u2026": "..."}

# Scripts where ZWJ/ZWNJ change how letters join, so they are part of the spelling.
JOINER_SCRIPTS = ("ARABIC", "SYRIAC", "DEVANAGARI", "BENGALI", "GURMUKHI", "GUJARATI", "ORIYA",
                  "TAMIL", "TELUGU", "KANNADA", "MALAYALAM", "SINHALA", "MYANMAR", "KHMER",
                  "MONGOLIAN", "TIBETAN", "THAANA", "NKO")

# Citation tokens and tracking parameters that chatbot UIs leave in copied text.
_PARAM = r"(?:utm_source=(?:chatgpt\.com|openai|copilot\.com)|referrer=grok\.com)"
RESIDUE = [
    ("chatgpt_cite", re.compile(r"\uE200(?:file)?cite[^\uE201\n]{0,300}\uE201")),
    ("oaicite", re.compile(r":?contentReference\[oaicite:\d+\](?:\{index=\d+\})?|\[oaicite:\d+\]")),
    ("turn_token", re.compile(r"\bturn\d+(?:search|view|news|image|file|fetch|academia|product)\d+\b")),
    ("gemini_cite", re.compile(r"\[cite_start\]|\[cite:\s*\d+(?:\s*,\s*\d+)*\]|\[span_\d+\]\((?:start|end)_span\)")),
    ("source_bracket", re.compile(r"\u3010\d+[\u2020:][^\u3011\n]{0,80}\u3011")),
    ("tracking_param", re.compile(
        rf"\?{_PARAM}(?=$|[\s)\]>\"'#])|(?<=\?){_PARAM}&|&{_PARAM}(?=$|[\s)\]>\"'#&])", re.MULTILINE)),
]


def _is_emoji_like(ch: str) -> bool:
    cp = ord(ch)
    return (unicodedata.category(ch) == "So" or 0x1F000 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF
            or 0x1F3FB <= cp <= 0x1F3FF or cp in (0xFE0F, 0x20E3))


def _in_joiner_script(ch: str) -> bool:
    if not ch or unicodedata.category(ch)[0] not in "LM":
        return False
    return unicodedata.name(ch, "").startswith(JOINER_SCRIPTS)


def _is_cjk(ch: str) -> bool:
    return bool(ch) and unicodedata.east_asian_width(ch) in "WF"


def _has_rtl(text: str) -> bool:
    return any(unicodedata.bidirectional(c) in ("R", "AL") for c in text)


def classify(text: str, i: int, rtl: bool) -> str | None:
    """Return the kind of mark at text[i], or None when the character should stay."""
    ch = text[i]
    cp = ord(ch)
    prev = text[i - 1] if i else ""
    nxt = text[i + 1] if i + 1 < len(text) else ""

    if cp in INVISIBLE:
        if cp == 0xFEFF and i == 0:
            return None  # a leading byte-order mark belongs to the file
        if cp in (0x200C, 0x200D):
            if prev and nxt and _is_emoji_like(prev) and _is_emoji_like(nxt):
                return None  # emoji sequence
            if _in_joiner_script(prev) and _in_joiner_script(nxt):
                return None
        return "zero_width"
    if cp in BIDI:
        return "bidi" if cp in (0x202D, 0x202E) or not rtl else None
    if 0xFE00 <= cp <= 0xFE0F:
        keeps = prev and (_is_emoji_like(prev) or (prev in "0123456789#*" and nxt == "\u20E3")
                          or ord(prev) > 0x2000)
        return None if keeps else "variation_selector"
    if 0xE0100 <= cp <= 0xE01EF:
        return None if _is_cjk(prev) else "variation_selector"
    if 0xE0000 <= cp <= 0xE007F:
        j = i - 1
        while j >= 0 and 0xE0020 <= ord(text[j]) <= 0xE007F:
            j -= 1
        return None if j >= 0 and ord(text[j]) == 0x1F3F4 else "tag_char"  # flag sequences
    if 0xFDD0 <= cp <= 0xFDEF or (cp & 0xFFFE) == 0xFFFE:
        return "noncharacter"
    if cp in EXOTIC_SPACES:
        if cp == 0x3000 and (_is_cjk(prev) or _is_cjk(nxt)):
            return None
        return "exotic_space"
    if cp in LINE_SEPARATORS:
        return "line_separator"
    return None


def clean(text: str, keep_spaces: bool = False, straight_quotes: bool = False):
    findings: list[tuple[int, int, str, str]] = []  # line, col, kind, detail

    def locate(pos: int, src: str) -> tuple[int, int]:
        line = src.count("\n", 0, pos) + 1
        col = pos - (src.rfind("\n", 0, pos) + 1) + 1
        return line, col

    # Residue first: the ChatGPT citation wrapper is built from private-use characters.
    stripped = text
    for kind, pattern in RESIDUE:
        pieces, last = [], 0
        for m in pattern.finditer(stripped):
            findings.append((*locate(m.start(), stripped), kind, m.group(0)[:60]))
            start = m.start()
            # A token dropped from " word [token]." would leave a space before the period.
            if stripped[start - 1:start] == " " and (stripped[m.end():m.end() + 1] or "\n") in ".,;:!?)\n":
                start -= 1
            pieces.append(stripped[last:start])
            last = m.end()
        pieces.append(stripped[last:])
        stripped = "".join(pieces)

    rtl = _has_rtl(stripped)
    out: list[str] = []
    for i, ch in enumerate(stripped):
        kind = classify(stripped, i, rtl)
        if kind is None or (kind == "exotic_space" and keep_spaces):
            if straight_quotes and ch in QUOTES:
                findings.append((*locate(i, stripped), "curly_punct", f"U+{ord(ch):04X}"))
                out.append(QUOTES[ch])
            else:
                out.append(ch)
            continue
        findings.append((*locate(i, stripped), kind,
                         f"U+{ord(ch):04X} {unicodedata.name(ch, 'UNNAMED')}"))
        if kind == "exotic_space":
            out.append(" ")
        elif kind == "line_separator":
            out.append("\n")
    return "".join(out), findings


def main() -> int:
    parser = argparse.ArgumentParser(description="Strip invisible Unicode marks and chatbot residue.")
    parser.add_argument("path", help="Text file, or - for stdin")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--in-place", action="store_true", help="Overwrite the file")
    mode.add_argument("--report", action="store_true", help="List findings and change nothing")
    parser.add_argument("--keep-spaces", action="store_true",
                        help="Leave non-breaking and other exotic spaces alone")
    parser.add_argument("--straight-quotes", action="store_true",
                        help="Also turn curly quotes and the ellipsis character into ASCII")
    args = parser.parse_args()

    if args.path == "-":
        if args.in_place:
            parser.error("--in-place needs a file path")
        text = sys.stdin.buffer.read().decode("utf-8")
    else:
        try:
            text = Path(args.path).read_bytes().decode("utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            print(f"error: cannot read {args.path} as UTF-8 text: {exc}", file=sys.stderr)
            return 2

    cleaned, findings = clean(text, keep_spaces=args.keep_spaces, straight_quotes=args.straight_quotes)
    counts = Counter(kind for _, _, kind, _ in findings)
    summary = ", ".join(f"{n} {kind}" for kind, n in sorted(counts.items())) or "nothing found"

    if args.report:
        for line, col, kind, detail in findings:
            print(f"{line}:{col}\t{kind}\t{detail}")
        print(summary, file=sys.stderr)
        return 0
    if args.in_place:
        if cleaned != text:
            Path(args.path).write_bytes(cleaned.encode("utf-8"))
        print(f"{args.path}: {summary}", file=sys.stderr)
        return 0
    sys.stdout.buffer.write(cleaned.encode("utf-8"))
    print(summary, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
