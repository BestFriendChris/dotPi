# Pie Mode Error Handling Specification

## Overview

This specification defines all possible error conditions in the pie mode system and their handling strategies. The pie mode system has multiple failure points across different phases of execution, each requiring specific error detection, reporting, and recovery mechanisms.

## Error Classification

Errors are classified by **Phase** (when they occur) and **Severity** (impact level):

### Severity Levels
- **FATAL**: Complete mode failure, cannot proceed
- **WARNING**: Degraded functionality but mode can continue
- **INFO**: Non-critical issues that don't affect functionality

### Error Phases
1. **Command Parsing & Mode Discovery**
2. **Configuration Loading & Parsing** 
3. **Content Validation & Security**
4. **Nono Integration**
5. **Pi Integration**
6. **Runtime & Operational**
7. **User Experience & Recovery**
8. **Trust & Verification**

## Phase 1: Command Parsing & Mode Discovery

### Input Validation Failures

#### Invalid Mode Name Characters
- **Error**: User provides shell injection attempts (`pie mode "rm -rf /"`)
- **Severity**: FATAL
- **Detection**: Regex validation on mode name input
- **Handling**: Reject with clear error message, suggest valid characters
- **Recovery**: None - user must provide valid input

#### Reserved Command Conflicts
- **Error**: User tries to create mode named "list", "create", "show", "validate"
- **Severity**: FATAL
- **Detection**: Check against reserved command list during creation
- **Handling**: Reject with list of reserved names
- **Recovery**: User must choose different name

#### Empty/Whitespace-Only Mode Names
- **Error**: `pie mode "   "`
- **Severity**: FATAL
- **Detection**: Trim input and check if empty
- **Handling**: Reject with "Mode name cannot be empty" error
- **Recovery**: User must provide non-empty name

#### Extremely Long Mode Names
- **Error**: DoS via filesystem limits (>255 characters)
- **Severity**: FATAL
- **Detection**: Length validation before filesystem operations
- **Handling**: Reject with maximum length message
- **Recovery**: User must provide shorter name

#### Unicode/Encoding Issues
- **Error**: Non-ASCII characters causing filesystem problems
- **Severity**: WARNING
- **Detection**: Character encoding validation
- **Handling**: Warn about potential compatibility issues, allow with confirmation
- **Recovery**: Continue with warning or user cancels

### Mode Discovery Failures

#### Mode Not Found Anywhere
- **Error**: Neither project, global, nor direct path exists
- **Severity**: FATAL
- **Detection**: Check all discovery locations sequentially
- **Handling**: Show attempted locations and suggest `pie mode list` or `pie mode create`
- **Recovery**: User creates mode or uses existing one

#### Permission Denied
- **Error**: Can't read mode directories due to filesystem permissions
- **Severity**: FATAL
- **Detection**: Catch filesystem permission errors
- **Handling**: Show specific directory with permission issue and suggest fix
- **Recovery**: User fixes permissions or uses different location

#### Broken Symlinks
- **Error**: Mode directory is a dead symlink
- **Severity**: FATAL
- **Detection**: Check if symlink target exists
- **Handling**: Report broken symlink and suggest removal/fix
- **Recovery**: User fixes symlink or removes it

#### Circular Symlinks
- **Error**: Infinite recursion in directory traversal
- **Severity**: FATAL
- **Detection**: Track visited paths during traversal
- **Handling**: Report circular reference chain
- **Recovery**: User breaks circular reference

#### Path Traversal Attacks
- **Error**: `pie mode ../../../etc/passwd`
- **Severity**: FATAL
- **Detection**: Canonicalize paths and validate they're within allowed directories
- **Handling**: Reject with security warning
- **Recovery**: User provides valid path

#### Network Path Timeouts
- **Error**: User provides UNC/NFS paths that timeout
- **Severity**: FATAL
- **Detection**: Timeout on directory access operations
- **Handling**: Report network timeout and suggest local path
- **Recovery**: User provides local path or fixes network

#### Special Filesystem Objects
- **Error**: Mode "directory" is actually a device file, FIFO, etc.
- **Severity**: FATAL
- **Detection**: Check file type before treating as directory
- **Handling**: Report unexpected file type
- **Recovery**: User provides actual directory

