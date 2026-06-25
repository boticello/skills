---
name: code-review
description: Review code, a diff, or current changes in a codebase. Use when asked to review code.
---

# Code Review

Review code, a diff, or current changes. The skill has two execution paths — choose based on what the user wants to do with the output.

## The two paths

**Path 1 — `ocr` (OpenCodeReview).** A deterministic-engineering pipeline + LLM agent, optimised for code review. Runs a sub-agent per file bundle with isolated context, applies fine-grained rule matching before the LLM sees the code, and uses external modules for comment positioning. Per OCR's own benchmark on 1,505 ground-truth issues across 200 PRs: significantly higher **Precision** and **F1** than a general-purpose agent, lower **Recall**, ~1/9 of the tokens, faster. Trade-off is deliberate — the system is tuned to suppress noise, not maximise surface area.
**Path 2 — agent reads the code.** The LLM (this agent) reads the diff itself, applies heuristics, and emits findings. The current code you're reading was generated this way. Higher recall on a small changeset, but subject to: incomplete coverage on large diffs, line-reference drift, and prompt-fragility. Best when the user is going to **discuss** the findings rather than act on them.

1. Use Path 1 when **all** of these hold:

- The user wants findings to act on (triaging, gating a PR, capturing for later), not a conversation about them.
- The changeset is bounded — workspace, a branch range, or a single commit. `ocr scan` for whole-file auditing.
- Cost or latency matters.
- The user did not ask a specific question about the code.

2. Use Path 2 when **any** of these hold:

- The user asked a specific question about the code ("is this thread-safe?", "will this break the existing flow?", "does this match what we did in `parser.go`?"). That's dialogue, not review.
- The user wants design-alternative discussion or trade-off analysis. OCR's review surface is findings, not design conversation.
- The changeset is small enough that the agent won't cut corners, and the user wants the agent to **explain** a finding in context, not just list it.
- The user is using the agent as a thinking partner — the conversation is the value.

When in doubt, ask before running. The cost of `ocr` is non-trivial (LLM tokens, latency) and re-running with the other path is the same cost a second time.

## Path 1: `ocr`

**Default**: `ocr review --audience agent` 

Suppresses progress lines and emits a single summary block the agent can read and present. 
After running it surface the structured findings to the user with minimal reframing.

**Full file audits (no diff)**: `ocr scan --path <dir>`.

**Notes**: 
- Smoke-test first: `op-env warm && ocr llm test`. 
- `ocr` is `Dotfiles/bin/ocr`, a 1Password wrapper: failures surface as auth errors. 
- See `cheat ocr` for invocation patterns.

## Output expectations

For both paths:

- Findings ordered by severity, not by file order.
- File and line references where possible.
- Brief summary only after findings.
- Skip low-value stylistic commentary unless it clearly violates local conventions.

For Path 1: trust OCR's positioning on line numbers — it's the deterministic module's job. If the agent then describes a finding, it should not "correct" the position.
For Path 2: be explicit when a finding is a hypothesis, not a confirmed defect. Agent-reads has higher recall and lower precision than `ocr`; the agent should flag its own uncertainty rather than asserting.

## Anti-patterns

- **Don't run `ocr` and then re-derive findings from the same code.** That's two reviews, not one review with corroboration. Either trust `ocr`'s output and present it, or read the code yourself — pick one.
- **Don't switch paths mid-review.** If you started with `ocr review` and the user asks a follow-up question about a finding, answer the question from the `ocr` output; don't re-read the code with fresh eyes and disagree.
- **Don't run `ocr` for design-alternative discussion.** OCR finds defects; it doesn't weigh trade-offs. The user is asking a different question.
- **Don't run agent-reads for a large PR.** You'll cut corners and not know it. If the diff is big enough to feel unwieldy, the answer is `ocr review --from main --to feature-branch`, not the agent reading 50 files.

## Related

- `cheat ocr` — invocation patterns, four review modes, pre-flight.
- `op-env` — the secret-injection wrapper that makes `ocr` work.
- `op-env-wrap-tool` skill — the workflow that produced the `ocr` wrapper.
