#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 3
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_dwilt.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_dwilt(f,g,M);

void
LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                         int UNUSED(nrhs), const mxArray *prhs[] )
{
    mwSignedIndex M, N, L, gl, W;

    // Get matrix dimensions.
    M = (mwSignedIndex)mxGetScalar(prhs[2]);
    L = (mwSignedIndex)mxGetM(prhs[0]);
    gl = (mwSignedIndex) mxGetM(prhs[1]);
    W = mxGetN(prhs[0]);

    N = L / M;

    mwSize dims[] = {2 * M, N / 2, W};
    mwSize ndim = W > 1 ? 3 : 2;
    plhs[0] = ltfatCreateNdimArray(ndim, dims,
                                   LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY);

    const LTFAT_TYPE* f = mxGetData(prhs[0]);
    const LTFAT_TYPE* g = mxGetData(prhs[1]);
    LTFAT_TYPE* cout = mxGetData(plhs[0]);

    if (gl < L)
    {
        LTFAT_NAME(dwilt_fb)(f, g, L, gl, W, M, cout);
    }
    else
    {
        LTFAT_NAME(dwilt_long)(f, g, L, W, M, cout);
    }
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
