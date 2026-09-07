# -*- coding: utf-8 -*-
"""
Convert the RST sources inside a readthedocs "Godot docs HTML" download
(godot-docs-html-stable/_sources/**/*.rst.txt) into a clean, per-page
Markdown text tree suitable as an AI-agent reference corpus.

No third-party dependencies. Handles the concrete RST dialect produced by
Godot's doc tooling (make_rst.py) plus Sphinx directives found in manuals.

Output layout (mirrors _sources, minus the _sources root):
    OUT/classes/class_node.md            (one page = one file)
    OUT/tutorials/.../page.md
    ...
Giant class pages (> MAX_PAGE_CHARS) are split into OUT/classes/class_xxx/
folders (one file per top-level section, chunks for huge sections).

Also writes:
    OUT/README.md                corpus guide
    OUT/api-symbol-index.tsv     every API symbol -> page + anchor map
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "godot-docs-html-stable" / "_sources"
OUT = Path(__file__).resolve().parent.parent / "godot-docs-md"

MAX_PAGE_CHARS = 180_000     # above this, a class page is split into a folder
MAX_CHUNK_CHARS = 100_000    # max chars of a section chunk inside a split page
SKIP_BASENAMES = {"index", "404", "search", "genindex", "py-modindex"}

SKIP_FILES = set()

# ---------------------------------------------------------------------------
# inline text handling
# ---------------------------------------------------------------------------

CODE_PLACEHOLDER = "\x00CODE\x00"

# role references:  :role:`display<target>`  /  :role:`display`  /  :role:`...`
ROLE_RE = re.compile(r":([\w:+\-]+):`([^`]+)`")
URL_LINK_RE = re.compile(r"`([^`]+?) <(https?://[^`>]+)>`_{1,2}")
BARE_URL_LINK_RE = re.compile(r"`<((?:https?|mailto):[^`>]+)>`_{1,2}")
REL_LINK_RE = re.compile(r"`([^`]+?) <([^`>]+)>`_{1,2}")
NAMED_REF_RE = re.compile(r"`([^`]+?)`_{1,2}")
CODE_SPAN_RE = re.compile(r"``(.+?)``", re.S)

# substitution names seen in Godot doc sources (icon/type shorthands)
SUBS = {
    "void": "void",
    "br": "",
    "const": "const",
    "enum": "enum",
    "signal": "signal",
    "method": "method",
    "property": "property",
    "class": "class",
    "godot": "Godot",
}


def _sub_repl(m: re.Match) -> str:
    name = m.group(1)
    return SUBS.get(name, name if re.fullmatch(r"[\w\-]+", name) else m.group(0))


PIPE_SUB_RE = re.compile(r"\|([\w\-]+)\|")


def clean_inline(text: str) -> str:
    """Apply inline RST markup to plain text."""
    # protect inline code spans first (their content must stay verbatim)
    spans: list[str] = []
    def _cap(m: re.Match) -> str:
        spans.append(m.group(1))
        return CODE_PLACEHOLDER
    text = CODE_SPAN_RE.sub(_cap, text)

    # role references: :role:`display<target>` or :role:`display <target>`
    def _ref(m: re.Match) -> str:
        role, content = m.group(1), m.group(2)
        display = content
        target = None
        if content.endswith(">") and "<" in content:
            cut = content.rfind("<")
            display = content[:cut].rstrip()
            target = content[cut + 1:-1]
        # emoji/bookmark icon links (e.g. trailing anchor icon in class refs)
        if display and not display.isascii() and len(display) <= 3:
            return ""
        if target is None or target == display:
            return display
        if target.startswith("http"):
            return f"[{display}]({target})"
        # plain readable display text; target is the canonical anchor id,
        # searchable inside the same page, so drop it from the text
        return display
    text = ROLE_RE.sub(_ref, text)

    # external hyperlinks `text <url>`_  (with one or two trailing underscores)
    text = URL_LINK_RE.sub(r"[\1](\2)", text)
    # bare-target hyperlink `<url>`_  -> plain URL
    text = BARE_URL_LINK_RE.sub(r"\1", text)
    # any other `text <ref>`_ constructs -> keep only display text
    text = REL_LINK_RE.sub(r"\1", text)
    # named references `name`_ / `name`__ -> plain name
    text = NAMED_REF_RE.sub(r"\1", text)

    # remove RST escape backslashes: \  -> space ; \( -> ( ; \* -> * etc.
    text = re.sub(r"\\([ \\().:;*_#`\"'<>=|{}/-])", r"\1", text)
    text = text.replace("\\", "")

    # substitutions |void| etc.
    text = PIPE_SUB_RE.sub(_sub_repl, text)

    # restore code spans
    def _restore(_m: re.Match) -> str:
        return "`" + spans.pop(0) + "`"
    text = CODE_PLACEHOLDER_RE.sub(_restore, text)
    return text.strip()


CODE_PLACEHOLDER_RE = re.compile(re.escape(CODE_PLACEHOLDER))

# ---------------------------------------------------------------------------
# block structure
# ---------------------------------------------------------------------------

UNDERLINE_CHARS = "=-~^\"'+#*"
DIRECTIVE_RE = re.compile(r"^(\s*)\.\.\s+([\w\-:]+)::\s*(.*)$")
HEADING_TXT_RE = re.compile(r"^(\S.*?)\s*$")
UNDERLINE_RE = re.compile(r"^([=\-~^\"'+#*])\1{2,}\s*$")
BULLET_RE = re.compile(r"^(\s*)[-*+]\s+(.*)$")
NUMBER_RE = re.compile(r"^(\s*)((?:[0-9]+|#|[a-zA-Z])[.)]\s+)(.*)$")
GRID_ROW_RE = re.compile(r"^\s*\|")
GRID_BORDER_RE = re.compile(r"^\s*\+[-+=\s]*\+?\s*$")
OPTION_LINE_RE = re.compile(r"^\s*:\w[\w\-]*:")

ADMONITIONS = {
    "note": "Note",
    "warning": "Warning",
    "tip": "Tip",
    "important": "Important",
    "seealso": "See also",
    "info": "Info",
    "attention": "Attention",
    "danger": "Danger",
    "caution": "Caution",
    "error": "Error",
    "hint": "Hint",
    "admonition": "Admonition",
}

# directives whose indented content should be discarded
DROP_CONTENT = {"image", "figure", "youtube", "video", "thumbnail", "toctree",
                "contents", "meta", "highlight", "raw", "math", "csv-table"}
# directives whose content is a code block (possibly with options lines)
CODE_DIRECTIVES = {"code-block", "code", "code-tab", "literalinclude", "sourcecode"}


def count_indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


class Converter:
    def __init__(self) -> None:
        self.heading_levels: dict[str, int] = {}
        self.anchor: str | None = None
        self.level2_ranges: list[tuple[str, int, int]] = []  # (title,start,end)

    # -- heading helpers ------------------------------------------------
    def heading_level(self, char: str) -> int:
        if char not in self.heading_levels:
            # assign in conventional order
            order = UNDERLINE_CHARS.index(char) if char in UNDERLINE_CHARS else 99
            used = sorted(self.heading_levels.values())
            level = next((c for c in (order + 1, 2, 3, 4, 5, 6) if c not in used), 6)
            self.heading_levels[char] = level
        return self.heading_levels[char]

    # -- main renderer ---------------------------------------------------
    def render_lines(self, lines: list[str]) -> str:
        """Render a dedented list of lines (one block level)."""
        out: list[str] = []
        i, n = 0, len(lines)
        text_pos = 0  # running char offset into 'out'

        def emit(s: str, track_heading: bool = False, title: str = "") -> None:
            nonlocal text_pos
            if track_heading:
                self.level2_ranges.append((title, text_pos, -1))
            out.append(s)
            text_pos += len(s)

        while i < n:
            line = lines[i]

            # blank
            if not line.strip():
                out.append("")
                text_pos += 1
                i += 1
                continue

            indent = count_indent(line)

            # heading: text followed by an underline of repeated chars
            if i + 1 < n and UNDERLINE_RE.match(lines[i + 1]):
                title = line.strip()
                lvl = self.heading_level(lines[i + 1][0])
                self.anchor = None
                prefix = "#" * min(lvl, 6)  # rst H1 -> md '#'
                emit(f"{prefix} {clean_inline(title)}\n", track_heading=(lvl == 2),
                     title=title)
                i += 2
                continue

            # standalone underline => transition / separator
            if UNDERLINE_RE.match(line):
                out.append("---")
                text_pos += 3
                i += 1
                continue

            # plain RST comment / anchor / substitution definition -> skip
            if line.startswith(".. ") and not DIRECTIVE_RE.match(line):
                i += 1
                continue

            # directive
            dm = DIRECTIVE_RE.match(line)
            if dm:
                name, arg = dm.group(2), dm.group(3).strip()
                body, i = self._take_directive_body(lines, i + 1, indent)
                rendered = self._directive(name, arg, body)
                if rendered is not None:
                    out.append(rendered)
                    text_pos += len(rendered)
                continue

            # bare grid table (not wrapped in a .. table:: directive)
            if GRID_BORDER_RE.match(line) or GRID_ROW_RE.match(line):
                block: list[str] = []
                while i < n and lines[i].strip():
                    if GRID_BORDER_RE.match(lines[i]) or GRID_ROW_RE.match(lines[i]):
                        block.append(lines[i])
                        i += 1
                    else:
                        break
                if block:
                    tbl = self._grid_table(block)
                    if tbl:
                        out.append(tbl)
                        text_pos += len(tbl)
                continue

            # plain paragraph / list run until next blank or block element
            run: list[str] = []
            while i < n and lines[i].strip():
                nxt = lines[i]
                if DIRECTIVE_RE.match(nxt):
                    break
                if i + 1 < n and UNDERLINE_RE.match(lines[i + 1]):
                    break
                if UNDERLINE_RE.match(nxt):
                    break
                # indented lines right after a '::' introducer are literal
                if run and re.search(r"::$", run[-1].rstrip()) and count_indent(nxt) > 0:
                    break
                run.append(nxt)
                i += 1
            if not run:
                continue

            # "::" literal block introducer (RST inline-code shorthand)
            is_literal = False
            if run[0].strip() and not (BULLET_RE.match(run[0])
                                       or NUMBER_RE.match(run[0])):
                if re.search(r"::$", run[-1].rstrip()):
                    is_literal = True
                    last = run[-1].rstrip()
                    if last == "::":
                        run.pop()
                    else:
                        run[-1] = last[:-2].rstrip()
            if run:
                out.append(self._render_run(run))
                text_pos += len(out[-1]) + 1
            out.append("")
            text_pos += 1

            if is_literal:
                code, j = self._take_literal(lines, i)
                i = j
                if code:
                    out.append(code)
                    text_pos += len(code)
                continue

        # close level2 ranges
        for idx in range(len(self.level2_ranges)):
            t, s, e = self.level2_ranges[idx]
            nxt = self.level2_ranges[idx + 1][1] if idx + 1 < len(self.level2_ranges) else text_pos
            self.level2_ranges[idx] = (t, s, nxt)
        return "\n".join(out)

    def _take_literal(self, lines: list[str], start: int
                      ) -> tuple[str | None, int]:
        """Literal block following a '::' paragraph.

        Content: following lines that are indented (any deeper indent);
        a non-indented non-blank line ends the block. Dedents by the minimum
        indent of the block.
        """
        j = start
        n = len(lines)
        raw: list[str] = []
        while j < n:
            ln = lines[j]
            if not ln.strip():
                # keep trailing blank candidates but stop at dedent after them
                raw.append("")
                j += 1
                continue
            if count_indent(ln) > 0:
                raw.append(ln)
                j += 1
            else:
                break
        while raw and not raw[-1].strip():
            raw.pop()
        if not raw:
            return None, j
        inds = [count_indent(l) for l in raw if l.strip()]
        m = min(inds)
        ded = [l[m:] if len(l) >= m else l for l in raw]
        return "```text\n" + "\n".join(ded).strip("\n") + "\n```", j

    # -- directive bodies ------------------------------------------------
    def _take_directive_body(self, lines: list[str], start: int, base_indent: int
                             ) -> tuple[list[str], int]:
        """Return (content_lines, next_index) for a directive at lines[start-1].

        Content = following lines more indented than the directive itself.
        Options lines (":word: ...") are not content.
        """
        body: list[str] = []
        i = start
        while i < len(lines):
            ln = lines[i]
            if not ln.strip():
                body.append("")
                i += 1
                continue
            if count_indent(ln) > base_indent:
                body.append(ln)
                i += 1
            else:
                break
        # trim trailing blanks, drop option lines at head
        while body and not body[-1].strip():
            body.pop()
        return body, i

    def _dedent(self, body: list[str]) -> list[str]:
        inds = [count_indent(l) for l in body if l.strip()]
        if not inds:
            return []
        m = min(inds)
        return [l[m:] if len(l) >= m else l for l in body]

    def _directive(self, name: str, arg: str, body: list[str]) -> str | None:
        if name in {"rst-class"}:
            self.anchor = None
            return None
        if name in {"github_url"}:
            return None
        if name in {"class", "function", "method", "attribute", "js:class",
                    "js:function", "js:attribute", "py:class", "py:function",
                    "py:method", "py:attribute", "py:data", "c:function",
                    "c:type", "c:var", "c:macro", "c:member", "c:enum",
                    "glossary", "index", "versionadded", "versionchanged",
                    "deprecated", "default-domain", "module", "currentmodule",
                    "exception", "cssclass", "role", "confval"}:
            # object descriptions: keep content, skip signature/role lines
            return self.render_lines(self._dedent(body)) or None
        if name in DROP_CONTENT:
            # 'only' with negation keeps content, 'raw' rarely carries text
            if name == "only" and "not" in arg:
                return self.render_lines(self._dedent(body)) or None
            return None
        if name in CODE_DIRECTIVES:
            body = self._dedent(body)
            body = [l for l in body if not OPTION_LINE_RE.match(l)]
            lang = (arg or "text").split()[0].lower()
            lang = re.sub(r"[^a-z0-9_+\-]", "", lang) or "text"
            code = "\n".join(body).strip("\n")
            return f"```{lang}\n{code}\n```" if code else None
        if name in {"tabs"}:
            return self.render_lines(self._dedent(body)) or None
        if name in {"tab"}:
            body = self._dedent(body)
            head = f"<!-- tab: {clean_inline(arg)} -->" if arg else None
            inner = self.render_lines(body)
            if head and inner:
                return f"{head}\n{inner}"
            return inner or None
        if name in ADMONITIONS:
            label = ADMONITIONS[name]
            body = self._dedent(body)
            if arg:
                # inline lead text continues as the first body paragraph
                body = [arg] + body
            inner = self.render_lines(body)
            if inner is None:
                return None
            return f"**[{label}]**\n{inner}"
        if name == "rubric":
            return f"**{clean_inline(arg)}**" if arg else None
        if name == "table":
            return self._grid_table(body)
        if name == "list-table":
            return self._list_table(body)
        if name == "include":
            return None
        if name in {"only", "raw"}:
            return None
        # unknown directive: render content without the directive line
        body = self._dedent(body)
        return self.render_lines(body) or None

    # -- tables -----------------------------------------------------------
    def _grid_table(self, body: list[str]) -> str | None:
        # strip wrapper lines (.. table::, :widths: ...)
        rows: list[list[str]] = []
        borders: list[int] | None = None
        for ln in body:
            if OPTION_LINE_RE.match(ln) or ln.strip() in (".. table::", ""):
                continue
            if GRID_BORDER_RE.match(ln):
                # remember column separators from the first border line
                if borders is None:
                    borders = [i for i, ch in enumerate(ln) if ch == "+"]
                continue
            if GRID_ROW_RE.match(ln):
                if borders is None:
                    borders = [i for i, ch in enumerate(ln) if ch == "|"]
                    borders = [0] + [i + 1 for i in borders[:-1]]
                cells = []
                for a, b in zip(borders, borders[1:]):
                    seg = ln[a + 1:b] if len(ln) >= b else ln[a + 1:]
                    cells.append(seg.replace("\\|", "|").strip())
                rows.append(cells)
        if not rows:
            return None
        return self._rows_to_md(rows)

    def _list_table(self, body: list[str]) -> str | None:
        rows: list[list[str]] = []
        cur: list[str] | None = None
        header_rows = 0
        for ln in body:
            if OPTION_LINE_RE.match(ln):
                m = re.match(r":header-rows:\s*(\d+)", ln.strip())
                if m:
                    header_rows = int(m.group(1))
                continue
            s = ln.strip()
            if s.startswith("* - "):
                if cur:
                    rows.append(cur)
                cur = [s[4:]]
            elif s.startswith("- ") and cur is not None:
                cur.append(s[2:])
            elif s and cur is not None:
                cur[-1] += " " + s
        if cur:
            rows.append(cur)
        if not rows:
            return None
        return self._rows_to_md(rows)

    def _rows_to_md(self, rows: list[list[str]]) -> str:
        cols = max(len(r) for r in rows)
        md: list[str] = []
        for ri, row in enumerate(rows):
            cells = [clean_inline(c).replace("|", "\\|") for c in row]
            cells += [""] * (cols - len(cells))
            md.append("| " + " | ".join(cells) + " |")
            if ri == 0 and len(rows) > 1:
                md.append("|" + "---|" * cols)
        return "\n".join(md)

    # -- paragraphs & lists ------------------------------------------------
    def _render_run(self, run: list[str]) -> str:
        first = run[0]
        bm = BULLET_RE.match(first)
        nm = NUMBER_RE.match(first)
        if bm and count_indent(first) == 0:
            # flat bullet list, one level deep is enough for our corpus
            items: list[str] = []
            cur: list[str] | None = None
            for ln in run:
                m = BULLET_RE.match(ln)
                if m and count_indent(ln) == 0:
                    if cur is not None:
                        items.append(cur)
                    cur = [m.group(2)]
                elif cur is not None:
                    cur.append(ln)
            if cur is not None:
                items.append(cur)
            return "\n".join(
                "- " + clean_inline(" ".join(t.strip() for t in it))
                for it in items)
        if nm and count_indent(first) == 0:
            items: list[list[str]] = []
            cur: list[str] | None = None
            for ln in run:
                m = NUMBER_RE.match(ln)
                if m and count_indent(ln) == 0:
                    if cur is not None:
                        items.append(cur)
                    num = m.group(2).replace("#.", "1.")
                    cur = [num + m.group(3)]
                elif cur is not None:
                    cur.append(ln)
            if cur is not None:
                items.append(cur)
            return "\n".join(
                clean_inline(" ".join(t.strip() for t in it)) for it in items)
        # plain paragraph (soft line breaks joined first so that references
        # spanning source lines are resolved together)
        return clean_inline(" ".join(l.strip() for l in run))

    # ------------------------------------------------------------------
    def render_file(self, text: str) -> str:
        lines = text.splitlines()
        self.level2_ranges = []
        self.heading_levels = {}
        # drop Sphinx 'field list' metadata at top (:github_url: hide)
        while lines and re.match(r"^:\w[\w\-]*(/[\w\-]*)*:\s*\S*$", lines[0]):
            lines.pop(0)
        out = self.render_lines(lines)
        out = re.sub(r"\n{3,}", "\n\n", out)
        return out.strip() + "\n"


# ---------------------------------------------------------------------------
# page splitting for giant class pages
# ---------------------------------------------------------------------------

def split_giant_page(title: str, text: str, max_chunk: int
                     ) -> list[tuple[str, str]]:
    """Split into (filename, content) chunks using ## level-2 sections."""
    conv = Converter()
    conv.heading_levels = {}
    # already rendered; re-derive level2 ranges from the markdown text
    secs: list[tuple[str, int, int]] = []
    starts = [(m.start(), m.group(1).strip())
              for m in re.finditer(r"(?m)^##\s+(.+)$", text)]
    # content before the first ## section (title, inheritance, brief) must
    # not be lost: give it its own leading section
    if starts and starts[0][0] > 0:
        secs.append((title, 0, starts[0][0]))
    for idx, (pos, t) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(text)
        secs.append((t, pos, end))
    if not secs:
        secs = [(title, 0, len(text))]

    files: list[tuple[str, str]] = []
    for idx, (t, s, e) in enumerate(secs):
        body = text[s:e].strip()
        name = f"{idx + 1:03d}-{t.lower()}"
        name = re.sub(r"[^a-z0-9]+", "-", name).strip("-")[:70] or f"section-{idx}"
        if len(body) <= max_chunk:
            files.append((name + ".md", body + "\n"))
            continue
        # chunk at entry boundaries: lines starting with '**' or 'enum **'
        paras: list[list[str]] = [[]]
        for ln in body.splitlines():
            if not ln.strip():
                if paras[-1]:
                    paras.append([])
                continue
            if paras and ln.startswith("**") and len("".join(paras[-1])) > 0:
                paras.append([])
            paras[-1].append(ln)
        chunks: list[list[str]] = [[]]
        size = 0
        for grp in paras:
            gtxt = "\n".join(grp).strip()
            if not gtxt:
                continue
            if size + len(gtxt) > max_chunk and chunks[-1]:
                chunks.append([])
                size = 0
            chunks[-1].append(gtxt)
            size += len(gtxt)
        for ci, grp in enumerate(chunks, 1):
            files.append((f"{name}-p{ci}.md", "\n\n".join(grp) + "\n"))
    return files


