#!/usr/bin/env python3
"""Find broken relative links in Markdown files.

Usage: md-links.py [file.md ...]   (default: every tracked .md/.mdx file)
Run from the repo root. Checks inline links and images, reference definitions,
and HTML src/href attributes. Skips URLs, anchors, and code. A leading "/"
resolves to the repo root, as on GitHub. A tracked file that links to a file
git doesn't track is reported too: the link works locally and 404s on GitHub.
Exit: 0 no broken links, 1 broken links listed, 2 not a git repo.
"""
import os
import re
import subprocess
import sys
from urllib.parse import unquote

INLINE = re.compile(r'!?\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+["\'(][^)]*)?\)')
REFDEF = re.compile(r'^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s|$)')
HTML = re.compile(r'\b(?:src|href)\s*=\s*["\']([^"\']+)["\']', re.I)
SKIP = re.compile(r'^(?:[a-z][a-z0-9+.-]*:|//|#|\{|\$|<)', re.I)  # URLs, anchors, template placeholders


def root():
    try:
        out = subprocess.run(['git', 'rev-parse', '--show-toplevel'],
                             capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        sys.exit(2)
    return out.stdout.strip()


def tracked(top, *specs):
    out = subprocess.run(['git', 'ls-files', '-z', '--', *specs],
                         capture_output=True, text=True, cwd=top)
    return [os.path.join(top, f) for f in out.stdout.split('\0') if f]


def tracked_paths(top):
    paths = {top}
    for f in tracked(top):
        while f != top and f not in paths:
            paths.add(f)
            f = os.path.dirname(f)
    return paths


def targets(line):
    for rx in (INLINE, HTML):
        for m in rx.finditer(line):
            yield m.group(1)
    m = REFDEF.match(line)
    if m:
        yield m.group(1)


def check(path, top, known):
    bad = []
    src_tracked = os.path.abspath(path) in known
    fence = None
    base = os.path.dirname(os.path.abspath(path))
    with open(path, encoding='utf-8', errors='replace') as fh:
        for n, line in enumerate(fh, 1):
            stripped = line.lstrip()
            if stripped.startswith(('```', '~~~')):
                mark = stripped[:3]
                fence = None if fence == mark else (fence or mark)
                continue
            if fence:
                continue
            line = re.sub(r'`[^`]*`', '', line)
            for t in targets(line):
                if SKIP.match(t):
                    continue
                t = unquote(t.split('#', 1)[0].split('?', 1)[0])
                if not t:
                    continue
                full = os.path.join(top, t.lstrip('/')) if t.startswith('/') else os.path.join(base, t)
                full = os.path.normpath(full)
                if not os.path.exists(full):
                    bad.append((n, 'broken link', t))
                elif src_tracked and full not in known:
                    bad.append((n, 'links to untracked file', t))
    return bad


def main():
    top = root()
    files = [os.path.abspath(f) for f in sys.argv[1:]] or tracked(top, '*.md', '*.mdx')
    known = tracked_paths(top)
    broken = 0
    for f in files:
        if not os.path.isfile(f):
            continue
        for n, kind, t in check(f, top, known):
            print(f'{os.path.relpath(f, top)}:{n}: {kind} -> {t}')
            broken += 1
    print(f'md-links: {broken} broken link(s) in {len(files)} file(s)', file=sys.stderr)
    sys.exit(1 if broken else 0)


if __name__ == '__main__':
    main()
