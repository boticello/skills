---
name: clojure
description: (no description)
disable-model-invocation: true
---

# Clojure/Babashka Development: REPL-Driven HTDP Best Practices

A practical guide for building reliable, maintainable scripts using Clojure and Babashka, incorporating lessons learned from development experiences.

---

## Core Philosophy: REPL-Driven HTDP Development

**Why This Approach?**
- Immediate feedback via REPL testing
- Systematic function design prevents bugs
- Single-file scripts reduce complexity
- Validation-first prevents runtime errors

---

## 1. HTDP (How to Design Programs) Methodology

### The HTDP Design Recipe

For **every function**, follow this systematic process:

#### Step 1: Data Definitions
Define your data structures explicitly:

```clojure
;; Examples:
;; A CSV-Field is a String
;; A CSV-Row is a Map<String, String>
;; A Markdown-Metadata is a Map<Keyword, (String | [String] | :empty)>
;; A File-Path is a String ending in ".md"
```

#### Step 2: Function Signature
```clojure
;; Name: Input-Type -> Output-Type
;; Examples:
;; parse-csv-line: String -> [String]
;; transform-row: CSV-Row -> Markdown-Metadata
;; sanitize-filename: String -> File-Path
```

#### Step 3: Purpose Statement
One sentence describing what the function computes:

```clojure
;; Purpose: Parses a single CSV line into a vector of field strings
```

#### Step 4: Examples (Test Cases)
Write examples **before** implementing:

```clojure
;; Examples:
;; (parse-csv-line "A;B;C") => ["A" "B" "C"]
;; (parse-csv-line "\"A\";\"B;C\"") => ["A" "B;C"]
;; (parse-csv-line "") => [""]
```

#### Step 5: Template
Based on input data structure:

```clojure
;; For String input (character-by-character processing):
(defn parse-csv-line [line]
  (loop [chars (vec line)
         result []
         ...]
    ;; ... process each character
    ))
```

#### Step 6: Implementation
Write the function body:

```clojure
(defn parse-csv-line
  "Parse a single CSV line into fields"
  [line]
  (loop [chars (vec line)
         result []
         current-field ""
         in-quotes false]
    ;; ... implementation ...
    ))
```

#### HTDP Comments in Code

Document HTDP steps as comments for self-documenting code:

```clojure
;; HTDP Recipe for parse-csv-line

;; Step 2: Function Signature
;; parse-csv-line: String -> [String]

;; Step 3: Purpose Statement
;; Purpose: Parse a single CSV line into fields with semicolon delimiter

;; Step 4: Examples (from implementation plan)
;; (parse-csv-line "A;B;C") => ["A" "B" "C"]
;; (parse-csv-line "\"A\";\"B;C\"") => ["A" "B;C"]

;; Step 5: Template
;; Based on String input - character-by-character processing

;; Step 6: Implementation
(defn parse-csv-line [...] ...)

;; Test the function
(println "Test result:" (parse-csv-line "A;B;C"))
```

**Benefits:**
- Documents intent alongside code
- Makes code self-explanatory for future maintainers
- Helps trace back to design decisions
- Great for code reviews

### What If a Test Fails?

**Critical section - real debugging example:**

```clojure
;; Test third example (first attempt - had a bug)
(parse-csv-line "\"ABC\";;\"\"")
;; Returns: ["ABC" ""]
;; Expected: ["ABC" "" ""]
;; BUG! Missing the last empty field

;; What to do:
;; 1. Describe the problem: "It's missing the last empty field"
;; 2. Check the code: I'm not adding the final field when loop ends
;; 3. Fix the implementation:
;;    Change base case from `result` to `(conj result current)`
;; 4. Test again:
(parse-csv-line "\"ABC;;\"\"")
;; Returns: ["ABC" "" ""]  ✓ Fixed!

;; Key lesson: Tests catch bugs immediately. If I didn't have examples,
;; I might not have caught this edge case.
```

**Debugging workflow:**
1. Describe the problem in plain English
2. Check the code against your examples
3. Trace through the logic step by step
4. Fix the implementation
5. Test again with all examples

**Why this matters:** Without examples, you might never test the edge case that fails. With examples, you know exactly what's broken and can fix it immediately.

---

## 2. REPL-Driven Development Workflow

### Always Start in REPL

**Never write a long script without testing each piece!**

#### REPL Workflow - Three Practical Approaches:

