#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 13
#define TYPEDEPARGS 0, 1, 2, 4, 5, 12
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_filterbankmaskedheapint.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//                                        0     1     2     3       4     5     6  7 8 9  10        11       12
// phase=comp_filterbankmaskedheapintreal(s,tgrad,fgrad,neigh,posInfo,cfreq, mask, a,M,N,tol,phasetype,usephase);

// phasetype defines how to adjust tgrad and fgrad such that
// phase corresponds to:
// phasetype  1:  timeinv
// phasetype  2:  do not adjust the gradient, it is already correct

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray* plhs[],
                              int UNUSED(nrhs), const mxArray* prhs[] )
{
    // Get inputs
    const mxArray* mxs  = prhs[0];
    const mxArray* mxneigh  = prhs[3];
    const mxArray* mxposinfo  = prhs[4];

    const LTFAT_REAL* s = mxGetData(mxs);

    const LTFAT_REAL* tgrad = mxGetData(prhs[1]);
    const LTFAT_REAL* fgrad = mxGetData(prhs[2]);
    const LTFAT_REAL* cfreq = mxGetData(prhs[5]);
    const double* maskDouble = mxGetData(prhs[6]);

    double* a = mxGetData(prhs[7]);
    mwSize M = (mwSize)mxGetScalar(prhs[8]);

    ltfat_int NPtr[M];

    double* N  = mxGetData(prhs[9]);

    for (mwSize ii = 0; ii < M; ++ii)
        NPtr[ii] = (ltfat_int) N[ii];

    LTFAT_REAL tol = (LTFAT_REAL) mxGetScalar(prhs[10]);
    int phasetype = (int)mxGetScalar(prhs[11]);
    const LTFAT_REAL* knownphase = mxGetData(prhs[12]);

    const ltfat_int Nsum = mxGetM(mxs);
    const ltfat_int W = mxGetN(mxs);

    int* mask = ltfat_malloc(Nsum * W * sizeof * mask);

    for (ltfat_int w = 0; w < Nsum * W; w++ )
        mask[w] = (int) maskDouble[w];

    mwSize neighLen = mxGetNumberOfElements(mxneigh);
    ltfat_int* neighPtr = ltfat_malloc(neighLen * sizeof * neighPtr);

    const double* neighDoublePtr = mxGetData(mxneigh);
    for (mwSize ii = 0; ii < neighLen; ++ii)
        neighPtr[ii] = (ltfat_int) neighDoublePtr[ii];

    const LTFAT_REAL* posinfoPtr = mxGetData(mxposinfo);


    // Create output matrix and zero it.
    plhs[0] = ltfatCreateNdimArray(mxGetNumberOfDimensions(mxs),
                                   mxGetDimensions(mxs),
                                   LTFAT_MX_CLASSID, mxREAL);

    // Get pointer to output
    LTFAT_REAL* phase = mxGetData(plhs[0]);
    memcpy(phase, knownphase, Nsum * W * sizeof * phase);

    //mexPrintf("L=%i, n[0] = %i, a = %f, M = %i \n",L,neighPtr[0],a[0],M);

    if (phasetype == 1)
        LTFAT_NAME(filterbankmaskedheapint)(s, tgrad, fgrad, mask, neighPtr, posinfoPtr, cfreq,
                                     a, M, NPtr, Nsum, W, tol, phase);
    else
        LTFAT_NAME(filterbankmaskedheapint_relgrad)(s , tgrad, fgrad, mask, neighPtr,
                                             posinfoPtr, cfreq, a, M, NPtr, Nsum, W, tol, phase);

    ltfat_free(mask);
    ltfat_free(neighPtr);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
