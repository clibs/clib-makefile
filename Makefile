
PREFIX ?= /usr/local

all: clean test

install:
	install clib-makefile.sh $(PREFIX)/bin/clib-makefile

uninstall:
	rm -f $(PREFIX)/bin/clib-makefile

test:
	BIN_NAME=foo LIB_NAME=foo FILE=test/Makefile ./clib-makefile.sh -y -d
	$(MAKE) -C test/
	$(MAKE) test -C test/
	$(MAKE) clean -C test/

clean:
	if test -f test/Makefile; then  $(MAKE) -C test; fi
	rm -f test/Makefile

.PHONY: test
