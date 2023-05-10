#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 6

#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXARGS
#define MATCHEDARGS 1

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_isepdgtreal.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_isepdgtreal(coef,g,L,a,M);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    int L, W, a, M, N, gl, M2;

    // Get matrix dimensions.
    L = (int)mxGetScalar(prhs[2]);
    a = (int)mxGetScalar(prhs[3]);
    M = (int)mxGetScalar(prhs[4]);
    int ptype = (int)mxGetScalar(prhs[5]) == 1 ? LTFAT_TIMEINV: LTFAT_FREQINV;
    N = L / a;
    M2 = M / 2 + 1;
    W = mxGetNumberOfElements(prhs[0]) / (N * M2);
    gl = mxGetM(prhs[1]);


    plhs[0] = ltfatCreateMatrix(L, W, LTFAT_MX_CLASSID, mxREAL);
    const LTFAT_COMPLEX* c_combined = (const LTFAT_COMPLEX*) mxGetData(prhs[0]);
    const LTFAT_REAL * g = (const LTFAT_REAL *) mxGetData(prhs[1]);
    LTFAT_REAL* f_r = (LTFAT_REAL*) mxGetData(plhs[0]);

    if (gl < L)
    {
        LTFAT_NAME(idgtreal_fb)(c_combined, g, L, gl, W, a, M, ptype, f_r);
    }
    else
    {
        LTFAT_NAME(idgtreal_long)(c_combined, g, L, W, a, M, ptype, f_r);
    }
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
