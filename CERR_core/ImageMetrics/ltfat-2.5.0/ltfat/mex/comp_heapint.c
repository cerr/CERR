#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 6
#define TYPEDEPARGS 0, 1, 2
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_heapint.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//                    0     1     2 3   4         5
// phase=comp_heapint(s,tgrad,fgrad,a,tol,phasetype);
// phasetype defines how to adjust tgrad and fgrad such that
// phase corresponds to:
// phasetype  0:  freqinv
// phasetype  1:  timeinv
// phasetype  2:  do not adjust the gradient, it is already correct

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray* plhs[],
                              int UNUSED(nrhs), const mxArray* prhs[] )
{
    // Get inputs
    const mxArray* mxs  = prhs[0];
    const LTFAT_REAL* s = mxGetData(mxs);
    const LTFAT_REAL* tgrad = mxGetData(prhs[1]);
    const LTFAT_REAL* fgrad = mxGetData(prhs[2]);
    mwSize a     = (mwSize)mxGetScalar(prhs[3]);
    LTFAT_REAL tol = (LTFAT_REAL) mxGetScalar(prhs[4]);
    int phasetype = (int)mxGetScalar(prhs[5]);
    switch (phasetype)
    {
        case 0: phasetype = LTFAT_FREQINV; break;
        case 1: phasetype = LTFAT_TIMEINV; break;
    }

    // Get matrix dimensions.
    mwSize M = mxGetM(mxs);
    mwSize N = ltfatGetN(mxs);
    mwSize L = N * a;
    mwSize W = 1;

    if (mxGetNumberOfDimensions(mxs) > 2)
        W = mxGetDimensions(mxs)[2];

    // Create empty output matrix
    plhs[0] = ltfatCreateNdimArray(mxGetNumberOfDimensions(mxs),
                                   mxGetDimensions(mxs),
                                   LTFAT_MX_CLASSID, mxREAL);

    // Get pointer to output
    LTFAT_REAL* phase = mxGetData(plhs[0]);

    if (phasetype == 2)
        LTFAT_NAME(heapint)(s, tgrad, fgrad, a, M, L, W, tol, phase);
    else
        LTFAT_NAME(heapint_relgrad)(s, tgrad, fgrad, a, M, L, W, tol,
                                    phasetype, phase);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
