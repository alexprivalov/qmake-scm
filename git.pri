isEmpty(QSCM_VERSION_PREFIX):QSCM_VERSION_PREFIX=v
isEmpty(QSCM_GIT): QSCM_GIT=git

# Check git exists
!system($$QSCM_GIT -C $$_PRO_FILE_PWD_ status): warning("Command 'git status' returned error.")

# sample output: v0.4.0-5-ga8152a7
QSCM_DESCRIBE=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ describe --long --tags --match="$$QSCM_VERSION_PREFIX*" 2>&1, true, QSCM_GIT_STATUS)

# If git failed then it either doesn't exist or failed to find a tag. Fallback to zero version.
!equals(QSCM_GIT_STATUS, "0") {
    qscm_debug: log("QSCM: git describe failed: " $$QSCM_DESCRIBE $$escape_expand(\n))
    QSCM_DESCRIBE=
}


QSCM_BRANCH=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ rev-parse --abbrev-ref HEAD)
QSCM_REPO_STATUS=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ status -s)

qscm_debug: log("QSCM_GIT_DESCRIBE:" $$QSCM_DESCRIBE $$escape_expand(\n))
qscm_debug: log("QSCM_GIT_BRANCH:" $$QSCM_BRANCH $$escape_expand(\n))
qscm_debug: log("QSCM_GIT_STATUS:" $$QSCM_REPO_STATUS $$escape_expand(\n))

# not running from repository or git unavailable
isEmpty(QSCM_BRANCH) {
    qscm_debug: log("QSCM: Failed to obtain information via Git" $$escape_expand(\n))
    # try to read version.txt file that should have been updated during export operation
    # sample data: HEAD -> master, tag: v0.0.3, 3e575e9
    isEmpty(QSCM_EXPORTED_VERSION_FILE): QSCM_EXPORTED_VERSION_FILE=$$PWD/version.txt
    QSCM_VERSION_INFO=$$cat($$QSCM_EXPORTED_VERSION_FILE)
    isEmpty(QSCM_VERSION_INFO) | isEqual(QSCM_VERSION_INFO, "$Format:%D, %h$") {
        warning("No version information available: building from unexported version")
        QSCM_DISTANCE=0
        QSCM_HASH=?
        QSCM_BRANCH=unknown
        QSCM_VERSION=0.0.0
    } else {
        QSCM_VERSION_INFO=$$replace(QSCM_VERSION_INFO, ",", )
        qscm_debug: log("QSCM_VERSION_INFO: " $$QSCM_VERSION_INFO $$escape_expand(\n))
        QSCM_VERSION_INFO_NUM_COMPONENTS=$$size(QSCM_VERSION_INFO)
        QSCM_VERSION_INFO_COMPONENT_3=$$member(QSCM_VERSION_INFO, 3)
        QSCM_HASH=$$last(QSCM_VERSION_INFO)
        QSCM_BRANCH=$$member(QSCM_VERSION_INFO, 2)
        QSCM_DISTANCE=0
        isEqual(QSCM_VERSION_INFO_COMPONENT_3, "tag:") {
            QSCM_VERSION=$$member(QSCM_VERSION_INFO, 4)
            QSCM_VERSION=$$replace(QSCM_VERSION, $$QSCM_VERSION_PREFIX, )
        }else {
            # no version information
            warning("No version information available (no tags)")
            QSCM_VERSION=0.0.0
        }
    }
}else {
    # detached head state
    isEqual(QSCM_BRANCH, "HEAD") {
        qscm_debug: log("QSCM: Detached head state" $$escape_expand(\n))

        QSCM_BRANCHES=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ branch -a --format=$$system_quote("%(refname:short)") --contains HEAD, lines)

        # Remove (HEAD detached ...) line, if any
        QSCM_BRANCHES -= $$find(QSCM_BRANCHES, ^$$re_escape("(HEAD"))
        QSCM_ORIGIN=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ remote)

        qscm_debug: log("QSCM_BRANCHES:" $$QSCM_BRANCHES $$escape_expand(\n))
        qscm_debug: log("QSCM_ORIGIN:" $$QSCM_ORIGIN $$escape_expand(\n))

        for(QSCM_BRANCH, QSCM_BRANCHES) {
            # strip remotes
            QSCM_BRANCH_PARTS=$$split(QSCM_BRANCH,"/")
            QSCM_BRANCH_PARTS-=$$QSCM_ORIGIN
            QSCM_BRANCH=$$join(QSCM_BRANCH_PARTS,/)

            QSCM_BRANCH_NAMES += $$QSCM_BRANCH
        }
        # if failed or contains master treat as master
        isEmpty(QSCM_BRANCH_NAMES) | contains(QSCM_BRANCH_NAMES, master): QSCM_BRANCH=master
        else: QSCM_BRANCH=$$first(QSCM_BRANCH_NAMES)
    }
    # has at least 1 tag
    !isEmpty(QSCM_DESCRIBE) {
        QSCM_DESCRIBE=$$replace(QSCM_DESCRIBE, $$QSCM_VERSION_PREFIX, )
        QSCM_DESCRIBE=$$split(QSCM_DESCRIBE, "-")

        QSCM_VERSION=$$member(QSCM_DESCRIBE, 0, -3)
        # join back if it was split
        QSCM_VERSION=$$join(QSCM_VERSION, -)
        QSCM_DISTANCE=$$member(QSCM_DESCRIBE, -2)
        QSCM_HASH=$$member(QSCM_DESCRIBE, -1)
        QSCM_HASH=$$section(QSCM_HASH,,2)
    }else {
        qscm_debug: log("QSCM: No tags found" $$escape_expand(\n))
        QSCM_DISTANCE=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ rev-list --count HEAD)
        QSCM_VERSION=0.0.0
        QSCM_HASH=$$system($$QSCM_GIT -C $$_PRO_FILE_PWD_ rev-parse --short HEAD)
    }
    !isEmpty(QSCM_REPO_STATUS): QSCM_HASH=$${QSCM_HASH}+
}

