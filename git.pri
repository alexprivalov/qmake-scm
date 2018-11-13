isEmpty(QSCM_VERSION_PREFIX):QSCM_VERSION_PREFIX=v

QSCM_DESCRIBE=$$system(git -C $$_PRO_FILE_PWD_ describe --long --tags --dirty=+ --match="$$QSCM_VERSION_PREFIX*")
# sample data: v0.4.0-5-ga8152a7
QSCM_BRANCH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --abbrev-ref HEAD)

# not running from repository or git unavailable
isEmpty(QSCM_BRANCH) {
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
        QSCM_REFS=$$system(git -C $$_PRO_FILE_PWD_ show -s --pretty=%d HEAD)
        QSCM_ORIGIN=$$system(git -C $$_PRO_FILE_PWD_ remote)

        # strip start and end parentheses
        QSCM_REFS=$$str_member($$QSCM_REFS, 1, -2)

        # make a list of separate refs
        QSCM_COMMA=,
        QSCM_REFS=$$split(QSCM_REFS, $$QSCM_COMMA)

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

        QSCM_VERSION=$$member(QSCM_DESCRIBE, 0)
        QSCM_DISTANCE=$$member(QSCM_DESCRIBE, 1)
        QSCM_HASH=$$member(QSCM_DESCRIBE, 2)
        QSCM_HASH=$$section(QSCM_HASH,,2)
    }else {
        QSCM_DISTANCE=$$system(git -C $$_PRO_FILE_PWD_ rev-list --count HEAD)
        QSCM_VERSION=0.0.0
        QSCM_HASH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --short HEAD)
        system(git -C $$_PRO_FILE_PWD_ diff-index --quiet HEAD): QSCM_HASH=$${QSCM_HASH}+
    }
}
QSCM_PRETTY_VERSION=v$$QSCM_VERSION
greaterThan(QSCM_DISTANCE, 0):QSCM_PRETTY_VERSION += +$$QSCM_DISTANCE
QSCM_PRETTY_VERSION += $$QSCM_HASH
!isEqual(QSCM_BRANCH, master) {
    QSCM_PRETTY_VERSION += (@$$QSCM_BRANCH)
}

VERSION = $$QSCM_VERSION

qscm.name = Generate version headers
qscm.input = QSCM_HEADERS
qscm.commands += $${QMAKE_STREAM_EDITOR}
qscm.commands += -e \"s%\\\$${QSCM_VERSION}%$${QSCM_VERSION}%g\"
qscm.commands += -e \"s%\\\$${QSCM_HASH}%$${QSCM_HASH}%g\"
qscm.commands += -e \"s%\\\$${QSCM_BRANCH}%$${QSCM_BRANCH}%g\"
qscm.commands += -e \"s%\\\$${QSCM_DISTANCE}%$${QSCM_DISTANCE}%g\"
qscm.commands += -e \"s%\\\$${QSCM_PRETTY_VERSION}%$${QSCM_PRETTY_VERSION}%g\"
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
