#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 9
#define TYPEDEPARGS 0, 1, 2, 8
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_maskedheapintreal.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//                              0     1     2    3 4 5   6         7        8
// phase=comp_maskedheapintreal(s,tgrad,fgrad,mask,a,M,tol,phasetype,usephase);
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
    const LTFAT_REAL* s     = mxGetData(mxs);
    const LTFAT_REAL* tgrad = mxGetData(prhs[1]);
    const LTFAT_REAL* fgrad = mxGetData(prhs[2]);
    const double* maskDouble  = mxGetData(prhs[3]);
    mwSize a      = (mwSize)mxGetScalar(prhs[4]);
    LTFAT_REAL tol = (LTFAT_REAL)mxGetScalar(prhs[6]);
    const LTFAT_REAL* knownphase = mxGetData(prhs[8]);
    int phasetype = (int)mxGetScalar(prhs[7]);
    switch (phasetype)
    {
        case 0: phasetype = LTFAT_FREQINV; break;
        case 1: phasetype = LTFAT_TIMEINV; break;
    }

    // Get matrix dimensions.
    mwSize M = (int) mxGetScalar(prhs[5]);
    mwSize M2 = mxGetM(prhs[0]);
    mwSize N = ltfatGetN(prhs[0]);
    mwSize L = N * a;
    mwSize W = 1;

    if (mxGetNumberOfDimensions(mxs) > 2)
        W = mxGetDimensions(mxs)[2];

    int* mask = ltfat_malloc(M2 * N * W * sizeof * mask);

    for (mwSize w = 0; w < M2 * N * W; w++ )
        mask[w] = (int) maskDouble[w];

    // Create output matrix and zero it.
    plhs[0] = ltfatCreateNdimArray(mxGetNumberOfDimensions(mxs),
                                   mxGetDimensions(mxs),
                                   LTFAT_MX_CLASSID, mxREAL);

    // Get pointer to output
    LTFAT_REAL* phase = mxGetData(plhs[0]);

    memcpy(phase, knownphase, M2 * N * W * sizeof * phase);

    if (phasetype == 2)
        LTFAT_NAME(maskedheapintreal)(s, tgrad, fgrad, mask, a, M, L, W, tol,
                                      phase );
    else
        LTFAT_NAME(maskedheapintreal_relgrad)(s, tgrad, fgrad, mask, a, M, L, W,
                                              tol, phasetype, phase );

    ltfat_free(mask);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