### Directory Structure Validation

#### Empty Mode Directory
- **Error**: Directory exists but contains no files
- **Severity**: FATAL
- **Detection**: Check for required files after directory access
- **Handling**: Report missing required files and suggest template
- **Recovery**: User populates directory or uses `pie mode create`

#### Mixed File Types
- **Error**: config.json is actually a directory, etc.
- **Severity**: FATAL
- **Detection**: Verify expected files are actually files
- **Handling**: Report specific file type mismatches
- **Recovery**: User fixes file types

#### Filesystem Corruption
- **Error**: Directory listing fails mid-enumeration
- **Severity**: FATAL
- **Detection**: Catch I/O errors during directory traversal
- **Handling**: Report filesystem corruption and suggest fsck
- **Recovery**: User repairs filesystem

#### Case Sensitivity Conflicts
- **Error**: `CONFIG.json` vs `config.json` on case-insensitive filesystems
- **Severity**: WARNING
- **Detection**: Check for multiple case variants of filenames
- **Handling**: Warn about potential cross-platform issues
- **Recovery**: Continue with found file, warn user

## Phase 2: Configuration Loading & Parsing

### config.json Issues

#### Missing config.json
- **Error**: Required file doesn't exist
- **Severity**: FATAL
- **Detection**: File existence check
- **Handling**: Report missing file and suggest template
- **Recovery**: User creates config.json or uses `pie mode create`

#### Permission Denied
- **Error**: Can't read config.json
- **Severity**: FATAL
- **Detection**: File read permission check
- **Handling**: Report permission issue with specific file
- **Recovery**: User fixes file permissions

#### Invalid JSON Syntax
- **Error**: Malformed JSON, trailing commas, comments
- **Severity**: FATAL
- **Detection**: JSON parser error handling
- **Handling**: Report syntax error with line/column if available
- **Recovery**: User fixes JSON syntax

#### JSON Parsing Limits
- **Error**: Extremely large JSON files (DoS protection)
- **Severity**: FATAL
- **Detection**: File size check before parsing
- **Handling**: Report file too large with size limits
- **Recovery**: User reduces config size

#### Schema Validation Failures
- **Error**: Missing required fields, invalid types, malformed patterns
- **Severity**: FATAL
- **Detection**: JSON schema validation
- **Handling**: Report specific validation errors with field paths
- **Recovery**: User fixes config according to schema

#### Logical Inconsistencies
- **Error**: Flag overrides reference non-existent fields, circular references
- **Severity**: FATAL
- **Detection**: Post-parse validation of references and logic
- **Handling**: Report specific logical errors
- **Recovery**: User fixes logical inconsistencies

### Inline File Embedding Resolution

#### @path/file.md References Fail
- **Error**: Referenced file doesn't exist, permission issues, corrupted content
- **Severity**: FATAL
- **Detection**: File resolution during config processing
- **Handling**: Report specific file reference issues
- **Recovery**: User fixes references - no fallback to default content

#### Circular File References
- **Error**: File A contains @B, File B contains @A (or longer chains)
- **Severity**: FATAL
- **Detection**: Track reference chain during recursive resolution
- **Handling**: Report complete circular reference chain
- **Recovery**: User breaks circular references

#### Path Traversal in File References
- **Error**: @../../../etc/passwd attempts to escape mode directory
- **Severity**: FATAL
- **Detection**: Canonicalize referenced paths during resolution
- **Handling**: Reject with security warning
- **Recovery**: User provides valid file references within mode directory

#### Binary/Non-Text File References
- **Error**: Referenced file is binary or has invalid encoding
- **Severity**: INFO
- **Detection**: Content type and encoding validation during embedding
- **Handling**: Replace @file_name with @/full/path/to/file for pi to handle
- **Recovery**: Automatic - pi receives file path instead of embedded content

#### File Size Limits Exceeded
- **Error**: Referenced file is too large for inline embedding
- **Severity**: INFO
- **Detection**: File size check during embedding
- **Handling**: Replace @file_name with @/full/path/to/file (treat as binary)
- **Recovery**: Automatic - pi receives file path instead of embedded content

