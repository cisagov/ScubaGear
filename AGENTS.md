# AGENTS.md

Instructions for AI coding agents working in this repository.

## Attribution requirements

Maintainers need to be able to tell at a glance when a coding agent contributed to a change. If you are a coding agent, you MUST disclose that in every commit you create and in every pull request you open, regardless of how small the change is.

The human developer who directed you remains the author and is responsible for the change. Attribution supplements that; it does not replace it.

### Commits

Add a `Co-authored-by` trailer to every commit message, naming the agent that produced the change. The trailer goes at the end of the message, separated from the body by a blank line.

```
Fix off-by-one error in pagination

Co-authored-by: <Agent Name> <agent-email@example.com>
```

Use the identity that matches the agent you are:

| Agent | Trailer |
| --- | --- |
| Claude / Claude Code | `Co-authored-by: Claude <noreply@anthropic.com>` |
| OpenAI Codex | `Co-authored-by: Codex <noreply@openai.com>` |
| GitHub Copilot | `Co-authored-by: Copilot <noreply@github.com>` |
| Cursor | `Co-authored-by: Cursor Agent <cursoragent@cursor.com>` |
| Gemini CLI | `Co-authored-by: Gemini <noreply@google.com>` |
| Any other agent | `Co-authored-by: <Agent Name> <noreply@<vendor-domain>>` |

Rules:

- Always name the specific agent. Never use a vague label such as "AI" or "bot".
- Keep one trailer per agent. If several agents contributed, add one trailer for each.
- Do not remove or rewrite existing trailers when amending or rebasing.
- Do not add the human developer's name as an agent, and do not impersonate a human.

### Pull request descriptions

Every PR description must include an attribution line stating which agent was used. Put it in its own section at the bottom of the description:

```
---
🤖 This pull request was created with the assistance of <Agent Name> (<model, if known>), directed by @<github-username>.
```

Rules:

- Name the agent and, when you know it, the model or version used.
- If the agent wrote or substantially edited the PR description itself, say so.
- Keep the attribution when the description is edited later. Do not delete it.
- If a PR contains a mix of human-written and agent-written commits, still include the attribution line.

### Checklist before committing or opening a PR

1. Does every commit you contributed to include the correct `Co-authored-by` trailer?
2. Does the PR description include the attribution section naming your agent?
3. Is the attribution accurate, with no overstating or understating of what the agent did?
