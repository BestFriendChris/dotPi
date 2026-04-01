# Pie A La Mode Feature Spec

## Overview

A new feature for the `pie` CLI to support specialized operating modes - highly focused, task-specific configurations with predefined system prompts, extensions, and nono security profiles.

## Core Concept

Specialized operating modes that bundle together:
1. A focused system prompt (PROMPT.md) tailored for specific tasks
2. Optional nono security profile for sandboxing
3. Optional pi extensions to auto-load
4. Other configuration as needed

Examples:
- `pie mode skill-creator` - Optimized for creating new skills
- `pie mode spec-writer` - Focused on writing project specifications
- `pie mode code-reviewer` - Constrained to code quality and review tasks

## Key Components

### Named Modes
- Each mode defined in its own directory under `.pi/a_la_mode/` or `~/.pi/a_la_mode/`
- Contains a PROMPT.md file with system prompt content (no frontmatter)
- Requires `config.json` with `name` and `description` fields (source of truth)
- Optional `nono-profile.json` for sandboxing
- Optional `extensions/` directory for auto-discovered extensions

### Pi System Prompt Integration
- Uses pi's `--system-prompt` and `--append-system-prompt` CLI flags
- No dependency on APPEND_SYSTEM.md files
- Flexible prompt composition with configurable merge order
- Supports disabling default pi prompts for full mode control

### Nono Profile Support
- **What is nono**: A sophisticated sandboxing tool with fine-grained security controls
- Supports profiles defined in `~/.config/nono/profiles/<name>.json`
- Provides filesystem access control, network filtering, credential management, etc.
- When `nono-profile.json` exists, launch with `nono run --profile <profile-location> -- pi` instead of just `pi`
- **For future reference**: Run `nono profile guide` for comprehensive authoring instructions
- **Profile integration**: `nono-profile.json` contains the actual profile content, making modes self-contained and portable
- **Constraint enforcement**: Both approaches supported - simple modes use system prompts only, secure modes add nono profiles
- **Sandbox notification**: When a nono profile is active, automatically inject sandbox notification into system prompt to prevent AI confusion about permission restrictions
- **Profile resolution order**:
  1. `config.json` has `"nono_profile": "path/to/profile.json"` → use that path (relative to mode directory)
  2. `config.json` has `"nono_profile": null` → explicitly disabled, no sandboxing even if `nono-profile.json` exists
  3. `config.json` omits `nono_profile` → auto-discover `nono-profile.json` in mode directory root
  4. No `nono-profile.json` found → no sandboxing

### Pi Extensions
- Automatic loading of extensions when the configuration starts
- **Integration mechanism**: Use pi's `--extension <path>` flag (can be used multiple times)
- Auto-discovered from `extensions/` subdirectory, passed as multiple `--extension` arguments
- `config.json` can override with specific extension list or disable auto-discovery
- Pi's existing system manages extension conflicts, load order, and failure cases
- Pie modes simply pass extensions via `--extension` flags; pi handles the rest

## Directory Structure

### Standard Mode Layout
```
~/.pi/a_la_mode/skill-creator/
├── PROMPT.md            # Pure system prompt content (no frontmatter)
├── nono-profile.json    # Optional sandboxing
├── extensions/          # Optional extensions (auto-discovered)
└── config.json          # Required config (source of truth)
```

