---
name: verify
description: Run structured verification on the current state. Use before handoff, review, or deployment.
---
# Verify

Run structured verification on the current state.

Default order:
1. build
2. type checks
3. lint
4. tests
5. targeted audits such as secrets or debug logging

Return a concise report with:
- pass/fail per category
- notable errors
- whether the change is ready for handoff or review
