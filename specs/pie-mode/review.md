# Pie Mode Spec Review

**Date**: 2026-04-01
**Reviewed files**:
- `specs/pie-mode-feature.md` (main spec)
- `specs/pie-mode/schema.json` (config.json schema)
- `specs/pie-mode/config-schema.json` (user config schema)
- `specs/pie-mode/error-handling.md`
- `specs/pie-mode/security.md`
- `examples/pi_a_la_mode/skill_creator/` (complete example)
- `bin/pie` (current CLI entrypoint)
- `bin/pie-init`, `bin/pie-sandbox` (existing subcommands)



---

## Finding 6: Initial Message Pass-Through & Non-Interactive Mode Are Self-Identified Gaps

**Severity**: Acknowledged gap (in spec)
**Location**: Feature spec → "Needs Clarification" section

These are already flagged in the spec but worth tracking:
- **Initial message**: `pie mode foo this is a message` — this is simplified by the flavor redesign (dot notation eliminates flag/message ambiguity). Remaining question: interaction with `--` separator.
- **Non-interactive mode**: `-p` flag for `pi -p` pass-through — interaction with `--allow` and error behavior needs definition.

---

## Finding 7: Schema Has Both `prompt` Default and `PROMPT.md` Convention — Unclear Precedence

**Severity**: Ambiguity
**Location**: `schema.json` → `prompt` field, Feature spec → File Requirements, Error handling → Phase 3

The schema says `prompt` defaults to `"@PROMPT.md"`. The feature spec says PROMPT.md is part of the standard layout. But:

- If `config.json` omits the `prompt` field entirely, the default `@PROMPT.md` kicks in. If `PROMPT.md` doesn't exist, the error-handling spec says this is FATAL "if no prompt can be inferred."
- What does "inferred" mean here? Is there a fallback beyond `PROMPT.md`?
- Can a mode legitimately have no prompt at all? (e.g., it only provides extensions and cli_args). The schema doesn't make `prompt` required, but the default always tries to load PROMPT.md.
- Should modes that don't want a prompt set `"prompt": ""` explicitly? Or `"prompt": null`? The schema doesn't allow `null` for the `prompt` field.

---

## Finding 8: Sandbox Notification Injection Is Mentioned But Not Specified

**Severity**: Gap
**Location**: Feature spec → Nono Profile Support

The spec says: "When a nono profile is active, automatically inject sandbox notification into system prompt to prevent AI confusion about permission restrictions."

But there's no specification of:
- What text is injected?
- Where in the prompt merge order does it go?
- Is it configurable or suppressible?
- Does it appear in the cached prompt or is it added at execution time?

---

## Finding 9: Example Doesn't Match Directory Convention

**Severity**: Inconsistency
**Location**: `examples/pi_a_la_mode/skill_creator/` vs Feature spec → Directory Structure

The feature spec says modes live in `.pi/a_la_mode/` or `~/.pi/a_la_mode/`. The example is at `examples/pi_a_la_mode/skill_creator/`. This is fine as an example, but:

- The example uses subdirectories (`project_specific/`, `user_specific/`) for variant nono profiles and append prompts. This is a clever pattern but isn't described anywhere in the feature spec or schema.
- The example `config.json` references `"nono_profile": "project_specific/nono-profile.json"` and the `global` flavor overrides it to `"user_specific/nono-profile.json"`. The spec's standard layout shows `nono-profile.json` at the root. The example demonstrates a more advanced pattern that the spec should acknowledge.
- The example has no `extensions/` directory — which is fine, but there's no minimal example showing extension auto-discovery.

---

## Finding 10: `config.json` `name` Must Match Directory Name — Edge Cases

**Severity**: Ambiguity
**Location**: Feature spec → File Requirements

The spec says: "The `name` field must match the directory name — a mismatch is a FATAL validation error."

But:
- What about direct path mode usage (`pie mode /path/to/my-mode`)? The directory name might not match the `name` field if the user renamed the directory.
- What about symlinked directories? (Though symlinks are rejected for files, is the mode *directory itself* allowed to be a symlink?)
- The name validation regex is `^[a-z0-9_-]+$` — does the directory name get the same validation? What if a directory is named `My Mode`?

