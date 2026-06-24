# Phase Lifecycle

Use this reference when shaping, executing, or closing a supervised phase.

## Phase Shape

A useful phase has:

- Objective: the user-visible or system-visible outcome.
- Scope: what will change, what will be explored, and what is explicitly out of scope.
- Acceptance criteria: concrete checks that determine whether the phase is done.
- Risks and open questions: uncertainties that could change the plan.
- Execution mode: direct work, delegated work, recon-first, or mixed.
- Verification plan: tests, smoke checks, reviews, documentation checks, or live trials.
- Reporting target: where the phase report, plan, or handoff should be written.

If these are not clear, define them before spawning workers or editing code. Make reasonable decisions when the user has delegated judgement to the supervisor, and record those decisions.

## Phase Execution

Run phases as evidence-producing slices:

1. Reconfirm repo/workspace state and active branch.
2. Read the smallest set of source documents needed to avoid stale assumptions.
3. Write the plan if the phase is non-trivial or will be delegated.
4. Execute or delegate bounded tasks.
5. Integrate work by inspecting artefacts and diffs, not summaries alone.
6. Verify against acceptance criteria.
7. Record the outcome, residual risks, and next recommended slice.

## Trial Finding Classifier

When agent trials or live smoke checks reveal issues, classify them before acting:

- Product rule gap: the system lacks deterministic behaviour or validation. Fix code and tests.
- Documentation/help gap: the behaviour exists but is hard to discover. Fix docs, examples, `--help`, or error guidance.
- Environment/tooling gap: the trial failed because of local service state, permissions, auth, sandboxing, Python version, or path setup. Fix tooling or runbook guidance without distorting the product.
- API uncertainty: upstream behaviour is unclear or unstable. Document the constraint, isolate it behind an interface, and add tests around known behaviour.
- Process/delegation issue: the worker prompt, model choice, or supervision pattern caused avoidable confusion. Update the plan, prompt template, or skill guidance.

Do not treat all trial friction as a CLI defect. Do not treat all worker confusion as user error.

## Phase Boundary Checklist

Before declaring a phase complete, capture:

- Code repo branch, latest commit, push status, and dirty files.
- Workspace repo branch, latest commit, push status, and dirty files.
- Tests run and exact skipped/deferred checks.
- Live services or databases created, modified, or left behind.
- Documentation or plans updated.
- Worker outputs integrated, rejected, or deferred.
- Open questions and the next recommended phase.

If any of these are unknown, say so explicitly.