**Option A: Interactive REPL (for rapid iteration)**
```bash
# Start REPL
bb

# Test each function individually
user=> (parse-csv-line "A;B;C")
["A" "B" "C"]  ✓

# If error, fix immediately
# If correct, continue to next function
```

**Option B: One-liner testing (for quick checks)**
```bash
# Test a single expression
bb -e '(parse-csv-line "A;B;C")'

# Test multiple expressions
bb -e '
(load-file "functions.clj")
(parse-csv-line "A;B;C")
'
```

**Option C: Test file (for complex tests)**
```clojure
;; test_functions.clj
(defn parse-csv-line [...] ...)
;; Run tests
(parse-csv-line "A;B;C")
(parse-csv-line "\"A\";\"B;C\"")

;; Execute
bb test_functions.clj
```

#### Build Scripts Incrementally

**Single-File Scripts for Babashka:**
- Prefer one concern per file
- Pure functions first, then I/O
- Consider the 200-line limit as a guideline, not a hard rule
- Scripts can be 300-500 lines if well-organized with clear sections
- Consider multiple files if approaching 1000 lines

**Better guideline:** One function per concern, clear section headers, comprehensive comments

### Incremental Testing with Separate Files

**When to use this approach:**
- For scripts with 10+ functions
- When building complex transformations
- To keep a development history/audit trail
- When working in environments where interactive REPL is less convenient

**Pattern:**
```clojure
;; test_parse_csv_line.clj
(defn parse-csv-line [...] ...)
;; Test immediately
(println "Test 1:" (parse-csv-line "A;B;C"))
(println "Test 2:" (parse-csv-line "\"A\";\"B;C\""))

;; Run
bb test_parse_csv_line.clj
```

**Benefits:**
- Each function can be tested independently
- Build complexity incrementally
- Easy to revert/fix individual functions
- Clear development progression
- Great for code reviews - each function has its own test history

**Workflow:**
1. Create `test_parse_csv_line.clj` → Test → ✓
2. Create `test_parse_csv_header.clj` (loads previous) → Test → ✓
3. Create `test_parse_csv.clj` (loads previous) → Test → ✓
4. ...continue building
5. Finally assemble into single file

---

## 3. Single-File Script Architecture

### For Simple Scripts (like CSV converters):

```clojure
#!/usr/bin/env bb

;; 1. DATA DEFINITIONS
;; A CSV-Row is {:name String :definition String ...}

;; 2. VALIDATION SCHEMAS (Malli or Manual)
;; (see Section 4 for both approaches)

;; 3. PURE FUNCTIONS (test first in REPL)
(defn parse-csv-line [line] ...)
(defn parse-csv [path] ...)
(defn transform-row [row] ...)
(defn generate-yaml [data] ...)
(defn generate-markdown [data] ...)

;; 4. MAIN (imperative shell)
(defn -main []
  ;; Parse CLI args
  ;; Read CSV
  ;; Transform rows
  ;; Write files
  )

;; ENTRY POINT
(apply -main *command-line-args*)
```

---

## 4. Validation Strategies

### Why Validate?
- Catch errors early at function boundaries
- Document expected data structures
- Prevent downstream errors

### Option A: Validation with Malli

**Schema-First Design:**

```clojure
;; Define schemas for all data
(require '[malli.core :as m])

(def CSV-Row-Schema
  [:map
   [:name :string]
   [:definition :string]
   [:status :string]])

(def Markdown-Metadata-Schema
  [:map
   [:created :string]
   [:name :string]
   [:definition :string]])

;; Validation function
(defn validate-csv-row [row]
  (if (m/validate CSV-Row-Schema row)
    row
    (throw (ex-info "Invalid CSV row" {:row row :errors (m/explain CSV-Row-Schema row)}))))
```

**Use Validation:**
```clojure
(defn transform-row [row]
  (let [validated (validate-csv-row row)]
    ;; transform validated data
    ))
```

### Option B: Manual Validation (When Malli Isn't Available)

**When to use:** Malli not installed, or simple validation is clearer

```clojure
(defn validate-csv-row
  "Validate CSV row has required fields"
  [row]
  (let [required [:name :definition :lastmodifiedon :createdon]
        missing (filter #(clojure.string/blank? (get row % "")) required)]
    (when (seq missing)
      (throw (ex-info (str "Missing required fields: " missing) {:row row})))
    row))

;; Test validation
(def valid-row {:name "Test" :definition "Sample" :lastmodifiedon "2025-01-01" :createdon "2024-01-01"})
(validate-csv-row valid-row)  ;; => returns row

(def invalid-row {:name "Test" :definition ""})
(validate-csv-row invalid-row)  ;; => throws exception
```