#### Recursive Embedding Depth Limit
- **Error**: File references nested too deeply (e.g., >10 levels)
- **Severity**: FATAL
- **Detection**: Track recursion depth during resolution
- **Handling**: Report maximum depth exceeded with reference chain
- **Recovery**: User reduces reference nesting depth

## Phase 3: Content Validation & Security

### PROMPT.md Issues

#### Missing Prompt File
- **Error**: Prompt file doesn't exist (default PROMPT.md or config-specified file)
- **Severity**: FATAL (if no prompt can be inferred), INFO (if config specifies alternative)
- **Detection**: File existence check for config-specified prompt file or default PROMPT.md
- **Handling**: If config.json specifies `prompt` field, use that file. If neither config nor PROMPT.md exists, fatal error.
- **Recovery**: User creates prompt file or specifies valid prompt in config.json

#### Empty PROMPT.md
- **Error**: Zero-length or whitespace-only content
- **Severity**: INFO
- **Detection**: Content size/whitespace check
- **Handling**: Info message about empty prompt
- **Recovery**: Mode runs without additional prompt content

#### Corrupted Content
- **Error**: Binary data, invalid encoding in prompt files
- **Severity**: FATAL
- **Detection**: Content type and encoding validation
- **Handling**: Report corrupted content, require user to fix
- **Recovery**: User fixes file content - no automatic cleaning attempted

#### Extremely Large Prompts
- **Error**: DoS via memory exhaustion from huge prompts
- **Severity**: FATAL
- **Detection**: File size limits before loading
- **Handling**: Report size limit exceeded
- **Recovery**: User reduces prompt size

#### Malicious Prompt Content
- **Error**: Attempts to override security, social engineering, prompt injection
- **Severity**: WARNING
- **Detection**: Content analysis for suspicious patterns
- **Handling**: Warn about potentially malicious content
- **Recovery**: Continue with warning or user confirmation

### Extension Validation

#### Extension Directory Issues
- **Error**: Permission denied, directory is file, broken symlinks
- **Severity**: WARNING
- **Detection**: Directory access validation
- **Handling**: Warn about extension loading issues
- **Recovery**: Skip extensions, mode continues

#### Extension File Problems
- **Error**: Corrupted files, invalid formats, malicious code
- **Severity**: WARNING
- **Detection**: Extension file validation
- **Handling**: Skip problematic extensions with warnings
- **Recovery**: Load remaining valid extensions

#### Extension Discovery Failures
- **Error**: Glob pattern fails, too many extensions
- **Severity**: WARNING
- **Detection**: Extension discovery error handling
- **Handling**: Report discovery issues, load what's possible
- **Recovery**: Use explicitly configured extensions

## Phase 4: Nono Integration

### Nono Availability

#### Nono Command Not Found
- **Error**: Not installed or not in PATH
- **Severity**: FATAL (if nono required), WARNING (if optional)
- **Detection**: Command existence check
- **Handling**: Report missing nono, suggest installation or disable sandboxing
- **Recovery**: Run without sandbox or user installs nono

#### Nono Version Incompatibility
- **Error**: Older version lacking required features
- **Severity**: FATAL
- **Detection**: Version check during nono validation
- **Handling**: Report version requirements
- **Recovery**: User upgrades nono

#### Nono Permission Issues
- **Error**: User lacks permissions to use nono
- **Severity**: FATAL
- **Detection**: Permission check during nono startup
- **Handling**: Report permission requirements
- **Recovery**: User fixes permissions or runs without sandbox

### Profile Processing

#### nono-profile.json Issues
- **Error**: Invalid JSON, schema violations, conflicting permissions
- **Severity**: FATAL
- **Detection**: Profile validation before nono execution
- **Handling**: Report specific profile issues
- **Recovery**: User fixes profile or disables sandboxing

#### Profile Creation Failures
- **Error**: Can't create temp profiles due to permissions/space
- **Severity**: FATAL
- **Detection**: Profile creation error handling
- **Handling**: Report creation failure reasons
- **Recovery**: User fixes filesystem issues

