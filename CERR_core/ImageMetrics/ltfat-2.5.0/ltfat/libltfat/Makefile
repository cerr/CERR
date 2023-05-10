# This is the main Makefile for libltfat
#
# Builds three static and three shared libraries (default prefix is build/):
#
# 	libltfat.a(.so)     Contains double, single and common code
# 	libltfatd.a(.so)    Contains double and common code
# 	libltfatf.a(.so)    Contains single and common code
#
# make CROSS=x86_64-w64-mingw32.static-
# or
# make CROSS=x86_64-w64-mingw32.static- NOBLASLAPACK=1
#
# Examples:
# ---------
#
# Linking against BLAS and LAPACK from Matlab (if shared libs are desired):
#  		make BLASLAPACKLIBS="-L/usr/local/MATLAB_R2013a/bin/glnxa64 -lmwblas -lmwlapack" 
#
#  		make clean && make BLASLAPACKLIBS="-L/usr/local/MATLAB_R2013a/bin/glnxa64 -lmwblas -lmwlapack" && make build/ltfat.h

include ostools.mk

ifdef CROSS
	CC=$(CROSS)gcc
	CXX=$(CROSS)g++
	AR=$(CROSS)ar
	RANLIB=$(CROSS)ranlib
	buildprefix ?= build/$(CROSS)
	objprefix ?= obj/$(CROSS)
	MINGW=1
else
	CC?=gcc
	CXX?=g++
	AR?=ar
	RANLIB?=ranlib
	buildprefix ?= build
	objprefix ?= obj
endif

# Base CFLAGS
CFLAGS+=-Wall -Wextra -std=c99
CXXFLAGS+=-Wall -Wextra -std=c++11 -fno-exceptions -fno-rtti
LFLAGS = -Wl,--no-undefined -Lbuild/$(CROSS) $(OPTLPATH) -Wl,-rpath,$$ORIGIN

MATLABROOT ?= /usr/local/MATLAB_R2017a
PREFIX ?= /usr/local
LIBDIR = $(PREFIX)/lib
INCDIR = $(PREFIX)/include

# The following adds parameters to CFLAGS
COMPTARGET ?= release
include comptarget.mk

ifdef MINGW
	EXTRALFLAGS += -Wl,--out-implib,$@.a -static-libgcc
	BLASLAPACKLIBS?=-llapack -lblas -lgfortran -lquadmath
	# NOTE that if both static and shared libraries are to be built, 
	# the obj files must be cleared in between make calls i.e.
	# make shared
	# make cleanobj
	# make static 
	ifneq ($(MAKECMDGOALS),shared)
		CFLAGS += -DLTFAT_BUILD_STATIC
		CXXFLAGS += -DLTFAT_BUILD_STATIC
	else
		CFLAGS += -DLTFAT_BUILD_SHARED
		CXXFLAGS += -DLTFAT_BUILD_SHARED
	endif
else
	CFLAGS +=-fPIC
	CXXFLAGS +=-fPIC
endif

ifdef USECPP
ifeq ($(USECPP),1)
	CC = $(CXX)
	CFLAGS = $(CXXFLAGS)
endif
endif

FFTWLIBS?=-lfftw3 -lfftw3f
BLASLAPACKLIBS?=-llapack -lblas
MODULE ?= libltfat
SRCDIR=modules/$(MODULE)/
CFLAGS+=-I$(SRCDIR)include
objprefix:=$(objprefix)/$(MODULE)
headerbase=$(MODULE:lib%=%)

# Define source files from $(SRCDIR)/
include $(SRCDIR)src/filedefs.mk

ifdef NOBLASLAPACK
	CFLAGS+=-DNOBLASLAPACK
endif

# Convert *.c names to *.o
toCompile = $(patsubst %.c,%.o,$(files))
toCompile_complextransp = $(patsubst %.c,%.o,$(files_complextransp))
toCompile_notypechange = $(patsubst  %.c,%.o,$(files_notypechange))

COMMONFILES = $(addprefix $(objprefix)/common/d,$(toCompile_notypechange))
COMMONFILESFORSFILES = $(addprefix $(objprefix)/common/s,$(toCompile_notypechange))

