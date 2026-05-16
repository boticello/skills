# skills

Portable AI agent skills — install once, deploy everywhere.

## Install

```bash
# Add all skills via SkillKit
skillkit add bear/skills

# Or add as a tapped source for ongoing updates
skillkit tap add bear/skills
```

## What's here

| Category | Skills |
|----------|--------|
| **analysis** | file-introspection, csv-data-summarizer, ship-learn-next |
| **debug** | code-debug, root-cause-debugger |
| **domain** | pharmaceutical-definition-creator, ruby-code-analysis |
| **knowledge-management** | documentation-writing, logseq-markdown |
| **planning** | feature-handoff, orchestration, plan, ticket-closedown, update-docs, wrap |
| **review** | code-review, remind-management, retro, verify |
| **tools** | context7-mcp, database-migration |
| **vcs** | git-change-manage, git-vcs, jj-change-manage, jj-vcs, work-unit-manage |
| **web** | article-extractor, tapestry, youtube-transcript |

## Skill format

Every skill is a directory containing a `SKILL.md` with standardised frontmatter:

```yaml
---
name: skill-name
description: What this skill does
---

# Skill Name

Instructions for the agent...
```

SkillKit translates this to the native format for 46+ agent harnesses (Claude Code, Codex, Cursor, Copilot, Windsurf, Craft Agents, etc.).

## Deploy to a specific agent

```bash
skillkit sync --agent codex
skillkit translate --all --to cursor
skillkit translate --all --to craft-agents
```

## License

Apache 2.0
