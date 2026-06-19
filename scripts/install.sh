#!/usr/bin/env bash
# Install a journey-graph entry point for the LLM tool of your choice.
# The format itself (SPEC.md, procedure.md, json-schema.json) is tool-neutral; this just
# drops the thin per-tool adapter into the right place.
#
#   ./scripts/install.sh [claude]            # symlink the skill into ~/.claude/skills/ (default)
#   ./scripts/install.sh claude --copy       # copy instead of symlink
#   ./scripts/install.sh cursor [PROJECT]    # copy the rule into <PROJECT>/.cursor/rules/ (default: cwd)
#   ./scripts/install.sh codex               # copy the prompt into ~/.codex/prompts/
#
# After a Claude install, run /reload-plugins in Claude Code (or start a new session).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="${1:-claude}"

install_claude() {
  local src="$REPO_ROOT/integrations/claude/skills/journey-graph"
  local dest_dir="${CLAUDE_HOME:-$HOME/.claude}/skills"
  local dest="$dest_dir/journey-graph"

  if [ ! -f "$src/SKILL.md" ]; then
    echo "error: $src/SKILL.md not found — run this from inside the cloned repo." >&2
    exit 1
  fi

  mkdir -p "$dest_dir"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Removing existing $dest"
    rm -rf "$dest"
  fi

  if [ "${2:-}" = "--copy" ]; then
    # -L dereferences the references/ symlink so the copy is self-contained.
    cp -RL "$src" "$dest"
    echo "Copied skill -> $dest"
  else
    ln -s "$src" "$dest"
    echo "Symlinked skill -> $dest  (-> $src)"
  fi
  echo "Done. Run /reload-plugins in Claude Code, then try: /journey-graph show examples/example-add-contact-ui.journey.json"
}

install_cursor() {
  local src="$REPO_ROOT/integrations/cursor/journey-graph.mdc"
  local project="${2:-$PWD}"
  local dest_dir="$project/.cursor/rules"
  local dest="$dest_dir/journey-graph.mdc"

  if [ ! -f "$src" ]; then
    echo "error: $src not found." >&2
    exit 1
  fi

  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  echo "Installed Cursor rule -> $dest"
  echo "Done. Ask Cursor, e.g.: \"build a journey graph for the add-contact flow\""
}

install_codex() {
  local src="$REPO_ROOT/integrations/codex/journey-graph.md"
  local dest_dir="${CODEX_HOME:-$HOME/.codex}/prompts"
  local dest="$dest_dir/journey-graph.md"

  if [ ! -f "$src" ]; then
    echo "error: $src not found." >&2
    exit 1
  fi

  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  echo "Installed Codex prompt -> $dest"
  echo "Done. In the Codex CLI: /journey-graph build a graph for the create-contact flow"
  echo "Tip: also paste integrations/codex/AGENTS.md into your repo's AGENTS.md."
}

case "$TOOL" in
  claude) install_claude "$@" ;;
  cursor) install_cursor "$@" ;;
  codex)  install_codex  "$@" ;;
  -h|--help|help)
    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "error: unknown tool '$TOOL'. Use one of: claude, cursor, codex." >&2
    exit 1
    ;;
esac