**Also document Malli schemas for reference (even if not using them):**
```clojure
(comment
  ;; These schemas document expected structure even if using manual validation
  (def CSV-Row-Schema
    [:map
     [:name :string]
     [:definition :string]
     [:lastmodifiedon :string]
     [:createdon :string]])

  (def Markdown-Metadata-Schema
    [:map
     [:created :string]
     [:name :string]
     [:definition :string]]))
```

---

## 5. Testing Strategy

### Test Each Function in REPL

**Example-driven testing:**

```clojure
;; Test parse-csv-line
(parse-csv-line "A;B;C")
;; Expected: ["A" "B" "C"]

(parse-csv-line "\"A\";\"B;C\"")
;; Expected: ["A" "B;C"]

;; Test transform-row
(let [row {:name "Test" :definition "Def"}
      result (transform-row row)]
  (assert (= (:name result) "Test"))
  (assert (= (:created result) "2025-11-03T10:00:00Z")))
;; All assertions pass ✓
```

### Fixture-Based Testing

```clojure
;; test/fixtures/sample.csv
"Name";"Definition"
"Test";"Sample definition"

;; In REPL:
(let [rows (parse-csv "test/fixtures/sample.csv")]
  (assert (= (count rows) 1))
  (assert (= (:name (first rows)) "Test")))
```

### Real-World Testing

**Always test with actual data (after synthetic tests):**

```clojure
;; After testing with synthetic data:
(def real-data (slurp "production-data.csv"))
(def rows (parse-csv real-data))

;; Process first few rows
(println "Real data row count:" (count rows))
(doseq [row (take 5 rows)]
  (process-csv-row row "."))

;; Check generated output
(println "Sample generated file:")
(println (slurp "generated-file.md"))
```

**Why this matters:**
- Real data often has edge cases synthetic data misses
- Different CSV formats, encodings, line endings
- Performance testing with actual data volumes
- Validation with production constraints

---

## 6. Common Patterns & Templates

### CSV Parsing Template

```clojure
(defn parse-csv-line
  "Parse CSV line with semicolon delimiter"
  [line delimiter]
  (loop [chars (vec line)
         result []
         current ""
         in-quotes false]
    (if (empty? chars)
      (conj result current)
      (let [c (first chars)
            rest (rest chars)]
        (cond
          ;; Handle quotes
          (and in-quotes (= c \"))
          (if (= (first rest) \")
            (recur (rest rest) result (str current \") in-quotes)
            (recur rest result current false))

          ;; Handle delimiter
          (and (not in-quotes) (= c delimiter))
          (recur rest (conj result current) "" in-quotes)

          ;; Regular character
          :else
          (recur rest result (str current c) in-quotes))))))
```

### Field Name Transformation Pattern

**Common when mapping between data sources:**

```clojure
(defn transform-row-to-metadata
  "Transform CSV row to markdown metadata"
  [row]
  {:name (:name row)
   ;; Map different field names
   :data-type (:conceptual-data-type row)      ;; :conceptual-data-type -> :data-type
   :data-asset (:az-data-asset row)           ;; :az-data-asset -> :data-asset
   :modified-on (:lastmodifiedon row)         ;; :lastmodifiedon -> :modified-on
   :created-on (:createdon row)               ;; :createdon -> :created-on
   ;; Direct mappings
   :definition (:definition row)
   :criticality-indicator (:criticality-indicator row)
   :data-domain (:data-domain row)
   :status (:status row)
   :asset-type (:asset-type row)})

;; Document field mappings at top of function or file:
;; CSV Fields → Markdown Fields
;; :conceptual-data-type → :data-type
;; :az-data-asset → :data-asset
;; :lastmodifiedon → :modified-on
;; :createdon → :created-on
```

---

## 7. Error Handling

### Fail Fast at Boundaries

```clojure
(defn -main []
  (try
    (let [args (parse-cli-args *command-line-args*)
          input (:input args)]

      ;; Validate input file exists
      (when-not (clojure.java.io/exists? (clojure.java.io/file input))
        (println "Error: File not found:" input)
        (System/exit 1))

      ;; Validate CSV structure
      (let [rows (parse-csv input)]
        (when (empty? rows)
          (println "Error: CSV is empty or has no data rows")
          (System/exit 1))

        ;; Process with confidence
        (process-rows rows)))

    (catch Exception e
      (println "Error:" (.getMessage e))
      (.printStackTrace e)
      (System/exit 1))))
```

