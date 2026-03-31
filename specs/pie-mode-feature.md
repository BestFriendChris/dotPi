# Pie A La Mode Feature Spec

## Overview

A new feature for the `pie` CLI to support specialized operating modes - highly focused, task-specific configurations with predefined system prompts, extensions, and nono security profiles.

## Core Concept

Specialized operating modes that bundle together:
1. A focused system prompt (MODE.md) tailored for specific tasks
2. Optional nono security profile for sandboxing
3. Optional pi extensions to auto-load
4. Other configuration as needed

Examples:
- `pie mode skill-creator` - Optimized for creating new skills
- `pie mode spec-writer` - Focused on writing project specifications
- `pie mode code-reviewer` - Constrained to code quality and review tasks

## Key Components

### Named Modes
- Each mode defined in its own directory under `./pi/a_la_mode/` or `~/.pi/a_la_mode/`
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
- **Sandbox notification**: When `nono-profile.json` exists, automatically inject sandbox notification into system prompt to prevent AI confusion about permission restrictions

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
- **config.json**: Required, contains `name` and `description` fields (source of truth)
- **PROMPT.md**: Pure system prompt content without frontmatter
- **nono-profile.json**: Optional, enables sandboxed execution
- **extensions/**: Optional directory for auto-discovered extensions

## User Experience

### Primary Workflow
1. User runs `pie mode <mode-name>` or `pie mode /path/to/mode`
2. Mode discovery: project `./pi/a_la_mode/` → global `~/.pi/a_la_mode/` → direct path
3. If mode has `nono-profile.json`, launch with `nono run --profile <profile-location> -- pi`
4. Otherwise, launch `pi` normally
5. PROMPT.md content gets appended to system prompt via pi's CLI flags
6. Extensions loaded: auto-discovered from `extensions/` unless `config.json` specifies otherwise

### Mode Discovery
- **Project-specific modes**: `./pi/a_la_mode/` (takes precedence over global)
- **Global modes**: `~/.pi/a_la_mode/` (user-wide availability)
- **Direct path support**: `pie mode /path/to/mode` for custom locations
- **Discovery order**: Project → Global → Direct path

### Commands
- `pie mode [-v|-vv|-vvv] <mode-name> [--allow] [-- <pi-args>...]` - Launch pi with specified mode and optional pi arguments
- `pie mode list [-v|-vv|-vvv]` - List all discoverable modes with descriptions, separated by project/user sections
- `pie mode create [-v|-vv|-vvv] (-u) <name>` - Create new modes using specialized mode-creation mode, with validation against reserved command names
- `pie mode show [-v|-vv|-vvv] (-u) <name>` - Show mode details (description, location, flags). `-u`/`--user` shows only user modes
- `pie mode validate [-v|-vv|-vvv] (-u) <name>` - Validate mode directory structure, config.json schema compliance, and file reference integrity
- `pie mode allow [-v|-vv|-vvv] <name>` - Explicitly trust and allow mode execution
- `pie mode disallow [-v|-vv|-vvv] <name>` - Explicitly deny mode execution

#### Global Flags
- `-v, --verbose` - Basic verbose output (mode discovery, selection, execution)
- `-vv` - Detailed verbose output (config parsing, file resolution, extension discovery)
- `-vvv` - Full debug output (all operations, file contents, command construction)
- `-u, --user` - Operate on user modes only (in `~/.pi/a_la_mode/`)
- `--allow` - Skip trust prompts and auto-allow modes (execution command only)

#### Argument Separation
- Use `--` to separate pie mode arguments from pi arguments
- Everything after `--` is passed directly to the pi command
- Example: `pie mode -vv skill-creator -- --verbose --model gpt-4`

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
- Full config.json content (sanitized)
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
1. Project directory: `./pi/a_la_mode/<name>/`
2. User directory: `~/.pi/a_la_mode/<name>/`
3. Direct path: `/explicit/path/to/mode/`

### Configuration Merging
Prompt composition follows strict precedence order:

#### Prompt Merge Order
```
[Existing Pi System Prompt] ++
[Mode Prompt] ++
[Existing Pi Append System Prompt] ++
[Mode Append System Prompt]
```

- **Empty sections**: Missing or unspecified prompts become empty strings
- **CLI implementation**: Uses `--system-prompt` and `--append-system-prompt` flags
- **No file dependencies**: Does not rely on APPEND_SYSTEM.md files

#### System Prompt Control
Mode configuration supports disabling default pi prompts in config.json

## Conflict Resolution

### Mode Name Conflicts
When multiple modes exist with the same name:

#### **Project vs User Mode Precedence**
- **Project modes** (`.pi/a_la_mode/`) take precedence over **user modes** (`~/.pi/a_la_mode/`)
- **Warning logged** when project mode overrides user mode: `"Using project mode 'skill-creator' (overriding user mode)"`
- **Path-based modes** (`pie mode /path/to/mode`) bypass name resolution entirely

#### **Discovery Order**
1. Project directory: `./pi/a_la_mode/<name>/`
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
- Cryptographically secure content verification

```bash
# Hash calculation example
find mode-dir -type f | sort | while read file; do
  echo "$(realpath --relative-to=mode-dir "$file"):$(md5sum "$file")"
done | md5sum
```

#### **Pre-Computed Cache Contents**
**One cache file per mode containing**:
- **Fully embedded prompts**: All `@file_name` references resolved
- **All flag configurations**: Every flag variant pre-processed
- **Validated extensions**: Checked paths and loading order
- **Processed nono profiles**: Ready-to-execute sandbox configuration
- **Complete CLI arguments**: All mode and flag arguments resolved

```json
// ~/.pi/cache/modes/skill-creator.json
{
  "content_hash": "a1b2c3d4e5f6...",
  "cached_at": "2024-03-31T10:30:00Z",
  "default_config": {
    "system_prompt": "/* fully embedded prompt content */",
    "append_prompt": "/* fully embedded append content */",
    "extensions": ["/full/path/to/ext1.js"],
    "cli_args": ["--model", "claude-3.5-sonnet"]
  },
  "flag_configs": {
    "--secure": {
      "nono_profile_path": "/path/to/secure-profile.json",
      "extensions": []
    }
  }
}
```

### Trust Integration
**Content-based trust verification with three states**:

#### **Trust States**
```json
// ~/.pi/trusted-modes.json  
{
  "modes": {
    "./pi/a_la_mode/skill-creator": {
      "state": "allowed",           // "allowed" | "denied" | "unknown"
      "content_hash": "a1b2c3d4e5f6...",
      "last_verified": "2024-03-31T10:30:00Z"
    }
  }
}
```

#### **Trust Management Commands**
- `pie mode allow <name>` - Explicitly trust mode
- `pie mode disallow <name>` - Explicitly deny mode  
- Trust state separate from validation/caching

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

### Validation Command Enhancement
**`pie mode validate <name>` behavior**:
- **Always** performs full recompute (no cache shortcuts)
- **Processes** all file embedding and flag variants
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

## Needs Clarification

### 1. ~~**Error Handling & Troubleshooting**~~ ✅ **RESOLVED**
- Comprehensive error handling specification created
- Covers 42 distinct error categories across 8 execution phases
- Includes detection strategies, handling approaches, and recovery mechanisms
- See: `specs/pie-mode/error-handling.md`

### 2. ~~**Debugging & Observability**~~ ✅ **RESOLVED**
- **Verbose output levels**: Multiple verbose flags (`-v`, `-vv`, `-vvv`) for progressive detail
- **Argument separation**: Use `--` to pass arguments to underlying pi process (e.g., `pie mode foo -- --verbose`)
- **Active mode display**: Custom "Pie a la mode" extension shows current mode info in pi TUI
- See: Debugging & Observability section below

### 3. ~~**Conflict Resolution Details**~~ ✅ **RESOLVED**
- **Project vs user modes**: Project modes take precedence (more specific), with warning logged about override
- **Configuration merging**: Clear precedence order for prompt composition
- **CLI-based prompt merging**: Uses `--system-prompt` and `--append-system-prompt` flags instead of files
- See: Conflict Resolution section below

### 4. ~~**Security & Validation**~~ ✅ **RESOLVED**
- **Comprehensive security framework**: Trust verification, file system protection, sandbox safety
- **Threat model analysis**: Attack scenarios and mitigation strategies identified
- **Phased implementation plan**: MVP security through enterprise-grade features
- See: `specs/pie-mode/security.md`

### 5. ~~**Performance & Caching**~~ ✅ **RESOLVED**
- **Hybrid discovery caching**: Fast browsing (list/show) with fresh execution data
- **Content-based mode caching**: Pre-computed prompts, extensions, and flag variants
- **Integrated trust system**: Content hash validation with allow/disallow commands
- See: Performance & Caching section below

### 6. **Migration & Compatibility**
- No versioning strategy for mode format changes
- How to handle backward compatibility if schema evolves
- Migration path from simple configurations to modes

### 7. **Cache & Configuration Storage Locations**
- Where should performance cache files be stored? (`~/.pi/cache/modes/`? `~/.cache/pi-mode/`?)
- Where should trust configuration be stored? (`~/.pi/trusted-modes.json`? `~/.config/pi-mode/trust.json`?)
- Should cache respect XDG Base Directory Specification?
- Cache cleanup strategy for unused/old modes?
- Trust configuration backup and portability considerations?

## Configuration Schema

The complete JSON schema for `config.json` is available at: **`specs/pie-mode/schema.json`**

### Key Schema Features:

- **Required fields**: Only `name` and `description` are required
- **Name validation**: Must be lowercase alphanumeric with hyphens and underscores
- **Inline file embedding**: Any `@file_name` reference in `prompt` or `append_prompt` is replaced with file contents
- **System prompt control**: `disable_pi_system_prompt` and `disable_pi_append_system_prompt` for full control
- **File type handling**: Plain text files embedded inline; binary files become `@/full/path/to/file`
- **Recursive embedding**: Referenced files can contain their own `@file_name` references (with circular detection)
- **Extension management**: Auto-discovery from `extensions/` directory or explicit control
- **Custom flags**: Mode-specific flags with configuration overrides
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
- Demonstrates project vs user configurations, flags, nono profiles, and append prompts
- Shows practical implementation of all major features

## Implementation Notes

- Uses pi's `--system-prompt` and `--append-system-prompt` CLI flags
- Integration with nono profiles for enhanced security
- All configuration details and directory structure have been defined
- Extension loading handled by pi's existing conflict resolution system

---

*This spec is a work in progress and will be updated iteratively.*