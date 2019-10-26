# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
Unreleased changes will be added to this section.

### Added
* Pre-release version information and build metadata are now parsed separately.
  Added substitutions: `@{QSCM_SEMVER_PREREL}` and `@{QSCM_SEMVER_BUILD}`.

### Fixed
* Fixed `QSCM_SEMVER_SIMPLE` substitution was not replaced while generating 
  header.
* Fixed handling of exported repositories with missing version file (default 
  is`version.txt`).
* Fixed handling of version strings containing build metadata without 
  pre-release version (they had `-` prefix instead of `+`).

### Changed
* QMake SCM now calls `qmake` with every build to always have accurate version 
  information.  
  A new `CONFIG` option `qscm_no_force_qmake` can be used to 
  revert to the previous behavior (get version information only at `qmake` 
  call).
* Untracked (and not ignored) files now commit to dirty state of the repo.
* Minor improvements in debug messages.


## 2019-07-30 [v1.1.1]

## Fixed
* `QSCM_SEMVER` to not end with `-` if `QSCM_SEMVER_SUFFIX` is empty

## 2019-05-14 [v1.1.0]

### Fixed
* `QSCM_SEMVER` now follows semantic versioning.  
  This variable previously contained only simple version information in `x.y.z`
  format.  
  This variable is different from `QSCM_VERSION` in that it contains normalized
  version with required dash after the `x.y.z` part.

### Added
* `QSCM_SEMVER_SIMPLE` variable contains simple version number (without 
  suffix).

### Changed
* On Unix platforms except for mac `VERSION` variable is set to contain full
  semantic version. Windows and mac platforms use simple version.

[v1.1.0]: https://gitlab.com/dm0/qmake-scm/compare/v1.0.0...v1.1.0


## 2018-11-16 v1.0.0
Public release of the project.


[Unreleased]: https://gitlab.com/dm0/qmake-scm/compare/v1.1.0...develop