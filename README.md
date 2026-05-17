# skills

Portable AI agent skills — install once, deploy everywhere.

## Install

```bash
# Add all skills via SkillKit
skillkit add boticello/skills

# Or add as a tapped source for ongoing updates
skillkit tap add boticello/skills
```

## What's here

29 original skills across 10 categories:

| Category | Skills |
|----------|--------|
| **analysis** | file-introspection |
| **debug** | code-debug, root-cause-debugger |
| **domain** | pharmaceutical-definition-creator, ruby-code-analysis |
| **go-slice** | go-slice-implementer, go-slice-planner, go-slice-reviewer, slice-retro |
| **knowledge-management** | documentation-writing, documentation-writer |
| **planning** | discovery-architect, feature-handoff, orchestration, plan, spike-planning, ticket-closedown, update-docs, wrap |
| **review** | code-review, remind-management, retro, verify |
| **tools** | database-migration |
| **vcs** | git-change-manage, git-vcs, jj-change-manage, jj-vcs, work-unit-manage |

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
