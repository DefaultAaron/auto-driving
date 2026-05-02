#!/usr/bin/env bash
# UserPromptSubmit hook — reminds the model of the codex CONFLICT discipline.
# Output is added to the model's prompt context. Stays terse.

cat <<'EOF'
[discipline reminder] For any non-trivial design / plan / draft change in this vault, the FIRST action is to dispatch codex-collaborator (MODE: CONFLICT) and reach AGREED before applying changes. See `feedback_workflow_discipline.md` and CLAUDE.md "Subagents and the per-chapter pipeline" section. Trivial / docs-only / single-sentence edits skip the deal-loop.
EOF
