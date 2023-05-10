#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 10
#define TYPEDEPARGS 0, 1, 2, 3, 9
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_ufilterbankmaskedheapint.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//                                     0     1     2     3    4 5       6   7         8        9
// phase=comp_ufilterbankmaskedheapint(s,tgrad,fgrad,cfreq,mask,a,do_real,tol,phasetype,usephase);
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
    const LTFAT_REAL* s      = mxGetData(mxs);
    const LTFAT_REAL* tgrad  = mxGetData(prhs[1]);
    const LTFAT_REAL* fgrad  = mxGetData(prhs[2]);
    const LTFAT_REAL* cfreq  = mxGetData(prhs[3]);
    const double* maskDouble = mxGetData(prhs[4]);
    mwSize a     = (mwSize)mxGetScalar(prhs[5]);
    const int do_real = (int)mxGetScalar(prhs[6]);
    LTFAT_REAL tol   = (LTFAT_REAL)mxGetScalar(prhs[7]);
    int phasetype   = (int)mxGetScalar(prhs[8]);
    const LTFAT_REAL* knownphase = mxGetData(prhs[9]);

    // Get matrix dimensions.
    mwSize M = ltfatGetN(prhs[0]);
    mwSize N = mxGetM(prhs[0]);
    mwSize L = N * a;
    mwSize W = 1;
    //phasetype--;

    if (mxGetNumberOfDimensions(mxs) > 2)
        W = mxGetDimensions(mxs)[2];

    int* mask = ltfat_malloc(M * N * W * sizeof * mask);

    for (mwSize w = 0; w < M * N * W; w++ )
        mask[w] = (int) maskDouble[w];

    // Create output matrix and zero it.
    plhs[0] = ltfatCreateNdimArray(mxGetNumberOfDimensions(mxs),
                                   mxGetDimensions(mxs),
                                   LTFAT_MX_CLASSID, mxREAL);

    // Get pointer to output
    LTFAT_REAL* phase = mxGetData(plhs[0]);

    memcpy(phase, knownphase, M * N * W * sizeof * phase);

    if (phasetype == 1)
        LTFAT_NAME(ufilterbankmaskedheapint)(s, tgrad, fgrad, cfreq, mask,
                                  a, M, L, W, do_real, tol, phase);
    else
        LTFAT_NAME(ufilterbankmaskedheapint_relgrad)(s, tgrad, fgrad, cfreq, mask,
                                          a, M, L, W, do_real, tol, phase);


    ltfat_free(mask);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