qscm_debug: log("QSCM_BRANCH:" $$QSCM_BRANCH $$escape_expand(\n))
qscm_debug: log("QSCM_VERSION:" $$QSCM_VERSION $$escape_expand(\n))
qscm_debug: log("QSCM_DISTANCE:" $$QSCM_DISTANCE $$escape_expand(\n))
qscm_debug: log("QSCM_HASH:" $$QSCM_HASH $$escape_expand(\n))

QSCM_PRETTY_VERSION=v$$QSCM_VERSION
greaterThan(QSCM_DISTANCE, 0):QSCM_PRETTY_VERSION += +$$QSCM_DISTANCE
QSCM_PRETTY_VERSION += $$QSCM_HASH
!isEqual(QSCM_BRANCH, master) {
    QSCM_PRETTY_VERSION += (@$$QSCM_BRANCH)
}
QSCM_SEMVER = $$QSCM_VERSION
QSCM_SEMVER_SUFFIX = $$QSCM_VERSION
QSCM_SEMVER_SUFFIX ~= s/^(\d+\.){0,2}\d+/
QSCM_SEMVER_SIMPLE = $$replace(QSCM_SEMVER,$$re_escape($$QSCM_SEMVER_SUFFIX),)

# Extract pre-release
QSCM_SEMVER_PREREL = $$QSCM_SEMVER_SUFFIX
QSCM_SEMVER_PREREL ~= s/\+[0-9A-Za-z.-]+$/
QSCM_SEMVER_PREREL ~= s/^-*/

# Extract buildinfo
QSCM_SEMVER_BUILD = $$QSCM_SEMVER_SUFFIX
QSCM_SEMVER_BUILD ~= s/^-?([0-9A-Za-z.-]+)/
QSCM_SEMVER_BUILD ~= s/^\+*/

# Remove leading "-" or "+" from prefix
QSCM_SEMVER_SUFFIX ~= s/^(-|\+)*/

QSCM_SEMVER=$${QSCM_SEMVER_SIMPLE}
!isEmpty(QSCM_SEMVER_PREREL):QSCM_SEMVER = $${QSCM_SEMVER}-$${QSCM_SEMVER_PREREL}
!isEmpty(QSCM_SEMVER_BUILD):QSCM_SEMVER = $${QSCM_SEMVER}+$${QSCM_SEMVER_BUILD}
QSCM_SEMVER_LIST = $$split(QSCM_SEMVER_SIMPLE, ".")
QSCM_SEMVER_MAJ = $$member(QSCM_SEMVER_LIST, 0)
QSCM_SEMVER_MIN = $$member(QSCM_SEMVER_LIST, 1)
QSCM_SEMVER_PAT = $$member(QSCM_SEMVER_LIST, 2)

