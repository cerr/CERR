#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 6
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
// The following forces converting coef and g to a complex type
#define COMPLEXARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_isepdgt.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_isepdgt(coef,g,L,a,M,phasetype);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    int L, W, a, M, N, gl;
    // Get matrix dimensions.
    L = (int)mxGetScalar(prhs[2]);
    a = (int)mxGetScalar(prhs[3]);
    M = (int)mxGetScalar(prhs[4]);
    int ptype = (int)mxGetScalar(prhs[5]) == 1 ? LTFAT_TIMEINV: LTFAT_FREQINV;
    N = L / a;

    gl = mxGetM(prhs[1]);
    W  = mxGetNumberOfElements(prhs[0]) / (M * N);

    plhs[0] = ltfatCreateMatrix(L, W, LTFAT_MX_CLASSID, mxCOMPLEX);
    const LTFAT_COMPLEX* c_combined = mxGetData(prhs[0]);
    const LTFAT_COMPLEX* g_combined = mxGetData(prhs[1]);
    LTFAT_COMPLEX* f_combined = mxGetData(plhs[0]);

    if (gl < L)
    {
        LTFAT_NAME_COMPLEX(idgt_fb)(c_combined, g_combined, L, gl, W, a, M, ptype,
                            f_combined);
    }
    else
    {
        LTFAT_NAME_COMPLEX(idgt_long)(c_combined, g_combined, L, W, a, M, ptype,
                              f_combined);
    }
    /*
     NOT CALLING idgt_fb_r:
     */
    return;
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
