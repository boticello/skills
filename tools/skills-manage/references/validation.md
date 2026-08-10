# Skill validation

Use `./deploy/skills-deploy lint` from the canonical repository for the
repository-wide check. It validates the manifest, canonical frontmatter,
explicit triggers, selected-skill dependencies, length and local references.
It is advisory by default and becomes a release gate with `--strict` after
the warnings have been reviewed.

The bundled `skill-creator` `quick_validate.py` is a generic scaffold check,
not the canonical repository validator. Its installed schema may reject
repository-approved optional metadata such as `triggers` and the operational
fields used by `br`. Treat that rejection as a validator-compatibility issue;
do not remove valid repository metadata merely to satisfy the generic check.
