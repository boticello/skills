# Third-Party Skills

Skills I use that are authored by others. Not in the public repo — installed from source.

## Installable via SkillKit

| Skill | Source | Install |
|-------|--------|---------|
| csv-data-summarizer | `coffeefuelbump/csv-data-summarizer-claude-skill` | `skillkit install coffeefuelbump/csv-data-summarizer-claude-skill` |
| find-skills | `vercel-labs/skills` | `skillkit install vercel-labs/skills --skill find-skills` |
| ship-learn-next | `softaworks/agent-toolkit` | `skillkit install softaworks/agent-toolkit --skill ship-learn-next` |
| youtube-transcript | `intellectronica/agent-skills` | `skillkit install intellectronica/agent-skills --skill youtube-transcript` |

## Installable via other methods

| Skill | Source | Install |
|-------|--------|---------|
| logseq-markdown | `jluo41/tools` (skillfish) | `npx skills add jluo41/tools` or manual clone |
| context7-mcp | Context7 MCP server | Configure as MCP server, not a skill — see context7 docs |
| article-extractor | PAI/skillfish community | `npx skills add` or manual — generic Readability wrapper |
| tapestry | PAI community (possibly) | Manual — orchestrates youtube-transcript + article-extractor + ship-learn-next |

## Notes

- These are installed directly into harness skill directories (`~/.codex/skills/`, etc.)
- Not version-controlled — reinstall from source on fresh machines
- Check original licenses before redistributing
