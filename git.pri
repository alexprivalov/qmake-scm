isEmpty(VCSQT_VERSION_PREFIX):VCSQT_VERSION_PREFIX=v

VCSQT_DESCRIBE=$$system(git -C $$_PRO_FILE_PWD_ describe --long --tags --dirty=+ --match="$$VCSQT_VERSION_PREFIX*")
# sample data: v0.4.0-5-ga8152a7
VCSQT_BRANCH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --abbrev-ref HEAD)

# not running from repository or git unavailable
isEmpty(VCSQT_BRANCH) {
    # try to read version.txt file that should have been updated during export operation
    # sample data: HEAD -> master, tag: v0.0.3, 3e575e9
    isEmpty(VCSQT_EXPORTED_VERSION_FILE): VCSQT_EXPORTED_VERSION_FILE=$$PWD/version.txt
    VCSQT_VERSION_INFO=$$cat($$VCSQT_EXPORTED_VERSION_FILE)
    isEqual(VCSQT_VERSION_INFO, "$Format:%D, %h$") {
        warning("No version information available: building from unexported version")
        VCSQT_DISTANCE=0
        VCSQT_HASH=?
        VCSQT_BRANCH=unknown
        VCSQT_VERSION=0.0.0
    } else {
        VCSQT_VERSION_INFO=$$replace(VCSQT_VERSION_INFO, ",", )
        VCSQT_VERSION_INFO_NUM_COMPONENTS=$$size(VCSQT_VERSION_INFO)
        VCSQT_VERSION_INFO_COMPONENT_3=$$member(VCSQT_VERSION_INFO, 3)
        VCSQT_HASH=$$last(VCSQT_VERSION_INFO)
        VCSQT_BRANCH=$$member(VCSQT_VERSION_INFO, 2)
        VCSQT_DISTANCE=0
        isEqual(VCSQT_VERSION_INFO_COMPONENT_3, "tag:") {
            VCSQT_VERSION=$$member(VCSQT_VERSION_INFO, 4)
            VCSQT_VERSION=$$replace(VCSQT_VERSION, $$VCSQT_VERSION_PREFIX, )
        }else {
            # no version information
            warning("No version information available (no tags)")
            VCSQT_VERSION=0.0.0
        }
    }
}else {
    # detached head state
    isEqual(VCSQT_BRANCH, "HEAD") {
        VCSQT_REFS=$$system(git -C $$_PRO_FILE_PWD_ show -s --pretty=%d HEAD)
        VCSQT_ORIGIN=$$system(git -C $$_PRO_FILE_PWD_ remote)

        # strip start and end parentheses
        VCSQT_REFS=$$str_member($$VCSQT_REFS, 1, -2)

        # make a list of separate refs
        VCSQT_COMMA=,
        VCSQT_REFS=$$split(VCSQT_REFS, $$VCSQT_COMMA)

        for(VCSQT_REF, VCSQT_REFS) {
            VCSQT_REF=$$replace(VCSQT_REF," ",)
            VCSQT_REF4=$$str_member($$VCSQT_REF, 0, 3)

            # skip tags
            !isEqual(VCSQT_REF4, "tag:") {
                # strip remotes
                VCSQT_REF_PARTS=$$split(VCSQT_REF,"/")
                VCSQT_REF_PARTS-=$$VCSQT_ORIGIN
                VCSQT_REF=$$join(VCSQT_REF_PARTS,/)

                # skip head
                !isEqual(VCSQT_REF, "HEAD") {
                    VCSQT_SELECTED_REFS += $$VCSQT_REF
                }
            }
        }
        # if failed, treat as master
        isEmpty(VCSQT_SELECTED_REFS): VCSQT_BRANCH=master
        else: VCSQT_BRANCH=$$first(VCSQT_SELECTED_REFS)
        VCSQT_BRANCH=$$replace(VCSQT_BRANCH,"\\)",)
    }
    # has at least 1 tag
    !isEmpty(VCSQT_DESCRIBE) {
        VCSQT_DESCRIBE=$$replace(VCSQT_DESCRIBE, $$VCSQT_VERSION_PREFIX, )
        VCSQT_DESCRIBE=$$split(VCSQT_DESCRIBE, "-")

        VCSQT_VERSION=$$member(VCSQT_DESCRIBE, 0)
        VCSQT_DISTANCE=$$member(VCSQT_DESCRIBE, 1)
        VCSQT_HASH=$$member(VCSQT_DESCRIBE, 2)
        VCSQT_HASH=$$section(VCSQT_HASH,,2)
    }else {
        VCSQT_DISTANCE=$$system(git -C $$_PRO_FILE_PWD_ rev-list --count HEAD)
        VCSQT_VERSION=0.0.0
        VCSQT_HASH=$$system(git -C $$_PRO_FILE_PWD_ rev-parse --short HEAD)
        system(git -C $$_PRO_FILE_PWD_ diff-index --quiet HEAD): VCSQT_HASH=$${VCSQT_HASH}+
    }
}
VCSQT_PRETTY_VERSION=v$$VCSQT_VERSION
greaterThan(VCSQT_DISTANCE, 0):VCSQT_PRETTY_VERSION += +$$VCSQT_DISTANCE
VCSQT_PRETTY_VERSION += $$VCSQT_HASH
!isEqual(VCSQT_BRANCH, master) {
    VCSQT_PRETTY_VERSION += (@$$VCSQT_BRANCH)
}

VERSION = $$VCSQT_VERSION

vcsqt.name = Generate version headers
vcsqt.input = VCSQT_HEADERS
vcsqt.commands += $${QMAKE_STREAM_EDITOR}
vcsqt.commands += -e \"s/\\\$${VCSQT_VERSION}/$${VCSQT_VERSION}/g\"
vcsqt.commands += -e \"s/\\\$${VCSQT_HASH}/$${VCSQT_HASH}/g\"
vcsqt.commands += -e \"s/\\\$${VCSQT_BRANCH}/$$replace(VCSQT_BRANCH, "/", "\\/")/g\"
vcsqt.commands += -e \"s/\\\$${VCSQT_DISTANCE}/$${VCSQT_DISTANCE}/g\"
vcsqt.commands += -e \"s/\\\$${VCSQT_PRETTY_VERSION}/$$replace(VCSQT_PRETTY_VERSION, "/", "\\/")/g\"
unix {
    vcsqt.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}.tmp;
    vcsqt.commands += if cmp ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT} >/dev/null 2>&1; then rm ${QMAKE_FILE_OUT}.tmp; else mv ${QMAKE_FILE_OUT}.tmp ${QMAKE_FILE_OUT}; fi
}
win32 {
    vcsqt.commands += ${QMAKE_FILE_IN} > ${QMAKE_FILE_OUT}
}
vcsqt.output = ${QMAKE_FILE_IN_BASE}.h
vcsqt.clean = ${QMAKE_FILE_OUT}
vcsqt.depends = .
vcsqt.CONFIG = no_link target_predeps

QMAKE_EXTRA_COMPILERS += vcsqt
