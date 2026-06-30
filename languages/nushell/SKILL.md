---
name: nushell
description: (no description)
disable-model-invocation: true
---

# Nushell Agents: Conventions, Guardrails, and Testing

This document defines how we build and operate Nushell-based agents for:

- Text conversion pipelines
- Structured data reading/writing (CSV/JSON/Parquet/TOML/YAML)
- Batch file operations
- Orchestrating Unix tools when useful, while preferring Nushell's structured data handling

## Goals

- Reliable, reproducible pipelines
- Robust error handling and clear failure modes
- Composable agents with consistent interfaces
- Strong guardrails: validation, logging, dry-run, idempotency
- Automated tests with fixtures

---

## 1. Design Principles

1. **Prefer Nushell's structured operations** (`open`, `to`, `from`, `select`, `update`, `where`, `group-by`, `reduce`, `merge`, `move`, `append`, `each`, `schema`) instead of ad-hoc text parsing whenever possible.

2. **Compose agents as small commands** with clear inputs/outputs. Avoid global state; use parameters and pipe structured data.

3. **Make all write operations opt-in** via `--apply` or `--write` flags. Default to dry-run that previews changes.

4. **Validate inputs early** with `schema`, `assert`, and custom guards. Fail fast with helpful messages.

5. **Emit logs and machine-readable status objects**. Human-readable errors should include suggestions.

6. **Support streaming and large files**: prefer line and table streaming when feasible; avoid loading entire files unnecessarily.

7. **Be explicit** about encodings, delimiters, timezones, and locales for reproducibility.

8. **Always provide examples and tests**.

---

## 2. Agent Interface Conventions

### Command Naming

`agent-<domain>-<action>` (e.g., `agent-txt-convert`, `agent-csv-normalize`, `agent-files-sync`)

### Standard Flags

- `--input` or pipe in: Source data/file(s)
- `--output` or pipe out: Destination file or stdout
- `--apply`: Perform writes (otherwise preview)
- `--format` / `--from` / `--to`: Explicit data formats
- `--encoding`: e.g., `utf-8`, `latin1`
- `--log-level`: `error|warn|info|debug`
- `--strict`: Treat warnings as errors
- `--force`: Override idempotency guards when necessary
- `--dry-run`: Alias for default preview mode

### Inputs

Accept file paths or structured data via pipeline

### Outputs

**When writing files**: return a structured status object with `ok`, `written`, `path`, `rows`, `skipped`, `errors`

**When previewing**: return transformed table to stdout

#### Example Status Object

