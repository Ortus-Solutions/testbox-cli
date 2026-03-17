# TestBox CLI

```
████████╗███████╗███████╗████████╗██████╗  ██████╗ ██╗  ██╗      ██████╗██╗     ██╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗╚██╗██╔╝     ██╔════╝██║     ██║
   ██║   █████╗  ███████╗   ██║   ██████╔╝██║   ██║ ╚███╔╝█████╗██║     ██║     ██║
   ██║   ██╔══╝  ╚════██║   ██║   ██╔══██╗██║   ██║ ██╔██╗╚════╝██║     ██║     ██║
   ██║   ███████╗███████║   ██║   ██████╔╝╚██████╔╝██╔╝ ██╗     ╚██████╗███████╗██║
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝      ╚═════╝╚══════╝╚═╝
```

> The official TestBox CLI for CommandBox — run, scaffold, watch, and manage your tests from the command line with ease. 🚀

## 📋 Table of Contents

- [License](#license)
- [Version Compatibility](#version-compatibility)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Language Detection](#language-detection)
- [Running Tests](#running-tests)
- [Watching Tests](#watching-tests)
- [Scaffolding](#scaffolding)
- [Generating a Test Harness](#generating-a-test-harness)
- [Generating a Test Browser](#generating-a-test-browser)
- [Generating a Test Visualizer](#generating-a-test-visualizer)
- [Generating a TestBox Module](#generating-a-testbox-module)
- [Installation Management](#installation-management)
- [Documentation & Resources](#documentation--resources)
- [Credits & Contributions](#credits--contributions)

---

## License

Apache License, Version 2.0.

## System Requirements

- CommandBox **6.x+**

## Installation

Install the CLI via CommandBox:

```bash
box install testbox-cli
```

Once installed, all `testbox` commands become available in your CommandBox shell. You can always get help on any command by appending `--help`:

```bash
testbox run --help
testbox create bdd --help
testbox generate harness --help
```

---

## 🔍 Language Detection

The CLI automatically detects whether your project targets **BoxLang** 🟦 or **CFML** so that generated files use the correct syntax. BoxLang is the primary supported language.

### BoxLang Detection (checked in order)

1. The server running in the current directory is a BoxLang server
2. `box.json` contains `testbox.runner=boxlang`
3. `box.json` contains `language=boxlang`

### CFML Detection (fallback)

1. The server running in the current directory is a CFML server (Lucee or Adobe ColdFusion)
2. `box.json` contains `language=cfml`

You can also override language detection on any generator command by passing `--boxlang` or `--noBoxlang` explicitly.

---

## ▶️ Running Tests

The `testbox run` command executes your TestBox test suite via HTTP and renders the results in the CLI.

### Basic Usage

```bash
# Uses testbox.runner from box.json
testbox run

# Pass a URL directly
testbox run http://localhost:8080/tests/runner.cfm

# Use a relative path (requires a running CommandBox server in the current directory)
testbox run /tests/runner.cfm
```

### Named Runners

When you have multiple test environments, define named runner targets in your `box.json`:

```json
"testbox": {
    "runner": [
        {
            "server1": "http://localhost:8080/tests/runner.cfm",
            "server2": "http://localhost:9090/tests/runner.cfm"
        }
    ]
}
```

Then target a specific runner by name:

```bash
testbox run server1
testbox run server2
```

### Filtering Tests

Run only specific bundles, suites, or specs:

```bash
# Run a specific bundle
testbox run bundles=tests.specs.MyBDDSpec

# Run tests in a directory (dot notation)
testbox run directory=tests.specs

# Run only tests matching a suite name
testbox run testSuites="My Suite"

# Run only a specific spec
testbox run testSpecs="it should do something"

# Filter by labels
testbox run labels=unit
testbox run labels=integration excludes=slow
```

### Verbose Output

By default only failing test details are shown. Use `--verbose` to see all passing and skipped specs as well:

```bash
testbox run --verbose
```

### Ad-hoc URL Options

Pass arbitrary options to the runner URL:

```bash
# From the command line
testbox run options:opt1=value1 options:opt2=value2

# Persist them in box.json
package set testbox.options.opt1=value1
package set testbox.options.opt2=value2
```

### Output Formats for CI/CD

Produce multiple report formats from a single test run — ideal for CI pipelines:

```bash
# Generate JSON and ANT JUnit reports
testbox run outputFormats=json,antjunit

# Generate multiple formats and save with a custom file name
testbox run outputFormats=json,antjunit,simple outputFile=myresults
```

Available formats: `json`, `xml`, `junit`, `antjunit`, `simple`, `dot`, `doc`, `min`, `mintext`, `text`, `tap`, `codexwiki`

### 🌊 Streaming Mode (Real-Time Feedback)

Stream test results in real-time via Server-Sent Events (SSE) as each spec executes — no waiting for the full run to complete:

```bash
testbox run --streaming
```

> ℹ️ Streaming requires your TestBox runner to support SSE output. This is available natively when running TestBox on BoxLang or a compatible CFML server.

### Configuring the Runner in `box.json`

Store your run preferences in `box.json` so they apply automatically:

```bash
package set testbox.runner=http://localhost:8080/tests/runner.cfm
package set testbox.verbose=true
package set testbox.labels=unit
package set testbox.testSuites=MySuite
```

---

## 👀 Watching Tests

The `testbox watch` command monitors your source files for changes and re-runs your tests automatically — perfect for a tight feedback loop during development.

### Basic Usage

```bash
# Start watching (uses testbox.runner from box.json)
testbox watch
```

When a file changes, the screen clears and `testbox run` fires automatically with your configured options.

Press **Ctrl+C** to stop the watcher.

### Watch Options

```bash
# Watch specific file patterns
testbox watch paths=models/**.bx,tests/**.bx

# Set the polling delay (milliseconds, minimum 150ms)
testbox watch delay=1000

# Scope tests to a specific directory or bundles
testbox watch directory=tests.specs
testbox watch bundles=tests.specs.MySpec

# Filter by labels
testbox watch labels=unit
```

### Configuring the Watcher in `box.json`

Persist your watch preferences so they are picked up automatically:

```bash
package set testbox.watchPaths=/models/**.bx,/tests/**.bx
package set testbox.watchDelay=1000
package set testbox.verbose=false
package set testbox.labels=unit
```

> 💡 Make sure your server is already running and `testbox.runner` is configured in `box.json` before starting the watcher.

---

## 🏗️ Scaffolding

The `testbox create` commands scaffold new test files for you, automatically using BoxLang (`.bx`) or CFML (`.cfc`) syntax based on your project's [language detection](#language-detection).

### Create a BDD Spec

```bash
# Create a BDD spec in the current directory
testbox create bdd MySpec

# Create in a specific directory
testbox create bdd MySpec directory=tests/specs

# Use dot notation for nested paths
testbox create bdd myPackage.MySpec

# Create and immediately open in your editor
testbox create bdd MySpec --open

# Force BoxLang syntax
testbox create bdd MySpec --boxlang

# Force CFML syntax
testbox create bdd MySpec --noBoxlang
```

**Generated BoxLang BDD Spec (`MySpec.bx`):**

```js
/**
 * My BDD Test
 */
class extends="testbox.system.BaseSpec" {

    function beforeAll() { }

    function afterAll() { }

    function run( testResults, testBox ) {
        describe( "My First Suite", () => {

            it( "A Spec", () => {
                fail( "implement" );
            } )

        } )
    }

}
```

### Create an xUnit Test

```bash
# Create an xUnit test in the current directory
testbox create unit MyTest

# Create in a specific directory
testbox create unit MyTest directory=tests/specs

# Use dot notation for nested paths
testbox create unit myPackage.MyTest

# Create and immediately open in your editor
testbox create unit MyTest --open
```

**Generated BoxLang xUnit Test (`MyTest.bx`):**

```js
/**
 * My xUnit Test
 */
class extends="testbox.system.BaseSpec" {

    function beforeTests() { }
    function afterTests() { }
    function setup( currentMethod ) { }
    function teardown( currentMethod ) { }

    @Test
    @DisplayName "A beautiful xUnit Test"
    function myMethodTest() {
        fail( "implement it" )
    }

}
```

---

## 🧪 Generating a Test Harness

The `testbox generate harness` command scaffolds a complete `tests/` directory structure for your project — including a runner, `Application.bx`/`Application.cfc`, and a sample spec.

```bash
# Generate a harness in the current project
testbox generate harness

# Generate a harness in a specific project directory
testbox generate harness /path/to/myApp

# Force BoxLang harness
testbox generate harness --boxlang

# Force CFML harness
testbox generate harness --noBoxlang
```

> ⚙️ If TestBox is not already installed locally, the CLI will install it automatically before scaffolding the harness.

---

## 🌐 Generating a Test Browser

The `testbox generate browser` command creates a web-based test browser UI at `tests/browser/`. This gives you a visual, in-browser way to browse and run your test bundles.

```bash
# Generate in the current project
testbox generate browser

# Generate in a specific directory
testbox generate browser /path/to/myApp

# Force BoxLang
testbox generate browser --boxlang
```

The browser is placed at `tests/browser/` in your project and can be accessed via your web server once your server is running.

---

## 📊 Generating a Test Visualizer

The `testbox generate visualizer` command generates a standalone HTML-based test results visualizer at `tests/test-visualizer/`. Feed it a JSON test results file to get a beautiful visual breakdown of your test run.

```bash
# Generate the visualizer in the current project
testbox generate visualizer

# Generate in a specific directory
testbox generate visualizer /path/to/myApp
```

To use the visualizer:

1. Run your tests and export JSON results: `testbox run outputFormats=json outputFile=test-results`
2. Open `tests/test-visualizer/index.html` in your browser
3. Load the `test-results.json` file

---

## 📦 Generating a TestBox Module

The `testbox generate module` command scaffolds a new TestBox extension module — useful for packaging custom matchers, reporters, or test helpers.

```bash
# Create a module named "myModule" in the current directory
testbox generate module myModule

# Create the module in a specific directory
testbox generate module myModule tests/resources/modules

# Force BoxLang syntax
testbox generate module myModule --boxlang
```

---

## 🔧 Installation Management

### View TestBox Info

Display information about which TestBox installation the CLI is using — whether it is from your local project or the CLI-bundled copy:

```bash
testbox info
```

The output shows the active TestBox version, path on disk, and whether it is sourced from your local project or the CLI's own bundle. If no TestBox is found anywhere, you will be offered the option to install it.

### Reinstall the CLI-Bundled TestBox

The CLI ships with its own bundled copy of TestBox for use with output formatting and report generation. If this copy becomes outdated or corrupted, you can wipe and reinstall it:

```bash
# Reinstall the latest stable version
testbox reinstall

# Reinstall a specific version
testbox reinstall version=5.3.0

# Skip the confirmation prompt
testbox reinstall --force
testbox reinstall version=5.3.0 --force
```

> ℹ️ This command only affects the CLI-bundled copy of TestBox. It does **not** modify any TestBox installation inside your project.

---

## 📚 Documentation & Resources

Open the TestBox documentation or API docs directly from the CLI:

```bash
# Open the TestBox documentation site in your browser
testbox docs

# Search the docs for a specific topic
testbox docs search=matchers
testbox docs search=mocking

# Open the TestBox API docs
testbox apidocs
```

---

## ⚡ Quick Reference

| Command | Description |
|---------|-------------|
| `testbox run` | Execute tests via HTTP runner |
| `testbox run --streaming` | Stream test results in real-time |
| `testbox watch` | Watch files and re-run tests on change |
| `testbox create bdd <name>` | Scaffold a new BDD spec |
| `testbox create unit <name>` | Scaffold a new xUnit test |
| `testbox generate harness` | Generate a full `tests/` harness |
| `testbox generate browser` | Generate a web-based test browser UI |
| `testbox generate visualizer` | Generate an HTML test results visualizer |
| `testbox generate module <name>` | Scaffold a new TestBox extension module |
| `testbox info` | Show TestBox installation details |
| `testbox reinstall` | Reinstall the CLI-bundled TestBox |
| `testbox docs` | Open TestBox documentation in a browser |
| `testbox apidocs` | Open TestBox API docs in a browser |

---

## Credits & Contributions

I THANK GOD FOR HIS WISDOM IN THIS PROJECT ✝️

### The Daily Bread

> "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" — John 14:6
