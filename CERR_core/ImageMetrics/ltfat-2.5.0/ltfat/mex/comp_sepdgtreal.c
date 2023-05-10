#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_sepdgtreal.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
// comp_sepdgtreal(f,g,a,M);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[], 
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    int L, gl, W, a, M, N, M2;

    // Get matrix dimensions.
    L  = mxGetM(prhs[0]);
    W  = mxGetN(prhs[0]);
    gl = mxGetM(prhs[1]);

    a = (int)mxGetScalar(prhs[2]);
    M = (int)mxGetScalar(prhs[3]);
    int ptype = (int)mxGetScalar(prhs[4]) == 1 ? LTFAT_TIMEINV: LTFAT_FREQINV;
    M2 = M / 2 + 1;
    N = L / a;

    mwSize dims[] = {M2, N, W};
    mwSize ndim = W > 1 ? 3 : 2;
    plhs[0] = ltfatCreateNdimArray(ndim, dims, LTFAT_MX_CLASSID, mxCOMPLEX);
    const LTFAT_REAL * f = (const LTFAT_REAL *) mxGetData(prhs[0]);
    const LTFAT_REAL * g = (const LTFAT_REAL *) mxGetData(prhs[1]);
    LTFAT_COMPLEX* out_combined = (LTFAT_COMPLEX*) mxGetData(plhs[0]);

    if (gl < L)
    {
        LTFAT_NAME(dgtreal_fb)(f, g, L, gl, W, a, M, ptype, out_combined);
    }
    else
    {
        LTFAT_NAME(dgtreal_long)(f, g, L, W, a, M, ptype, out_combined);
    }
    return;
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */

