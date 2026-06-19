---
name: journey-graph
description: "Build, read, extend, and query journey graphs — self-describing JSON maps of any workflow as states (nodes) + actions on elements (edges) + branches + named paths. Use when the user says 'map this journey/flow', 'build a journey graph', 'add a branch to <journey>', 'what paths/branches exist', 'what's not covered', 'turn this flow into a graph', or '/journey-graph'. The graph lets any LLM understand a workflow without re-reading the source docs and append new branches without re-deriving the whole flow. Domain-neutral: works for UI flows, API sequences, CLI workflows, and business processes."
---

# journey-graph

A journey graph is a self-describing JSON document that maps a workflow as a directed
graph — **nodes = states, edges = actions on elements, branches = divergence points,
paths = named end-to-end traversals**. It is a reusable knowledge cache: read it instead
of re-reading source docs; extend it with branches instead of re-deriving the flow.

This skill is a thin entry point. The authoritative, **tool-neutral** definitions and
procedures live in the shared `spec/` directory, surfaced here through the skill's
`references/` symlink — any LLM can follow them with no special tooling:

- **Format spec** → `${CLAUDE_SKILL_DIR}/references/SPEC.md` (the repo's `spec/SPEC.md`). If that path isn't resolvable in your install, read `spec/SPEC.md` from the repo root, or the copy this skill's `init` mode drops into the host project.
- **Procedure** (all modes) → `${CLAUDE_SKILL_DIR}/references/procedure.md`
- **JSON Schema** → `${CLAUDE_SKILL_DIR}/references/json-schema.json`

Read `procedure.md` before doing real work; read `SPEC.md` when you need the exact field meanings.

---

## Modes

Dispatch on what the user asks (arguments after `/journey-graph`):

| Intent | Mode | What it does |
|---|---|---|
| "set up journey graphs here" / first use in a project | **init** | Copy `SPEC.md` into the host project's `journey-graphs/` so any LLM there can read graphs without this skill; create the folder. |
| "map / build a journey graph for X" | **build** | Create a new graph from a described or observed flow → write `journey-graphs/<namespace>/<slug>.json`. |
| "show / summarise <graph>" / "what's covered" | **show** | Read a graph; summarise its paths, branch points, and **uncovered variants** (gaps). |
| "add a branch to <graph> at <state>" | **branch** | Append new nodes/edges + a branch variant (and optionally a new path) **without touching existing ids**. |
| "which paths use X" / "shared prefix of A & B" / "what's not covered" | **query** | Answer structural questions by reading the graph. |
| "validate <graph>" | **validate** | Check a graph file against the JSON Schema. |

If the intent is ambiguous, ask one short question naming the candidate modes.

---

## Hard rules (also in SPEC.md §7 — enforce them)

- **IDs are immutable** — never renumber or reuse `node`/`edge`/`path` ids.
- **Append, don't rewrite** — adding a branch must not modify existing nodes/edges. This is what makes branching cheap.
- **Record provenance** — when building/extending from a source, add it to `graph.context.sources` with `readAt`, so the next reader trusts the graph instead of re-reading.
- **Mark gaps honestly** — a known-but-unmodelled variant goes in `branches` with `edge:null, covered:false`.
- **Stay generic** — domain specifics (selectors, endpoints, payloads, framework details) go in `data`/`extensions`, never as new core fields.
- **Validate before declaring done** — the written graph must pass the JSON Schema.

---

## Where graphs live

By default, `journey-graphs/<namespace>/<slug>.json` at the host-project root, with a
`SPEC.md` copy alongside (from `init`). The user may point you elsewhere — honour that.
Each graph file is self-contained and references the spec via its `specRef` field.
