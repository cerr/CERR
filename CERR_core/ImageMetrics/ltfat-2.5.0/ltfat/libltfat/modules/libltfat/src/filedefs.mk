files = dgt.c dgtreal_fb.c dgt_multi.c dgt_ola.c dgt_shear.c	\
		dgtreal_long.c dwilt.c idwilt.c wmdct.c iwmdct.c \
		filterbank.c ifilterbank.c heapint.c heap.c wfacreal.c \
		idgtreal_long.c idgtreal_fb.c iwfacreal.c pfilt.c reassign_ti.c \
		windows.c  \
		dgt_shearola.c utils.c rtdgtreal.c circularbuf.c slicingbuf.c \
		dgtrealwrapper.c dgtrealmp.c dgtrealmp_parbuf.c dgtrealmp_kernel.c dgtrealmp_guts.c maxtree.c \
		slidgtrealmp.c \
		filterbankphaseret.c fbheapint.c

files_complextransp =\
ci_utils.c ci_windows.c spread.c wavelets.c goertzel.c \
reassign.c gabdual_painless.c wfac.c iwfac.c \
dgt_long.c idgt_long.c dgt_fb.c idgt_fb.c ci_memalloc.c \
dgtwrapper.c

files_blaslapack = ltfat_blaslapack.c gabdual_fac.c gabtight_fac.c

files_blaslapack_complextransp = gabdual.c gabtight.c

files_fftw_complextransp = dct.c dst.c

files_notypechange = memalloc.c error.c version.c argchecks.c \
					 dgtwrapper_typeconstant.c dgtrealmp_typeconstant.c  \
				   	 reassign_typeconstant.c wavelets_typeconstant.c \
					 integer_manip.c firwin_typeconstant.c

FFTBACKEND ?= FFTW

ifneq ($(FFTBACKEND),FFTW)
ifneq ($(FFTBACKEND),KISS)
$(error FFTBACKEND must be either FFTW or KISS)
endif
endif

ifeq ($(FFTBACKEND),FFTW)
	files += fftw_wrappers.c
	files_complextransp += $(files_fftw_complextransp)
	LFLAGS+= $(FFTWLIBS)
	CFLAGS+=-DFFTW
endif

ifeq ($(FFTBACKEND),KISS)
	files += kissfft_wrappers.c kiss_fft.c
	CFLAGS+=-DKISS
endif

ifndef NOBLASLAPACK
	files += $(files_blaslapack)
	files_complextransp += $(files_blaslapack_complextransp)
 	LFLAGS+=$(BLASLAPACKLIBS)
endif

extradepincludes:=\#include <stddef.h>\n

