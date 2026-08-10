---
name: database-migration
description: >
  Use when changing the SurrealDB schema or migrating data as part of a feature,
  refactor, or bugfix. Triggers on "migration", "schema change", "ALTER TABLE",
  "DEFINE FIELD", "update all records", "change field values", "backfill data".
  Also use when the user mentions needing to update the live database to match
  schema changes.
---

# Database Migration

Schema changes and data migrations for me-cli's SurrealDB backend. Without this
skill, agents guess at migration syntax, forget to update both schema file and
live DB, or fail to handle constraints during value changes.

## When to Migrate

| Trigger | Example |
|---------|---------|
| New field/table | Adding `slug` field to ticket |
| Changing field type | `string` → `option<record<...>>` |
| Changing allowed values | `annual` → `yearly` in enum |
| Adding index | New FULLTEXT or unique index |
| Backfilling data | Setting defaults on existing records |

## The Three-File Rule

**All three must stay in sync:**

1. `schema/setup.surql` — the cumulative current schema (source of truth)
2. `schema/migrations/YYYYMMDD-<slug>.surql` — the incremental migration file
3. Live database — applied by running the migration

Update `setup.surql` and write the migration file together. Then run the migration against live.
Never change one without the others. See `schema/README.md` for the full convention.

## Preflight Drift Check

When work touches SurrealDB schema or live invariants, the first risk is usually not the Ruby patch but the live data shape.

Before deciding the migration shape:

1. Check the live table definition with `INFO FOR TABLE <table>;`
2. Sample live rows for the fields involved
3. Look for drift such as:
   - legacy fields still present on records
   - `NONE` values that will violate a new required field
   - old enum values still in live data
   - type mismatches between live rows and `setup.surql`
4. Record what you found in the plan or ticket note

This matters because many migrations that look like a simple `DEFINE FIELD` actually require:
- a staged migration
- a backfill
- a temporary relaxed field type
- or a cleanup of legacy fields before the main update can succeed

## Migration File Convention

Each migration is a standalone `.surql` file in `schema/migrations/`:

- **Named**: `YYYYMMDD-<slug>.surql` (e.g. `20260405-filing-audit-trail.surql`)
- **Idempotent**: Use `DEFINE ... OVERWRITE` throughout
- **Header**: First line is a comment with ticket number and description
- **Seed data**: Separate file with `-seed-<table>` suffix
- **Append-only**: Never edit a migration after it has been run
- **One per ticket**: Each schema-changing ticket produces one migration file

See `schema/README.md` for the full convention including file layout and workflow.

## Local SurrealDB Docs

When SurrealQL syntax or behaviour is uncertain, check the local SurrealDB docs before guessing or working around the issue in Ruby.

Local docs path:

```text
~/Me/80-tech/80-reference/docs.surrealdb.com/src/content
```

Useful patterns:

```bash
rg -n "UPDATE .*UNSET|UPDATE .*CONTENT" ~/Me/80-tech/80-reference/docs.surrealdb.com/src/content
rg -n "DEFINE FIELD OVERWRITE|REMOVE FIELD|INFO FOR TABLE" ~/Me/80-tech/80-reference/docs.surrealdb.com/src/content
rg -n "SCHEMAFULL|NONE" ~/Me/80-tech/80-reference/docs.surrealdb.com/src/content/doc-surrealql
```

Use the docs especially when:
- `UPDATE`, `UNSET`, `CONTENT`, `REMOVE`, or `DEFINE` syntax is unclear
- `SCHEMAFULL` behaviour affects migration safety
- `INFO FOR TABLE` output needs to be interpreted
- a query failure tempts you to move business logic into Ruby

## Migration Script Pattern

```ruby
ruby -Ilib -e '
require "me"
config = Me::Config.new
client = Me::Client.new(config.surreal)

# Use OVERWRITE to make migrations re-runnable
client.query("DEFINE FIELD OVERWRITE my_field ON my_table TYPE string;")
client.query("DEFINE INDEX OVERWRITE idx_my ON my_table FIELDS my_field UNIQUE;")

# Backfill if needed
items = client.query_one("SELECT id, field1 FROM my_table WHERE field2 = NONE;")
items.each do |item|
  client.query("UPDATE #{item["id"]} SET field2 = \"default\";")
end
'
```

## OVERWRITE Syntax

**Correct:**
```sql
DEFINE TABLE OVERWRITE my_table SCHEMAFULL;
DEFINE FIELD OVERWRITE my_field ON my_table TYPE string;
DEFINE INDEX OVERWRITE idx_my ON my_table FIELDS my_field UNIQUE;
```

**Wrong:**
```sql
DEFINE FIELD my_field ON my_table OVERWRITE TYPE string;  -- syntax error
```

