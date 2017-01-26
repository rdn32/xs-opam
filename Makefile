#
#
#

DATE    := $(shell printf '%x' `date +%s`)
RELEASE := $(shell git describe --always)
VERSION := 0.0.$(DATE)

TOP :=  	$(PWD)
SRC := 		"$(TOP)/build/src"

SPEC 	+= xs-opam-src.spec
SPEC 	+= xs-opam-repo.spec


all: repo spec

#
# build an Opam repo in build/ with all URL files pointing
# to sources in build/src.
#
repo: 	sources.txt build
	cp -r packages build
	grep -v '^#' $< | while read pkg url; do \
	  echo "http: \"file://$(SRC)/$$(basename $$url)\"" > build/packages/$$pkg/url;\
	done
	cd build; opam-admin make

build:
	mkdir -p build/src


# generate spec files
spec: 	$(SPEC)

xs-opam-src.spec: xs-opam-src.in sources.txt Makefile
	awk '/^#/ {next}; /http/ { printf "Source%03d: %s\n", ++n, $$2}' sources.txt > sources.spec
	sed -e '/^# sources.spec/r sources.spec' -e 's/@VERSION@/$(VERSION)/' $< > $@
	rm sources.spec

xs-opam-repo.spec: xs-opam-repo.in Makefile
	sed -e 's/@VERSION@/$(VERSION)/' $< > $@


# download all archives but skip those that are already present
download: build
	cd $(SRC); awk '/^#/ {next}; {print $$2}' ../../sources.txt | \
	while read url; do \
	      test -f $$(basename $$url) || curl --fail -L -O $$url; \
	done

clean:
	rm -rf build
	rm -f xs-opam-src.spec xs-opam-repo.spec


