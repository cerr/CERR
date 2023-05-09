## Copyright 2015-2016 Carnë Draug
## Copyright 2015-2016 Oliver Heimlich
## Copyright 2015-2016 Zdeněk Průša
##
## Copying and distribution of this file, with or without modification,
## are permitted in any medium without royalty provided the copyright
## notice and this notice are preserved.  This file is offered as-is,
## without any warranty.

## This makefile requires 
##	 python 3.x  --- python and modules are not checked in this Makefile
##		pygments  
##		docutils  
##
##   javac
##   lynx
##	 dos2unix
##   bibtex2html 
##   mat2doc https://github.com/ltfat/mat2doc <-- pulled automatically
##


## Note the use of ':=' (immediate set) and not just '=' (lazy set).
## http://stackoverflow.com/a/448939/1609556
PACKAGE := ltfat
VERSION := $(shell cat "ltfat_version")

## This are the files that will be created for the releases.
TARGET_DIR      := ~/publish/$(PACKAGE)-octaveforge
RELEASE_DIR     := $(TARGET_DIR)/$(PACKAGE)-$(VERSION)
TMP_DIR         := $(TARGET_DIR)/$(PACKAGE)-tmp
RELEASE_TARBALL := $(TARGET_DIR)/$(PACKAGE)-$(VERSION).tar.gz
HTML_DIR        := $(TARGET_DIR)/$(PACKAGE)-html
HTML_TARBALL    := $(TARGET_DIR)/$(PACKAGE)-html.tar.gz
RELEASE_INFOFILE := $(TARGET_DIR)/$(PACKAGE)-$(VERSION)-info


MAT2DOC         := $(TARGET_DIR)/mat2doc/mat2doc.py
## These can be set by environment variables which allow to easily
## test with different Octave versions.
OCTAVE    ?= octave
MKOCTFILE ?= mkoctfile

HAS_BIBTEX2HTML := $(shell which bibtex2html)
HAS_JAVAC := $(shell which javac)
HAS_LYNX := $(shell which lynx)
HAS_DOS2UNIX := $(shell which dos2unix)
HAS_AUTOCONF := $(shell which autoconf) 

ifndef HAS_BIBTEX2HTML
$(error "Please install bibtex2html. E.g. sudo apt-get install bibtex2html")
endif
ifndef HAS_JAVAC
$(error "Please install javac. E.g. sudo apt-get install openjdk-X-jdk, where X is at least 6")
endif
ifndef HAS_LYNX
$(error "Please install lynx. E.g. sudo apt-get install lynx")
endif
ifndef HAS_DOS2UNIX
$(error "Please install dos2unix utility. E.g. sudo apt-get install dos2unix")
endif
## If autoconf is missing, a broken package would be silently created.
ifndef HAS_AUTOCONF
$(error "Please install development utilities like autoconf.")
endif


## Targets that are not filenames.
## https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: help dist html release install all check run clean update

## make will display the command before runnning them.  Use @command
## to not display it (makes specially sense for echo).
help:
	@echo "Targets:"
	@echo "   dist    - Create $(RELEASE_TARBALL) for release"
	@echo "   html    - Create $(HTML_TARBALL) for release"
	@echo "   release - Create both of the above and store md5sums in $(RELEASE_DIR).md5"
	@echo
	@echo "   install - Install the package in GNU Octave"
	@echo "   all     - Build all oct files"
	@echo "   check   - Execute package tests (w/o install)"
	@echo "   run     - Run Octave with development in PATH (no install)"
	@echo
	@echo "   clean   - Remove releases, html documentation, and oct files"

$(MAT2DOC):
	git clone https://github.com/ltfat/mat2doc $(TARGET_DIR)/mat2doc

update:
	( cd $(TARGET_DIR)/mat2doc ; \
	  git pull ; )

## dist and html targets are only PHONY/alias targets to the release
## and html tarballs.
dist: $(RELEASE_TARBALL)
html: $(HTML_TARBALL)