DFILES   = $(addprefix $(objprefix)/double/,$(toCompile) $(toCompile_complextransp)) \
		   $(addprefix $(objprefix)/complexdouble/,$(toCompile_complextransp))
SFILES   = $(addprefix $(objprefix)/single/,$(toCompile) $(toCompile_complextransp)) \
		   $(addprefix $(objprefix)/complexsingle/,$(toCompile_complextransp))

CFLAGS += $(EXTRACFLAGS) $(OPTCFLAGS)
LFLAGS += $(EXTRALFLAGS) $(OPTLFLAGS) -lm

# Define libraries
DSTATIC = $(MODULE)d.a
SSTATIC = $(MODULE)f.a
DSSTATIC = $(MODULE).a

ifndef MINGW
	DSHARED = $(patsubst %.a,%.so,$(DSTATIC))
	SSHARED = $(patsubst %.a,%.so,$(SSTATIC))
	DSSHARED = $(patsubst %.a,%.so,$(DSSTATIC))
else
	DSHARED = $(patsubst %.a,%.dll,$(DSTATIC))
	SSHARED = $(patsubst %.a,%.dll,$(SSTATIC))
	DSSHARED = $(patsubst %.a,%.dll,$(DSSTATIC))
endif

# Define targets
DTARGET=$(buildprefix)/$(DSTATIC)
STARGET=$(buildprefix)/$(SSTATIC)
DSTARGET=$(buildprefix)/$(DSSTATIC)
SO_DTARGET=$(buildprefix)/$(DSHARED)
SO_STARGET=$(buildprefix)/$(SSHARED)
SO_DSTARGET=$(buildprefix)/$(DSSHARED)

DDEP = $(buildprefix) $(objprefix)/double $(objprefix)/complexdouble $(objprefix)/common
SDEP = $(buildprefix) $(objprefix)/single $(objprefix)/complexsingle $(objprefix)/common

all: static 

$(DSTARGET): $(DDEP) $(SDEP) $(COMMONFILES) $(DFILES) $(SFILES)
	$(AR) rv $@ $(COMMONFILES) $(DFILES) $(SFILES)
	$(RANLIB) $@

$(DTARGET): $(DDEP) $(DFILES) $(COMMONFILES)
	$(AR) rv $@ $(DFILES) $(COMMONFILES)
	$(RANLIB) $@

$(STARGET): $(SDEP) $(SFILES) $(COMMONFILESFORSFILES)
	$(AR) rv $@ $(SFILES) $(COMMONFILESFORSFILES)
	$(RANLIB) $@

$(SO_DSTARGET): $(DDEP) $(SDEP) $(COMMONFILES) $(DFILES) $(SFILES)
	$(CC) -shared -fPIC -o $@ $(COMMONFILES) $(DFILES) $(SFILES) $(LFLAGS) $(DSLFLAGS) 

$(SO_DTARGET): $(DDEP) $(COMMONFILES) $(DFILES)
	$(CC) -shared -fPIC -o $@ $(COMMONFILES) $(DFILES) $(LFLAGS) $(DLFLAGS)

$(SO_STARGET): $(SDEP) $(SFILES) $(COMMONFILESFORSFILES)
	$(CC) -shared -fPIC -o $@ $(COMMONFILESFORSFILES) $(SFILES) $(LFLAGS) $(SLFLAGS)

$(objprefix)/common/d%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS) -DLTFAT_DOUBLE -c $< -o $@ 

$(objprefix)/double/%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS) -DLTFAT_DOUBLE  -c $< -o $@

$(objprefix)/complexdouble/%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS) -DLTFAT_DOUBLE -DLTFAT_COMPLEXTYPE -c $< -o $@

$(objprefix)/double/kiss_%.o: $(SRCDIR)thirdparty/kissfft/%.c
	$(CC) $(CFLAGS) -DLTFAT_DOUBLE -c $< -o $@ 

$(objprefix)/common/s%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS)  -DLTFAT_SINGLE -c $< -o $@

$(objprefix)/single/%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS) -DLTFAT_SINGLE  -c $< -o $@

