# Retirement and Handoff

Use this reference when context is long, assumptions are becoming stale, or a new supervisor would be safer.

## Retirement Triggers

Announce supervisor retirement when one or more conditions apply:

- A clean phase boundary has been reached and the next phase is substantial.
- The thread has accumulated enough history that stale assumptions are likely.
- The supervisor has managed several small phases or one to two substantial phases.
- Repo layout, documentation organisation, tool permissions, or worker systems have changed during the thread.
- The work now spans multiple active conceptual stacks: product design, implementation, live service state, docs, worker orchestration, and process redesign.
- Worker capacity or subagent lifecycle problems have made supervision state unreliable.
- The user asks for reflection on the supervisor process.

For very long efforts, expect many supervisors. A fourteen-phase project should normally be handed off repeatedly rather than carried by one continuing supervisor.

## Retirement Protocol

Before retiring:

1. Stabilise repositories if appropriate: commit, push, or clearly document dirty state.
2. Verify current state or state why verification was not run.
3. Write a compact handoff that distinguishes facts from recommendations.
4. Announce that the next supervisor should take over and provide the handoff prompt.
5. Avoid starting a new feature slice unless the user explicitly asks the same supervisor to continue.

The retiring supervisor owns the handoff prompt itself. Do not delegate the
handoff prompt to a worker. If supporting recon or report extraction was
delegated earlier, integrate that output first and then write the handoff
prompt locally so the execution boundary and next-step mode are stated
explicitly.

If repository stabilisation is blocked by permissions, auth, or Touch ID, state the blocker and give the exact command or action needed.

## Handoff Prompt Template

Use this structure for a handoff prompt:

```text
You are taking over supervision of <project>.

User intent:
- <what the user ultimately wants>
- <current phase or next requested phase>

Expected next-step mode:
- <planning-only | planning-then-execution | execution-only | handoff-only>
- Required deliverable this turn: <plan | implementation | report | handoff>

Current state:
- Workspace: <path, branch, latest commit, dirty state>
- Code repo: <path, branch, latest commit, dirty state>
- Live services/data: <ports, databases, branches, records, cleanup needs>
- Active or recent workers: <ids/status if known>

Completed work:
- <phase summaries with commits/reports>
- <verification run and results>

Important decisions:
- <design/product/process decisions>
- <known terminology and rules>

Risks and open questions:
- <unresolved issues>
- <deferred checks>

Next recommended action:
- <specific next slice>
- <commands or files to inspect first>

Do not:
- <known traps, abandoned tools, stale assumptions>
```

Keep the handoff short enough to be used as a new prompt. Put detailed history in reports and link to those files instead of copying it all.

If a plan file already exists, say whether the next supervisor should refine
that plan only, execute it, or both. Do not assume the next supervisor will
infer that from filenames alone.
