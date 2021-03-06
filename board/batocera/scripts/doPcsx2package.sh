#!/bin/bash

# run manually:  board/batocera/scripts/doPcsx2package.sh "output/target" "output/pcsx2" "output/images/batocera"

basicLdd() {
    LANG=C readelf -d "${1}" | grep -E "Shared library: " | sed -e s+"^.*Shared library: \[\([^]]*\)\]$"+"\1"+
}

findDeps() {
    local FILE=$1
    local OUTDIR=$2
    local DEP=
    local DEPDIR=

    if ! basicLdd "${FILE}" |
    while read DEP
    do
        DEPDIR=$(findLibDir "${DEP}")
        if test -d "${DEPDIR}"
        then
            if test ! -e "${OUTDIR}/${DEP}"
            then
                if ! cpLib "${DEPDIR}/${DEP}" "${OUTDIR}"
                then
                    return 1
                fi
                if ! findDeps "${DEPDIR}/${DEP}" "${OUTDIR}"
                then
                    return 1
                fi
            fi
        else
            echo "error: ${DEP} not found for ${FILE}" >&2
            return 1
        fi
    done
    then
        return 1
    fi
    return 0
}

findLibDir() {
    for XDIR in "${G_TARGETDIR}/lib" "${G_TARGETDIR}/usr/lib"
    do
        test -e "${XDIR}/${1}" && echo "${XDIR}" && return
    done
}

cpLib() {
    cp -P "${1}" "${2}" || return 1
    echo "   "$(basename "${1}")
    if test -L "${1}"
    then
        LNK=$(readlink -f "${1}")
        cp -P "${LNK}" "${2}" || return 1
    fi
    return 0
}

G_TARGETDIR="${1}"
TMPOUT="${2}"
TARGET_IMAGE="${3}"

if ! rm -rf "${TMPOUT}"
then
    exit 1
fi
if ! mkdir -p "${TMPOUT}/lib32"
then
    exit 1
fi

# libs32
echo "libs..."
for BIN in "${G_TARGETDIR}/usr/pcsx2/bin/pcsx2" \
"${G_TARGETDIR}/usr/pcsx2-avx2/bin/pcsx2" \
"${G_TARGETDIR}/usr/pcsx2/bin/plugins/"*.so \
"${G_TARGETDIR}/usr/pcsx2-avx2/bin/plugins/"*.so \
"${G_TARGETDIR}/usr/lib/libEGL_mesa"* \
"${G_TARGETDIR}/usr/lib/libGLX_mesa"*
do
    findDeps "${BIN}" "${TMPOUT}/lib32" || exit 1
done
cp "${G_TARGETDIR}/usr/lib/libEGL_mesa"* "${TMPOUT}/lib32"
cp "${G_TARGETDIR}/usr/lib/libGLX_mesa"* "${TMPOUT}/lib32"

# binaries
echo "binaries..."
mkdir -p "${TMPOUT}/usr"                              || exit 1
echo "  PCSX/"
cp -pr "${G_TARGETDIR}/usr/PCSX"      "${TMPOUT}/usr" || exit 1
echo "  PCSX_AVX2/"
cp -pr "${G_TARGETDIR}/usr/PCSX_AVX2" "${TMPOUT}/usr" || exit 1

# dri
echo "dri..."
for i in "${G_TARGETDIR}/usr/lib/dri/"*.so
do
    echo "   "$(basename "${i}")
done
cp -pr "${G_TARGETDIR}/usr/lib/dri" "${TMPOUT}/lib32/dri"
for BIN in "${G_TARGETDIR}/usr/lib/dri/"*.so
do
    findDeps "${BIN}" "${TMPOUT}/lib32" || exit 1
done

# ld
echo "ld..."
mkdir -p "${TMPOUT}/lib"                                      || exit 1
ENDINGNAME=$(echo "${G_TARGETDIR}/lib/ld-linux"* | sed -e s+'^.*/\([^/]*\)$'+'\1'+)
echo  "   ${ENDINGNAME}"
(cd "${TMPOUT}/lib" && ln -sf ../lib32/ld-*.so "${ENDINGNAME}") || exit 1

if echo "${TARGET_IMAGE}" | grep -qE "^/"
then
    XTARGET_IMAGE="${TARGET_IMAGE}"
else
    XTARGET_IMAGE="${PWD}/${TARGET_IMAGE}"
fi

XTARGET_VERSION=$(cat "${G_TARGETDIR}/usr/share/batocera/batocera.version" | sed -e s+" .*$"++)
XTARGET_ARCH=$(cat "${G_TARGETDIR}/usr/share/batocera/batocera.arch")
XTARGET_FILE="pcsx2-${XTARGET_ARCH}-${XTARGET_VERSION}.tar.gz"

echo "tar.gz..."
(cd "${TMPOUT}" && tar zcf "${XTARGET_IMAGE}/${XTARGET_FILE}" *) || exit 1

echo "${XTARGET_IMAGE}/${XTARGET_FILE}"
exit 0
