# Journey Graph — Format Specification

**Version 1.0** · tool-neutral · LLM-agnostic

A **journey graph** is a JSON document that models a *journey* — any goal-directed
workflow — as a directed graph:

- **nodes** are *states* the journey can be in (a screen, a page, an API resource state, a CLI prompt, a step in a process);
- **edges** are *actions* that move from one state to another, each naming the *element* acted upon and any *input* given;
- **branches** mark the points where a journey can diverge (and record which divergences are already covered);
- **paths** are named end-to-end traversals — each path is one concrete journey instance (e.g. a test case, a runbook, a tutorial).

The whole point: a journey graph is **self-describing knowledge** that any LLM can
read to understand a workflow *without re-reading the original source material*, and
can **extend with new branches** without re-deriving what is already known.

This spec is the single source of truth. A graph file points back to it via `specRef`.
Nothing here is specific to any product, framework, or domain. The running example below
(publishing a post) is illustrative only.

---

## 1. Top-level shape

A journey graph is one JSON object:

```jsonc
{
  "schemaVersion": "1.0",
  "kind": "journey-graph",
  "legend": "Nodes are states; edges are actions on elements; a path is one journey.",
  "specRef": "https://github.com/devangchhajed/journey-graph/blob/main/spec/SPEC.md",

  "graph":    { ... },   // identity + provenance of this journey
  "nodes":    [ ... ],   // the states
  "edges":    [ ... ],   // the actions between states
  "branches": [ ... ],   // divergence points (optional but recommended)
  "paths":    [ ... ]    // named end-to-end traversals (optional)
}
```

| Field | Req | Meaning |
|---|---|---|
| `schemaVersion` | ✅ | `"1.0"`. Bump only on breaking format changes. |
| `kind` | ✅ | Always `"journey-graph"`. Lets a reader detect the file type. |
| `legend` | ✅ | One human sentence so a cold reader instantly knows how to read the file. |
| `specRef` | ➖ | URL/path to this spec. Strongly recommended for portability. |
| `graph` | ✅ | Identity + provenance (see §2). |
| `nodes` | ✅ | Array of states (see §3). At least one with `type:"start"`. |
| `edges` | ✅ | Array of actions (see §4). May be empty for a stub graph. |
| `branches` | ➖ | Divergence index (see §5). |
| `paths` | ➖ | Named traversals (see §6). |

---

## 2. `graph` — identity & provenance

```jsonc
"graph": {
  "id": "blog/publish-post",        // "<namespace>/<slug>", stable, unique
  "title": "Publish a blog post",
  "domain": "ui",                   // free string: ui | api | cli | process | <anything>
  "description": "An author writes a post, reviews it, and publishes it at a chosen visibility.",
  "roles": ["author"],              // actors involved; ["maker","checker"] for multi-actor
  "entry": "https://app.example/posts/new", // optional: where the journey starts (URL, command, endpoint)
  "context": {                      // free-form PROVENANCE — what this graph was built from
    "sources": [
      { "type": "doc",  "ref": "docs/posts.md", "readAt": "2026-06-19" },
      { "type": "live", "ref": "observed in the editor UI", "readAt": "2026-06-19" }
    ],
    "notes": "Drafts auto-save; this journey models only the publish action."
  },
  "extensions": { }                 // opaque, project-specific blob; generic readers IGNORE it
}
```

| Field | Req | Meaning |
|---|---|---|
| `id` | ✅ | Stable unique id, `"<namespace>/<slug>"`. Used to reference the graph. Never reuse. |
| `title` | ✅ | Human title. |
| `domain` | ➖ | What kind of journey. Free string; common: `ui`, `api`, `cli`, `process`. |
| `description` | ➖ | 1–3 sentences. |
| `roles` | ➖ | Actors. Multi-actor journeys (e.g. an approval) list more than one. |
| `entry` | ➖ | Where the journey begins, in whatever form fits the domain. |
| `context` | ➖ | **Provenance.** `sources[]` records what was read to build the graph (with `readAt`), so a later reader trusts the graph instead of re-reading those sources. |
| `extensions` | ➖ | Escape hatch for project-specific data. A generic reader/validator ignores it; a specific tool may read it. |

---

