# Mark objects as 'ancient' so they are taken out of the OCaml heap.
# $Id: Makefile,v 1.1 2006-09-27 12:07:07 rich Exp $

CC	:= gcc
CFLAGS	:= -g -fPIC -Wall -Werror

OCAMLCFLAGS	:= -g
OCAMLCPACKAGES	:= 
OCAMLCLIBS	:= 

OCAMLOPTFLAGS	:=
OCAMLOPTPACKAGES := $(OCAMLCPACKAGES)
OCAMLOPTLIBS	:= 

OCAMLDOCFLAGS := -html -stars -sort $(OCAMLCPACKAGES)

all:	ancient.cma ancient.cmxa test_ancient.opt META

ancient.cma: ancient.cmo ancient_c.o
	ocamlmklib -o ancient $^

ancient.cmxa: ancient.cmx ancient_c.o
	ocamlmklib -o ancient $^

test_ancient.opt: ancient.cmxa test_ancient.cmx
	LIBRARY_PATH=.:$$LIBRARY_PATH \
	ocamlfind ocamlopt $(OCAMLOPTFLAGS) $(OCAMLOPTLIBS) -o $@ $^

# Common rules for building OCaml objects.

.mli.cmi:
	ocamlfind ocamlc $(OCAMLCFLAGS) $(OCAMLCINCS) $(OCAMLCPACKAGES) -c $<
.ml.cmo:
	ocamlfind ocamlc $(OCAMLCFLAGS) $(OCAMLCINCS) $(OCAMLCPACKAGES) -c $<
.ml.cmx:
	ocamlfind ocamlopt $(OCAMLOPTFLAGS) $(OCAMLOPTINCS) $(OCAMLOPTPACKAGES) -c $<

# Findlib META file.

META:	META.in Makefile.config
	$(SED)  -e 's/@PACKAGE@/$(PACKAGE)/' \
		-e 's/@VERSION@/$(VERSION)/' \
		< $< > $@

# Clean.

clean:
	rm -f *.cmi *.cmo *.cmx *.cma *.cmxa *.o *.a *.so *~ core META *.opt

# Dependencies.

depend: .depend

.depend: $(wildcard *.mli) $(wildcard *.ml)
	rm -f .depend
	ocamldep $^ > $@

ifeq ($(wildcard .depend),.depend)
include .depend
endif

# Install.

install:
	rm -rf $(DESTDIR)$(OCAMLLIBDIR)/ancient
	install -c -m 0755 -d $(DESTDIR)$(OCAMLLIBDIR)/weblogs
	install -c -m 0644 *.cmi *.mli *.cma *.cmxa *.a META \
	  $(DESTDIR)$(OCAMLLIBDIR)/ancient

# Distribution.

dist:
	$(MAKE) check-manifest
	rm -rf $(PACKAGE)-$(VERSION)
	mkdir $(PACKAGE)-$(VERSION)
	tar -cf - -T MANIFEST | tar -C $(PACKAGE)-$(VERSION) -xf -
	tar zcf $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)
	ls -l $(PACKAGE)-$(VERSION).tar.gz

check-manifest:
	@for d in `find -type d -name CVS | grep -v '^\./debian/'`; \
	do \
	b=`dirname $$d`/; \
	awk -F/ '$$1 != "D" {print $$2}' $$d/Entries | \
	sed -e "s|^|$$b|" -e "s|^\./||"; \
	done | sort > .check-manifest; \
	sort MANIFEST > .orig-manifest; \
	diff -u .orig-manifest .check-manifest; rv=$$?; \
	rm -f .orig-manifest .check-manifest; \
	exit $$rv

# Debian packages.

dpkg:
	@if [ 0 != `cvs -q update | wc -l` ]; then \
	echo Please commit all changes to CVS first.; \
	exit 1; \
	fi
	$(MAKE) dist
	rm -rf /tmp/dbuild
	mkdir /tmp/dbuild
	cp $(PACKAGE)-$(VERSION).tar.gz \
	  /tmp/dbuild/$(PACKAGE)_$(VERSION).orig.tar.gz
	export CVSROOT=`cat CVS/Root`; \
	  cd /tmp/dbuild && \
	  cvs export \
	  -d $(PACKAGE)-$(VERSION) \
	  -D now merjis/freeware/ancient
	cd /tmp/dbuild/$(PACKAGE)-$(VERSION) && dpkg-buildpackage -rfakeroot
	rm -rf /tmp/dbuild/$(PACKAGE)-$(VERSION)
	ls -l /tmp/dbuild

# Developer documentation (in html/ subdirectory).

doc:
	rm -rf html
	mkdir html
	-ocamlfind ocamldoc $(OCAMLDOCFLAGS) -d html ancient.ml{i,}

.PHONY:	depend dist check-manifest dpkg doc

.SUFFIXES:	.cmo .cmi .cmx .ml .mli