### Nono Execution

#### Nono Startup Failures
- **Error**: Process fails to start
- **Severity**: FATAL
- **Detection**: Process spawn error handling
- **Handling**: Report startup failure with nono error details
- **Recovery**: Run without sandbox

#### Nono Runtime Crashes
- **Error**: Process dies during execution
- **Severity**: FATAL
- **Detection**: Process monitoring and exit code handling
- **Handling**: Report crash details and suggest profile fixes
- **Recovery**: Restart without sandbox

#### Resource Limits
- **Error**: Nono hits memory/CPU/file limits
- **Severity**: WARNING
- **Detection**: Resource monitoring and limit detection
- **Handling**: Warn about resource constraints
- **Recovery**: Continue with degraded performance

## Phase 5: Pi Integration

### Pi Availability & Compatibility

#### Pi Command Not Found
- **Error**: Not installed or not in PATH
- **Severity**: FATAL
- **Detection**: Command existence check
- **Handling**: Report missing pi with installation instructions
- **Recovery**: User installs pi

#### Pi Version Incompatibility
- **Error**: Doesn't support required features
- **Severity**: FATAL
- **Detection**: Feature detection during pi validation
- **Handling**: Report version requirements and missing features
- **Recovery**: User upgrades pi or disables unsupported features

#### Pi Configuration Conflicts
- **Error**: Mode settings conflict with existing pi config
- **Severity**: WARNING
- **Detection**: Config validation before pi startup
- **Handling**: Warn about conflicts and show resolution options
- **Recovery**: Override with mode config or merge intelligently

### APPEND_SYSTEM Mechanism

#### Multiple APPEND_SYSTEM Sources
- **Error**: Both project and global APPEND_SYSTEM.md exist
- **Severity**: WARNING
- **Detection**: Check for existing APPEND_SYSTEM files
- **Handling**: Warn about conflicts and show merge strategy
- **Recovery**: Use precedence rules or merge content

#### APPEND_SYSTEM Failures
- **Error**: Can't write temporary APPEND_SYSTEM file
- **Severity**: FATAL
- **Detection**: File creation error handling
- **Handling**: Report write failure reasons
- **Recovery**: Use alternative prompt injection methods

### Extension Loading

#### Extension Conflicts
- **Error**: Mode extensions conflict with default extensions
- **Severity**: WARNING
- **Detection**: Extension conflict analysis during loading
- **Handling**: Report conflicts and resolution strategy
- **Recovery**: Use mode extensions with priority or merge

#### Extension Failures
- **Error**: Loading timeouts, crashes, unmet dependencies
- **Severity**: WARNING
- **Detection**: Extension loading error monitoring
- **Handling**: Skip failed extensions with detailed warnings
- **Recovery**: Continue with remaining extensions

### Pi Execution

#### Pi Startup Failures
- **Error**: Process fails to start with mode configuration
- **Severity**: FATAL
- **Detection**: Process spawn and startup monitoring
- **Handling**: Report startup failure with pi error details
- **Recovery**: Try fallback configuration

#### Pi Runtime Crashes
- **Error**: Mode configuration causes pi instability
- **Severity**: FATAL
- **Detection**: Process monitoring and crash detection
- **Handling**: Report crash details and suggest config fixes
- **Recovery**: Restart with simplified configuration

#### Resource Exhaustion
- **Error**: Mode uses too much memory/CPU
- **Severity**: WARNING
- **Detection**: Resource monitoring during execution
- **Handling**: Warn about high resource usage
- **Recovery**: Continue with monitoring or terminate if critical

## Phase 6: Runtime & Operational

### Concurrency Issues

#### Multiple Mode Instances
- **Error**: User runs multiple pie modes simultaneously
- **Severity**: WARNING
- **Detection**: Process/lock file detection
- **Handling**: Warn about concurrent execution
- **Recovery**: Allow with warnings or queue execution

#### File Locking Conflicts
- **Error**: Modes compete for same files
- **Severity**: WARNING
- **Detection**: File lock conflict detection
- **Handling**: Report lock conflicts and suggest resolution
- **Recovery**: Wait for locks or use alternative files