$(objprefix)/complexsingle/%.o: $(SRCDIR)src/%.c
	$(CC) $(CFLAGS) -DLTFAT_SINGLE -DLTFAT_COMPLEXTYPE -c $< -o $@

$(objprefix)/single/kiss_%.o: $(SRCDIR)thirdparty/kissfft/%.c
	$(CC) $(CFLAGS) -DLTFAT_SINGLE  -c $< -o $@

$(buildprefix):
	@$(MKDIR) $(subst /,$(PS)/,$(buildprefix))

$(objprefix)/%:
	@$(MKDIR) $(subst /,$(PS),$@)

.PHONY: clean cleanobj help doc doxy static shared allshared munit unit $(MODULE)

doc:
	(cd modules/libltfat ; doxygen doc/doxyconfig)
	(cd modules/libphaseret ; doxygen doc/doxyconfig)

static: $(DTARGET) $(STARGET) $(DSTARGET)

phaseret:
	$(MAKE) clean
	$(MAKE) MODULE=libphaseret

allshared:
	$(MAKE) clean
	$(MAKE) MODULE=libltfat shared 
	$(MAKE) MODULE=libphaseret shared

shared: $(SO_DTARGET) $(SO_STARGET) $(SO_DSTARGET)
	$(MAKE) $(buildprefix)/$(headerbase).h USECPP=0 CC=gcc

cleanobj:
	@-$(RMDIR) obj

clean: cleanobj
	@-$(RMDIR) build

cleanall: clean
	find . -name 'CMakeCache.txt' -o -name '*.cmake' -o -name 'CMakeFiles' -exec rm -rf {} +

help:
	@echo "USAGE: make [target]"
	@echo "Options:"
	@echo "    make [target] CONFIG=debug               Compiles the library in a debug mode"
	@echo "    make [target] NOBLASLAPACK=1             Compiles the library without BLAS and LAPACK dependencies"
	@echo "    make [target] USECPP=1                   Compiles the library using a C++ compiler"

allmunit:
	$(MAKE) clean
	$(MAKE) MODULE=libltfat munit
	$(MAKE) MODULE=libphaseret munit

munit: 
	$(MAKE) $(SO_DSTARGET) BLASLAPACKLIBS="-L$(MATLABROOT)/bin/glnxa64 -lmwblas -lmwlapack"
	$(MAKE) $(buildprefix)/$(headerbase).h USECPP=0 CC=gcc

$(buildprefix)/$(headerbase).h: $(buildprefix) 
	$(CC) -E -P -DLTFAT_NOSYSTEMHEADERS $(EXTRACFLAGS) $(OPTCFLAGS) -Imodules/libltfat/include -I$(SRCDIR)include -nostdinc $(SRCDIR)include/$(headerbase).h -o $(buildprefix)/$(headerbase).h
	sed -i '1 i #ifndef _$(headerbase)_H' $(buildprefix)/$(headerbase).h
	sed -i '1 a #define _$(headerbase)_H' $(buildprefix)/$(headerbase).h
	sed -i '2 a #ifndef LTFAT_NOSYSTEMHEADERS\n $(extradepincludes) #endif' $(buildprefix)/$(headerbase).h
	sed -i '$$ a #endif' $(buildprefix)/$(headerbase).h
	$(CC) -E -P -DLTFAT_NOSYSTEMHEADERS -Iinclude -nostdinc $(buildprefix)/$(headerbase).h -o $(buildprefix)/$(headerbase)_flat.h

install:
	install -d $(LIBDIR)
	install $(STARGET) $(DTARGET) $(DSTARGET) $(SO_STARGET) $(SO_DTARGET) $(SO_DSTARGET) $(LIBDIR)
	mkdir -p $(INCDIR)
	cp -r include/* $(INCDIR)

uninstall:
	rm -f $(LIBDIR)/$(DSTATIC) $(LIBDIR)/$(SSTATIC) $(LIBDIR)/$(DSSTATIC)
	rm -f $(LIBDIR)/$(DSHARED) $(LIBDIR)/$(SSHARED) $(LIBDIR)/$(DSSHARED)
	rm -f $(INCDIR)/$(headerbase).h
	rm -rf $(INCDIR)/$(headerbase)
