#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 4
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_chirpzt.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
// Calling convention:
//  c = comp_chirpcz(f,K,deltao,o)

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{

    mwSize L  = mxGetM(prhs[0]);
    mwSize W  = mxGetN(prhs[0]);
    mwSize K = (mwSize) mxGetScalar(prhs[1]);
    double deltao = mxGetScalar(prhs[2]);
    double o = mxGetScalar(prhs[3]);
    const LTFAT_TYPE* fPtr = mxGetData(prhs[0]);

    plhs[0] = ltfatCreateMatrix(K, W, LTFAT_MX_CLASSID, mxCOMPLEX);
    LTFAT_COMPLEX* cPtr = mxGetData(plhs[0]);

    LTFAT_NAME(chzt)(fPtr, L, W, K, deltao, o, cPtr);
    // Alternative implementation
    // LTFAT_NAME(chzt_fact)(fPtr,L,W,K,deltao,o,cPtr);

    return;
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
