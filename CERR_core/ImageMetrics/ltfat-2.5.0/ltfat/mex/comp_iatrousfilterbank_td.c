#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

/*  Define which arguments are to be checked and cast to single if either of them is single. */
#define NARGINEQ 4
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_iatrousfilterbank_td.c

/* The following header includes this file twice setting either LTFAT_SINGLE or LTFAT_DOUBLE.
    At the end of the header, LTFAT_SINGLE or LTFAT_DOUBLE is unset. */
#include "ltfat_mex_template_helper.h"
/* Do not allow processing this file further unless LTFAT_SINGLE or LTFAT_DOUBLE is specified. */
#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)


/** From now on, it is like ordinary mexFunction but params prhs[PRHSTOCHECK[i]], i=0:length(PRHSTOCHECK)-1 are now of type LTFAT_TYPE.
    Complex array still has to be processed separatelly.
    Enclose calls to the ltfat backend in LTFAT_NAME() macro.
    Enclose calls to the fftw in LTFAT_FFTW() macro.
    Avoid using mx functions working with concrete data type.
    e.g. use mxGetData intead of mxGetPr (or recast to LTFAT_TYPE*)
         mxCreateNumericArray with macro LTFAT_MX_CLASSID instead of createDoubleMatrix
 */
#include "ltfat/types.h"
/*
%COMP_IATROUSFILTERBANK_TD   Synthesis Uniform filterbank by conv2
%   Usage:  f=comp_iatrousfilterbank_fft(c,g,a,offset);
%
%   Input parameters:
%         c    : L*M*W array of coefficients.
%         g    : Filterbank filters - filtLen*M array.
%         a    : Filters upsampling factor - scalar.
%         offset : Delay of the filters - scalar or array of length M.
%
%   Output parameters:
%         f  : Output L*W array.
%
*/
void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    const mxArray* mxc = prhs[0];
    const mxArray* mxg = prhs[1];
    double* aDouble = mxGetPr(prhs[2]);
    double* offsetDouble = mxGetPr(prhs[3]);

    const mwSize *dims = mxGetDimensions(mxc);
    mwSize L = dims[0];
    // number of channels
    mwSize M = dims[1];
    mwSize W = 1;
    if (mxGetNumberOfDimensions(mxc) > 2)
    {
        W = dims[2];
    }

    // filter length
    mwSize filtLen = mxGetM(mxg);

    // allocate output
    mwSize ndim2 = 2;
    mwSize dims2[] = {L, W};
    plhs[0] = ltfatCreateNdimArray(ndim2, dims2, LTFAT_MX_CLASSID,
                                   LTFAT_MX_COMPLEXITY);

    // POINTER TO OUTPUT
    LTFAT_TYPE* fPtr = mxGetData(plhs[0]);

    // POINTER TO THE FILTERS
    const LTFAT_TYPE* gPtrs[M];
    ltfat_int offset[M];
    ltfat_int a[M];
    ltfat_int filtLens[M];

    for (mwSize m = 0; m < M; m++)
    {
        offset[m] = offsetDouble[m];
        a[m] = *aDouble;
        filtLens[m] = filtLen;
        gPtrs[m] = ((LTFAT_TYPE*) mxGetData(mxg)) + m * filtLen;
    }

    LTFAT_TYPE* cPtr = mxGetData(mxc);

    LTFAT_NAME(iatrousfilterbank_td)(cPtr, gPtrs, L, filtLens, W, a, offset, M,
                                     fPtr, PER);


}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