# ---------------------------------------------------------------------------
# API symbol index: every documented symbol (class / property / method /
# signal / enum / constant / …) -> page that documents it.
#
# The class pages are generated RST, so every API object has a
# ".. _<anchor>:" line, e.g.:
#     .. _class_Node_method_queue_free:
#     .. _class_Node_property_name:
#     .. _class_Node_signal_ready:
#     .. _class_Node_constant_NOTIFICATION_READY:
#     .. _enum_Node_ProcessMode:
# ---------------------------------------------------------------------------

MEMBER_KINDS = [
    "global_scope_constant", "global_scope_method", "private_method",
    "theme_font_size", "theme_constant", "theme_stylebox", "theme_color",
    "theme_font_variations", "theme_font", "theme_icon", "theme_type_variation",
    "theme_item", "property", "signal", "constant", "method",
    "constructor", "operator", "annotation", "enum",
]

CLASS_ANCHOR_RE = re.compile(r"(?m)^\.\. _((?:class|enum)_[^:\s]+):\s*$")


def scan_class_anchors() -> list[tuple[str, str, str, str]]:
    rows: set[tuple[str, str, str, str]] = set()
    for rst in sorted((SRC / "classes").glob("*.rst.txt")):
        cls_page = rst.stem[:-4]              # class_node.rst.txt -> class_node
        text = rst.read_text(encoding="utf-8", errors="replace")
        for m in CLASS_ANCHOR_RE.finditer(text):
            anchor = m.group(1)
            pm = re.match(r"^(class|enum)_([^_]+)(?:_(.*))?$", anchor)
            if not pm:
                continue
            kind0, cls, rest = pm.group(1), pm.group(2), pm.group(3) or ""
            sym = cls
            kind = "class"
            if kind0 == "enum":
                kind = "enum"
                sym = f"{cls}.{rest}" if rest else cls
            elif rest:
                r2 = rest
                matched = None
                for k in sorted(MEMBER_KINDS, key=len, reverse=True):
                    if r2.startswith(k + "_"):
                        matched = k
                        r2 = r2[len(k) + 1:]
                        break
                name = r2
                if matched is None:
                    matched = "member"
                kind = matched
                # private GDScript members keep their underscore (e.g. _input)
                if kind == "private_method":
                    kind = "method"
                sym = f"{cls}.{name}" if name else cls
            page = "classes/" + cls_page
            if (OUT / "classes" / cls_page).is_dir():
                page += "/"   # giant class split into a folder
            else:
                page += ".md"
            rows.add((sym, kind, page, anchor))
    return sorted(rows)


