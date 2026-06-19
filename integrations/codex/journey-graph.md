# journey-graph (Codex custom prompt)

Install this file at `~/.codex/prompts/journey-graph.md` to get a `/journey-graph`
slash command in the Codex CLI. Invoke it as `/journey-graph <intent>`, e.g.
`/journey-graph build a graph for the add-contact flow`.

The request: **$ARGUMENTS**

---

You are working with **journey graphs** — self-describing JSON documents that map a
workflow as a directed graph: **nodes = states, edges = actions on elements,
branches = divergence points, paths = named end-to-end traversals**. A journey graph is
a reusable knowledge cache: read it instead of re-reading source docs; extend it with
branches instead of re-deriving the whole flow.

The authoritative, **tool-neutral** definitions and procedures are shared across every
integration. Read them before doing real work:

- **Format spec** → `journey-graphs/SPEC.md` in this project (dropped by `init`), or the
  journey-graph repo's `spec/SPEC.md`. Each graph also names its spec in `specRef`.
- **Procedure** (all modes) → the repo's `spec/procedure.md`.
- **JSON Schema** → the repo's `spec/json-schema.json`.

If no local copy or repo is reachable, the model and hard rules below are enough to build
a valid graph; fetch the spec for exact field semantics when needed.

## Modes — dispatch on `$ARGUMENTS`

- **init** — "set up journey graphs here": create `journey-graphs/` and copy `SPEC.md` into it.
- **build** — "map/build a graph for X": create `journey-graphs/<namespace>/<slug>.json` from the described or observed flow.
- **show** — "show/summarise <graph>": report paths, branch points, and uncovered variants (gaps).
- **branch** — "add a branch to <graph> at <state>": append new nodes/edges + a branch variant **without touching existing ids**.
- **query** — "which paths use X" / "shared prefix of A & B" / "what's not covered": answer structurally by reading the graph.
- **validate** — "validate <graph>": check against the JSON Schema.

If the intent is ambiguous, ask one short question naming the candidate modes.

## Hard rules (also in SPEC.md §7 — enforce them)

- **IDs are immutable** — never renumber or reuse `node`/`edge`/`path` ids.
- **Append, don't rewrite** — adding a branch must not modify existing nodes/edges.
- **Record provenance** — add each source to `graph.context.sources` with `readAt`.
- **Mark gaps honestly** — known-but-unmodelled variants go in `branches` with `edge:null, covered:false`.
- **Stay generic** — domain specifics go in `data`/`extensions`, never as new core fields.
- **Validate before declaring done** — the written graph must pass the JSON Schema.

Graphs live at `journey-graphs/<namespace>/<slug>.json` by default; honour any path the user gives.