`OVERWRITE` comes immediately after the definition type (`TABLE`, `FIELD`, `INDEX`), not after the table name.

## Value Change Pattern (Enum/Allowed Values)

When changing allowed values (e.g., `annual` → `yearly`):

**Three-step migration:**

```ruby
ruby -Ilib -e '
require "me"
config = Me::Config.new
client = Me::Client.new(config.surreal)

# Step 1: Schema accepts both old and new
client.query("DEFINE FIELD OVERWRITE frequency ON subscription TYPE string " \
  "ASSERT $value IN [\"weekly\", \"monthly\", \"quarterly\", \"annual\", \"yearly\"];")

# Step 2: Migrate data
client.query("UPDATE subscription SET frequency = \"yearly\" WHERE frequency = \"annual\";")

# Step 3: Schema accepts only new
client.query("DEFINE FIELD OVERWRITE frequency ON subscription TYPE string " \
  "ASSERT $value IN [\"weekly\", \"monthly\", \"quarterly\", \"yearly\"];")
'
```

**Why three steps?** The ASSERT constraint is checked on every UPDATE. If you try to
set `frequency = "yearly"` while the schema only allows `"annual"`, the update fails.

## Type Change Pattern

When changing a field's type (e.g., `string` → `option<record<...>>`):

```ruby
ruby -Ilib -e '
require "me"
config = Me::Config.new
client = Me::Client.new(config.surreal)

# Step 1: Relax constraint (optional or remove type)
client.query("DEFINE FIELD OVERWRITE my_field ON my_table;")

# Step 2: Transform data if needed
items = client.query_one("SELECT id, my_field FROM my_table;")
items.each do |item|
  # Transform logic here
end

# Step 3: Apply new type
client.query("DEFINE FIELD OVERWRITE my_field ON my_table TYPE option<record<other>>;")
'
```

## Adding a Computed Field

Computed fields don't need migration — they're evaluated on read. Just add to schema:

```sql
DEFINE FIELD children ON ticket COMPUTED <~(ticket FIELD parent);
```

**Gotcha:** Computed reverse fields (`<~`) are unreliable on self-referential tables.
See ARCHITECTURE.md "SurrealDB gotchas" for details.

## Adding an Index

```ruby
ruby -Ilib -e '
require "me"
config = Me::Config.new
client = Me::Client.new(config.surreal)

# Create index
client.query("DEFINE INDEX OVERWRITE idx_ticket_status ON ticket FIELDS status;")

# For FULLTEXT, rebuild to index existing data
client.query("DEFINE INDEX OVERWRITE idx_ticket_title ON ticket FIELDS title FULLTEXT;")
client.query("REBUILD INDEX idx_ticket_title ON ticket;")
'
```

## Verification

After migration, verify:

```ruby
# Check schema applied
ruby -Ilib -e '
require "me"
c = Me::Client.new(Me::Config.new.surreal)
require "json"
puts JSON.pretty_generate(c.query_one("INFO FOR TABLE subscription;"))
'

# Check data migrated
ruby -Ilib -e '
require "me"
c = Me::Client.new(Me::Config.new.surreal)
puts c.query_one("SELECT count() FROM subscription WHERE frequency = \"yearly\" GROUP ALL;").inspect
'
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Found 'X' for field ... but field must conform to: $value IN [...]` | Updating to value not in ASSERT | Use three-step pattern |
| `Unexpected token 'OVERWRITE'` | OVERWRITE in wrong position | Move after definition type |
| `Parse error: Unexpected token` | String escaping in Ruby | Use escaped quotes or heredoc |
| Index not finding data | FULLTEXT index not rebuilt | Run `REBUILD INDEX` |

## Workflow Checklist

1. [ ] Identify what's changing (field, type, values, index)
2. [ ] Check live schema and sample live rows for drift
3. [ ] Check local SurrealDB docs when syntax or behaviour is uncertain
4. [ ] Update `schema/setup.surql`
5. [ ] Write migration script with OVERWRITE
6. [ ] For value changes: use three-step pattern
7. [ ] For required new fields on existing data: decide whether you need relax → backfill → tighten
8. [ ] Run `me db backup` before applying changes to the live database
9. [ ] Run migration
10. [ ] Verify schema applied (`INFO FOR TABLE`)
11. [ ] Verify data migrated (spot-check query)
12. [ ] Update tests if needed
13. [ ] Run full test suite

## Related

- `schema/README.md` — Migration file convention and file layout
- `ARCHITECTURE.md` — Schema Migrations section, SurrealDB gotchas
- `AGENTS.md` — SurrealDB Schema Changes section
- The consuming project's database-ticket-shaping guidance —
  pre-implementation drift checks and migration shapes
- The consuming project's ticket-commit guidance — Git commit format for
  ticket-tracked work