# ---------------------------------------------------------------------------

def convert_all() -> None:
    if not SRC.is_dir():
        print(f"SOURCE NOT FOUND: {SRC}")
        sys.exit(1)
    OUT.mkdir(parents=True, exist_ok=True)
    # regenerate from scratch: previous runs may have left obsolete files
    import shutil
    for item in OUT.iterdir():
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()

    total = 0
    skipped = []
    conv = Converter()
    rst_files = sorted(SRC.rglob("*.rst.txt"))
    for rst in rst_files:
        base = rst.stem[:-4]  # strip '.rst'
        if base in SKIP_BASENAMES:
            skipped.append(rst)
            continue
        rel = rst.relative_to(SRC).with_suffix("")  # -> about/faq
        # rel currently has no .rst suffix (with_suffix('') removes .txt only?)
        rel = Path(str(rel).replace(".rst", ""))
        text = rst.read_text(encoding="utf-8", errors="replace")
        md = conv.render_file(text)
        target = OUT / rel.with_suffix(".md")
        if len(md) <= MAX_PAGE_CHARS or rel.parts[0] != "classes":
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(md, encoding="utf-8")
        else:
            folder = OUT / rel
            folder.mkdir(parents=True, exist_ok=True)
            files = split_giant_page(rel.name, md, MAX_CHUNK_CHARS)
            for fname, content in files:
                (folder / fname).write_text(content, encoding="utf-8")
            # manifest
            toc = "\n".join(f"- `{fn}`" for fn, _ in files)
            (folder / "_sections.md").write_text(
                f"# {rel.name} (split page)\n\nSections:\n{toc}\n",
                encoding="utf-8")
        total += 1
        if total % 200 == 0:
            print(f"  ... {total}/{len(rst_files)}", flush=True)

    print(f"converted {total} pages, skipped {len(skipped)}")
    return total


