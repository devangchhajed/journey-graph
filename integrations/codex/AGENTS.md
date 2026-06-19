# Journey graphs in this repo (Codex guidance)

> Paste this section into your repo's `AGENTS.md` (or `~/.codex/AGENTS.md` for all repos)
> so Codex knows about journey graphs even without the `/journey-graph` slash command.

This project may contain **journey graphs** under `journey-graphs/` — self-describing JSON
documents that map a workflow as a directed graph: **nodes = states, edges = actions on
elements, branches = divergence points, paths = named end-to-end traversals**.

When asked to map, build, extend, summarise, or query a workflow:

1. Read `journey-graphs/SPEC.md` for field semantics (each graph also names its spec in `specRef`).
2. Prefer **reading an existing graph** over re-reading the original source docs — provenance is recorded inside the graph under `graph.context.sources`.
3. To add a variant, **append a branch** (new nodes/edges + a `branches` variant) rather than re-deriving the whole flow. Never modify or renumber existing `node`/`edge`/`path` ids.
4. Mark known-but-unmodelled variants honestly: `branches[].variants` with `edge:null, covered:false`.
5. Validate any graph you write against `journey-graphs/json-schema.json` (or the repo's schema) before declaring done.

Graphs live at `journey-graphs/<namespace>/<slug>.json`.