## 3. `nodes` — states

Each node is one state the journey can occupy.

```jsonc
{
  "id": "n_editor",                 // stable, unique within the graph
  "type": "start",                  // start | state | terminal
  "name": "Editor",
  "locator": "/posts/new",          // optional: how to recognise/reach this state (route, screen name, endpoint, prompt)
  "elements": [                     // optional: the interactive elements known in this state
    { "ref": "title-input", "kind": "input",  "note": "post title" },
    { "ref": "body-input",  "kind": "input",  "note": "post body" },
    { "ref": "review-button", "kind": "button", "note": "go to review" }
  ],
  "data": { }                       // optional free-form per-node blob
}
```

| Field | Req | Meaning |
|---|---|---|
| `id` | ✅ | Stable unique node id. Convention: `n_<slug>`. **Never renumber/reuse.** |
| `type` | ✅ | `start` (entry), `state` (intermediate), or `terminal` (an end state). At least one `start`. |
| `name` | ✅ | Human label. |
| `locator` | ➖ | How to identify/reach the state — domain-shaped (a URL, a screen title, an API path, a CLI prompt). |
| `elements` | ➖ | The known interactive elements in this state — the reusable *vocabulary* of the state. |
| `data` | ➖ | Project-specific per-node data; ignored generically. |

### `elements[]` entries

| Field | Req | Meaning |
|---|---|---|
| `ref` | ✅ | A **generic element identifier** — a stable handle for the element. A UI binding maps it to a selector/test id; an API binding to a field/param; a CLI binding to a flag. Edges refer to elements by this `ref`. |
| `kind` | ➖ | Element category: `button`, `input`, `select`, `link`, `field`, `toggle`, … free string. |
| `note` | ➖ | One-line purpose. |
| `data` | ➖ | Project-specific blob. |

> Heavy artifacts (full HTML snapshots, screenshots, payload samples) do **not** belong
> in the graph — keep the graph readable. Reference them from `data`/`extensions` if needed.

---

## 4. `edges` — actions

Each edge is an action that transitions from one node to another.

```jsonc
{
  "id": "e_to_review",              // stable, unique within the graph
  "from": "n_editor",
  "to": "n_review",
  "action": {
    "verb": "click",                // click | type | select | check | navigate | call | run | submit | <free>
    "target": "review-button",      // an element `ref` from the `from` node (optional for verbs like navigate)
    "input": null                   // value typed / option chosen / payload sent (optional)
  },
  "label": "Go to review",          // optional human label
  "guards": [],                     // optional preconditions, human-readable strings
  "branchOf": null,                 // optional: nodeId this edge is a branch variant of (see §5)
  "data": { }                       // optional project blob
}
```

| Field | Req | Meaning |
|---|---|---|
| `id` | ✅ | Stable unique edge id. Convention: `e_<slug>`. |
| `from` | ✅ | Source node id. |
| `to` | ✅ | Destination node id. |
| `action` | ✅ | What is done (see below). |
| `label` | ➖ | Human label. |
| `guards` | ➖ | Preconditions/rules that must hold (e.g. `"title is not empty"`). Each is a candidate negative case. |
| `branchOf` | ➖ | If set, names the node at which this edge is one of several variants — see §5. |
| `data` | ➖ | Project-specific blob. |

### `action`

| Field | Req | Meaning |
|---|---|---|
| `verb` | ✅ | The kind of action. Generic set: `click`, `type`, `select`, `check`, `submit`, `navigate`, `call`, `run`, `wait`. Free string — add your own. |
| `target` | ➖ | The element `ref` (in the `from` node) acted upon. Optional for verbs that need none (`navigate`, `wait`). |
| `input` | ➖ | The value supplied: typed text, chosen option, request payload, command args. |

---

## 5. `branches` — divergence points

A branch records a node where the journey can go more than one way, and **which ways
are already covered**. This is how a graph captures both what is tested and what is *not yet*.

```jsonc
{
  "at": "n_visibility",             // the node where divergence happens
  "question": "What visibility?",
  "variants": [
    { "key": "public",   "edge": "e_set_public",   "covered": true,  "ref": "p_public" },
    { "key": "unlisted", "edge": "e_set_unlisted", "covered": false, "ref": null },
    { "key": "private",  "edge": null,             "covered": false, "ref": "known from docs/posts.md, not yet modelled" }
  ]
}
```