### File Requirements
- **config.json**: Required, contains `name` and `description` fields (source of truth). The `name` field must match the directory name — a mismatch is a FATAL validation error.
- **PROMPT.md**: Pure system prompt content without frontmatter
- **nono-profile.json**: Optional, enables sandboxed execution
- **extensions/**: Optional directory for auto-discovered extensions

## User Experience

### Primary Workflow
1. User runs `pie mode <mode-name>` or `pie mode /path/to/mode`
2. Mode discovery: project `.pi/a_la_mode/` → global `~/.pi/a_la_mode/` → direct path
3. If mode has `nono-profile.json`, launch with `nono run --profile <profile-location> -- pi`
4. Otherwise, launch `pi` normally
5. PROMPT.md content gets appended to system prompt via pi's CLI flags
6. Extensions loaded: auto-discovered from `extensions/` unless `config.json` specifies otherwise

### Mode Discovery
- **Project-specific modes**: `.pi/a_la_mode/` (takes precedence over global)
- **Global modes**: `~/.pi/a_la_mode/` (user-wide availability)
- **Direct path support**: `pie mode /path/to/mode` for custom locations
- **Discovery order**: Project → Global → Direct path

### Commands
- `pie mode [-v|-vv|-vvv] <mode-name>[.<flavor>] [--allow] [-- <pi-args>...]` - Launch pi with specified mode, optional flavor variant, and optional pi arguments
- `pie mode list [-v|-vv|-vvv] [--format json]` - List all discoverable modes with descriptions, separated by project/user sections (see List Command Output below)
- `pie mode create [-v|-vv|-vvv] (-u) <name>` - Create new modes using specialized mode-creation mode, with validation against reserved command names
- `pie mode show [-v|-vv|-vvv] [--format json] (-u) <name|path>` - Show mode details with tiered verbosity (see Show Command Output below). `--format json` for structured output. `-u`/`--user` shows only user modes
- `pie mode validate [-v|-vv|-vvv] (-u) <name|path>` - Validate mode directory structure, config.json schema compliance, and file reference integrity
- `pie mode allow [-v|-vv|-vvv] [-f|--force] <name|path>` - Explicitly trust and allow a single mode
- `pie mode allow [-v|-vv|-vvv] [-f|--force] --all [<directory>]` - Bulk approve all modes in a directory (does not override explicit denials). `-f`/`--force` skips confirmation prompt
- `pie mode disallow [-v|-vv|-vvv] <name|path>` - Explicitly deny mode execution
- `pie mode gc [-v|-vv|-vvv]` - Remove stale cache and approval entries for modes whose paths no longer exist
- `pie mode config` - Show all settings with current values and defaults
- `pie mode config <key>` - Show a single setting's value and default
- `pie mode config <key> <value>` - Set a configuration value
- `pie mode config <key> --reset` - Reset a setting to its default

### List Command Output

The `list` command displays tiered mode listings grouped by source (project/user). Default output is human-readable; `--format json` produces a single JSON object to stdout with the same field sets.

#### Trust Icons (all levels)
- `✓` allowed
- `?` unknown
- `✗` denied
- `⚠` validation error (mode is broken/invalid)

#### Default (no verbosity flags)
Compact listing. One line per mode: trust icon, name, description. No flavor, extension, or nono information — use `show` for that detail.

```
Project modes:
  ✓ skill-creator     Create new pi skills
  ? code-reviewer     Code review and quality analysis

User modes:
  ✓ spec-writer       Write project specifications
  ✗ untrusted-mode    Experimental mode
  ⚠ broken-mode       (invalid: missing required field "description")
```

- Sections with no modes are omitted entirely
- Invalid modes show the validation error in parentheses in place of the description

#### `-v` (Basic)
Adds compact metadata indicators after description, separated by ` · `.

```
  ✓ skill-creator     Create new pi skills             2 flavors · 🔒 · 3 ext
  ? code-reviewer     Code review and quality analysis  1 ext
```

- `N flavors` — flavor count
- `🔒` — nono profile active
- `N ext` — extension count
- Indicators omitted when nothing to show

#### `-vv` (Detailed)
Expands flavors as tree children with parenthetical explanations for all icons and states.

```
  ✓ skill-creator — Create new pi skills (allowed, 🔒 sandboxed)
    ├── user — Create skills in user directory (default)
    └── minimal — Minimal skill template

  ✗ untrusted-mode — Experimental mode (denied)
    ├── safe — Run without network (default)
    └── full — Full access

  ⚠ broken-mode (invalid: missing required field "description")
```

- All icons get parenthetical explanations: `(allowed)`, `(unknown)`, `(denied)`, `(invalid: <reason>)`
- `🔒 sandboxed` in the mode's parenthetical if nono profile active
- `(default)` after the default flavor
- `(flavor required)` appended to mode parenthetical when `require_flavor` is true
- Tree markers: `├──` for non-last, `└──` for last flavor
- Blank line between modes for readability

#### `-vvv` (Debug)
All `-vv` content plus mode paths and flavor override keys. Not a full config dump — prompt content, extension paths, nono profile details, and cache state belong to `show`.

```
  ✓ skill-creator — Create new pi skills (allowed, 🔒 sandboxed)
    .pi/a_la_mode/skill-creator
    ├── user — Create skills in user directory (default)
    │   overrides: nono_profile, append_prompt
    └── minimal — Minimal skill template
        overrides: extensions
```

Adds to `-vv`:
- Mode directory path (relative for project modes, absolute for user modes)
- Flavor `override_config` keys listed per flavor (which fields, not the values)

#### `--format json`
Structured JSON to stdout. Verbosity tier controls field depth (same pattern as `show`).

#### Behavior
- `-u`/`--user` restricts to user modes only (omits project section)
- Modes that fail validation are always shown with `⚠` and the error — never hidden
- Sections with no modes are omitted
- Uses discovery cache for speed (as specified in the caching section)

### Show Command Output

The `show` command displays tiered mode information. Default output is human-readable; `--format json` produces a single JSON object to stdout with the same field sets.

#### Default (no verbosity flags)
Quick summary card:
- Name, description, source location (project/user/direct)
- Trust state (allowed/denied/unknown + content hash match)
- Flavors listed with names, aliases, descriptions; notes `require_flavor` / `default_flavor` if set
- Nono profile status (enabled → path, disabled, or not configured)
- Extension summary (count + discovery mode)

#### `-v` (Basic)
All default output plus config-level detail:
- Prompt source reference (e.g. `@PROMPT.md`, not the full text)
- Append prompt source reference
- `disable_pi_system_prompt` / `disable_pi_append_system_prompt` if `true`
- Explicit `cli_args` list
- Extension paths (pre-glob)
- Flavor `override_config` keys (which fields each flavor overrides, not the values)

#### `-vv` (Detailed)
All `-v` output plus resolved content:
- Full prompt content (with `@file` embeddings resolved)
- Extension paths after glob expansion
- Flavor override values
- Nono profile summary (key permissions/constraints)

#### `-vvv` (Full Debug)
All `-vv` output plus:
- Raw `config.json` content
- Full nono profile JSON
- Complete file embedding resolution chain
- Cache state (hit/miss, hash, cached_at)

#### `--format json`
Structured JSON output to stdout. Available at all verbosity levels — the verbosity tier controls how much data is included in the JSON (same field sets as above). Intended for scripting, editor integrations, and tooling.

#### Error Behavior
If the mode fails validation, `show` still displays what it can and appends validation errors at the end (rather than refusing to show anything). This makes it a useful debugging tool. Modes that don't exist produce a FATAL error.

#### Global Flags
- `-v, --verbose` - Basic verbose output (mode discovery, selection, execution)
- `-vv` - Detailed verbose output (config parsing, file resolution, extension discovery)
- `-vvv` - Full debug output (all operations, file contents, command construction)
- `-u, --user` - Operate on user modes only (in `~/.pi/a_la_mode/`)
- `--allow` - Skip trust prompts and auto-allow modes (execution command only)

#### Flavors
- Named mode variants defined in `config.json` under the `flavors` key
- Selected via dot notation after the mode name: `pie mode <mode-name>.<flavor>`
- Only one flavor can be active at a time
- Example: `pie mode skill-creator.user -- --verbose`
- Flavors may define `aliases` for shorter names (e.g., `pie mode skill-creator.u`)
- All flavor names and aliases must be unique across the mode's `flavors` object
- `require_flavor: true` in config makes a flavor mandatory — bare invocation prints help listing available flavors with descriptions. FATAL validation error if `require_flavor` is `true` but no `flavors` are defined
- `default_flavor` in config specifies which flavor to use when none is given
- `default_flavor` must reference a flavor key name (not an alias); validated at load time
- Parsing: split on first `.` — safe because mode names use `^[a-z0-9_-]+$` (no dots)
- Flavor names and aliases follow the same `^[a-z0-9_-]+$` pattern
- No collision with global flags — flavors use dot notation, not `--` prefix

#### Argument Separation
- Use `--` to separate pie mode arguments from pi arguments
- Everything after `--` is passed directly to the pi command
- Example: `pie mode -vv skill-creator -- --verbose --model gpt-4`

### Config Command

User-level configuration for pie mode, stored at `~/.pi/a_la_mode/.config.json`. Schema defined in `specs/pie-mode/config-schema.json`.

#### Supported Keys
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `file_embedding_size_limit` | string | `100KB` | Maximum file size for inline `@file` embedding. Accepts `B`, `KB`, `MB` suffixes. |
| `gc_stale_age_days` | integer | `30` | Days before lazy GC considers cache/approval entries stale. |

#### Behavior
- `pie mode config` — lists all keys with current values and defaults
- `pie mode config <key>` — shows the key's current value and default
- `pie mode config <key> <value>` — sets a value (validated against schema before writing)
- `pie mode config <key> --reset` — removes the key from `.config.json`, reverting to default
- Config file is created on first `config set` if it doesn't exist

## Debugging & Observability

### Verbose Output Levels
Progressive detail levels for troubleshooting mode discovery, loading, and execution:

#### `-v` (Basic)
- Mode discovery path and result
- Selected mode location and name
- Nono profile status (enabled/disabled)
- Extension count and auto-discovery status
- Final pi command being executed

#### `-vv` (Detailed)
- All `-v` output plus:
- Config.json parsing and validation results
- PROMPT.md and file embedding resolution
- Extension discovery details (found/skipped/invalid)
- System prompt composition and CLI flag construction
- Nono profile validation and setup

#### `-vvv` (Full Debug)
- All `-vv` output plus:
- Complete file system traversal during discovery
- Full config.json content
- All file read operations and content sizes
- Environment variable setup
- Complete nono command construction
- Pi extension loading sequence

### Argument Separation
Use `--` to separate pie mode arguments from pi arguments:
```bash
# Pass --verbose to pi, not pie mode
pie mode skill-creator -- --verbose

# Pass multiple flags to pi
pie mode code-reviewer -- --model claude-3.5-sonnet --no-extensions

# Combine pie mode verbosity with pi arguments
pie mode -vv skill-creator -- --verbose --extension /path/to/custom
```

### Active Mode Information
Custom "Pie a la mode" extension provides mode visibility within pi:

#### Mode Status Display
- Current mode name and description in pi TUI header/status bar
- Mode source location (project vs user vs direct path)
- Nono sandbox status indicator
- Active extensions from mode

#### Environment Integration
- Mode information passed to pi via environment variables:
  - `PIE_MODE_NAME`: Active mode name
  - `PIE_MODE_PATH`: Full path to mode directory
  - `PIE_MODE_SANDBOX`: "true" if nono profile active
  - `PIE_MODE_SOURCE`: "project", "user", or "direct"

#### Extension Features (Future)
- Mode-specific command palette
- Quick mode switching without exiting pi
- Mode configuration validation and hot-reload
- Sandbox permission status and controls

### Error Context Enhancement
Verbose modes enhance error reporting:
- Include discovery path traversal in "mode not found" errors
- Show config validation details for malformed modes
- Display file permission issues during mode loading
- Provide nono profile troubleshooting context

## Conflict Resolution

### Mode Name Conflicts
When multiple modes exist with the same name:

#### Project vs User Mode Precedence
- **Project modes** (`.pi/a_la_mode/`) take precedence over **user modes** (`~/.pi/a_la_mode/`)
- **Warning logged** when project mode overrides user mode: "Using project mode 'skill-creator' (overriding user mode)"
- **Path-based modes** (`pie mode /path/to/mode`) bypass name resolution entirely

#### Discovery Order
1. Project directory: `.pi/a_la_mode/<name>/`
2. User directory: `~/.pi/a_la_mode/<name>/`
3. Direct path: `/explicit/path/to/mode/`

### Configuration Merging
Prompt composition follows strict precedence order:

#### **Prompt Merge Order**
```
[Existing Pi System Prompt] ++
[Mode Prompt] ++
[Existing Pi Append System Prompt] ++
[Mode Append System Prompt]
```

- **Empty sections**: Missing or unspecified prompts become empty strings
- **CLI implementation**: Uses `--system-prompt` and `--append-system-prompt` flags
- **No file dependencies**: Does not rely on APPEND_SYSTEM.md files

#### **System Prompt Control**
Mode configuration supports disabling default pi prompts:

```json
{
  "disable_pi_system_prompt": true,
  "disable_pi_append_system_prompt": true,
  "prompt": "@CUSTOM_SYSTEM.md",
  "append_prompt": "@CUSTOM_APPEND.md"
}
```

**Result with disabled defaults**:
```
[Mode Prompt] ++
[Mode Append System Prompt]
```

### Extension Conflict Handling
Extension conflicts resolved by pi's existing mechanisms:

#### **Mode vs Pi Extensions**
- Mode extensions loaded via multiple `--extension` flags
- Pi handles duplicate/conflicting extensions automatically
- Mode extensions do not override pi's conflict resolution
- Load order: Pi defaults → Mode extensions → Explicit `--extension` args

#### **Extension Discovery Control**
```json
{
  "disable_extension_discovery": true,  // Disable pi's auto-discovery
  "extensions": ["./mode-specific.js"] // Only load mode extensions
}
```

### CLI Argument Precedence
Argument precedence when using `pie mode <name> -- <pi-args>`:

1. **Explicit pi arguments** (after `--`) - highest precedence
2. **Mode configuration** (`cli_args`, extensions, prompts)
3. **Pi defaults** - lowest precedence

#### **Example Resolution**
```bash
# Mode config: cli_args: ["--model", "claude-3.5-sonnet"]
pie mode skill-creator -- --model gpt-4o

# Result: --model gpt-4o (explicit arg wins)
```

### Environment Variable Conflicts
Mode-related environment variables:

- **`PIE_MODE_*` variables**: Set by pie mode, available to pi and extensions
- **No conflict with pi variables**: Uses separate namespace
- **Mode information**: Available to extensions and custom tools

## Performance & Caching

### Hybrid Discovery Caching
Two-tier caching strategy optimizing for different use cases:

#### **Fast Browsing Cache**
**Commands using cache**: `pie mode list`, `pie mode show <name>`
- **Cached data**: Mode names, descriptions, locations only
- **Cache location**: One file per directory scanned
- **Invalidation**: Directory timestamp checking
- **Benefits**: Instant mode browsing and tab completion

#### **Fresh Data for Critical Operations**  
**Commands bypassing discovery cache**: `pie mode <name>`, `pie mode validate <name>`
- **Always fresh**: Complete config parsing and file resolution
- **Security focus**: Trust-sensitive operations use authoritative data
- **Execution safety**: No risk of stale cache affecting behavior

### Content-Based Mode Caching
Pre-computed execution cache with comprehensive content validation:

#### **Content Hash Strategy**
**Hash includes ALL files in mode directory**:
- Every file's relative path + content (recursive)
- Any addition, removal, move, or edit invalidates cache and trust
- Content integrity tracking for change detection

```bash
# Hash calculation example
find mode-dir -type f | sort | while read file; do
  echo "$(realpath --relative-to=mode-dir "$file"):$(sha256sum "$file")"
done | sha256sum
```

#### **Pre-Computed Cache Contents**
**One cache file per mode containing**:
- **Fully embedded prompts**: All `@file_name` references resolved
- **All flavor configurations**: Every flavor variant pre-processed
- **Validated extensions**: Checked paths and loading order
- **Processed nono profiles**: Ready-to-execute sandbox configuration
- **Complete CLI arguments**: All mode and flavor arguments resolved

Cache files are stored in `~/.pi/a_la_mode/.cache/` using a `<mode-name>-<hash>.json` naming scheme, where `<hash>` is a truncated hash of the mode's full path. This avoids collisions between project and user modes with the same name.

```
~/.pi/a_la_mode/.cache/
├── skill-creator-a1b2c3d4.json    # from ./pi/a_la_mode/skill-creator
├── skill-creator-f7e83b12.json    # from ~/.pi/a_la_mode/skill-creator
└── code-reviewer-c4d5e6f7.json
```

```json
// ~/.pi/a_la_mode/.cache/skill-creator-a1b2c3d4.json
{
  "mode_path": "/Users/foo/project/.pi/a_la_mode/skill-creator",
  "content_hash": "a1b2c3d4e5f6...",
  "cached_at": "2024-03-31T10:30:00Z",
  "default_config": {
    "system_prompt": "/* fully embedded prompt content */",
    "append_prompt": "/* fully embedded append content */",
    "extensions": ["/full/path/to/ext1.js"],
    "cli_args": ["--model", "claude-3.5-sonnet"]
  },
  "flavor_configs": {
    "secure": {
      "nono_profile_path": "/path/to/secure-profile.json",
      "extensions": []
    }
  }
}
```

### Trust Integration
**Content-based trust verification with three states**:

Approval state is stored in `~/.pi/a_la_mode/.approvals.json`, using the same `<mode-name>-<hash>` keying as cache files. Approvals are machine-specific and not portable across machines (similar to direnv).

#### **Approval States**
```json
// ~/.pi/a_la_mode/.approvals.json
{
  "modes": {
    "skill-creator-a1b2c3d4": {
      "path": "/Users/foo/project/.pi/a_la_mode/skill-creator",
      "state": "allowed",           // "allowed" | "denied" | "unknown"
      "content_hash": "a1b2c3d4e5f6...",
      "last_verified": "2024-03-31T10:30:00Z"
    }
  }
}
```

#### **Trust Management Commands**
- `pie mode allow <name>` - Explicitly trust and allow a single mode
- `pie mode allow --all` - Bulk approve all discoverable project modes (does not override explicit denials)
- `pie mode allow --all --user` - Bulk approve all user modes
- `pie mode allow --all /path/to/a_la_mode/` - Bulk approve all modes in a specific directory
- `pie mode disallow <name>` - Explicitly deny mode execution
- Trust state separate from validation/caching

#### **Bulk Approval Output**
`pie mode allow --all` always shows a full status list with icons and descriptions:

```bash
$ pie mode allow --all
Found 4 modes in ./pi/a_la_mode/:
  ✓ skill-creator   Specialized mode for creating skills (already approved)
  + code-reviewer    Code review mode (will be approved)
  + spec-writer      Spec writing mode (will be approved)
  ✗ untrusted-mode   Untrusted experimental mode (denied, unchanged)