qscm_debug: log("QSCM_VERSION:" $$QSCM_VERSION $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER:" $$QSCM_SEMVER $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_SIMPLE:" $$QSCM_SEMVER_SIMPLE $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_MAJ:" $$QSCM_SEMVER_MAJ $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_MIN:" $$QSCM_SEMVER_MIN $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_PAT:" $$QSCM_SEMVER_PAT $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_SUFFIX:" $$QSCM_SEMVER_SUFFIX $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_PREREL:" $$QSCM_SEMVER_PREREL $$escape_expand(\n))
qscm_debug: log("QSCM_SEMVER_BUILD:" $$QSCM_SEMVER_BUILD $$escape_expand(\n))


!qscm_no_version_setup {
    unix:!macx: VERSION = $$QSCM_SEMVER
    else: VERSION = $$QSCM_SEMVER_SIMPLE
    VER_MAJ = $$QSCM_SEMVER_MAJ
    VER_MIN = $$QSCM_SEMVER_MIN
    VER_PAT = $$QSCM_SEMVER_PAT
    qscm_debug: log("QSCM: Version setup:" $$escape_expand(\n))
    qscm_debug: log($$escape_expand(\t) "VERSION:" $$VERSION $$escape_expand(\n))
    qscm_debug: log($$escape_expand(\t) "VER_MAJ:" $$VER_MAJ $$escape_expand(\n))
    qscm_debug: log($$escape_expand(\t) "VER_MIN:" $$VER_MIN $$escape_expand(\n))
    qscm_debug: log($$escape_expand(\t) "VER_PAT:" $$VER_PAT $$escape_expand(\n))
}

QSCM_SUBSTITUTIONS = \
    s|@{QSCM_VERSION}|$${QSCM_VERSION}|g\
    s|@{QSCM_SEMVER}|$${QSCM_SEMVER}|g\
    s|@{QSCM_SEMVER_SIMPLE}|$${QSCM_SEMVER_SIMPLE}|g\
    s|@{QSCM_SEMVER_MAJ}|$${QSCM_SEMVER_MAJ}|g\
    s|@{QSCM_SEMVER_MIN}|$${QSCM_SEMVER_MIN}|g\
    s|@{QSCM_SEMVER_PAT}|$${QSCM_SEMVER_PAT}|g\
    s|@{QSCM_SEMVER_PREREL}|$${QSCM_SEMVER_PREREL}|g\
    s|@{QSCM_SEMVER_BUILD}|$${QSCM_SEMVER_BUILD}|g\
    s|@{QSCM_SEMVER_SUFFIX}|$${QSCM_SEMVER_SUFFIX}|g\
    s|@{QSCM_HASH}|$${QSCM_HASH}|g\
    s|@{QSCM_BRANCH}|$${QSCM_BRANCH}|g\
    s|@{QSCM_DISTANCE}|$${QSCM_DISTANCE}|g\
    s|@{QSCM_PRETTY_VERSION}|$$join(QSCM_PRETTY_VERSION, " ")|g\

qscm.name = Generate version headers
qscm.input = QSCM_HEADERS
qscm.commands += $${QMAKE_STREAM_EDITOR}

# Generate sed script file on unix or fallback to command line generation on win32
unix {
    QSCM_SUBSTITUTIONS_FILE = "$$OUT_PWD/qscmsubst.sed"
    write_file($$QSCM_SUBSTITUTIONS_FILE, QSCM_SUBSTITUTIONS)
    qscm.commands += -f $$shell_quote($$QSCM_SUBSTITUTIONS_FILE)
}
win32 {
    for(QSCM_SUBST, QSCM_SUBSTITUTIONS) {
        qscm.commands += -e $$shell_quote($$QSCM_SUBST)
    }
}

# Conditionally update file on unix and always on win32
unix {
    qscm.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}.tmp;
    qscm.commands += if cmp ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT} >/dev/null 2>&1; then rm ${QMAKE_FILE_OUT}.tmp; else mv ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT}; fi
}
win32 {
    qscm.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}
}
qscm.output = ${QMAKE_FILE_IN_BASE}.h
qscm.clean = ${QMAKE_FILE_OUT} $${QSCM_SUBSTITUTIONS_FILE}
qscm.depends = .
qscm.CONFIG = no_link target_predeps

QMAKE_EXTRA_COMPILERS += qscm

# Force qmake execution if not instructed to skip it.
# This help to have always up to date version information. The version info
# is captured during the qmake call.
!qscm_no_force_qmake {
    qmakeforce.target = dummy
    qmakeforce.commands = $(MAKE) qmake
    qmakeforce.depends = FORCE
    PRE_TARGETDEPS += $$qmakeforce.target
    QMAKE_EXTRA_TARGETS += qmakeforce
}