## An implicit rule with a recipe to build the tarballs correctly.
$(RELEASE_TARBALL): $(MAT2DOC) update
	LANG=C python3 $(MAT2DOC) . mat --script=release_keep_tests.py --octpkg --unix --outputdir=$(TMP_DIR) --projectname=$(PACKAGE)
	mv $(TMP_DIR)/$(PACKAGE)-files/$(PACKAGE)-$(VERSION).tar.gz $(RELEASE_TARBALL)
	mv $(TMP_DIR)/$(PACKAGE)-mat/$(PACKAGE) $(RELEASE_DIR)

$(HTML_TARBALL): $(HTML_DIR)
	( cd $(TARGET_DIR) ; \
	tar -czvf $(PACKAGE)-html.tar.gz $(PACKAGE)-html ; )

## install is a prerequesite to the html directory (note that the html
## tarball will use the implicit rule for ".tar.gz" files).
$(HTML_DIR): install
	$(RM) -r "$@"
	$(OCTAVE) --no-window-system --silent \
	  --eval "pkg load generate_html; " \
	  --eval "pkg load $(PACKAGE);" \
	  --eval 'generate_package_html ("${PACKAGE}", "$@", "octave-forge");'
	chmod -R a+rX,u+w,go-w $@

## To make a release, build the distribution and html tarballs.
release: dist html
	md5sum $(RELEASE_TARBALL) $(HTML_TARBALL) > $(RELEASE_DIR).md5
	@echo "Upload @ https://sourceforge.net/p/octave/package-releases/new/" > $(RELEASE_INFOFILE)
	@echo "    and inform to rebuild release with commit hash '$$(git rev-parse --short HEAD)'" >> $(RELEASE_INFOFILE) 
	@echo 'Execute: git tag -l "of-v${VERSION}"' >> $(RELEASE_INFOFILE) 

install: $(RELEASE_TARBALL)
	@echo "Installing package locally ..."
	$(OCTAVE) --eval 'pkg ("install", "-verbose", "$(RELEASE_TARBALL)")'

# This will not clean all older builds.
# To make a stronger clean you could replace with
# $(RM) -r $(TARGET_DIR)
# But be careful, TARGET_DIR will be deleted!
# That is, be careful what you set in that variable
clean:
	@echo "Cleaning ..."
	$(RM) -r $(RELEASE_DIR) $(RELEASE_TARBALL) $(HTML_TARBALL) $(HTML_DIR) $(TARGET_DIR)/*.md5 $(TMP_DIR)

pushforge:
	git push https://git.code.sf.net/p/octave/ltfat octaveforge:master

forcepushforge:
	git push --force https://git.code.sf.net/p/octave/ltfat octaveforge:master

##
## Recipes for testing purposes
##

## Build any requires oct files. 
all: 
	(cd $(RELEASE_DIR)/src ; \
	./configure ; \
	make -j4 ; )

## Start an Octave session with the package directories on the path for
## interactice test of development sources.
run: all
	(cd $(RELEASE_DIR) ; \
	$(OCTAVE) --persist --path "$(RELEASE_DIR)/inst/" --path "$(RELEASE_DIR)/src/" \
	  --eval 'if(!isempty("$(DEPENDS)")); pkg load $(DEPENDS); endif;' \
	  --eval 'ltfatstart();' ; )

# ## Test example blocks in the documentation.  Needs doctest package
# ##  https://octave.sourceforge.io/doctest/index.html
# doctest: all
# 	$(OCTAVE) --path "inst/" --path "src/" \
# 	  --eval '${PKG_ADD}' \
# 	  --eval 'pkg load doctest;' \
# 	  --eval "targets = '$(shell (ls inst; ls src | grep .oct) | cut -f2 -d@ | cut -f1 -d.)';" \
# 	  --eval "targets = strsplit (targets, ' ');" \
# 	  --eval "doctest (targets);"

## 
check: all 
	(cd $(RELEASE_DIR) ; \
	$(OCTAVE) --path "$(RELEASE_DIR)/inst/" --path "$(RELEASE_DIR)/src/" \
	  --eval 'if(!isempty("$(DEPENDS)")); pkg load $(DEPENDS); endif;' \
	  --eval 'ltfatstart();' \
	  --eval 'test_all_ltfat();' ; )
	  #--eval '__run_test_suite__ ({"inst", "src"}, {});'
