# Delegation and Workers

Use this reference when deciding whether to delegate and how to manage workers
at the phase-supervision level. The supervisor assigns every worker directly;
workers do not dispatch one another. For implementation or documentation work,
make the ownership, access mode, paths, handoff evidence and integration point
explicit in the supervisor's prompt.

## When to Delegate

Delegate when a task is:

- Bounded enough to prompt clearly.
- Parallelisable without shared-file collisions.
- Independently reviewable through a diff, report, test, or transcript.
- Useful as recon, black-box trial, implementation, review, or documentation pass.
- Valuable enough to justify the model cost and integration overhead.

Do the work directly when the task is small, tightly coupled, urgent, blocked by unavailable worker capacity, or too ambiguous to delegate safely.

## Model Selection

Choose the cheapest model that can reliably perform the task. Default policy for this project:

- gpt-5.4-mini at medium reasoning: mechanical edits, docs checks, simple black-box CLI trials, small verification tasks, report extraction, and other low-ambiguity work.
- gpt-5.3-codex at medium reasoning: ordinary implementation, tests, focused bug fixes, routine integration support, and standard coding work.
- gpt-5.4 at medium reasoning: ambiguous recon, architecture/design trade-offs, difficult implementation, root-cause debugging, high-value review, or high-intelligence supervision support.
- Do not delegate to gpt-5.5 unless a future user explicitly changes this policy.

At the end of each phase report, record whether the delegated models were insufficient, appropriate, or overkill. Use that evidence to adjust the next phase delegation plan rather than changing model policy by habit.

Avoid large worker pools by default. Prefer one recon worker plus one implementation worker, or two parallel workers with non-overlapping ownership. Increase concurrency only when tasks are independent and the integration cost is lower than the elapsed-time saving.

## Worker Prompt Checklist

This checklist is the minimum prompt contract for workers that may edit files.

Each worker prompt should state:

- Role and model expectation, if the tooling supports model choice.
- Objective and acceptance criteria.
- Files, directories, branches, or live services they may use.
- Files or areas they must not touch.
- Whether the task is black-box; if so, forbid source-code reading unless the task explicitly requires it.
- Required output: patch, report, commands run, tests, live-state changes, and unresolved questions.
- Handoff format and where to place artefacts.

For implementation workers, require a small diff and tests. For recon workers, require conclusions with evidence and no code changes unless authorised.

## Integration Discipline

After delegating a coding or documentation slice, the supervisor must treat the delegated write set as locked. Before any local file edit while workers are active, compare the target path with active worker ownership. Do not edit overlapping files or reimplement the delegated responsibility locally until the worker is complete, cancelled, or explicitly reassigned. If the supervisor decides to take the work back, close or interrupt the worker first and record why.

The supervisor must:

- Wait for workers when their outputs are needed for the phase decision.
- Inspect worker artefacts directly.
- Compare overlapping recommendations and resolve conflicts explicitly.
- Run verification after integrating, even when workers claim tests passed.
- Keep staged patches, branches, worktrees, or sandboxes separated by ownership.
- Close worker threads with the available Codex subagent lifecycle tool when possible.

If a worker cannot be spawned because of capacity or tool failure, continue directly or reduce the phase. Report the exact failure rather than consulting unrelated systems.

## Worker Lifecycle Hygiene

Do not let worker count grow without need:

- Spawn only workers with a defined output and phase relevance.
- Prefer sequential probes when one result should shape the next task.
- Close or mark workers complete once outputs are integrated.
- At phase boundaries, record which workers mattered and which were abandoned or unavailable.

Do not use unrelated tools such as abandoned local worker managers to infer Codex subagent state.
