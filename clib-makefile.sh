#!/bin/bash

## meta
CLIB_MAKEFILE_VERSION="0.0.1"
OS="`uname`"
AGENT="`uname -a`"
VALGRIND="valgrind"
CC="cc"
TAB="	"

## opts
FORCE_YES=0

## static
OBJS='$(SRC:.c=.o)'

## defaults
FILE="Makefile"
TESTS="test.c"
SRC="src/*.c"
MAIN_SRC="src/main.c"
SRC_FILTER="${MAIN_SRC}"

HEADER_DIR="include/"

MAN_FILES="man/*.{1,2,3}"
MAN_TPLS="man/*.md"

PREFIX="/usr/local"
MAN1PREFIX="${PREFIX}/share/man1"
MAN2PREFIX="${PREFIX}/share/man2"
MAN3PREFIX="${PREFIX}/share/man3"

VERSION_MAJOR="0"
VERSION_MINOR="0"
VERSION_PATCH="1"
VERSION_EXTRA=""
VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"

CFLAGS+="-std=c99 -Wall -02 -fvisibility=hidden -fPIC -pedantic"
CFLAGS+="-Ideps -Iinclude"

LDFLAGS+='-o $(TARGET_DSOLIB) -shared -soname $(TARGET_DSO).$(VERSION_MAJOR)'

usage () {
  {
    echo "usage: clib-makefile [-hyV]"
  } >&2
}

prompt () {
  local var="$1"
  local q="$2"
  local value=""
  printf "%s" "${q}"
  read -r value;
  if [ ! -z "${value}" ]; then
    eval "${var}"="${value}"
  fi
}

hint () {
  {
    printf "  hint: %s\n" "$@"
  } >&2
}

error () {
  {
    printf "error: %s\n" "${@}"
  } >&2
}

mcmd () {
  echo "\$(${@})"
}

shell () {
  mcmd "shell ${@}"
}

filter-out () {
  mcmd "filter-out ${@}"
}

wildcard () {
  mcmd "wildcard ${@}"
}

append () {
  echo "$@" >> "${FILE}"
}

appendf () {
  local fmt="$1"
  shift
  printf "${fmt}" "${@}" >> "${FILE}"
}

## parse opts
{
  while true; do
    arg="$1"
    if [ "" = "${arg}" ]; then
      break;
    fi

    case "${arg}" in
      -y|--yes)
        FORCE_YES=1
        ;;

      -V|--version)
        echo "${CLIB_MAKEFILE_VERSION}"
        exit 0
        ;;

      -h|--help)
        usage
        exit 0
        ;;

      *)
        error "Unknown option: \`${arg}'"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

## intro
echo " clib-makefile(1) v${CLIB_MAKEFILE_VERSION}"
echo "-------------------------"
echo "Detected OS = '${OS}'"
echo

## destination
prompt FILE "Enter \`Makefile' file name (${FILE}): "

if test -f "${FILE}"; then
  if [ "1" = "${FORCE_YES}" ]; then
    rm -f "${FILE}"
  else
    prompt ANSWER "\`${FILE}' already exists. Overwrite? (no): "
    if [ "y" = "${ANSWER:0:1}" ]; then
      rm -f "${FILE}"
    else
      exit 1
    fi
  fi
fi

## CC
prompt CC "Enter \`CC' compiler (${CC}): "

## valgrind
prompt VALGRIND "Enter valgrind program (${VALGRIND}): "

## sources
prompt SRC "Enter sources (${SRC}): "

## main source
prompt MAIN_SRC "Enter main source file with \`void main(int, char **)' defined (${MAIN_SRC}): "

## source filters
prompt SRC_FILTER "Enter ignored sources (${SRC_FILTER}): "

## header include directory
prompt HEADER_DIR "Enter header include directory (${HEADER_DIR}): "

## tests
prompt TESTS "Enter test sources (${TESTS}): "

## prefixes
prompt PREFIX "Enter install path prefix (${PREFIX}): "
prompt MAN1PREFIX "Enter man1 path prefix (${MAN1PREFIX}): "
prompt MAN2PREFIX "Enter man2 path prefix (${MAN2PREFIX}): "
prompt MAN3PREFIX "Enter man3 path prefix (${MAN3PREFIX}): "

## man files
prompt MAN_FILES "Enter man file sources (${MAN_FILES}): "

## man template files
prompt MAN_TPLS "Enter man template (markdown) files (${MAN_TPLS}): "

## binary name if applicable
prompt BIN_NAME "Enter bin name if applicable: "

## lib name if applicable
prompt LIB_NAME "Enter lib name if applicable: "

## version
{
  IFS="." prompt VERSION "Enter source version (${VERSION}): "
  let i=0
  for p in "${VERSION[@]}"; do
    case "${i}" in
      0) VERSION_MAJOR="${p}" ;;
      1) VERSION_MINOR="${p}" ;;
      2) VERSION_PATCH="${p}" ;;
      3) VERSION_EXTRA="${p}" ;;
      *) break; ;;
  esac
  ((++i))
done
}