---

## Finding 11: `schema_version` Migration Path Is Hand-Waved

**Severity**: Design gap
**Location**: `schema.json` → `schema_version`, `config-schema.json` → `schema_version`

Both schemas define `schema_version` with `"const": "1.0.0"` and say "PATCH changes are auto-handled at runtime. MINOR and MAJOR changes are not yet supported; future versions may introduce a migration command."

- What does "auto-handled at runtime" mean for patch changes? If someone has `1.0.1`, does pie accept it? The `const: "1.0.0"` would reject it.
- The `const` constraint makes the schema reject *any* version other than `1.0.0`, contradicting the patch-handling claim.
- Should this be a `pattern` or `enum` instead of `const`?

---

## Finding 12: `disable_extension_discovery` vs Pi's `--no-extensions` Flag

**Severity**: Ambiguity
**Location**: `schema.json` → `disable_extension_discovery`, Feature spec → Extension Conflict Handling

The schema has `disable_extension_discovery` which maps to pi's `--no-extensions` (`-ne`) flag. But pi's help says:

> `--no-extensions, -ne` — Disable extension discovery (explicit -e paths still work)

This is a perfect match semantically. However:
- The feature spec's example shows `"disable_extension_discovery": true` alongside `"extensions": ["./mode-specific.js"]`. This would translate to `pi --no-extensions --extension ./mode-specific.js`. Does pi handle this correctly? (Pi's help says yes — explicit `-e` paths still work.)
- But what about pi's own *user-configured* extensions from `settings.json`? Does `--no-extensions` suppress those too? If a user has extensions in their pi settings, does the mode silently disable them? This could be surprising.
- Similarly, `--no-skills`, `--no-prompt-templates`, `--no-themes` exist in pi. Should modes be able to control those too?

---

## Finding 13: `cli_args` Security Posture Is Intentionally Permissive — But Warrants a Callout

**Severity**: Design note
**Location**: `security.md` → Code Execution Boundary, `schema.json` → `cli_args`

The security doc explicitly states: "`cli_args` are passed through verbatim — no sanitization." This is a deliberate decision, but:

- A mode could pass `--system-prompt "ignore all instructions"` via `cli_args`, overriding the mode's own prompt. Is this intentional?
- A mode could pass `--extension /path/to/malicious.js` via `cli_args` in addition to the extensions mechanism. No dedup or validation.
- A mode could pass `--no-skills --no-extensions` via `cli_args`, conflicting with the mode's own extension configuration.

The trust system is supposed to be the answer here ("you reviewed and approved it"), but it's worth documenting that `cli_args` is effectively arbitrary command injection into the pi invocation.

---

## Finding 14: Cache Key Collision Risk

**Severity**: Minor
**Location**: Feature spec → Performance & Caching

Cache files use `<mode-name>-<hash>.json` where `<hash>` is a "truncated hash of the mode's full path." But:

- How many characters of the hash? Truncation length isn't specified.
- With short truncation, collision risk increases for users with many modes.
- The approvals file uses the same keying — a collision there would be a security issue (approving one mode could inadvertently trust another).

---

## Finding 15: `pie mode gc` Behavior Details Missing

**Severity**: Gap
**Location**: Feature spec → Garbage Collection

The `gc` command and lazy cleanup are described at a high level but:

- Does `gc` produce output? What does it look like?
- Does it require confirmation before deleting entries?
- Does it respect verbosity flags for showing what it's cleaning?
- The lazy cleanup triggers on `pie mode list` when the file is >30 days old — is that the *file mtime* of `.approvals.json`/`.cache/`? Or a timestamp stored inside the file?

---

## Finding 16: No Specification for How `pie mode` Integrates into the Existing `pie` CLI

**Severity**: Gap
**Location**: `bin/pie` (current entrypoint)

The current `pie` CLI uses a `pie-<subcommand>` delegation pattern (dispatching to `pie-sandbox`, `pie-init`, etc.). The new `pie mode` command would need a `bin/pie-mode` script. This is straightforward given the existing pattern, but:

