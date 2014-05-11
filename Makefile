
PREFIX ?= /usr/local

all: test

install:
	install clib-makefile.sh $(PREFIX)/bin/clib-makefile

uninstall:
	rm -f $(PREFIX)/bin/clib-makefile

test:
	./clib-makefile.sh

.PHONY: test