| Field | Req | Meaning |
|---|---|---|
| `at` | ✅ | Node id where the journey diverges. |
| `question` | ➖ | The decision being made. |
| `variants` | ✅ | All known ways forward — including ones not yet modelled or covered. |

### `variants[]`

| Field | Req | Meaning |
|---|---|---|
| `key` | ✅ | Short identifier for the variant. |
| `edge` | ✅ | The edge id taking this variant, or `null` if not modelled yet. |
| `covered` | ✅ | `true` if a `path` exercises this variant; `false` otherwise. |
| `ref` | ➖ | Pointer to the covering path/artifact, or a note about where the variant is known from. |

> An edge that implements a variant should set `branchOf: "<at node id>"`.
> Listing a variant with `edge:null, covered:false` is valuable: it records a **known gap**.

---

## 6. `paths` — named traversals

A path is one end-to-end journey instance: an ordered walk through nodes (the edges
between consecutive nodes are implied; name them explicitly if a node pair has more than one edge).

```jsonc
{
  "id": "p_public",
  "title": "Publish the post publicly",
  "nodes": ["n_editor", "n_review", "n_visibility", "n_published"],
  "edges": ["e_to_review", "e_to_visibility", "e_set_public"],  // optional; required only to disambiguate
  "outcome": "Post is live and publicly visible",  // optional: the asserted end state
  "ref": null                       // optional: link to an external artifact (a test file, a runbook)
}
```

| Field | Req | Meaning |
|---|---|---|
| `id` | ✅ | Stable unique path id. Convention: `p_<slug>`. |
| `title` | ✅ | Human title. |
| `nodes` | ✅ | Ordered node ids from a `start` to (usually) a `terminal`. |
| `edges` | ➖ | Ordered edge ids — required only when a node pair has multiple edges. |
| `outcome` | ➖ | The expected end state / assertion. |
| `ref` | ➖ | Link to whatever this path maps to externally. |

---

## 7. Rules for any LLM reading or writing a graph

These rules keep graphs mergeable and trustworthy across many editing sessions and tools:

1. **IDs are immutable.** Never renumber or reuse `node`/`edge`/`path` ids. To remove something, you may delete it, but never repurpose its id.
2. **Append, don't rewrite.** Adding a branch = add new nodes/edges/paths. Do **not** modify or delete existing `nodes`/`edges`/`paths`. This is what makes branching cheap. *The one allowed in-place edit:* updating a `branches[].variants` entry to record newly-added coverage — flipping `covered:false`→`true` and setting its `edge`/`ref` (or adding a new variant). Updating provenance in `graph.context.sources` is likewise expected. Nothing else is edited in place.
3. **Reference, don't duplicate.** Edges reference element `ref`s; paths reference node/edge ids; variants reference paths. Don't inline copies.
4. **Record provenance.** When you build or extend from a source, add it to `graph.context.sources` with `readAt`. The next reader relies on this to avoid re-reading.
5. **Mark gaps honestly.** A known-but-unmodelled variant goes in `branches` with `edge:null, covered:false`. Silent omission loses knowledge.
6. **Stay generic.** Domain specifics (selectors, endpoints, secrets, framework details) live in `data`/`extensions`, never as new top-level/core fields.
7. **Validate.** A graph should validate against `spec/json-schema.json`.

---

## 8. Minimal valid graph

```json
{
  "schemaVersion": "1.0",
  "kind": "journey-graph",
  "legend": "Nodes are states; edges are actions on elements; a path is one journey.",
  "graph": { "id": "demo/hello", "title": "Hello", "domain": "ui" },
  "nodes": [
    { "id": "n_home", "type": "start", "name": "Home" },
    { "id": "n_done", "type": "terminal", "name": "Done" }
  ],
  "edges": [
    { "id": "e_go", "from": "n_home", "to": "n_done", "action": { "verb": "click", "target": "go-button" } }
  ],
  "branches": [],
  "paths": [
    { "id": "p_main", "title": "Home to Done", "nodes": ["n_home", "n_done"] }
  ]
}
```