- The feature spec doesn't mention this implementation detail at all.
- Implementation language isn't specified — the existing scripts are bash. Is `pie-mode` also bash? The complexity (JSON parsing, schema validation, hash computation, glob expansion) suggests a more capable language might be needed.
- The spec should at least acknowledge the implementation vehicle.

---

## Finding 17: Pi's `--system-prompt` Replaces vs Appends — Semantic Risk

**Severity**: Clarification needed
**Location**: Feature spec → Prompt Merge Order, Pi CLI help

Pi's `--system-prompt` flag says: "System prompt (default: coding assistant prompt)." This implies it *replaces* the default prompt entirely.

The feature spec's merge order shows:
```
[Existing Pi System Prompt] ++ [Mode Prompt]
```

But if `--system-prompt` *replaces* the default, you can't get both the existing pi prompt AND the mode prompt concatenated — you get one or the other. The spec seems to assume concatenation semantics.

How does the mode *append* to pi's default system prompt without replacing it? The `--append-system-prompt` flag exists for appending. Does this mean the mode's PROMPT.md should actually go through `--append-system-prompt`, not `--system-prompt`?

The merge order diagram and the actual pi CLI semantics may be in conflict. This needs verification and the spec should document exactly which flags are used for which prompt slots.

---

## Finding 18: `config-schema.json` Has `required: ["schema_version"]` — But `config` Command Creates Empty File

**Severity**: Minor inconsistency
**Location**: `config-schema.json`, Feature spec → Config Command

The config schema requires `schema_version`, but the feature spec says: "Config file is created on first `config set` if it doesn't exist." If a user runs `pie mode config file_embedding_size_limit 200KB`, does the created file automatically include `schema_version: "1.0.0"`? This needs to be implicit behavior but isn't stated.

---

## Finding 19: `null` Semantics Need Consistent Definition Across Entire Config

**Severity**: Design gap
**Location**: `schema.json` — all nullable fields, flavor `override_config`

The current schema uses `null` inconsistently:
- `nono_profile: null` → "explicitly disabled, no sandboxing"
- `extensions: null` → "disable mode extensions"
- Flavor override fields with `null` → "return to default behavior"

The proposal is to unify: **`null` universally means "use the default value"** — both at the top level and in flavor overrides. This gives consistent semantics everywhere:

- Top-level `null` → same as omitting the field (use schema default)
- Flavor override `null` → revert to base config value (already the documented behavior)

This means the current `nono_profile: null` = "disable sandboxing" interpretation changes. To explicitly disable something, use the appropriate zero/empty value instead (e.g., `[]` for extensions, `false` for booleans). The `nono_profile` disable case needs a new mechanism — possibly `"nono_profile": ""` or a separate `"disable_nono": true` flag.

**Impact:** Affects `schema.json`, `config-schema.json`, feature spec, security doc, and the example. Needs careful design before updating.

---

---

## Resolved Findings

## Finding 1: `pie mode create` Has No Specification ✅

**Severity**: Gap
**Location**: Feature spec → Commands section

The `pie mode create` command is listed in the commands table and mentioned in several error recovery suggestions ("use `pie mode create`"), but there is no specification for how it works. The description says it uses a "specialized mode-creation mode" but:

- What is this mode-creation mode? Is it itself a pie mode? Where does it live?
- What does it scaffold — just a `config.json` + `PROMPT.md` template?
- How does the `-u` flag interact with create (project vs user location)?
- What validation does it perform at creation time?
- Does it launch pi interactively to help write the prompt, or is it purely a scaffolding command?

### Resolution

The `pie mode create` command has two operating paths:

