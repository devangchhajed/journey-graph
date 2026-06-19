# Integrations — using journey-graph with any LLM tool

The journey-graph **format** ([`spec/SPEC.md`](../spec/SPEC.md)) and **procedures**
([`spec/procedure.md`](../spec/procedure.md)) are tool-neutral plain docs — that's the
actual product. Everything in this directory is just thin packaging that gives a specific
assistant a native entry point (a skill, a rule, a slash command). Every integration is a
**sibling adapter** that delegates to the same shared `spec/` — there is no forked logic and
no preferred tool.

| Tool | Entry point | Lives in this repo at |
|---|---|---|
| **Claude Code** | `/journey-graph` skill + plugin | [`claude/`](./claude/) |
| **Cursor** | `.cursor/rules/journey-graph.mdc` (Agent-Requested rule) | [`cursor/journey-graph.mdc`](./cursor/journey-graph.mdc) |
| **OpenAI Codex CLI** | `/journey-graph` custom prompt + `AGENTS.md` guidance | [`codex/journey-graph.md`](./codex/journey-graph.md), [`codex/AGENTS.md`](./codex/AGENTS.md) |
| **Any other LLM** | point it at `spec/SPEC.md` + `spec/procedure.md` | — |

One installer covers all of them: `scripts/install.sh <claude|cursor|codex>`.

---

## Claude Code

The plugin/skill lives in [`claude/`](./claude/). Its `skills/journey-graph/references/` is a
symlink to the repo's [`spec/`](../spec/), so the skill always sees the same canonical docs
— nothing is duplicated.

```bash
scripts/install.sh claude            # symlink the skill into ~/.claude/skills/
scripts/install.sh claude --copy     # self-contained copy (dereferences the spec symlink)
```

As a plugin: the repo's root `.claude-plugin/marketplace.json` points its plugin `source` at
`./integrations/claude`, so `/plugin marketplace add <owner>/journey-graph` then
`/plugin install journey-graph@journey-graph-marketplace` works. Ad-hoc:
`claude --plugin-dir integrations/claude`.

---

## Cursor

Cursor reads **project rules** from `.cursor/rules/*.mdc`. The adapter is an
*Agent-Requested* rule — it carries a `description` and `alwaysApply: false`, so Cursor's
agent pulls it in automatically when your request matches (build/show/branch/query a flow).

```bash
scripts/install.sh cursor                  # copies into ./.cursor/rules/journey-graph.mdc
scripts/install.sh cursor /path/to/project  # ...into another project
```

Or by hand: copy [`cursor/journey-graph.mdc`](./cursor/journey-graph.mdc) to
`<project>/.cursor/rules/journey-graph.mdc`. Then ask Cursor, e.g. *"build a journey graph
for the add-contact flow"*.

To let any LLM in that project read the graphs you create, also run the **init** mode once
(it drops `SPEC.md` + `json-schema.json` into `journey-graphs/`).

---

## OpenAI Codex CLI

Codex supports two complementary hooks:

1. **Custom prompt → slash command.** Files in `~/.codex/prompts/*.md` become
   `/<name>` commands. Installing [`codex/journey-graph.md`](./codex/journey-graph.md) gives
   you `/journey-graph <intent>` in the Codex CLI.
2. **`AGENTS.md` guidance.** Codex reads `AGENTS.md` (repo-level or `~/.codex/AGENTS.md`)
   as standing instructions. [`codex/AGENTS.md`](./codex/AGENTS.md) is a paste-in snippet so
   Codex understands journey graphs even when you don't use the slash command.

```bash
scripts/install.sh codex                   # copies into ~/.codex/prompts/journey-graph.md
```

Then in Codex: `/journey-graph build a graph for the create-contact flow`. For the
`AGENTS.md` snippet, paste the contents of [`codex/AGENTS.md`](./codex/AGENTS.md) into your
repo's `AGENTS.md` (or `~/.codex/AGENTS.md`).

---

## Keeping adapters honest

All adapters must stay *thin*: they restate the data model, the mode dispatch, and the hard
rules (so they work even with nothing else loaded), then defer to `spec/SPEC.md` and
`spec/procedure.md` for full field semantics and per-mode steps. If you change the format,
change the files under `spec/` — the adapters should not need edits unless the *mode list* or
*hard rules* themselves change.