### Common Error Patterns & Solutions

#### Error 1: Entry Point Arguments
**Problem:** `(-main)` doesn't receive command-line args
```clojure
;; WRONG
(-main)
;; Correct output: Error: No input file...

;; RIGHT
(apply -main *command-line-args*)
;; Correct output: Processes actual arguments
```

#### Error 2: Empty CSV Handling
```clojure
(let [rows (parse-csv csv-content)]
  (when (empty? rows)
    (println "Error: CSV has no data rows")
    (System/exit 1)))
```

#### Error 3: File Not Found
```clojure
(when-not (.exists (java.io.File. input-file))
  (println "Error: File not found:" input-file)
  (System/exit 1))
```

#### Error 4: Processing Individual Rows
```clojure
(defn process-csv-row
  "Process single row with error isolation"
  [row output-dir]
  (try
    ;; ... transformation logic that might fail
    (validate-csv-row row)
    (let [metadata (transform-row-to-metadata row)]
      ;; ... more processing
      )
    (catch Exception e
      (println "Error processing row:" (.getMessage e))
      ;; Continue with next row instead of failing entire process
      )))
```

#### Error 5: Argument Parsing Indexing
```clojure
;; WRONG - using 'second' on rest
(recur (rest args) (assoc result :input (second args)))

;; RIGHT - using 'first' on rest
(recur (vec (rest rest-args)) (assoc result :input (first rest-args)))
```

---

## 8. CLI Design for Scripts

### Flexible Argument Parsing

**Support multiple argument styles:**

```clojure
(defn parse-cli-args
  "Parse command line arguments"
  [args]
  (loop [args (vec args) result {}]
    (if (empty? args) result
      (let [arg (first args) rest-args (rest args)]
        (cond
          ;; Flag style
          (or (= arg "-i") (= arg "--input"))
          (if (seq rest-args)
            (recur (vec (rest rest-args)) (assoc result :input (first rest-args)))
            (recur rest-args result))

          ;; Help flag
          (or (= arg "-h") (= arg "--help"))
          (recur rest-args (assoc result :help true))

          ;; Positional argument (CSV file)
          (and (not (contains? result :input))
               (clojure.string/ends-with? arg ".csv"))
          (recur rest-args (assoc result :input arg))

          :else
          (recur rest-args result))))))

;; Usage:
;; ./script.clj data.csv                    (positional)
;; ./script.clj -i data.csv                 (flag)
;; ./script.clj --input data.csv            (long flag)
;; ./script.clj --help                      (help)
```

### Simple Argument Parsing (Alternative)

```clojure
(defn parse-args [args]
  (loop [args args
         result {}]
    (if (empty? args)
      result
      (let [arg (first args)]
        (cond
          (or (= arg "-i") (= arg "--input"))
          (recur (rest args) (assoc result :input (second args)))

          (or (= arg "-h") (= arg "--help"))
          (recur (rest args) (assoc result :help true))

          :else
          (recur (rest args) result))))))
```

---

## 9. Common Pitfalls & Solutions

### Pitfall: Writing Long Scripts First
**Problem:** 100+ lines without testing
**Solution:** Build in REPL, one function at a time

### Pitfall: Complex Nested Forms
**Problem:** Deep `cond`/`let` blocks
**Solution:** Break into smaller functions

### Pitfall: String vs Keyword Confusion
**Problem:** CSV has strings, code uses keywords
**Solution:** Explicit data definitions + validation schemas

### Pitfall: No Validation
**Problem:** Errors discovered too late
**Solution:** Validate at every boundary (Malli or manual)

### Pitfall: Syntax Errors in Large Files
**Problem:** Hard to find missing parens
**Solution:** Build incrementally, test at each step

### Pitfall: Testing Only with Synthetic Data
**Problem:** Real data has edge cases
**Solution:** Always test with production data early

### Pitfall: Rigid CLI Design
**Problem:** Only accepting one argument style
**Solution:** Support both positional and flag arguments

### Pitfall: Skipping Data Definitions
**Problem:** No explicit data structure defined

