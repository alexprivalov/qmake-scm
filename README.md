# Version support for Qt projects

This project adds ability to automatically get version information from VCS (currently git only) and use it in Qt projects.

## How to use

1. Add `vcsqt` submodule to your project
2. Copy default header template `version.in` to you project (and add to version control). Or create your own header template using [substitutions](#markdown-header-substitutions).
3. Include `git.pri` in your Qt project file `include(vcsqt/git.pri)` (path depends on your project's structure).
4. Add header templates that should be processed to `VCSQT_HEADERS` variable: `VCSQT_HEADERS=$$PWD/version.in` (path depends on the header template file location).
5. Include `version.h` to you sources and use defines. Additionally `git.pri` also defines variable `VERSION` that influences version of shared library projects.
6. Use tags in the form `v1.2.3` to specify version of your project.

### [Optional] Make version control work with exported repository

When building from cloned repository `vcsqt` obtain version information directly from VCS (git). But when repository was exported (for example downloaded from Bitbucket) this source of information doesn't work anymore.

Fortunately there is a way to get some version information. Though it requires additional setup:

1. Add file `version.txt` to the root of your project with following content:

        $Format:%D, %h$

2. Add `export-subst` attribute for this file (don't forget to commit):

        echo "version.txt export-subst" >> .gitattributes

In general the name and the path of the versions file is not important. But content is. If you decided to use other file name or place it in some other location use variable `VCSQT_EXPORTED_VERSION_FILE`. This variable defaults to `$$PWD/version.txt`.

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

Project include file defines "custom compiler" with name `vcsqt`. Compiler accepts input via variable VCSQT_HEADERS. For each file listed in this variable it creates file with the same name and extension `.h`, so `version.in` becomes `version.h`. This file generated in the build directory. File only updated if new file differs from the previous to avoid triggering rebuild of files that include it.

Custom compiler uses version information fetched during qmake step. So in order to update version one should explicitly run qmake step after updating version in the repository.

Also it is trivial to make Qt Creator perform this step on every build (at the cost of a bit slower build). Specify following "Make arguments" in project setup page `qmake_all all`. This will run qmake step following build step on every build.

### Substitutions

Version header file generated using template substitution. Following pattern are defined:

`${VCSQT_VERSION}`
:   Version string in the form `1.2.3` (without leading "v").

`${VCSQT_HASH}`
:   Commit id of current commit. May include "+" as a sign of a dirty repository state (modified files).

`${VCSQT_DISTANCE}`
:   Distance from the latest tag. Number greater or equal to zero.

`${VCSQT_BRANCH}`
:   Current branch name

`${VCSQT_PRETTY_VERSION}`
:   Version string that includes up to several components depending on their values.

    * _v<version> <hash>_: `v0.0.1 b232a77`. Built from repository in clean state (no modified files) at tag `v0.0.1` and commit id `b232a77`.
    * _v<version> <hash>+_: `v0.0.1 b232a77+`. Built from repository in dirty state (modified files) at tag `v0.0.1` and commit id `b232a77`.
    * _v<version> +<distance> <hash>_: `v0.0.1 +1 b232a77`. Built from repository in clean state (no modified files) at commit id `b232a77`, one commit away of tag `v0.0.1`.
    * _v<version> +<distance> <hash> (@<branch>)_: `v0.0.1 +1 b232a77 (@hotfix/my-fix)`. Built from repository in clean state (no modified files) at commit id `b232a77`, one commit away of tag `v0.0.1` in branch `hotfix/my-fix`.

    *Not all possible combinations are shown above*.

#### Default header template 

**Before substitution:**

```h
#define VERSION "${VCSQT_VERSION}"
#define VCSQT_HASH "${VCSQT_HASH}"
#define VCSQT_DISTANCE ${VCSQT_DISTANCE}
#define VCSQT_BRANCH "${VCSQT_BRANCH}"
#define VCSQT_PRETTY_VERSION "${VCSQT_PRETTY_VERSION}"
```

**After substitution (sample):**

```h
#define VERSION "0.0.1"
#define VCSQT_HASH "c1cec22"
#define VCSQT_DISTANCE 1
#define VCSQT_BRANCH "master"
#define VCSQT_PRETTY_VERSION "v0.0.1 +1 c1cec22"
```
