#ifndef _ltfat_mex_includes_h
#define _ltfat_mex_includes_h

#ifndef LTFAT_LARGEARRAYS
#define LTFAT_LARGEARRAYS
#endif

#include "ltfat.h"
#include "ltfat/macros.h"
#include <stdio.h>
#include <string.h>

#ifndef MATLAB_MEX_FILE
#define MATLAB_MEX_FILE
#endif
#include <mex.h>

// Compatibility for pre-2017b
#ifndef MX_HAS_INTERLEAVED_COMPLEX
#define MX_HAS_INTERLEAVED_COMPLEX 0
#endif

#include <complex.h>

#endif