**❌ Wrong approach:**
```clojure
;; Bad - no explicit data structure
(defn parse-csv [content] ...)
```
**Result:** Confusion about types, what format is expected, unclear intent

**✓ Right approach:**
```clojure
;; Good - data definitions guide everything
;; A CSV-Content is a String with multiple lines
;; A CSV-Row is a Map<String, String>
(defn parse-csv [content] ...)
```
**Result:** Clear expectations, guides implementation, prevents confusion

### Pitfall: Not Testing Edge Cases
**Problem:** Only testing happy path

**❌ Wrong approach:**
```clojure
;; Only testing simple cases
(parse-csv-line "A;B;C")  ;; ✓ Works
;; But never testing edge cases...
```
**Result:** Edge cases will break in production

**✓ Right approach:**
```clojure
;; Test edge cases too
(parse-csv-line "A;B;C")        ;; ✓ Simple case
(parse-csv-line "\"ABC;;\"\"")   ;; ✓ Empty fields
(parse-csv-line "")             ;; ✓ Empty string
(parse-csv-line "\"A\";\"B;C\"") ;; ✓ Quoted fields
```
**Result:** Robust function handles all cases

---

## 10. Comprehensive Checklists

### Function Checklist

Before considering a function complete:

- [ ] **Data definition written** (What type is the input? What type is output?)
- [ ] **Function signature written** (Name: Input-Type -> Output-Type)
- [ ] **Purpose statement written** (one sentence, no "and" or "or")
- [ ] **Examples written** (minimum 3, including edge cases)
- [ ] **Template created from data structure** (guides the implementation)
- [ ] **Implementation follows template** (stays true to design)
- [ ] **All examples tested in REPL** (don't skip this!)
- [ ] **All examples pass** (including edge cases)
- [ ] **Edge cases tested** (empty strings, empty collections, etc.)
- [ ] **Error cases handled** (what if input is malformed?)
- [ ] **Function does exactly what purpose statement says** (no more, no less)

### Script Checklist

Before considering a script complete:

- [ ] **Every function follows HTDP process** (not just "good ones")
- [ ] **Every function tested in REPL** (or test files)
- [ ] **End-to-end test with real data** (synthetic tests aren't enough)
- [ ] **Error handling for all failure modes** (missing files, invalid data, etc.)
- [ ] **Clear error messages** (not stack traces for users)
- [ ] **Script works for valid input** (happy path tested)
- [ ] **Script fails gracefully for invalid input** (no crashes)
- [ ] **Code is readable and well-commented** (future you will thank you)
- [ ] **Field mappings documented** (for CSV transformations)
- [ ] **Validation catches invalid data** (both manual and schema)
- [ ] **Statistics included** (lines, functions, success rate)

### Code Organization Checklist

- [ ] Each function tested in REPL (or test files)
- [ ] All examples from HTDP pass
- [ ] Validation schemas defined (Malli or manual)
- [ ] Validation catches invalid data
- [ ] Error handling at boundaries
- [ ] Simple, readable code
- [ ] Single responsibility per function
- [ ] Tested with real data (not just synthetic)
- [ ] Field mappings documented
- [ ] Script statistics/self-documentation included

### Script Structure Template:
```
1. Data Definitions
2. Validation Schemas (Malli) / Manual Validation
3. Pure Functions (tested in REPL)
4. Imperative Main
5. Entry Point Call
6. Error Handling Examples (in comments)
7. Key Takeaways & Statistics
```

---

## 11. Example Complete Workflow

### Task: Build CSV to Markdown Converter

#### Step 1: Design Data
```clojure
;; CSV-Row: Map<String, String>
;; Markdown-File: String (YAML + Markdown)
```

#### Step 2: REPL Tests
```clojure
;; Test parse-csv-line
bb> (parse-csv-line "A;B;C")
["A" "B", "C"]  ✓

;; Test transform-row
bb> (transform-row {:name "Test"})
{:created "..." :name "Test" ...}  ✓

;; Test with real data
bb> (def real-data (slurp "production.csv"))
bb> (def rows (parse-csv real-data))
bb> (count rows)
253  ✓
```

#### Step 3: Implement Main
```clojure
(defn -main [& args]
  (let [parsed-args (parse-cli-args args)
        input-file (:input parsed-args)]
    (when-not input-file
      (println "Usage: bb script.clj -i <input.csv>")
      (System/exit 1))

    (let [rows (parse-csv (slurp input-file))]
      (doseq [row rows]
        (-> (transform-row row)
            generate-markdown
            write-file))
      (println "Conversion complete!"))))

;; Run
bb script.clj -i input.csv
```

---

## 12. Script Statistics as Documentation

**Add to end of script for maintainers:**

```clojure
;; =============================================================================
;; KEY TAKEAWAYS
;; =============================================================================
;; 1. REPL-driven development: Built and tested each function incrementally
;; 2. HTDP methodology: Used signature, purpose, examples, template, implementation
;; 3. Single-file architecture: All functions in one self-contained script
;; 4. Validation-first: validate-csv-row catches errors early
;; 5. Pure functions: Core logic is pure, I/O isolated in specific functions
;; 6. Error handling: Graceful handling of missing files, empty CSVs, invalid data
;; 7. Flexible CLI: Supports both positional and flag-based arguments
;; 8. Clean output: Generated markdown with YAML front-matter for Obsidian

;; =============================================================================
;; STATISTICS
;; =============================================================================
;; Lines of code: 314
;; Functions: 12
;; Tested: Yes (REPL-driven + real data)
;; CSV rows processed: 253
;; Success rate: 100%

;; =============================================================================
;; ERROR HANDLING TESTS (for validation)
;; =============================================================================
(comment
  ;; Test 1: Empty CSV
  (def empty-csv "")
  (parse-csv empty-csv)  ;; => []

  ;; Test 2: Invalid row (missing required fields)
  (def bad-row {:name "Test" :definition ""})
  (try (validate-csv-row bad-row) (catch Exception e (.getMessage e)))
  ;; => "Missing required fields: ..."

  ;; Test 3: File not found error
  ;; Run: ./csv-converter.clj nonexistent.csv
  ;; Expected: "Error: File not found: nonexistent.csv"
  )
```

---

## Appendix: REPL Session Examples

### Typical REPL Session - Building parse-csv-line

```clojure
user=> ;; I'm starting with parse-csv-line
user=> ;; Step 1: I need to define what a CSV-Field is
user=> ;; A CSV-Field is a String
;; nil

user=> ;; Step 2: Function signature
user=> ;; parse-csv-line: String -> [String]
;; nil

user=> ;; Step 3: Purpose
user=> ;; Purpose: Parse CSV line into vector of fields
;; nil

user=> ;; Step 4: Examples
user=> (parse-csv-line "A;B;C")
;; => ["A" "B" "C"]
;; (This fails because function doesn't exist yet!)

user=> ;; Step 5: Template based on String input
user=> (defn parse-csv-line [line]
         (loop [chars (vec line)
                result []
                current ""
                in-quotes false]
           ;; Will implement step by step
           ))
;; #'user/parse-csv-line

user=> ;; Step 6: Implementation
user=> (defn parse-csv-line [line]
         (loop [chars (vec line)
                result []
                current ""
                in-quotes false]
           (if (empty? chars)
             (conj result current)
             (let [c (first chars)
                   rest (rest chars)]
               (cond
                 (and in-quotes (= c \"))
                 (if (= (first rest) \")
                   (recur (rest rest) result (str current \") in-quotes)
                   (recur rest result current false))
                 
                 (and (not in-quotes) (= c \"))
                 (recur rest result current true)
                 
                 (and (not in-quotes) (= c \;))
                 (recur rest (conj result current) "" in-quotes)
                 
                 :else
                 (recur rest result (str current c) in-quotes))))))
;; #'user/parse-csv-line

user=> ;; Now test it!
user=> (parse-csv-line "A;B;C")
["A" "B" "C"]

user=> (parse-csv-line "\"A\";\"B;C\"")
["A" "B;C"]

user=> (parse-csv-line "\"ABC;;\"\"")
["ABC" "" ""]

user=> (parse-csv-line "")
[""]

user=> ;; All tests pass! ✓
;; ✓ Success!

user=> ;; Now I can move to the next function
user=> ;; Let's build parse-csv-header
```

### Alternative: Using Test Files

```bash
# Create test file
$ cat > test_parse_csv_line.clj << 'EOF'
;; HTDP Recipe for parse-csv-line

;; Data definitions:
;; A CSV-Field is a String

;; Signature: parse-csv-line: String -> [String]

;; Purpose: Parse a single CSV line into fields

;; Examples:
;; (parse-csv-line "A;B;C") => ["A" "B" "C"]
;; (parse-csv-line "\"A\";\"B;C\"") => ["A" "B;C"]

;; Implementation:
(defn parse-csv-line [line]
  (loop [chars (vec line)
         result []
         current ""
         in-quotes false]
    (if (empty? chars)
      (conj result current)
      (let [c (first chars)
            rest (rest chars)]
        (cond
          (and in-quotes (= c \"))
          (if (= (first rest) \")
            (recur (rest rest) result (str current \") in-quotes)
            (recur rest result current false))
          
          (and (not in-quotes) (= c \"))
          (recur rest result current true)
          
          (and (not in-quotes) (= c \;))
          (recur rest (conj result current) "" in-quotes)
          
          :else
          (recur rest result (str current c) in-quotes))))))

;; Test the function
(println "Test 1:" (parse-csv-line "A;B;C"))
(println "Test 2:" (parse-csv-line "\"A\";\"B;C\""))
(println "Test 3:" (parse-csv-line "\"ABC;;\"\""))

EOF

# Run the test file
$ bb test_parse_csv_line.clj
Test 1: [A B C]
Test 2: [A B;C]
Test 3: [ABC  ]
```

### Typical Beginner Mistakes

```clojure
;; ❌ MISTAKE 1: No examples, jumping straight to code
user=> (defn parse-csv-line [line] ...)
;; Writes entire implementation
;; Tests at the end
;; Gets 50 errors - which one to fix first?

;; ✓ BETTER: Examples first
user=> ;; (parse-csv-line "A;B;C") => ["A" "B" "C"]
user=> ;; Now implement, test this example
user=> (defn parse-csv-line [line] ...)
```

```clojure
;; ❌ MISTAKE 2: No data definitions
user=> (defn parse-csv [content] ...)
;; What format is content? String? File? Vector?

;; ✓ BETTER: Define data first
user=> ;; A CSV-Content is a String with lines separated by \n
user=> ;; A CSV-Row is a Map<String, String>
user=> (defn parse-csv [content] ...)
```

```clojure
;; ❌ MISTAKE 3: Testing only happy path
user=> (parse-csv-line "A;B;C")
["A" "B" "C"]  ;; ✓ Works!
;; Tests complete... or are they?

;; ✓ BETTER: Test edge cases too
user=> (parse-csv-line "")           ;; Empty
user=> (parse-csv-line "\"A;;\"\"")  ;; Empty fields
user=> (parse-csv-line "\"A;\"B\"")  ;; Mismatched quotes
```

---

## 13. Key Takeaways

1. **REPL is your friend** - Always test in REPL first (interactive, -e, or test files)
2. **HTDP prevents bugs** - Examples before implementation
3. **Single-file scripts** - Simpler is better for Babashka (but >200 lines is OK if well-organized)
4. **Validate everything** - Malli schemas or manual validation at boundaries
5. **Break down complexity** - Small, pure functions
6. **Test as you go** - Don't write 100 lines without testing
7. **Test with real data** - Synthetic tests are not enough
8. **Document field mappings** - Future maintainers will thank you
9. **Flexible CLI** - Support both positional and flag arguments
10. **Error isolation** - One bad row shouldn't kill the entire process

---

## 14. Final Development Workflow

### Detailed Workflow with HTDP

```
1. Start REPL session (bb or bb -e or test files)
2. Define data structures (explicit types for everything)
3. Design function using HTDP:
   a. Write data definitions
   b. Write function signature (Input-Type -> Output-Type)
   c. Write purpose statement (one sentence)
   d. Write examples BEFORE coding (minimum 3, include edge cases)
   e. Create template from data structure
   f. Implement following template
4. Load function in REPL
5. Test ALL examples (don't skip any!)
6. Fix any failures (use debugging workflow)
7. Move to next function (repeat 2-6)
8. When all functions done:
   a. Assemble into main function
   b. End-to-end test with test CSV
   c. Fix any integration issues
9. Add validation (Malli schemas or manual validation)
10. Add error handling for all failure modes
11. Test with real production data (not just synthetic)
12. Add statistics, key takeaways, and self-documentation
13. Final review against checklists
14. Ship!

Remember:
- If you're stuck on syntax errors, you're going too fast
- Use the REPL constantly (not just at the end)
- Write examples before code (this is non-negotiable)
- Describe what you're doing as you go (helps debugging)
- Test small pieces until you're confident
- One broken test is enough to stop and fix
```

**Key Principle:** The REPL is your primary development tool. Test constantly, fail fast, fix immediately.
