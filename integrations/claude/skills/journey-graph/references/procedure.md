# Journey Graph — Procedures (tool-neutral)

How to build, read, extend, query, and validate a journey graph. Written so **any LLM**
can follow it with only file read/write. The format is defined in `SPEC.md`; this file is
the *how*. Always keep the rules in `SPEC.md §7` in force.

Conventions used below:
- A graph file lives at `journey-graphs/<namespace>/<slug>.json` (or wherever the user says).
- Node ids: `n_<slug>` · edge ids: `e_<slug>` · path ids: `p_<slug>`. Slugs are short and stable.
- "Source" = whatever you derived knowledge from (a doc, a live observation, a recording, the user's description).

---

## Mode: init

Make a project able to use journey graphs even without an installed adapter.

1. Determine the host-project root (ask if ambiguous).
2. Create `journey-graphs/` there if absent.
3. Copy `SPEC.md` and `json-schema.json` into `journey-graphs/` (so a cold LLM in this project can read graphs, and so graphs can be validated locally).
4. Optionally drop a one-line `journey-graphs/README.md`: "Journey graphs (see SPEC.md). Each `*.json` maps a workflow as states+actions+branches+paths."

Report the paths created.

---

## Mode: build

Create a new journey graph from a flow you can observe or that the user describes.

1. **Gather the flow.** From the source(s): list the ordered states the journey passes through and the action that moves between each. For each state, note the interactive elements that matter. Record every source you used.
2. **Choose `graph.id`** = `<namespace>/<slug>` (e.g. `blog/publish-post`). Confirm it doesn't collide with an existing file.
3. **Write nodes.** One per state. First state `type:"start"`; end state(s) `type:"terminal"`; rest `type:"state"`. Give each a `name`, a `locator` if known, and an `elements[]` list (each `{ ref, kind?, note? }`). `ref` is a stable generic handle (see SPEC §3).
4. **Write edges.** One per action, `from`→`to`, with `action:{ verb, target?, input? }`. `target` is an element `ref` in the `from` node. Add `guards[]` for preconditions/rules (each is a future negative case). Add a human `label`.
5. **Write branches.** Wherever the journey could go more than one way, add a `branches[]` entry at that node listing **all** known variants — set `covered`/`edge` per variant; include known-but-unmodelled ones with `edge:null, covered:false`.
6. **Write paths.** At least the primary traversal: `{ id, title, nodes:[...], outcome? }`. Add `edges[]` only if a node pair has more than one edge.
7. **Fill `graph.context.sources`** with each source + `readAt` date. This is the anti-re-reading payoff.
8. **Set** `schemaVersion`, `kind`, `legend`, `specRef`.
9. **Validate** (see Mode: validate). Fix until clean. Write the file. Report id, counts (nodes/edges/paths), and any gaps recorded.

Keep it readable: do not paste large HTML/payloads into the graph — reference them from `data`/`extensions` instead.

---

## Mode: show

Summarise an existing graph for a human.

1. Read the graph file.
2. Report:
   - **Journey**: `title`, `domain`, `roles`, one-line description.
   - **Paths**: each `id` — `title` — `outcome`, with node count.
   - **Branch points**: for each `branches[]` entry, the node + question + variants, clearly flagging which are **covered** vs **uncovered** (`covered:false`).
   - **Gaps**: a short list of every uncovered variant and every `guard` not yet exercised by a path — these are the obvious next things to model/test.
   - **Provenance**: what sources the graph was built from and when (so the reader knows its freshness).
3. Do NOT re-read the original sources unless the user asks or the graph's provenance is stale/empty.

---

## Mode: branch

Add a new way through an existing journey **cheaply** — reuse the shared prefix, only add the divergence. This is the core value: no re-walking the whole flow.

1. Read the graph. Identify the **branch node** (the `at` state where the new variant diverges) and the shared prefix of nodes leading to it.
2. **Append only** (never edit existing nodes/edges):
   - Add the new node(s) reached by the branch (`type:"state"`/`"terminal"`).
   - Add the new edge(s); set `branchOf:"<branch node id>"` on the first divergent edge.
   - Capture elements for the new node(s).
3. **Update the branch index**: in the `branches[]` entry for that node, either flip an existing variant's `covered`→`true` and set its `edge`, or add a new variant `{ key, edge, covered:true|false, ref }`. If no `branches[]` entry exists for that node yet, create one and include the pre-existing variant(s) too.
4. **Add a path** for the new end-to-end traversal: `nodes` = shared prefix + new branch nodes. Reference it from the variant's `ref`.
5. **Append to `graph.context.sources`** the source for the new branch + `readAt`.
6. **Validate** and write. Report: which ids were ADDED (nothing should be modified), the new path, and the branch variant now covered.

Verify immutability: diff against the prior file — only additions to `nodes`/`edges`/`paths` and the targeted `branches`/`context` updates should appear.

---

## Mode: query / impact

Answer structural questions purely by reading the graph (cheap, no source re-reading):

- **"Which paths use element X / node N / edge E?"** → scan `paths[].nodes`/`edges` and `edges[].action.target` for `ref == X`; list matching path ids + titles.
- **"Shared prefix of path A and B?"** → compare their `nodes` arrays from the start; report the common leading run and the node where they diverge.
- **"What's not covered?"** → list `branches[].variants` with `covered:false`, plus any `guards` no path exercises.
- **"Impact if element/state X changes?"** → list every edge whose `action.target == X` (or node `X`), then every path that includes those edges/nodes, then each path's `ref` (the external artifact that would need updating).

Always answer with concrete ids/titles from the file.

---

## Mode: validate

1. Locate `json-schema.json` (the repo's `spec/json-schema.json`, the copy dropped into `journey-graphs/` by `init`, or — for the Claude skill — `${CLAUDE_SKILL_DIR}/references/json-schema.json`).
2. Validate the graph JSON against it. If a JSON-Schema validator is available, use it, e.g.:
   ```bash
   npx --yes ajv-cli validate -s <schema> -d <graph.json>
   ```
   If no validator is available, check by hand against `SPEC.md`: required fields present, ids unique, every `edge.from`/`to` and `path.nodes[]` and `branch.at` resolve to a node id, every `variant.edge` (when non-null) and `path.edges[]` resolve to an edge id, exactly the allowed `node.type` values, at least one `start` node.
3. Report PASS, or each violation with the offending id/field.

Referential checks the schema alone can't do (always run these by hand):
- every `from`/`to`/`branch.at`/`path.nodes[]` references an existing node id;
- every non-null `variant.edge` and `path.edges[]` references an existing edge id;
- every `action.target` that is set matches an `element.ref` present in the `from` node (warn, don't fail, if missing — it may be intentional);
- node/edge/path ids are unique.
