# Journey Graph

**Map any workflow as a graph an LLM can read, reuse, and extend.**

A *journey graph* is a self-describing JSON document that models a journey — any
goal-directed workflow — as a directed graph:

- **nodes** = states (a screen, a page, an API resource state, a CLI prompt, a process step)
- **edges** = actions that move between states, each naming the **element** acted on and any **input**
- **branches** = the points where a journey diverges, and which divergences are already **covered**
- **paths** = named end-to-end traversals (one path = one concrete journey, e.g. a test case or runbook)

### Why

Two things get expensive when an LLM works with workflows:

1. **Re-reading the source docs** every time you revisit a flow.
2. **Re-deriving the whole flow** just to test or document a *variant*.

A journey graph fixes both. It's a durable, append-only knowledge cache: read the graph
instead of the docs (provenance is recorded inside it), and **add a branch** — reusing the
shared prefix — instead of re-walking the journey.

### Tool-neutral by design

The **format** ([`spec/SPEC.md`](./spec/SPEC.md)) and the **procedures**
([`spec/procedure.md`](./spec/procedure.md)) are plain docs any model can follow — that's
the whole product. Claude Code, Cursor, and OpenAI Codex each get a thin, **equal** adapter
under [`integrations/`](./integrations/) that just points back at the same `spec/`. No tool
is privileged; adding another is one more sibling adapter.

```
            ┌─────────────────────────── spec/ ───────────────────────────┐
            │   SPEC.md   ·   procedure.md   ·   json-schema.json           │
            └───────▲───────────────▲───────────────▲────────────▲─────────┘
                    │               │               │            │
            integrations/    integrations/    integrations/   …any LLM:
              claude/           cursor/          codex/        read the
            (skill+plugin)    (.mdc rule)    (prompt+AGENTS)   two docs
```

---

## Quick look

```jsonc
{
  "schemaVersion": "1.0",
  "kind": "journey-graph",
  "legend": "Nodes are states; edges are actions on elements; a path is one journey.",
  "graph": { "id": "contacts/add-contact", "title": "Add a contact", "domain": "ui" },
  "nodes": [ /* start / state / terminal */ ],
  "edges": [ /* { from, to, action:{ verb, target, input } } */ ],
  "branches": [ /* divergence points; covered + known-but-uncovered variants */ ],
  "paths": [ /* named end-to-end traversals */ ]
}
```

Worked examples (a contact-management UI flow and a contact REST API) are in
[`examples/`](./examples/); the full format is in [`spec/SPEC.md`](./spec/SPEC.md).

---

## Install

One installer covers every tool: `scripts/install.sh <claude|cursor|codex>`. Each target
just drops that tool's adapter (all delegate to the same `spec/`). See
[`integrations/`](./integrations/) for details.

### Claude Code

As a plugin (the repo is its own self-referential marketplace):

```text
/plugin marketplace add devangchhajed/journey-graph
/plugin install journey-graph@journey-graph-marketplace
/reload-plugins
```

Or as a standalone skill via git clone:

```bash
git clone https://github.com/devangchhajed/journey-graph.git ~/journey-graph
~/journey-graph/scripts/install.sh claude   # symlinks the skill into ~/.claude/skills/
# then run /reload-plugins in Claude Code
```

(For local dev without publishing, use `scripts/install.sh claude` above — it symlinks the
whole skill so the shared `spec/` resolves. Avoid `claude --plugin-dir integrations/claude`
for this repo: local `--plugin-dir` installs skip symlinks that point outside the plugin
dir, so the skill wouldn't find `spec/`. A published marketplace install is unaffected —
it dereferences the symlink and copies the spec into the plugin cache.)

### Cursor

Installs an Agent-Requested rule into a project's `.cursor/rules/`:

```bash
scripts/install.sh cursor [PROJECT]   # default PROJECT is the current directory
```

Then ask Cursor, e.g. *"build a journey graph for the add-contact flow."*

### OpenAI Codex CLI

Installs a `/journey-graph` custom prompt into `~/.codex/prompts/`:

```bash
scripts/install.sh codex
```

Then in Codex: `/journey-graph build a graph for the create-contact flow`. For standing
guidance without the slash command, paste
[`integrations/codex/AGENTS.md`](./integrations/codex/AGENTS.md) into your repo's `AGENTS.md`.

### Any other LLM

Just point your model at [`spec/SPEC.md`](./spec/SPEC.md) and
[`spec/procedure.md`](./spec/procedure.md). That's the whole tool — the rest is convenience
packaging.

---

## Using it

After installing — `/journey-graph` in Claude Code or Codex, or just by asking in Cursor:

```text
/journey-graph init                                   # set up journey-graphs/ in this project
/journey-graph build a graph for the add-contact flow # create a new graph
/journey-graph show examples/example-add-contact-ui.journey.json
/journey-graph add a branch: the "duplicate-email" variant at the new-contact form
/journey-graph what's not covered in contacts/add-contact
/journey-graph validate journey-graphs/contacts/add-contact.json
```

Graphs are written to `journey-graphs/<namespace>/<slug>.json` in your project, alongside a
copy of `SPEC.md` (and `json-schema.json`) so any LLM working in that repo can read and
validate them.

---

## Layout

```
spec/                                    # SINGLE SOURCE OF TRUTH (tool-neutral)
  SPEC.md                                #   the format specification
  procedure.md                           #   build/show/branch/query/validate procedures
  json-schema.json                       #   machine-checkable JSON Schema (draft-07)
integrations/                            # one thin adapter per tool — all point back at spec/
  claude/                                #   skill + plugin (references/ -> ../../../../spec)
  cursor/journey-graph.mdc               #   Cursor Agent-Requested rule
  codex/journey-graph.md                 #   Codex CLI /journey-graph custom prompt
  codex/AGENTS.md                        #   Codex AGENTS.md guidance snippet
examples/*.journey.json                  # worked examples (contact management: UI + API)
scripts/install.sh                       # multi-tool installer: install.sh <claude|cursor|codex>
.claude-plugin/marketplace.json          # plugin marketplace manifest (source -> integrations/claude)
```

## Validate a graph

```bash
npx --yes ajv-cli validate -s spec/json-schema.json -d 'examples/*.json'
```

## License

MIT — see [`LICENSE`](./LICENSE).