**Default (pi-assisted creation):** `pie mode create <name>` validates the name (regex, reserved names, target directory doesn't already exist), scaffolds the directory structure with minimal templates, then launches pi using a **built-in mode-creation mode** that ships bundled with pie. This built-in mode is a fully hand-crafted pie mode (its own `config.json`, `PROMPT.md`, etc.) stored in pie's install directory. It receives context about the new mode (name, target path) and interactively helps the user write the PROMPT.md, configure flavors, decide on nono profiles, etc.

**Bare scaffolding:** `pie mode create <name> --bare` performs only the scaffolding step — creates the directory with template `config.json` (populated with name, description placeholder, schema_version) and an empty `PROMPT.md`. No pi launch.

**Common behavior for both paths:**
- `-u`/`--user` controls target: `~/.pi/a_la_mode/<name>/` vs `.pi/a_la_mode/<name>/`
- Validates name against `^[a-z0-9_-]+$` regex and reserved command names (`list`, `create`, `show`, `validate`, `allow`, `disallow`, `gc`, `config`)
- FATAL error if target directory already exists
- The built-in mode-creation mode is discovered via a special internal path, not through normal mode discovery

**Mode-creation mode override:** The built-in mode-creation mode can be overridden by a user or project mode with the same reserved name (e.g., a mode named `create` in `~/.pi/a_la_mode/` or `.pi/a_la_mode/`). Standard discovery precedence applies — project overrides user, user overrides built-in. This lets users customize the creation experience (e.g., with org-specific templates or conventions).

The feature spec's command table and description should be updated to reflect both paths. The built-in mode-creation mode itself is created by hand — no bootstrapping issue.

---

## Finding 2: `extensions` Default Glob vs Schema Semantics Are Unclear ✅

**Severity**: Ambiguity
**Location**: `schema.json` → `extensions` field, Feature spec → Extension loading

The schema defines `extensions` with `"default": ["extensions/*"]`. However:

- Is `extensions/*` a literal glob pattern that pie must expand, or conceptual shorthand for "auto-discover from extensions/ directory"?
- If it's a real glob, what glob syntax is supported? Just `*`? Recursive `**`?
- The feature spec says "auto-discovered from `extensions/` subdirectory" — this suggests flat directory scanning, not glob expansion.
- What happens if someone writes `"extensions": ["my-ext.js"]` — is that relative to the mode directory? The schema says "relative to mode directory" but the security doc's symlink/traversal rules need to also cover these paths explicitly in the schema description.
- What does `"extensions": null` mean vs `"extensions": []`? The schema allows `null` and says "disable mode extensions." Is `[]` also "no extensions" or does it re-enable auto-discovery?

The distinction between `null` (disable), `[]` (explicit empty list), and omitted (auto-discover) needs to be crisply defined.

### Resolution

**Real glob support with containment:** Each entry in the `extensions` array is a glob pattern, resolved relative to the mode directory. Pie's mode engine expands all globs, resolves each result to a full path, and performs a containment check — FATAL error if any expanded path escapes the mode directory. Symlink rules apply post-expansion (symlinks pointing outside the mode directory are rejected per existing security rules). Supported glob syntax: `*` (single level), `**` (recursive), `?` (single char).

**Relative path base:** All extension paths/globs are relative to the mode directory. Confirmed.

**Semantics of null/omitted/empty:** The `null` semantics across the entire config are being revisited (see Finding 19). For extensions specifically:
- Omitted → default `["extensions/*"]` auto-discovery
- `null` → same as omitted (use default) — see Finding 19 for rationale
- `[]` → explicit empty list, no mode extensions

The schema default of `["extensions/*"]` is confirmed as a real glob. The feature spec's "auto-discovered from extensions/ subdirectory" language should be updated to say "default glob `extensions/*` is expanded" for consistency.

---

## Finding 4: `pie mode show` Output Is Not Specified ✅

**Severity**: Gap
**Location**: Feature spec → Commands

The `show` command is listed but there's no specification of what it displays.

### Resolution

**Tiered human-readable output aligned with the existing `-v`/`-vv`/`-vvv` verbosity system, plus a `--format json` flag for programmatic access.**

#### Default (no flags) — quick summary card:
- Name, description, source location (project/user/direct)
- Trust state (allowed/denied/unknown + content hash match)
- Flavors listed with names, aliases, descriptions; notes `require_flavor` / `default_flavor` if set
- Nono profile status line (enabled → path, disabled, or not configured)
- Extension summary (count + discovery mode)

#### `-v` — adds config-level detail:
- All default output plus:
- Prompt source reference (e.g. `@PROMPT.md`, not the full text)
- Append prompt source reference
- `disable_pi_system_prompt` / `disable_pi_append_system_prompt` if `true`
- Explicit `cli_args` list
- Extension paths (pre-glob)
- Flavor `override_config` keys (which fields each flavor overrides, not the values)

#### `-vv` — adds resolved content:
- All `-v` output plus:
- Full prompt content (with `@file` embeddings resolved)
- Extension paths after glob expansion
- Flavor override values
- Nono profile summary (key permissions/constraints)

#### `-vvv` — full dump:
- All `-vv` output plus:
- Raw `config.json` content
- Full nono profile JSON
- Complete file embedding resolution chain
- Cache state (hit/miss, hash, cached_at)

#### `--format json` — structured output:
- Available at all verbosity levels; the verbosity tier controls how much data is included in the JSON (same field sets as above)
- Output is a single JSON object to stdout
- Intended for scripting, editor integrations, and tooling
- Human-readable output is the default; `--format json` must be explicitly requested

#### Behavior notes:
- Output is human-readable by default. `--format json` switches to structured JSON.
- `-u`/`--user` restricts discovery to `~/.pi/a_la_mode/` only — same meaning as the global flag.
- If the mode fails validation, `show` still displays what it can and appends validation errors at the end (rather than refusing to show anything). This makes it a useful debugging tool.
- Modes that don't exist produce a FATAL error (same as other commands).

**Impact:** Feature spec commands table needs the `--format json` flag added to `show`. The `--format` flag is scoped to `show` only for now — other commands (`list`, `config`) may adopt it later if needed.

---

## Finding 3: Flag Combination / Multi-Flag Behavior Undefined ✅

**Severity**: Gap
**Location**: `schema.json` → `flags`, Feature spec → Mode-Defined Flags

The flags system supports `override_config` per flag, but:

- What happens when multiple mode flags are passed simultaneously? E.g., `pie mode foo --secure --verbose-prompt`
- Are overrides merged? Deep-merged? Last-flag-wins?
- Can flags conflict (e.g., two flags both override `nono_profile` to different values)?
- The cache spec says "Every flag variant pre-processed" — does this mean every *combination* of flags? That's 2^N cache entries. Or just individual flags?

### Resolution

**Complete redesign: replace flags with flavors.** Instead of `--flag` style arguments, modes support **flavors** — named variants selected via dot notation:

```bash
pie mode skill-creator.global    # not: pie mode skill-creator --global
pie mode testmode.secure         # not: pie mode testmode --secure
```

**Key design:**
- Only one flavor can be active at a time. This eliminates the multi-flag combination problem entirely — no merge strategy, no conflicts, no 2^N cache explosion.
- The `.` separator is safe because mode names use `^[a-z0-9_-]+$` (no dots allowed). Parsing is: split on first `.`, left is mode name, right is flavor name.
- Flavor names and aliases follow the same `^[a-z0-9_-]+$` pattern as mode names.
- Each flavor has an optional `aliases` array (shorter alternative names), a `description`, and `override_config` (same structure as the current flag `override_config`).
- All flavor key names and all aliases must be unique across the entire `flavors` object.

**Flavor control (top-level keys):**
- `require_flavor` (boolean, default `false`): When `true`, a flavor must be active. Bare `pie mode testmode` prints help listing available flavors with descriptions. Top-level `prompt` is not required when enabled but can still be defined as a shared base prompt for all flavors. FATAL validation error if `true` but no `flavors` are defined.
- `default_flavor` (string): Specifies which flavor to use when none is given via dot notation. Must reference a flavor key name (not an alias). Validated at load time.
- These keys are independent. The typical use case is `default_flavor` set with `require_flavor` at its default of `false`. Setting both is valid but redundant — `default_flavor` already ensures a flavor is always active.

**Schema change:** The `flags` key in `config.json` is renamed to `flavors`. Each entry's `short`/`long` fields are replaced by an optional `aliases` array for shorter alternative names. The key name becomes the flavor name used after the dot. Two new top-level keys are added: `require_flavor` and `default_flavor`.

**Example (updated skill-creator):**
```json
{
  "name": "skill-creator",
  "flavors": {
    "user": {
      "aliases": ["u"],
      "description": "Create skills in user global directory (~/.pi/agent/skills)",
      "override_config": {
        "nono_profile": "user_specific/nono-profile.json",
        "append_prompt": "@user_specific/APPEND_PROMPT.md"
      }
    }
  }
}
```

**Caching:** One cache entry per flavor (linear, not exponential). Base mode + N flavors = N+1 cache entries.

**Impact:** Affects `schema.json` (flags → flavors, replace short/long with aliases, add require_flavor/default_flavor), feature spec (commands, argument parsing, reserved flags section → simplified), error handling (flag collision detection → flavor/alias uniqueness validation), and the example. Flavors don't collide with global CLI flags since they use dot notation, not `--` prefix.

---

## Finding 5: `pie mode list` Output Format Unspecified ✅

**Severity**: Gap
**Location**: Feature spec → Commands

`list` is described as "List all discoverable modes with descriptions, separated by project/user sections" but:
- What's the exact output format?
- How are project vs user modes visually separated?
- Does it show trust status (allowed/denied/unknown)?
- What does `-v` add to the list output?
- How does it handle modes that fail validation (show with warning? skip?)?

### Resolution

**Tiered output matching the `show` command pattern, with trust icons at all verbosity levels and `--format json` for programmatic access.**

#### Trust Icons (all levels)
- `✓` allowed
- `?` unknown
- `✗` denied
- `⚠` validation error (mode is broken/invalid)

#### Default (no flags)
Compact listing grouped by source. One line per mode: trust icon, name, description. No flavor, extension, or nono information at this level — use `show` for detail on `require_flavor`, `default_flavor`, etc.

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
Project modes:
  ✓ skill-creator     Create new pi skills             2 flavors · 🔒 · 3 ext
  ? code-reviewer     Code review and quality analysis  1 ext

User modes:
  ✓ spec-writer       Write project specifications      🔒
  ✗ untrusted-mode    Experimental mode                 1 flavor
  ⚠ broken-mode       (invalid: missing required field "description")
```

- `N flavors` — flavor count
- `🔒` — nono profile active
- `N ext` — extension count
- Indicators omitted when nothing to show

#### `-vv` (Detailed)
Expands flavors as tree children with parenthetical explanations for all icons and states.

```
Project modes:
  ✓ skill-creator — Create new pi skills (allowed, 🔒 sandboxed)
    ├── user — Create skills in user directory (default)
    └── minimal — Minimal skill template

  ? code-reviewer — Code review and quality analysis (unknown)

User modes:
  ✓ spec-writer — Write project specifications (allowed, 🔒 sandboxed)
    └── strict — Strict review mode

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
All `-vv` content plus mode paths and flavor override keys. Specifically **not** a full config dump — prompt content, extension paths, nono profile details, and cache state belong to `show`.

```
Project modes:
  ✓ skill-creator — Create new pi skills (allowed, 🔒 sandboxed)
    .pi/a_la_mode/skill-creator
    ├── user — Create skills in user directory (default)
    │   overrides: nono_profile, append_prompt
    └── minimal — Minimal skill template
        overrides: extensions

  ? code-reviewer — Code review and quality analysis (unknown)
    .pi/a_la_mode/code-reviewer
```

Adds to `-vv`:
- Mode directory path (relative for project modes, absolute for user modes)
- Flavor `override_config` keys listed per flavor (which fields each flavor overrides, not the values)

#### `--format json`
Structured JSON output to stdout. Verbosity tier controls field depth (same pattern as `show`).

#### Behavior
- `-u`/`--user` restricts to user modes only (omits project section)
- Modes that fail validation are always shown with `⚠` and the error — never hidden
- Sections with no modes are omitted
- Uses discovery cache for speed (as specified in the caching section)

**Impact:** Feature spec commands table needs `--format json` flag added to `list`. Feature spec needs a List Command Output section parallel to the existing Show Command Output section.