Approve 2 modes? [y/N]: y
Approved: code-reviewer, spec-writer
```

With `--force`, the confirmation prompt is skipped but output is still shown:

```bash
$ pie mode allow --all --force
Found 4 modes in ./pi/a_la_mode/:
  ✓ skill-creator   Specialized mode for creating skills (already approved)
  ✓ code-reviewer    Code review mode (approved)
  ✓ spec-writer      Spec writing mode (approved)
  ✗ untrusted-mode   Untrusted experimental mode (denied, unchanged)
```

Key rules:
- `--all` never overrides explicit `disallow` denials
- Always shows full list with status icons, names, descriptions, and parenthetical status
- `--force` skips the confirmation prompt but still prints results

#### **Execution Trust Flow**
```bash
pie mode skill-creator [--allow]
```

1. **`"allowed"`**: Execute immediately (cache hit if hash matches)
2. **`"unknown"`**: Prompt "Trust mode 'skill-creator'? [y/N]"
   - With `--allow`: Skip prompt, auto-allow
3. **`"denied"`**: Hard stop with error message

#### **Content Change Handling**
```bash
# After editing mode files
pie mode skill-creator
# ⚠️  Mode 'skill-creator' content has changed!
# Previous hash: a1b2c3d4e5f6...
# Current hash:  x9y8z7w6v5u4...
# Re-validate and trust updated mode? [y/N]:
```

**`--allow` flag works for**:
- First-time unknown modes
- Content-changed re-verification
- Skips all trust prompts

#### **Non-Interactive Environments (CI/Scripts)**
- If stdin is not a TTY and a trust prompt would be required, the mode fails with a FATAL error and a message suggesting `--allow` or pre-approving with `pie mode allow`
- `--allow` is the only non-interactive path for untrusted/changed modes
- Already-trusted modes (state `"allowed"` with matching hash) execute without prompts in any environment

### Validation Command Enhancement
**`pie mode validate <name>` behavior**:
- **Always** performs full recompute (no cache shortcuts)
- **Processes** all file embedding and flavor variants
- **Updates** performance cache with complete data
- **Updates** content hash for trust verification
- **Never** changes trust state (use `allow`/`disallow`)

**Performance benefit**: Run `validate` once, get instant execution afterward

```bash
pie mode validate skill-creator  # Pre-compute everything
pie mode skill-creator          # Instant execution (cache hit)
```

### Cache Invalidation
**Cache becomes invalid when**:
1. **Content changes**: Any file modification in mode directory
2. **Structure changes**: Files added/removed  
3. **Trust revocation**: User runs `disallow`
4. **Schema updates**: Pie mode version changes
5. **Manual**: `pie mode validate` always refreshes cache

**Cache benefits**:
- **Sub-second execution** for trusted modes
- **Complex modes supported**: Deep file embedding, many extensions
- **Security maintained**: Content verification on every access
- **Developer workflow**: Edit → validate → instant testing

### Garbage Collection
**Dual strategy for cleaning stale cache and approval entries**:

#### **Lazy Cleanup (Opportunistic)**
- Triggered only by `pie mode list`, and only if cache/approvals file is older than 30 days (configurable)
- Checks if cached/approved mode paths still exist, removes stale entries
- Not performed during `pie mode <name>` execution — no cleanup overhead on the hot path
- Lightweight — only checks path existence, no revalidation

#### **Explicit Cleanup (`pie mode gc`)**
- Full sweep of all `.cache/` files and `.approvals.json` entries
- Checks every stored path, removes entries where the mode directory no longer exists
- Useful for periodic cleanup or after removing many projects

## Needs Clarification

### Initial message pass-through
- Trailing arguments (without `--`) should be passed as an initial message to pi
- Example: `pie mode foo this is a message` behaves like `pi this is a message`, passing "this is a message" as an initial prompt
- Needs: Define interaction with `--` separator (flavor selection via dot notation eliminates flag/message ambiguity)

### Non-interactive mode flag
- A new flag to run a mode non-interactively, requiring a message argument
- Would pass `pi -p` under the hood
- Example: `pie mode foo -p "refactor this function"`
- Needs: Define flag name (`-p`/`--prompt`?), behavior when no message is provided, interaction with `--allow`

## Configuration Schema

The complete JSON schema for `config.json` is available at: **`specs/pie-mode/schema.json`**

### Key Schema Features:

- **Required fields**: `name`, `description`, and `schema_version` (currently `"1.0.0"`, semver format)
- **Name validation**: Must be lowercase alphanumeric with hyphens and underscores
- **Inline file embedding**: Any `@file_name` reference in `prompt` or `append_prompt` is replaced with file contents
- **System prompt control**: `disable_pi_system_prompt` and `disable_pi_append_system_prompt` for full control
- **File type handling**: Plain text files embedded inline; binary files become `@/full/path/to/file`
- **Recursive embedding**: Referenced files can contain their own `@file_name` references (with circular detection)
- **Extension management**: Auto-discovery from `extensions/` directory or explicit control
- **Flavors**: Named mode variants with configuration overrides, selected via dot notation
- **Strict validation**: `additionalProperties: false` prevents typos and undefined fields

### Schema Validation

Use `pie mode validate <name>` to verify:
- JSON schema compliance
- File reference integrity 
- Circular reference detection
- Path traversal prevention
- Size and depth limits

## Related Documentation

### Error Handling
- **Comprehensive error specification**: `specs/pie-mode/error-handling.md`
- Covers all possible failure modes across 8 execution phases
- Defines detection, handling, and recovery strategies for each error type
- Includes security considerations and abuse prevention

### Security & Validation
- **Complete security framework**: `specs/pie-mode/security.md`
- Trust verification system design (similar to direnv)
- File system protection and attack prevention
- Nono profile security and failure handling
- Phased implementation plan from MVP to enterprise security

### Examples
- Complete example available in `examples/pi_a_la_mode/skill_creator/`
- Demonstrates flavors, nono profiles, and append prompts

## Implementation Notes

- Uses pi's `--system-prompt` and `--append-system-prompt` CLI flags
- Integration with nono profiles for enhanced security
- All configuration details and directory structure have been defined
- Extension loading handled by pi's existing conflict resolution system

---

*This spec is a work in progress and will be updated iteratively.*