def build_symbol_index() -> int:
    rows = scan_class_anchors()
    idx = OUT / "api-symbol-index.tsv"
    lines = ["symbol\tkind\tpage\tanchor"]
    lines += [f"{s}\t{k}\t{p}\t{a}" for s, k, p, a in rows]
    idx.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"symbol index: {len(rows)} entries -> {idx}")
    return len(rows)


def write_readme(n_pages: int, n_syms: int) -> None:
    readme = f"""# Godot docs — Markdown corpus (for AI agents)

Generated from the RST sources inside `godot-docs-html-stable/_sources`
(the official Godot HTML documentation download). One page = one Markdown
file; pure text, no HTML/JS boilerplate.

- Source docs version: Godot **4.7** (development) — page titles may carry
  "(DEV)". Match this corpus to the Godot editor version you actually use.
- Pages converted: **{n_pages}**
- Layout mirrors the docs site: `classes/`, `tutorials/`, `getting_started/`,
  `engine_details/`, `community/`, `about/`.
- `classes/class_<name>.md` = Godot class reference for `<name>`
  (e.g. `classes/class_node.md`, `classes/class_characterbody2d.md`).
  Class pages larger than {MAX_PAGE_CHARS} chars are split into a folder
  `classes/class_<name>/` (one file per top-level section, e.g.
  `…-property-descriptions-p1.md`).
- `api-symbol-index.tsv`: one row per documented API object:
  `symbol<TAB>kind<TAB>page<TAB>anchor`, e.g.
  `Node.queue_free   method   classes/class_node.md   class_Node_method_queue_free`.
  Grep it to resolve any symbol (`Node.queue_free`, `Sprite2D.texture`,
  `SceneTree`, `CharacterBody2D.move_and_slide`, …) to the page + anchor that
  documents it; inside that page, `anchor` text appears verbatim so an agent
  can locate the exact entry.

## Suggested agent usage

- Never load the whole tree: look up `api-symbol-index.tsv` or guess
  `classes/class_<name>.md`, then read only that page (or the matching chunk).
- Inside a class page, entry signatures appear as `**name**` lines; property
  and method summaries live under `## Properties` / `## Methods`, full docs
  under `## Property Descriptions` / `## Method Descriptions`.
- Tutorial pages cover GDScript language, shaders, physics, UI, etc. under
  `tutorials/`.
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")


if __name__ == "__main__":
    npages = convert_all()
    nsym = build_symbol_index()
    write_readme(npages, nsym)
    print("done.")
