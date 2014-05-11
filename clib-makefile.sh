#!/bin/bash

## sets optional variable from environment
opt () { eval "if [ -z "\${$1}" ]; then ${1}=${2}; fi";  }

## meta
CLIB_MAKEFILE_VERSION="0.0.1"
OS="`uname`"
AGENT="`uname -a`"
TAB="	"

## opts
FORCE_YES=0
FORCE_DEFAULT=0

## static
OBJS='$(SRC:.c=.o)'

## defaults
opt CC "cc"
opt VALGRIND "valgrind"
opt FILE "Makefile"
opt TESTS "test.c"
opt SRC "src/*.c"
opt MAIN_SRC "src/main.c"
opt SRC_FILTER "${MAIN_SRC}"
opt PREFIX "/usr/local"

## dirs
HEADER_DIR="include/"

## man
MAN_FILES="man/*.{1,2,3}"
MAN_TPLS="man/*.md"
MAN1PREFIX="${PREFIX}/share/man1"
MAN2PREFIX="${PREFIX}/share/man2"
MAN3PREFIX="${PREFIX}/share/man3"

## version
VERSION_MAJOR="0"
VERSION_MINOR="0"
VERSION_PATCH="1"
VERSION_EXTRA=""
VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"

## cc flags
CFLAGS+="-std=c99 -Wall -O2 -fvisibility=hidden -fPIC -pedantic -Ideps -Iinclude"
LDFLAGS+='-o $(TARGET_DSOLIB) -shared $(TARGET_DSO).$(VERSION_MAJOR)'

## output usage
usage () {
  {
    echo "usage: clib-makefile [-hyidV]"
  } >&2
}

## prompt with question and store result
## in variable
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

## alert user of hint
hint () {
  {
    echo
    printf "  hint: %s\n" "$@"
    echo
  } >&2
}

## output error
error () {
  {
    printf "error: %s\n" "${@}"
  } >&2
}

## generate make systax command
mcmd () {
  echo "\$(${@})"
}

## make `shell' command
shell () {
  mcmd "shell ${@}"
}

## make `filter-out' command
filter-out () {
  mcmd "filter-out ${@}"
}

## make `wildcard' command
wildcard () {
  mcmd "wildcard ${@}"
}

## append line to Makefile
append () {
  echo "$@" >> "${FILE}"
}

## append formatted string to Makefile
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

      -d|--default)
        FORCE_DEFAULT=1
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

if [ "0" == "${FORCE_DEFAULT}" ]; then
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
  prompt BIN_NAME "Enter bin name if applicable (${BIN_NAME}): "

  ## lib name if applicable
  prompt LIB_NAME "Enter lib name if applicable (${LIB_NAME}): "

  ## version
  {
    prompt VERSION "Enter source version (${VERSION}): "
    IFS="." read -ra VERSION <<< "${VERSION}"
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

## CFLAGS
hint "Define \`CFLAGS' environment variable for appending"
prompt CFLAGS "Enter CFLAGS (${CFLAGS}): "

## LDFLAGS
hint "Define \`LDFLAGS' environment variable for appending"
prompt LDFLAGS "Enter LDFLAGS (${LDFLAGS}): "
fi

VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"

## library targets (if lib name provided)
if [ ! -z "${LIB_NAME}" ]; then
  TARGET_NAME="lib${LIB_NAME}"
  TARGET_STATIC="${TARGET_NAME}.a"
  TARGET_DSOLIB="${TARGET_NAME}.so.${VERSION}"
  TARGET_DSO="${TARGET_NAME}.so"
fi

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

## bin name
if [ ! -z "${BIN_NAME}" ]; then
  append "BIN ?= ${BIN_NAME}"
fi

## lib name
if [ ! -z "${LIB_NAME}" ]; then
  append "LIB_NAME ?= ${LIB_NAME}";
fi

## version
cat >> "${FILE}" << MAKEFILE
VERSION = ${VERSION}
VERSION_MAJOR = ${VERSION_MAJOR}
VERSION_MINOR = ${VERSION_MINOR}
VERSION_PATCH = ${VERSION_PATCH}
VERSION_EXTRA =${VERSION_EXTRA}

MAKEFILE

## lib targets
if [ ! -z "${TARGET_NAME}" ]; then
  append "TARGET_NAME = ${TARGET_NAME}";
  append "TARGET_STATIC = ${TARGET_STATIC}";
  append "TARGET_DSOLIB = ${TARGET_DSOLIB}";
  append "TARGET_DSO = ${TARGET_DSO}";
  append ""
fi;

## cc flags
cat >> "${FILE}" << MAKEFILE
CFLAGS += ${CFLAGS}
LDFLAGS += ${LDFLAGS}

ifeq (\$(OS), Darwin)
${TAB}LDFLAGS += -lc -Wl,-install_name,\$(TARGET_DSO)
endif

MAKEFILE

## bin build
if [ ! -z "${BIN_NAME}" ]; then
  appendf "\$(BIN): ";
  if [ ! -z "${LIB_NAME}" ]; then
    appendf "\$(TARGET_STATIC) \$(TARGET_DSO)\n";
    appendf "${TAB}\$(CC) \$(SRC) \$(CFLAGS) ${MAIN_SRC} -o \$(BIN)";
  fi
  append ""
  append ""
fi

## install
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

## lib build targets
if [ ! -z "${TARGET_NAME}" ]; then
  append "\$(TARGET_STATIC): \$(OBJS)"
  append "${TAB}ar crus \$(TARGET_STATIC) \$(OBJS)"
  append ""
  append "\$(TARGET_DSO): \$(OBJS)"
  append "ifeq (Darwin,\$(OS))"
  append "${TAB}\$(CC) -shared \$(OBJS) -o \$(TARGET_DSOLIB)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO).\$(VERSION_MAJOR)"
  append "else"
  append "${TAB}\$(CC) \$(LDFLAGS) -soname \$(OBJS) -o \$(TARGET_DSOLIB)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO)"
  append "${TAB}ln -s \$(TARGET_DSOLIB) \$(TARGET_DSO).\$(VERSION_MAJOR)"
  append "${TAB}strip --strip-unneeded \$(TARGET_DSO)"
  append "endif"
  append ""
fi

## misc targets
cat >> "${FILE}" << MAKEFILE
\$(OBJS):
${TAB} \$(CC) \$(CFLAGS) -c -o \$@ \$(@:.o=.c)

test: \$(TESTS)

\$(TESTS):
${TAB} \$(CC) \$(OBJS) \$(@) \$(CFLAGS) -o \$(@:.c=)
${TAB} ./\$(@:.c=)

\$(MAN_FILES): \$(MAN_TPLS)

\$(MAN_TPLS):
${TAB} curl -# -F page=@\$(@) -o \$(@:%.md=%) http://mantastic.herokuapp.com

clean:
${TAB}rm -f \$(OBJS) \$(BIN) \$(TARGET_STATIC) \$(TARGET_DSO) \$(TARGET_DSOLIB) *.so*

.PHONY: \$(MAN_FILES) \$(TESTS) \$(BIN) test
MAKEFILE

exit $?
