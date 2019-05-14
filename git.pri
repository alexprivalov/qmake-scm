isEmpty(QSCM_VERSION_PREFIX):QSCM_VERSION_PREFIX=v

QSCM_DESCRIBE=$$system(git -C $$_PRO_FILE_PWD_ describe --long --tags --dirty=+ --match="$$QSCM_VERSION_PREFIX*")
# sample data: v0.4.0-5-ga8152a7
QSCM_BRANCH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --abbrev-ref HEAD)

qscm_debug: log("QSCM_GIT_DESCRIBE:" $$QSCM_DESCRIBE $$escape_expand(\n))
qscm_debug: log("QSCM_GIT_BRANCH:" $$QSCM_BRANCH $$escape_expand(\n))

# not running from repository or git unavailable
isEmpty(QSCM_BRANCH) {
    qscm_debug: log("QSCM: Failed to obtain information via Git" $$escape_expand(\n))
    # try to read version.txt file that should have been updated during export operation
    # sample data: HEAD -> master, tag: v0.0.3, 3e575e9
    isEmpty(QSCM_EXPORTED_VERSION_FILE): QSCM_EXPORTED_VERSION_FILE=$$PWD/version.txt
    QSCM_VERSION_INFO=$$cat($$QSCM_EXPORTED_VERSION_FILE)
    isEqual(QSCM_VERSION_INFO, "$Format:%D, %h$") {
        warning("No version information available: building from unexported version")
        QSCM_DISTANCE=0
        QSCM_HASH=?
        QSCM_BRANCH=unknown
        QSCM_VERSION=0.0.0
    } else {
        QSCM_VERSION_INFO=$$replace(QSCM_VERSION_INFO, ",", )
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

        QSCM_REFS=$$system(git -C $$_PRO_FILE_PWD_ show -s --pretty=%d HEAD)
        QSCM_ORIGIN=$$system(git -C $$_PRO_FILE_PWD_ remote)

        qscm_debug: log("QSCM_REFS:" $$QSCM_REFS $$escape_expand(\n))
        qscm_debug: log("QSCM_ORIGIN:" $$QSCM_ORIGIN $$escape_expand(\n))

        # strip start and end parentheses
        QSCM_REFS=$$str_member($$QSCM_REFS, 1, -2)

        # make a list of separate refs
        QSCM_COMMA=,
        QSCM_REFS=$$split(QSCM_REFS, $$QSCM_COMMA)
        qscm_debug: log("QSCM_REFS (list):" $$QSCM_REFS $$escape_expand(\n))

        for(QSCM_REF, QSCM_REFS) {
            QSCM_REF=$$replace(QSCM_REF," ",)
            QSCM_REF4=$$str_member($$QSCM_REF, 0, 3)

            # skip tags
            !isEqual(QSCM_REF4, "tag:") {
                # strip remotes
                QSCM_REF_PARTS=$$split(QSCM_REF,"/")
                QSCM_REF_PARTS-=$$QSCM_ORIGIN
                QSCM_REF=$$join(QSCM_REF_PARTS,/)

                # skip head
                !isEqual(QSCM_REF, "HEAD") {
                    QSCM_SELECTED_REFS += $$QSCM_REF
                }
            }
        }
        # if failed or contains master treat as master
        isEmpty(QSCM_SELECTED_REFS) | contains(QSCM_SELECTED_REFS, master): QSCM_BRANCH=master
        else: QSCM_BRANCH=$$first(QSCM_SELECTED_REFS)
        QSCM_BRANCH=$$replace(QSCM_BRANCH,"\\)",)
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
        qscm_debug: log("QSCM: No refs found" $$escape_expand(\n))
        QSCM_DISTANCE=$$system(git -C $$_PRO_FILE_PWD_ rev-list --count HEAD)
        QSCM_VERSION=0.0.0
        QSCM_HASH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --short HEAD)
        system(git -C $$_PRO_FILE_PWD_ diff-index --quiet HEAD): QSCM_HASH=$${QSCM_HASH}+
    }
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
QSCM_SEMVER_SUFFIX ~= s/^(\d+\.)*\d+/
QSCM_SEMVER_SIMPLE = $$replace(QSCM_SEMVER,$$QSCM_SEMVER_SUFFIX,)
QSCM_SEMVER_SUFFIX ~= s/^(-|\+)*/
QSCM_SEMVER = $${QSCM_SEMVER_SIMPLE}-$${QSCM_SEMVER_SUFFIX}
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


!qscm_no_version_setup {
    VERSION = $$QSCM_SEMVER
    VER_MAJ = $$QSCM_SEMVER_MAJ
    VER_MIN = $$QSCM_SEMVER_MIN
    VER_PAT = $$QSCM_SEMVER_PAT
}

qscm.name = Generate version headers
qscm.input = QSCM_HEADERS
qscm.commands += $${QMAKE_STREAM_EDITOR}
qscm.commands += -e \"s|@{QSCM_VERSION}|$${QSCM_VERSION}|g\"
qscm.commands += -e \"s|@{QSCM_SEMVER}|$${QSCM_SEMVER}|g\"
qscm.commands += -e \"s|@{QSCM_SEMVER_MAJ}|$${QSCM_SEMVER_MAJ}|g\"
qscm.commands += -e \"s|@{QSCM_SEMVER_MIN}|$${QSCM_SEMVER_MIN}|g\"
qscm.commands += -e \"s|@{QSCM_SEMVER_PAT}|$${QSCM_SEMVER_PAT}|g\"
qscm.commands += -e \"s|@{QSCM_SEMVER_SUFFIX}|$${QSCM_SEMVER_SUFFIX}|g\"
qscm.commands += -e \"s|@{QSCM_HASH}|$${QSCM_HASH}|g\"
qscm.commands += -e \"s|@{QSCM_BRANCH}|$${QSCM_BRANCH}|g\"
qscm.commands += -e \"s|@{QSCM_DISTANCE}|$${QSCM_DISTANCE}|g\"
qscm.commands += -e \"s|@{QSCM_PRETTY_VERSION}|$${QSCM_PRETTY_VERSION}|g\"
unix {
    qscm.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}.tmp;
    qscm.commands += if cmp ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT} >/dev/null 2>&1; then rm ${QMAKE_FILE_OUT}.tmp; else mv ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT}; fi
}
win32 {
    qscm.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}
}
qscm.output = ${QMAKE_FILE_IN_BASE}.h
qscm.clean = ${QMAKE_FILE_OUT}
qscm.depends = .
qscm.CONFIG = no_link target_predeps

QMAKE_EXTRA_COMPILERS += qscm
