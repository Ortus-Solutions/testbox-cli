# TestBox CLI - AI Coding Instructions

This is a CommandBox module providing CLI commands for TestBox framework test management. It generates test scaffolding, runs tests via HTTP runners, provides watch capabilities, and supports both CFML and BoxLang languages.

## Architecture & Key Components

**Command Structure**: Commands follow CommandBox's hierarchical structure in `/commands/testbox/` with subcommands in nested folders (e.g., `create/unit.cfc`, `generate/harness.cfc`). Each command extends `BaseCommand.cfc` which provides common functionality like BoxLang detection, TestBox installation management, and runner URL discovery.

**Dual Language Support**: Code generation supports both CFML and BoxLang via template selection in `/templates/cfml/` vs `/templates/bx/`. The key difference is BoxLang uses `class` keyword instead of `component` and includes `@Test` annotations.

**HTTP-Based Test Execution**: Unlike typical CLI runners, TestBox CLI executes tests via HTTP requests to runner URLs configured in `box.json`. The `run.cfc` command handles URL discovery, parameter building, and result processing from JSON responses.

**Template System**: Uses simple text templates with direct file copying rather than token replacement. BoxLang conversion is handled by `toBoxLangClass()` method that transforms `component` declarations to `class`.

## Key Detection & Configuration Patterns

**BoxLang Project Detection**: The `isBoxLangProject()` method in `BaseCommand.cfc` detects BoxLang projects via:
1. Server engine detection (`serverInfo.cfengine` contains "boxlang")
2. Package.json `testbox.runner` setting equals "boxlang"
3. Package.json `language` property equals "boxlang"

**TestBox Installation Management**: `ensureTestBox()` method automatically installs TestBox if not found locally, checking `/testbox` directory in webroot first, then CLI module path, with fallback to CommandBox installation.

**Runner URL Discovery**: `discoverRunnerUrl()` resolves test runner URLs from:
1. Direct URLs passed as arguments
2. `box.json` testbox.runner configuration (string or array of named runners)
3. Server resolution for relative paths (e.g., `/tests/runner.cfm`)

## Development Workflows

**Command Development**:
- Extend `BaseCommand.cfc` and use dependency injection (`property name="testingService" inject="TestingService@testbox-cli"`)
- Commands typically: validate paths → read templates → create directories → copy/write files
- Use `resolvePath()` for path resolution and `directoryCreate()` for safe directory creation

**Test Running Architecture**:
- Tests execute via HTTP calls to configured runners, not local execution
- JSON responses processed by `CLIRenderer.cfc` for formatted output
- Support for multiple output formats via post-processing with TestBox reporters
- Exit codes set based on test failures for CI integration

**Watch Mode Implementation**: Uses CommandBox's built-in file watching with configurable glob patterns and delays. Clears screen between runs and handles command exceptions gracefully to prevent watcher termination.

## Testing & Integration Patterns

**Module Configuration**: `ModuleConfig.cfc` only sets template path mapping - minimal configuration compared to other CLI modules. The module relies heavily on CommandBox's dependency injection and service layer.

**CLI Output Rendering**: `CLIRenderer.cfc` provides sophisticated test result formatting with color coding, progress indicators (`√`, `X`, `!!`, `-`), nested suite reporting, and tabular summaries. Supports both verbose and minimal output modes.

**Build Process**: Uses task-based builds in `/build/Build.cfc` with source copying, token replacement for versioning, API doc generation via DocBox, and artifact creation with checksums.