## library targets (if lib name provided)
if [ ! -z "${LIB_NAME}" ]; then
  TARGET_NAME="lib${LIB_NAME}"
  TARGET_STATIC="${TARGET_STATIC}.a"
  TARGET_DSOLIB="${TARGET_NAME}.so.${VERSION_MAJOR}${VERSION_MINOR}${VERSION_PATCH}${VERSION_PATCH}"
  TARGET_DSO="${TARGET_NAME}.so"
fi

## CFLAGS
hint "Define \`CFLAGS' environment variable for appending"
prompt CFLAGS "Enter CFLAGS (${CFLAGS}): "

## LDFLAGS
hint "Define \`LDFLAGS' environment variable for appending"
prompt LDFLAGS "Enter LDFLAGS (${LDFLAGS}): "

## Makefile template
touch "${FILE}"
cat >> "${FILE}" <<MAKEFILE

CC ?= ${CC}
VALGRIND ?= ${VALGRIND}
OS ?= $(shell uname)

SRC = $(filter-out ${SRC_FILTER}, $(wildcard ${SRC}))
OBJS = ${OBJS}
TESTS = ${TESTS}

PREFIX ?= ${PREFIX}
MAN1PREFIX ?= ${MAN1PREFIX}
MAN2PREFIX ?= ${MAN2PREFIX}
MAN3PREFIX ?= ${MAN3PREFIX}

MAN_FILES = ${MAN_FILES}
MAN_TPLS = ${MAN_TPLS}

MAKEFILE

if [ ! -z "${BIN_NAME}" ]; then
  append "BIN ?= ${BIN_NAME}"
fi

if [ ! -z "${LIB_NAME}" ]; then
  append "LIB_NAME ?= ${LIB_NAME}";
fi

cat >> "${FILE}" << MAKEFILE
VERSION = ${VERSION}
VERSION_MAJOR = ${VERSION_MAJOR}
VERSION_MINOR = ${VERSION_MINOR}
VERSION_PATCH = ${VERSION_PATCH}
VERSION_EXTRA =${VERSION_EXTRA}

MAKEFILE

if [ ! -z "${TARGET_NAME}" ]; then
  append "TARGET_NAME = ${TARGET_NAME}";
  append "TARGET_STATIC = ${TARGET_STATIC}";
  append "TARGET_DSOLIB = ${TARGET_DSOLIB}";
  append "TARGET_DSO = ${TARGET_DSO}";
  append ""
fi;

cat >> "${FILE}" << MAKEFILE
CFLAGS += ${CFLAGS}
LDFLAGS += ${LDFLAGS}

ifeq (\$(OS), Darwin)
${TAB}LDFLAGS += -lc -Wl,-install_name,\$(TARGET_DSO)
endif

MAKEFILE

if [ ! -z "${BIN_NAME}" ]; then
  appendf "\$(BIN): ";
  if [ ! -z "${LIB_NAME}" ]; then
    appendf "\$(TARGET_STATIC) \$(TARGET_DSO)\n";
    appendf "${TAB}\$(CC) \$(CFLAGS) ${MAIN_SRC} -o \$(BIN)";
  fi
  append ""
fi

if [ ! -z "${BIN_NAME}" ] || [ ! -z "${LIB_NAME}" ]; then
  appendf "install: "
  if [ ! -z "${BIN_NAME}" ]; then
    appendf "\$(BIN)\n"
  fi

  if [ ! -z "${LIB_NAME}" ]; then
    append "${TAB}cp -rf ${HEADER_DIR} \$(PREFIX)/include"
    append "${TAB}cp *.so* \$(PREFIX)/lib"
  fi
  append ""
fi

if [ ! -z "${TARGET_NAME}" ]; then
  append "\$(TARGET_STATIC): \$(OBJS):"
  append "${TAB}ar crus \$(TARGET_STATIC) \$(OBJS)"
  append ""
  append "\$(TARGET_DSO): \$(OBJS):"
  append "${TAB}ifeq (Darwin,\$(OS))"
  append "${TAB}\$(CC) -shared \$(OBJS) -o \$(TARGET_DSOLIB)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO).\$(VERSION_MAJOR)"
  append "${TAB}else"
  append "${TAB}\$(CC) \$(LDFLAGS) \$(OBJS) -o \$(TARGET_DSOLIB)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO).\$(VERSION_MAJOR)"
  append "${TAB}strip --strip-unneeded \$(TARGET_DSO)"
  append "${TAB}endif"
  append ""
fi

cat >> "${FILE}" << MAKEFILE
\$(OBJS):
${TAB} \$(CC) \$(CFLAGS) -c -o \$@ \$(@:.o=.c)

test: \$(OBJS) \$(TESTS)

\$(TESTS): \$(OBJS)
${TAB} \$(CC) \$(@) \$(CFLAGS) -o \$(@:.c=)
${TAB} ./\$(@:.c=)

\$(MAN_FILES): \$(MAN_TPLS)

\$(MAN_TPLS):
${TAB} curl -# -F page=@\$(@) -o \$(@:%.md=%) http://mantastic.herokuapp.com

.PHONY: \$(MAN_FILES) \$(TESTS)
MAKEFILE

exit $?