```nu
{
  ok: true,
  action: "write",
  path: "/out/normalized.csv",
  rows: 1234,
  skipped: 0,
  errors: []
}

## 3. Error Handling and Guardrails
Use do and try Blocks
do { 
  # ... operation ...
} catch { |err|
  error make { 
    msg: $"Agent failed: ($err.msg)", 
    cause: $err 
  }
}

Validate File Existence and Permissions
def guard-file [path: path] {
  if not ($path | path exists) {
    error make $"Input file not found: ($path)"
  }
  if not (($path | path type) == "file") {
    error make $"Not a file: ($path)"
  }
}

Validate Schema
def guard-schema [tbl, required_cols: list<string>] {
  let missing = ($required_cols | where {|c| 
    not ($tbl | columns | any {|col| $col == $c })
  })
  if ($missing | length) > 0 {
    error make { 
      msg: "Missing required columns", 
      missing: $missing 
    }
  }
}

Idempotency Guard

Maintain a hash/signature of input to avoid redundant writes unless --force is set.

def compute-signature [data] {
  $data | to json -p | hash md5
}

Dry-Run Default

Only write when --apply provided. Otherwise preview results and report what would be written.

Structured Logging
def log [level: string, msg: string, extra?: record] {
  {
    ts: (date now),
    level: $level,
    msg: $msg,
    extra: ($extra | default {})
  } | to json -p | print
}

## 4. Using Unix Tools (When Helpful)
When to Use Unix Tools

Prefer Nushell but use Unix tools for:

Very large file manipulation (sed, awk, xargs, rg, fd, parallel)
Compression (gzip, xz, zstd)
External converters (pandoc for document formats)
Integration Pattern

Always wrap outputs into structured Nushell data (open --raw, from json/csv/yaml/toml).

Example
# Use ripgrep to list matching files, then bring into structured Nushell
rg -n --json 'ERROR' logs/ 
  | from json 
  | select type data.path data.line_number data.lines.text

## 5. Patterns and Examples
5.1 Text Conversion Agent (CSV → Normalized CSV)
# file: agents/agent-csv-normalize.nu

def agent-csv-normalize [
  --input: path,
  --output: path,
  --delimiter: string = ",",
  --encoding: string = "utf-8",
  --apply: bool = false,
  --strict: bool = false,
  --log-level: string = "info"
] {
  use std assert
  
  log $log-level "Starting agent-csv-normalize" { 
    input: $input, 
    output: $output 
  }
  
  guard-file $input
  
  # Stream read; specify delimiter/encoding explicitly
  let raw = open $input --encoding $encoding 
    | from csv --separator $delimiter
  
  # Validate required columns
  let required = ["id", "name", "email"]
  guard-schema $raw $required
  
  # Transform: trim, lowercase emails, strip invalid rows
  let cleaned = (
    $raw
    | update name {|row| ($row.name | str trim)}
    | update email {|row| ($row.email | str downcase | str trim)}
    | where {|row| 
        ($row.id | into int) != null and 
        ($row.email | str contains "@")
      }
  )
  
  if $strict and ($cleaned | length) != ($raw | length) {
    error make { 
      msg: "Row count changed under --strict", 
      before: ($raw | length), 
      after: ($cleaned | length) 
    }
  }
  
  # Idempotency via signature
  let sig_in = compute-signature $raw
  let sig_out = compute-signature $cleaned
  log "debug" "Signatures computed" { 
    input_sig: $sig_in, 
    output_sig: $sig_out 
  }
  
  if not $apply {
    log "info" "Dry-run: preview transformed data (no write)"
    $cleaned
  } else {
    # Write safely: temp file + atomic move
    let tmp = ($output | path dirname) 
      | path join $"._tmp_($sig_out).csv"
    
    do {
      $cleaned | to csv --separator $delimiter | save -f $tmp
      # On success, atomically move to final
      mv -f $tmp $output
      {
        ok: true,
        action: "write",
        path: $output,
        rows: ($cleaned | length),
        skipped: (($raw | length) - ($cleaned | length)),
        errors: []
      }
    } catch {|err|
      rm -f $tmp
      error make { msg: "Write failed", cause: $err }
    }
  }
}

5.2 JSON → Parquet Pipeline (Structured, Column Selection)
# file: agents/agent-json-to-parquet.nu

def agent-json-to-parquet [
  --input: path,
  --output: path,
  --columns: list<string> = [],
  --apply: bool = false,
  --log-level: string = "info"
] {
  log $log-level "Starting agent-json-to-parquet" { 
    input: $input, 
    output: $output 
  }
  
  guard-file $input
  
  let tbl = open $input | from json
  
  let tbl = if ($columns | length) > 0 {
    guard-schema $tbl $columns
    $tbl | select ...$columns
  } else {
    $tbl
  }
  
  if not $apply {
    log "info" "Dry-run: showing sample rows"
    $tbl | first 20
  } else {
    # Parquet support depends on Nushell build; fallback to CSV if not available
    if (help commands | where command == "to parquet" | length) == 1 {
      $tbl | to parquet | save -f $output
    } else {
      log "warn" "Parquet not available; writing CSV instead"
      $tbl | to csv | save -f $output
    }
    { 
      ok: true, 
      action: "write", 
      path: $output, 
      rows: ($tbl | length), 
      errors: [] 
    }
  }
}

5.3 Batch File Text Conversion Using Unix Tool
# file: agents/agent-txt-convert.nu

def agent-txt-convert [
  --dir: path,
  --pattern: string = "*.txt",
  --apply: bool = false,
  --log-level: string = "info"
] {
  log $log-level "Starting agent-txt-convert" { 
    dir: $dir, 
    pattern: $pattern 
  }
  
  if not ($dir | path exists) { 
    error make $"Directory not found: ($dir)" 
  }
  
  # Find files with fd if available; fallback to Nushell glob
  let files = if (which fd | length) > 0 {
    fd $pattern $dir --type f --absolute-path | lines
  } else {
    glob ([$dir, $pattern] | path join)
  }
  
  if ($files | length) == 0 {
    error make { 
      msg: "No files matched", 
      dir: $dir, 
      pattern: $pattern 
    }
  }
  
  let transformed = $files | each {|f|
    let content = open --raw $f
    
    # Example conversion: normalize line endings + trim trailing spaces
    let fixed = (
      $content
      | str replace -a "\r\n" "\n"
      | lines
      | each {|l| $l | str trim -r} 
      | str join "\n"
    )
    
    { 
      path: $f, 
      size_before: ($content | str length), 
      size_after: ($fixed | str length), 
      preview: ($fixed | str substring 0..200) 
    }
  }
  
  if not $apply {
    log "info" "Dry-run: previewing transformed metadata"
    $transformed
  } else {
    $transformed | each {|rec|
      do {
        $rec.preview | save -f $rec.path
        { path: $rec.path, ok: true }
      } catch {|err|
        { path: $rec.path, ok: false, error: $err.msg }
      }
    }
  }
}

## 6. Testing

Use nu's std assert, snapshot testing via saved fixtures, and deterministic inputs.

Directory Structure
agents/
  agent-*.nu
tests/
  fixtures/
    csv/
    json/
    txt/
  test-agent-csv-normalize.nu
  test-agent-json-to-parquet.nu
  test-agent-txt-convert.nu

Test Runner Pattern
# file: tests/test-agent-csv-normalize.nu

use std assert
source ../agents/agent-csv-normalize.nu
source ../agents/_common.nu  # where guards/log live, if factored

let input = "tests/fixtures/csv/sample.csv"
let output = "tests/tmp/normalized.csv"

# Clean
mkdir tests/tmp | ignore
rm -f $output | ignore

# Dry-run should not write and should return table
let dry = (agent-csv-normalize --input $input --output $output --apply false)
assert equal ($dry | length) 3  # example expected row count

# Apply should write a file and return status
let status = (agent-csv-normalize --input $input --output $output --apply true)
assert equal $status.ok true
assert ($output | path exists)

# Idempotency behavior: second run should produce same hash
let data = open $output | from csv
let sig = compute-signature $data
assert ($sig | str length) == 32

Run All Tests
ls tests/test-*.nu | get name | each {|t| nu $t } | flatten

Snapshot Testing for Outputs
let actual = (agent-json-to-parquet 
  --input tests/fixtures/json/sample.json 
  --apply false 
  | to json -p)
let expected = open tests/fixtures/json/expected.json

use std assert
assert equal $actual $expected

## 7. Common Utilities (Factorization)

Create agents/_common.nu and agents/_logging.nu to share guards and logging.

agents/_common.nu
export def guard-file [path: path] { 
  if not ($path | path exists) { 
    error make $"Input file not found: ($path)" 
  }
  if not (($path | path type) == "file") { 
    error make $"Not a file: ($path)" 
  }
}

export def guard-schema [tbl, required_cols: list<string>] {
  let missing = ($required_cols | where {|c| 
    not ($tbl | columns | any {|col| $col == $c })
  })
  if ($missing | length) > 0 {
    error make { 
      msg: "Missing required columns", 
      missing: $missing 
    }
  }
}

export def compute-signature [data] { 
  $data | to json -p | hash md5 
}

agents/_logging.nu
export def log [level: string, msg: string, extra?: record] {
  {
    ts: (date now),
    level: $level,
    msg: $msg,
    extra: ($extra | default {})
  } | to json -p | print
}

Usage in Agents
source agents/_common.nu
source agents/_logging.nu

## 8. Performance and Large Files
Prefer streaming reads: open --raw | lines for raw text; open | from csv/json for structured where feasible
Use each --keep-env --parallel for CPU-bound transforms cautiously; ensure order doesn't matter
For massive CSV: Consider chunking with split-by or external tools (mlr, xsv) then reassemble
Avoid to json on giant tables unless required; prefer hash md5 on smaller canonical representations if needed
## 9. Security and Safety
Never write secrets to logs. When logging records, redact known secret keys: update api_key { |v| "***redacted***" }
Validate paths to prevent directory traversal; restrict writes to known output directories
Use atomic writes via temp files + mv -f
Do not execute external commands on untrusted input without sanitization
Be explicit about encodings; avoid silent conversions
## 10. Examples: End-to-End
Normalize CSV, Then Convert to Parquet
source agents/agent-csv-normalize.nu
source agents/agent-json-to-parquet.nu

agent-csv-normalize \
  --input data/raw/users.csv \
  --output data/normalized/users.csv \
  --apply true

open data/normalized/users.csv 
  | from csv 
  | to parquet 
  | save -f data/warehouse/users.parquet

Batch Fix Text Files with Preview
source agents/agent-txt-convert.nu

agent-txt-convert --dir notes/ --pattern "*.md" --apply false | first 5

## 11. Maintenance
Document each agent's inputs/outputs and examples in its file header
Keep fixtures up to date with real-world edge cases
Add regression tests whenever a bug is fixed
Version agents by tagging commits and noting format changes in CHANGELOG
## 12. Troubleshooting
Issue	Solution
"Parquet not available"	Check help commands | where command == "to parquet". Install Nushell with parquet feature or fallback to CSV.
"Schema mismatch"	Inspect columns and use guard-schema to add clear messages.
"Large file slow"	Switch to streaming conversions or use xsv/mlr to pre-process, then return to Nushell for structured steps.
"Unicode issues"	Set --encoding explicitly and normalize with into string --encoding utf-8.
## 13. Style Guide
Use descriptive names: prefer snake_case for variables and kebab-case for command files
Comment why, not just what. Include data shape assumptions.
Keep functions small; compose with pipes
Return structured status objects for operations that mutate state
Notes
This guide assumes you're using a recent Nushell with std assert and common from/to formats.
Parquet command availability varies by build; the doc includes a fallback.
For specific formats or extra agents, extend the patterns above following the same conventions.

Happy building. Keep it structured, safe, and testable.
