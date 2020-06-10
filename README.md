# Version support for QMake projects

This project adds ability to automatically get version information from SCM (currently git only) and use it in QMake projects.

Tags should follow [Semantic Versioning](https://semver.org/) with optional [prefix](#configuring-qmake-scm).

## How to use

1. Copy `version.in` and `git.pri` to your project.  
   _(Alternatively include this project as a submodule)_
2. Include `git.pri` in your project `.pro`-file: `include(path/to/git.pri)`
3. Add `QSCM_HEADERS += $$PWD/version.in` line to your project `.pro`-file.
4. Include `version.h` and use defines (the file is created on the first build).
5. Use tags in the form `v1.2.3` in your project.

See next sections to find out how to create your own templates using [substitutions](#markdown-header-substitutions), change [version prefix](#configuring-qmake-scm)) and support exported (archived) repositories.

### [Optional] Make version control work with exported repository

When building from cloned repository `qmake-scm` obtains version information directly from SCM (git). But when repository was exported this source of information doesn't work anymore.

Fortunately there is a way to get some version information. Though it requires additional setup:

1. Add file `version.txt` to the root of your project with the following content:
    
    ```
    $Format:%D, %h$
    ```

2. Add `export-subst` attribute for this file:

    ```bash
    echo "version.txt export-subst" >> .gitattributes
    ```

    Changes must be commited to have an effect.

In general the name and the path of the versions file is not important. But content is. It is possible to change file path and name using  `QSCM_EXPORTED_VERSION_FILE` variable (defaults to `$$PWD/version.txt`).

To simplify initial project setup this project includes shell script `git_setup.sh` that copies `version.in`, `version.txt` and setups git attributes:

```bash
#!/bin/bash

BASEPATH=$(dirname $0)
cp -n $BASEPATH/git_version.txt version.txt
cp -n $BASEPATH/version.in version.in
echo "version.txt export-subst" >> .gitattributes
echo "Don't forget to commit changes"
```

## How it works

Project include file (`.pri`) defines "custom compiler" with name `qscm`. Compiler accepts input via variable `QSCM_HEADERS`. For each file listed in this variable it creates file with the same name and extension `.h`, so `version.in` becomes `version.h`. This file generated in the build directory. 

On unix platforms the output file is only updated if it is different to avoid triggering rebuild of files that include it.  
Windows platforms always update output file (MRs are welcome).

### Substitutions

Version header file generated using template substitution. Following pattern are defined:

* `@{QSCM_VERSION}`  
  Version string in the form `1.2.3` without prefix.  
  Also includes all other parts like pre-release identifiers and build numbers as they exist in the tag: `1.2.3rc.1+build`.

* `@{QSCM_SEMVER_SIMPLE}`  
  Version string containing only major, minor and patch numbers, for example 
  `1.2.3`.

* `@{QSCM_SEMVER_SUFFIX}`  
  The rest of the version string with stripped leading `-` and `+`.

* `@{QSCM_SEMVER_PREREL}`  
  Pre-release part of semantic version. Dot-delimited part that follows 
  version. Doesn include build metadata (starts after `+`).

* `@{QSCM_SEMVER_BUILD}`  
  Build metadata part of semantic version. Dot-delimited part that starts 
  after `+`.

* `@{QSCM_SEMVER}`  
  Version string that follows semantic versioning.  
  `@{QSCM_SEMVER}` = `@{QSCM_SEMVER_SIMPLE}` + `-` + `@{QSCM_SEMVER_PREREL}` + `+` + 
  `@{QSCM_SEMVER_BUILD}` (`+` is concatenation, pre-release and build metadata 
  parts are only added if they are not empty).

* `@{QSCM_SEMVER_MAJ}`  
  Major version number (integer).

* `@{QSCM_SEMVER_MIN}`  
  Minor version number (integer).

* `@{QSCM_SEMVER_PAT}`  
  Patch version number (integer).

* `@{QSCM_HASH}`  
  Commit id of the current commit. May include "+" as a sign of a dirty repository state (modified files).

* `@{QSCM_DISTANCE}`  
  Distance from the latest tag. Number greater or equal to zero.

* `@{QSCM_BRANCH}`  
  Current branch name

* `@{QSCM_PRETTY_VERSION}`  
  Version string that includes up to several components depending on their values:

    - *v&lt;version&gt; &lt;hash&gt;*: `v0.0.1 b232a77`.  
      Built from repository in clean state (no modified files) at tag `v0.0.1` and commit id `b232a77`.
    - *v&lt;version&gt; &lt;hash&gt;+*: `v0.0.1 b232a77+`.  
      Built from repository in dirty state (modified files) at tag `v0.0.1` and commit id `b232a77`.
    - *v&lt;version&gt; +&lt;distance&gt; &lt;hash&gt;*: `v0.0.1 +1 b232a77`.  
      Built from repository in clean state (no modified files) at commit id `b232a77`, one commit away of tag `v0.0.1`.
    - *v&lt;version&gt; +&lt;distance&gt; &lt;hash&gt; (@&lt;branch&gt;)*: `v0.0.1 +1 b232a77 (@hotfix/my-fix)`.  
      Built from repository in clean state (no modified files) at commit id `b232a77`, one commit away of tag `v0.0.1` in branch `hotfix/my-fix`.

    **Not all possible combinations are shown above**.

### Default header template 

**Before substitution:**

```cpp
#define VERSION "@{QSCM_VERSION}"
#define QSCM_SEMVER "@{QSCM_SEMVER}"
#define QSCM_SEMVER_SIMPLE "@{QSCM_SEMVER_SIMPLE}"
#define QSCM_SEMVER_MAJ @{QSCM_SEMVER_MAJ}
#define QSCM_SEMVER_MIN @{QSCM_SEMVER_MIN}
#define QSCM_SEMVER_PAT @{QSCM_SEMVER_PAT}
#define QSCM_SEMVER_SUFFIX "@{QSCM_SEMVER_SUFFIX}"
#define QSCM_HASH "@{QSCM_HASH}"
#define QSCM_DISTANCE @{QSCM_DISTANCE}
#define QSCM_BRANCH "@{QSCM_BRANCH}"
#define QSCM_PRETTY_VERSION "@{QSCM_PRETTY_VERSION}"
```

**After substitution (sample):**

```cpp
#define VERSION "1.2.3rc.2+build.4567"
#define QSCM_SEMVER "1.2.3-rc.2+build.4567"
#define QSCM_SEMVER_SIMPLE "1.2.3"
#define QSCM_SEMVER_MAJ 1
#define QSCM_SEMVER_MIN 2
#define QSCM_SEMVER_PAT 3
#define QSCM_SEMVER_SUFFIX "rc.2+build.4567"
#define QSCM_HASH "c1cec22"
#define QSCM_DISTANCE 1
#define QSCM_BRANCH "master"
#define QSCM_PRETTY_VERSION "v1.2.3-rc.2+build.4567 +1 c1cec22"
```

## Configuring QMake SCM

QMake SCM defines several variables that can be defined before including the `.pri` file to alter behavior.

* `QSCM_VERSION_PREFIX`  
    Tag version prefix that should be stripped from the tag name before further processing. Also influences names of the tags `qmake-scm` will consider. Calls `git describe` with `--match="<QSCM_VERSION_PREFIX>*"` argument.

    Default value is `v`.

    Can be used to build multiple projects in one repository each with own version.

* `qscm_debug` (`CONFIG` option)  
    Enable debug output from `qmake-scm`.

    Use `CONFIG+=qscm_debug` when calling `qmake` or in project file.

* `qscm_no_version_setup` (`CONFIG` option)  
    Turn off setup of standard `qmake` variables related to version.

    Default is to setup the following variables:

  
        VERSION = $$QSCM_SEMVER
        VER_MAJ = $$QSCM_SEMVER_MAJ
        VER_MIN = $$QSCM_SEMVER_MIN
        VER_PAT = $$QSCM_SEMVER_PAT
  

* `qscm_no_force_qmake` (`CONFIG` option)  
  Starting from version 1.2 QMake SCM calls `qmake` to update version 
  information with every build. This can be turned off by using 
  `qscm_no_force_qmake`.  
  Added in version `1.2`.


## Testing

Tests for this project are maintained in a separate repository [QMake SCM Tests](https://gitlab.com/dm0/qmake-scm-tests).

A separate repository allows to keep code of this repository clean.


## Known issues

1. Some versions of Qt on windows platform have a bug resulting in `sed` 
    (invoked via qmake) running forever on files containing windows line 
    endings (see https://bugreports.qt.io/browse/QTBUG-80443).

    The solution is to save file with unix line endings and turn of crlf conversion via git attributes (`.gitattributes`):

        **/version.in -crlf

2. Some VCS hostings (at least GitLab) fetch not all references in their CI
    builds. This results in branch information is not available and branch
    name reported as master.

    A workaround is to run `git fetch` before building your project.