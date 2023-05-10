#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 2
#define TYPEDEPARGS 0
#define MATCHEDARGS 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_gga.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)

// Calling convention:
//  c = comp_gga(f,indvec)

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    mwSize L  = mxGetM(prhs[0]);
    mwSize W  = mxGetN(prhs[0]);
    mwSize M = mxGetNumberOfElements(prhs[1]);

    const LTFAT_TYPE* fPtr = mxGetData(prhs[0]);
    const LTFAT_REAL* indVecPtr = mxGetData(prhs[1]);

    plhs[0] = ltfatCreateMatrix(M, W, LTFAT_MX_CLASSID, mxCOMPLEX);
    LTFAT_COMPLEX* cPtr = mxGetData(plhs[0]);

    LTFAT_NAME(gga)(fPtr, indVecPtr, L, W, M, cPtr);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
