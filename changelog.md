# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

## [1.6.0] - 2024-09-23

## [1.5.0] - 2024-09-17

### Added

- Visualizer template missing.

### Fixed

- Overgreedy ignore, missing the `tests` folder in the final package

## [1.5.0] - 2024-09-17

### Added

- Internal refactoring for reuse of commands
- BoxLang support for all generation commands and templates
- You can now also use `--boxlang` to generate templates in BoxLang explicitly without detection
- Bundle `displayName` now showing up on the reports
- Updated the `run` command with tons of docs
- Mutually exclusive options for `run` command which never existed before for `bundles` and `directory`

### Bugs

- Using the `useTestBoxLocal` was not working correctly and re-downloading TestBox every time
- TestBox run should use webroot when resolving testbox location in ensureTestBox()

## [1.4.0] - 2024-02-29

### Added

- New Github Actions for testing and releases

* * *

## [1.3.0] - 2023-10-05

### Added

- New runners section on the test browser

### Fixed

- Aggregated colors for failures and errors on tests results output.

* * *

## [1.2.2] - 2023-08-18

### Fixed

- More issues with the CLI Renderer

* * *

## [1.2.1] - 2023-08-17

### Fixed

- `ensureTestBox()` was not looking at the right folder

* * *

## [1.2.0] - 2023-08-17

### Added

- If a localized version of TestBox cannot be found, then it installs one for you

### Fixed

- More fixes on runner not working
- Localized `testbox` location finding for `outputFormats` was using the wrong path

* * *

## [1.1.3] - 2023-08-16

### Fixed

- More fixes on runner not working

* * *

## [1.1.2] - 2023-08-16

### Fixed

- Missing another older injection

* * *

## [1.1.1] - 2023-08-16

### Fixed

- Invalid module name since we refactored, so all testing runners are failing.

* * *

## [1.1.0] - 2023-07-28

### Added

- TestBox 5 modules support
- New updated test harness

* * *

## [1.0.3] - 2023-05-17

- Invalid version fixed

* * *

## [1.0.2] - 2023-05-17

- Invalid version fixed

* * *

## [1.0.1] - 2023-05-17

- Invalid version fixed

* * *

## [1.0.0] - 2023-05-17

### Added

- New `testbox docs` command to open the TestBox docs in your browser and search as well: `testbox docs search="event handlers"`
- New `testbox apidocs` command to open the TestBox API Docs in your browser.
- Initial Creation of this project

[Unreleased]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.6.0...HEAD

[1.6.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.5.0...v1.6.0

[1.5.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.4.0...v1.5.0

[1.4.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.3.0...v1.4.0

[1.3.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.2.2...v1.3.0

[1.2.2]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.2.1...v1.2.2

[1.2.1]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.2.0...v1.2.1

[1.2.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.1.3...v1.2.0

[1.1.3]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.1.2...v1.1.3

[1.1.2]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.1.1...v1.1.2

[1.1.1]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.1.0...v1.1.1

[1.1.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.0.3...v1.1.0

[1.0.3]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.0.2...v1.0.3

[1.0.2]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.0.1...v1.0.2

[1.0.1]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.0.0...v1.0.1

[1.0.0]: https://github.com/Ortus-Solutions/testbox-cli/compare/v1.0.0...v1.0.0
