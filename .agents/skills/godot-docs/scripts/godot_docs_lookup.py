#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
godot_docs_lookup.py — offline lookup over the bundled Godot docs corpus
(`godot-docs-md/`, generated from the official Godot 4.7-dev docs HTML download).

Canonical copy: .github/skills/godot-docs/scripts/godot_docs_lookup.py
(an identical copy lives under .agents/skills/godot-docs/scripts/ — keep in sync)

Stdlib only, no third-party dependencies. Run from anywhere; the repo root is
auto-detected by walking up until a folder containing `godot-docs-md/` is found
(override with --root).

Subcommands
-----------
  symbol <name> ...      Resolve API symbols against api-symbol-index.tsv.
                         Accepts partial names; '()' suffixes are ignored.
                         Examples:  Node.queue_free
                                    node.queue_free()
                                    process_mode
                                    Area3D.body_entered
  page <Class>           Print the markdown page for a Godot class.
                         Examples:  Node | node | CharacterBody2D | @GDScript
  search <terms...>      Full-text search of the corpus (all terms must appear
                         in one line). Prints relpath:line: text.

Exit codes: 0 = at least one result, 1 = nothing found.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

CORPUS_DIRNAME = "godot-docs-md"
DEFAULT_LIMIT = 50


def find_root(start: Path | None = None) -> Path | None:
    """Nearest ancestor of `start` (default: cwd) that holds the corpus."""
    cands = [Path.cwd()]
    if start is not None:
        cands.insert(0, start)
    if os.environ.get("GODOT_DOCS_ROOT"):
        cands.insert(0, Path(os.environ["GODOT_DOCS_ROOT"]))
    seen: set[Path] = set()
    for c in cands:
        p = c.resolve()
        while p not in seen and len(p.parts) > 1:
            seen.add(p)
            if (p / CORPUS_DIRNAME).is_dir():
                return p
            p = p.parent
    return None


def load_index(root: Path) -> list[tuple[str, str, str, str]]:
    rows: list[tuple[str, str, str, str]] = []
    idx = root / CORPUS_DIRNAME / "api-symbol-index.tsv"
    if not idx.is_file():
        return rows
    for ln in idx.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = ln.split("\t")
        if len(parts) == 4 and parts[0] != "symbol":
            rows.append((parts[0], parts[1], parts[2], parts[3]))
    return rows


def out(s: str = "") -> None:
    print(s)


def cmd_symbol(rows: list[tuple[str, str, str, str]], query: str, limit: int) -> int:
    q = query.strip().rstrip(")").rstrip("(")
    if q.startswith("class_"):
        q = q[len("class_"):]
    ql = q.lower()
    exact = [r for r in rows if r[0].lower() == ql]
    if not exact:
        exact = [r for r in rows if r[0].lower().endswith("." + ql)]
    hits = exact or [r for r in rows if ql in r[0].lower()]
    if not hits:
        out(f"[godot-docs] no symbol matches '{query}'")
        return 1
    extra = len(hits) - limit
    for sym, kind, page, anchor in hits[:limit]:
        out(f"{sym}\t{kind}\t{page}\t{anchor}")
    if extra > 0:
        out(f"# ... and {extra} more matches (limit {limit}); refine your query")
    return 0


def cmd_page(root: Path, cls: str) -> int:
    name = cls.strip()
    low = re.sub(r"[^a-z0-9_@]+", "", name.lower())
    if not low.startswith("class_"):
        low = "class_" + low.lstrip("@")
    cand_file = root / CORPUS_DIRNAME / "classes" / (low + ".md")
    cand_dir = root / CORPUS_DIRNAME / "classes" / low
    rel = root / CORPUS_DIRNAME / "classes"
    if cand_file.is_file():
        out(str(cand_file.relative_to(root)))
        return 0
    if cand_dir.is_dir():  # giant class split into a folder
        out(f"{cand_dir.relative_to(root)}/  (split page — see _sections.md)")
        return 0
    # filename may differ from symbol case (@GDScript etc.); try index rows
    rows = load_index(root)
    for sym, _k, page, _a in rows:
        if sym.lower() == name.lower() and "." not in sym:
            out(f"{page}")
            return 0
    out(f"[godot-docs] no class page for '{name}' under {rel}")
    return 1


def cmd_search(root: Path, terms: list[str], limit: int) -> int:
    if not terms:
        out("[godot-docs] search needs at least one term")
        return 2
    lows = [t.lower() for t in terms]
    hits: list[str] = []
    corpus = root / CORPUS_DIRNAME
    for md in sorted(corpus.rglob("*.md")):
        if md.name == "README.md":
            continue
        rel = str(md.relative_to(root))
        for n, ln in enumerate(
            md.read_text(encoding="utf-8", errors="replace").splitlines(), 1
        ):
            ll = ln.lower()
            if all(t in ll for t in lows):
                hits.append(f"{rel}:{n}: {ln.strip()[:220]}")
                if len(hits) >= limit:
                    break
        if len(hits) >= limit:
            break
    if not hits:
        out(f"[godot-docs] no lines matched {terms}")
        return 1
    for h in hits:
        out(h)
    if len(hits) >= limit:
        out(f"# first {limit} hits shown; narrow the query or read a specific page")
    return 0


def main(argv: list[str]) -> int:
    if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    args = [a for a in argv if a != "--help" and a != "-h"]
    limit = DEFAULT_LIMIT
    cleaned: list[str] = []
    i = 0
    while i < len(args):
        if args[i] == "--root" and i + 1 < len(args):
            os.environ["GODOT_DOCS_ROOT"] = args[i + 1]
            i += 2
        elif args[i] == "--limit" and i + 1 < len(args):
            limit = max(1, int(args[i + 1]))
            i += 2
        else:
            cleaned.append(args[i])
            i += 1
    if not cleaned or cleaned[0] not in ("symbol", "page", "search"):
        print(__doc__)
        return 2
    cmd, rest = cleaned[0], cleaned[1:]
    root = find_root(Path(__file__).resolve())
    if root is None:
        out(f"[godot-docs] corpus '{CORPUS_DIRNAME}/' not found under cwd or env "
            f"GODOT_DOCS_ROOT (run from inside the Godot project)")
        return 2
    if cmd == "page":
        if not rest:
            print(__doc__)
            return 2
        return cmd_page(root, rest[0])
    rows = load_index(root)
    if cmd == "symbol":
        if not rest:
            print(__doc__)
            return 2
        code = 0
        for q in rest:
            code |= cmd_symbol(rows, q, limit)
        return code
    return cmd_search(root, rest, limit)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
