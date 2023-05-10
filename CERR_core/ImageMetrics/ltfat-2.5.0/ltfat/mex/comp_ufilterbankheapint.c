#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 8
#define TYPEDEPARGS 0, 1, 2, 3
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_ufilterbankheapint.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//                               0     1     2     3 4       5   6         7
// phase=comp_ufilterbankheapint(s,tgrad,fgrad,cfreq,a,do_real,tol,phasetype);
// phasetype defines how to adjust tgrad and fgrad such that
// phase corresponds to:
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
    const LTFAT_REAL* cfreq = mxGetData(prhs[3]);
    mwSize a     = (mwSize)mxGetScalar(prhs[4]);
    const int do_real = (int)mxGetScalar(prhs[5]);
    LTFAT_REAL tol = (LTFAT_REAL) mxGetScalar(prhs[6]);
    int phasetype = (int)mxGetScalar(prhs[7]);

    // Get matrix dimensions.
    mwSize M = ltfatGetN(mxs);
    mwSize N = mxGetM(mxs);
    mwSize L = N * a;
    mwSize W = 1;
    //phasetype--;

    if (mxGetNumberOfDimensions(mxs) > 2)
        W = mxGetDimensions(mxs)[2];

    // Create empty output matrix
    plhs[0] = ltfatCreateNdimArray(mxGetNumberOfDimensions(mxs),
                                   mxGetDimensions(mxs),
                                   LTFAT_MX_CLASSID, mxREAL);

    // Get pointer to output
    LTFAT_REAL* phase = mxGetData(plhs[0]);

    if (phasetype == 1)
        LTFAT_NAME(ufilterbankheapint)(s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol, phase);
    else
        LTFAT_NAME(ufilterbankheapint_relgrad)(s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol,
                                    phase);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
