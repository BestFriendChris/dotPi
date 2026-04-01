# Pie A La Mode Security & Validation

## Overview

Security considerations and validation mechanisms for the pie mode feature, covering trust verification, sandboxing, file system protection, and abuse prevention.

## Security Design

### Trust Verification System
**See**: `specs/pie-mode-feature.md` → Trust Integration section

- Direnv-like content-based trust with three states: `allowed`, `denied`, `unknown`
- Content hash covers ALL files in the mode directory (any change invalidates trust)
- Approval state stored in `~/.pi/a_la_mode/.approvals.json` using `<mode-name>-<hash>` keying
- Approvals are machine-specific, not portable across machines
- `--allow` flag skips trust prompts; `pie mode allow --all` never overrides explicit denials
- `pie mode disallow <name>` explicitly denies execution

### File System Security
**See**: `specs/pie-mode/schema.json`, `specs/pie-mode/error-handling.md` → Phase 2/3

- `@file_name` references validated during config processing
- Path traversal detection (canonicalize and reject escapes from mode directory)
- Circular reference detection with depth limits
- Binary files converted to `@/full/path/to/file` instead of inline embedding
- **Symlinks are never followed** — if a referenced file is a symlink, reject it with a clear error. This eliminates symlink-based attacks entirely and can be relaxed later if needed.
- **File size threshold**: 100KB default. Files exceeding this fall back to path substitution (`@/full/path/to/file`). Configurable via `pie mode config file_embedding_size_limit` (see `specs/pie-mode/config-schema.json`).
- **Permission pre-checking**: Pre-check file read permissions before attempting embedding. Produce a clear, specific error (e.g., "Cannot read PROMPT.md: permission denied") rather than relying on OS errors.

### Non-`@` Path Security
The same path security principles apply to `nono_profile` and `extensions` paths specified in `config.json`:

- **Must be relative**: All paths must be relative to the mode directory. Absolute paths are rejected.
- **No path traversal**: Canonicalize and reject paths that escape the mode directory (e.g., `../../etc/passwd`).
- **Symlinks are never followed**: Same rule as `@file` references — reject symlinks with a clear error.
- **Permission pre-checking**: Verify readability before passing to nono or pi.

### Nono Profile Failure Handling
**See**: `specs/pie-mode/error-handling.md` → Phase 4: Nono Integration

- Nono not installed: FATAL error with clear messaging
- Profile validation failures: FATAL with specific error details
- Runtime crashes: FATAL, user must fix profile or remove nono-profile.json
- Resource limits: WARNING, continue with degraded performance

### Code Execution Boundary

Pie is a thin launcher — the trust system is the security boundary.

- Once a user has reviewed and approved a mode, pie passes extensions and CLI args to pi as-is. Extension sandboxing, validation, and signing are pi's concern.
- Any files pie is responsible for resolving (e.g., auto-discovered extensions from `extensions/`) are validated to exist and be readable before being passed to pi. This is operational validation, not security gatekeeping.
- `cli_args` are passed through verbatim — no sanitization. The user explicitly trusted the mode's config, which includes its CLI args.
- Extension signing/validation is not pie's responsibility. Pi manages extension execution.

### Information Disclosure

- **No sanitization in verbose output** — if the user asked for `-vvv`, they want full debug info. They're running it on their own machine for their own modes. Redacting output makes debugging harder with no real security benefit.
- **Verbosity levels are the control** — sensitive details (environment variables, full file contents, config dumps) are naturally excluded from `-v` and `-vv` by the tiered output design (see feature spec → Verbose Output Levels). `-vvv` is explicitly "full debug" and shows everything.
- **User responsibility** — users should be cautious when sharing `-vvv` output (e.g., in bug reports).

## Deferred: Supply Chain Security (Phase 3)

No verification of mode authenticity or integrity beyond the local trust model.

### Current Gaps
- No mode signing or verification
- User and project modes can be tampered with (trust system detects changes but doesn't verify origin)
- No distribution security model
- No update/versioning security

### Future Questions
- Mode signing required for distribution?
- Checksum verification for shared modes?
- Repository trust model needed?

## Implementation Priorities

### **Phase 1: MVP Security**
- [ ] File system path restriction enforcement
- [ ] Symlink rejection enforcement
- [ ] File size threshold enforcement (100KB default)
- [ ] Permission pre-checking enforcement

### **Phase 2: Enhanced Security**
- [ ] Security event logging
- [ ] Log/output redaction policy (if user demand arises)

### **Phase 3: Enterprise Security**
- [ ] Supply chain security framework
- [ ] Mode signing and distribution
- [ ] Organization-wide mode policies
- [ ] Compliance and audit features

## Threat Model

### **Attack Scenarios**

#### **Malicious Mode Attack**
1. Attacker creates mode with path traversal in `@` references
2. User trusts mode without inspection
3. Mode reads sensitive files (SSH keys, credentials)
4. Information exfiltrated via prompt content

**Mitigation**: Path restrictions, symlink rejection, trust verification, permission pre-checking

#### **Extension Injection Attack**
1. Attacker modifies project mode to include malicious extension
2. Extension contains code execution payload
3. Extension runs with user permissions when mode loads
4. System compromise via JavaScript execution

**Mitigation**: Trust verification detects file changes, pi manages extension execution security

#### **Sandbox Bypass Attack**
1. User creates mode with nono profile
2. Attacker modifies profile to weaken restrictions
3. Mode appears sandboxed but has elevated access
4. Privilege escalation via profile manipulation

**Mitigation**: Trust verification detects profile changes, profile validation before execution

## Security Guidelines

### **For Mode Authors**
- Minimize file dependencies and external references
- Use explicit paths rather than relative references
- Validate all user inputs in custom extensions
- Document security implications of mode features
- Use least-privilege principles for nono profiles

### **For Mode Users**
- Review mode contents before trusting
- Understand sandbox implications and limitations
- Monitor mode changes and re-verify trust
- Use project-specific modes for sensitive work
- Report suspected malicious modes

### **For Pie Mode Implementation**
- Validate all file paths before resolution
- Pre-check permissions before file access
- Reject symlinks in `@` references
- Implement fail-safe defaults for security features
- Provide clear security status indicators
- Document security assumptions and limitations

---

*This security analysis will be updated as the supply chain security framework is designed.*