### Environment Issues

#### Working Directory Issues
- **Error**: CWD is invalid or inaccessible
- **Severity**: WARNING
- **Detection**: Directory access validation at startup
- **Handling**: Report CWD issues and suggest fixes
- **Recovery**: Use alternative working directory

#### Environment Variable Conflicts
- **Error**: Mode settings conflict with user environment
- **Severity**: INFO
- **Detection**: Environment analysis during setup
- **Handling**: Info about environment modifications
- **Recovery**: Apply mode environment with precedence

### Long-running Issues

Note: Interactive mode execution and memory management are out of scope for pie. Users manage these directly.

#### Cleanup Failures
- **Error**: Mode doesn't clean up temporary files on exit
- **Severity**: WARNING
- **Detection**: Cleanup verification after mode exit
- **Handling**: Report cleanup failures and manually clean
- **Recovery**: Force cleanup of known temporary files

## Phase 7: User Experience & Recovery

### Error Communication

#### Error Message Security
- **Error**: Errors leak sensitive information
- **Severity**: WARNING
- **Detection**: Error message content analysis
- **Handling**: Sanitize error messages before display
- **Recovery**: Show sanitized errors with option for detailed logs

#### Error Message Clarity
- **Error**: Users can't understand what went wrong
- **Severity**: INFO
- **Detection**: User feedback and error message analysis
- **Handling**: Provide clear, actionable error messages
- **Recovery**: Offer help resources and troubleshooting steps

#### Error Cascades
- **Error**: Initial error triggers secondary failures
- **Severity**: WARNING
- **Detection**: Error correlation and cascade detection
- **Handling**: Report root cause and stop cascade propagation
- **Recovery**: Focus on fixing root cause

#### Silent Failures
- **Error**: Mode appears to work but is misconfigured
- **Severity**: WARNING
- **Detection**: Configuration validation and health checks
- **Handling**: Report misconfigurations with impact assessment
- **Recovery**: Fix configuration or continue with warnings

### Recovery Scenarios

#### Partial Mode Initialization
- **Error**: Some components work, others fail
- **Severity**: WARNING
- **Detection**: Component-by-component initialization tracking
- **Handling**: Report partial success and degraded functionality
- **Recovery**: Continue with available functionality

#### Graceful Degradation
- **Error**: Mode should fall back to safe defaults
- **Severity**: INFO
- **Detection**: Feature availability assessment
- **Handling**: Fall back to safer configuration automatically
- **Recovery**: Continue with degraded but functional mode

#### State Corruption
- **Error**: Mode leaves system in bad state after failure
- **Severity**: FATAL
- **Detection**: State validation after failures
- **Handling**: Report corruption and initiate cleanup
- **Recovery**: Reset to clean state

#### Emergency Exits
- **Error**: User needs to force-quit malfunctioning mode
- **Severity**: INFO
- **Detection**: User interrupt signals
- **Handling**: Provide clean emergency shutdown
- **Recovery**: Cleanup and restore previous state

## Phase 8: Trust & Verification

### Mode Trust Verification
- **Scope**: Security handled through user trust verification (similar to direnv)
- **Implementation**: Content hash verification before mode execution
- **User Experience**: Prompt user to trust mode on first use or content changes
- **Note**: Malicious content detection and DoS protection are out of scope for pie tool

## Implementation Strategy

### Error Detection Framework
- Comprehensive validation at each phase boundary
- Resource monitoring throughout execution
- Security scanning for malicious content
- User input sanitization and validation

### Error Reporting Framework
- Structured error codes and categories
- Clear, actionable error messages
- Detailed logs for debugging (when safe)
- Progressive disclosure of error details

### Recovery Framework
- Graceful degradation strategies
- Automatic fallback to safe defaults
- Manual recovery procedures
- Emergency cleanup mechanisms

### Trust Framework
- User-based trust verification (similar to direnv)
- Content hash verification for mode integrity
- Explicit user consent for mode execution
- Trust database for approved modes

---

*This specification will be updated as new error conditions are discovered during implementation and testing.*