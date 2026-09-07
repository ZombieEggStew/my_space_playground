---
name: godot-docs
description: >-
  Look up Godot engine documentation from the bundled offline corpus in
  `godot-docs-md/` (official Godot 4.7-dev docs, one Markdown page per doc
  page; classes in `classes/`, manuals in `tutorials/`, `getting_started/`,
  `engine_details/`; API symbol map in `api-symbol-index.tsv`). Use whenever
  writing or reviewing GDScript/Godot code and you need the exact API for a
  class, method, property, signal, enum, constant or annotation, or you need a
  manual topic (input, physics, shaders, UI, multiplay, export, …). Do not
  guess signatures or semantics from memory: resolve first, read the matching
  page, then answer.
---

# godot-docs — offline Godot reference lookup

This project bundles an offline Markdown corpus of the official Godot
documentation (source version: **Godot 4.7-dev**, page titles may carry
"(DEV)"; match this to the Godot editor version actually used in this repo,
currently `project.godot` targets 4.7).

Corpus layout (repo root = the folder containing `project.godot` and
`godot-docs-md/`):

```
godot-docs-md/
├─ api-symbol-index.tsv   # every documented API symbol → page + anchor
├─ README.md              # corpus guide (read it once)
├─ classes/class_<name>.md        # class reference, one file per class
├─ classes/class_<name>/…md       # ONLY for huge classes, split per section
├─ tutorials/…                     # GDScript, physics, shaders, UI, …
├─ getting_started/  engine_details/  community/  about/
```

## Workflow

### 1. Resolve the API symbol first (never guess a file)

`api-symbol-index.tsv` columns: `symbol \t kind \t page \t anchor`.
Example rows:

```
Node.queue_free    method    classes/class_node.md    class_Node_method_queue_free
Sprite2D.texture   property  classes/class_sprite2d.md class_Sprite2D_property_texture
```

Quickest: use the bundled helper (Python 3, stdlib only) from anywhere in the
repo:

```
python .tools/godot-docs/godot_docs_lookup.py symbol "Node.queue_free()"
python .tools/godot-docs/godot_docs_lookup.py symbol "process_mode"
python .tools/godot-docs/godot_docs_lookup.py page CharacterBody2D
python .tools/godot-docs/godot_docs_lookup.py topic "物理层"
python .tools/godot-docs/godot_docs_lookup.py search "physics interpolation"
```

No Python available? Equivalent plain-text lookups:

- Resolve a symbol (ripgrep): `rg -P "^Node\.queue_free\t" godot-docs-md/api-symbol-index.tsv`
- Fuzzy: `rg -i "process_mode" godot-docs-md/api-symbol-index.tsv | head -20`
- Search prose: `rg -n -i "term1 term2" godot-docs-md/tutorials` (or your
  editor's file search over `godot-docs-md/`).

### 2. Cross-reference: topic → canonical page

`topic-index.tsv` (in `.tools/godot-docs/`, next to the script) is a
curated **topic → canonical page** index covering the topics this project
actually touches (physics layers, signals, shaders, viewports, input map, …).
Columns: `category \t topic \t aliases \t page \t note`. Use it when you only
have a **concept / Chinese keyword** and no concrete API name:

```
python .tools/godot-docs/godot_docs_lookup.py topic "物理层"
python .tools/godot-docs/godot_docs_lookup.py topic "spring arm"
```

Matching is case-insensitive substring over topic+aliases (multiple terms are
AND-ed). On no curated match it falls back to full-text `search`. The hit gives
the canonical page path — read that page.

### 3. Read the resolved page, then the exact entry

Open the page given by the index. A class page has this anatomy:

```
# Node                        ← class name; brief summary; inheritance
## Description                ← long-form overview
## Tutorials                  ← links to relevant tutorial pages
## Properties | ## Methods | ## Signals | ## Enumerations | ## Constants
                               ← compact reference tables (type/name/default)
## Property Descriptions      ← one block per property
## Method Descriptions        ← one block per method, e.g.
                               `void **queue_free** ( )`
```

The `anchor` value from the index (e.g. `class_Node_method_queue_free`) appears
verbatim in the page source, so grep the page for it to land on the entry:
`rg -n "class_Node_method_queue_free" godot-docs-md/classes/class_node.md`.

### 4. Manuals / tutorials

`tutorials/` mirrors the docs site (`tutorials/scripting/gdscript/…`,
`tutorials/physics/…`, `tutorials/rendering/…`, `tutorials/ui/…`,
`tutorials/networking/…`, …). Topic pages are per-folder; guess the folder or
use full-text search above. Pages are one file per page, no HTML boilerplate;
GDScript/C# code examples are kept as fenced blocks.

## Constraints & gotchas

- **Read only the pages/entries you need.** Never dump the whole corpus (≈
  11 MB text, 1500+ files) into context. Resolve → read → answer.
- **Huge classes** (`RenderingServer`, `ProjectSettings`) are split into
  `classes/class_<name>/` folders (numbered section files, chunks under
  `…-p1.md`; manifest `_sections.md`). Prefer `page <class>` or the index
  `page` column, which already point there.
- **File names are lower-case**: `CharacterBody2D` →
  `classes/class_characterbody2d.md`; special names keep their glyph
  (`@GDScript` → `classes/class_@gdscript.md`). The index's `symbol` column
  keeps the real case — resolve through it rather than constructing paths.
- **Version drift**: these are 4.7-dev docs. If code must run on a stable
  engine (e.g. 4.6.x), double-check members flagged as new/renamed; when in
  doubt search the class page's method/property list before using an API.
- **Not in the corpus**: images/figures were dropped (text only) and doc
  landing/index pages were skipped. Tutorial prose that says "as shown in the
  image" may lack the image — say so rather than inventing it.
