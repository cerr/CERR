#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_sepdgt.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_dgt_fb(f,g,a,M);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    int L  = mxGetM(prhs[0]);
    int W  = mxGetN(prhs[0]);
    int gl = mxGetNumberOfElements(prhs[1]);
    int a = (int)mxGetScalar(prhs[2]);
    int M = (int)mxGetScalar(prhs[3]);
    int ptype = (int)mxGetScalar(prhs[4]) == 1 ? LTFAT_TIMEINV: LTFAT_FREQINV;;
    int N = L / a;

    mwSize dims[3] = {M, N, W};
    mwSize ndim = W > 1 ? 3 : 2;
    plhs[0] = ltfatCreateNdimArray(ndim, dims, LTFAT_MX_CLASSID, mxCOMPLEX);
    const LTFAT_TYPE* f_combined = mxGetData(prhs[0]);
    const LTFAT_TYPE* g_combined = mxGetData(prhs[1]);
    LTFAT_COMPLEX* out_combined = mxGetData(plhs[0]);

    if (gl < L)
    {
        LTFAT_NAME(dgt_fb)(f_combined, g_combined, L, gl, W, a, M, ptype,
                           out_combined);
    }
    else
    {
        LTFAT_NAME(dgt_long)(f_combined, g_combined, L, W, a, M, ptype,
                             out_combined);
    }
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */

