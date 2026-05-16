Recommended extension gems by project type:

| Gem | When |
|---|---|
| `rubocop-performance` | Always |
| `rubocop-rails` | Rails projects |
| `rubocop-rspec` | Projects with RSpec |
| `rubocop-rake` | Projects with Rakefile tasks |

Standard `.rubocop.yml` starting point:

```yaml
# frozen_string_literal: true
require:
  - rubocop-performance

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - "db/schema.rb"
    - "vendor/**/*"
    - "node_modules/**/*"

Metrics/MethodLength:
  Max: 5

Metrics/ClassLength:
  Max: 100

Metrics/AbcSize:
  Max: 17

Style/FrozenStringLiteralComment:
  Enabled: true

Style/StringLiterals:
  EnforcedStyle: single_quotes
```

---
