#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

/*  Define which arguments are to be checked and cast to single if either of them is single. */
#define NARGINEQ 6
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT


#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

#define MEX_FILE comp_ifilterbank_td.c


#include "ltfat_mex_template_helper.h"
#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)

#include "mex.h"
#include "math.h"
#include "ltfat.h"
/**  The following defines single and double versions for the types and macros:
  LTFAT_COMPLEX - fftw_complex or fftwf_complex
  LTFAT_REAL - double or float
  LTFAT_NAME(name) - for LTFAT_SINGLE add "s" to the beginning of the function name
  LTFAT_FFTW(name) - adds "fftw_" or "fftwf_" to the beginning of the function name
  LTFAT_MX_CLASSID - mxDOUBLE_CLASS or mxSINGLE_CLASS
**/
#include "ltfat/types.h"

/*
%COMP_IFILTERBANK_TD   Synthesis filterbank
%   Usage:  f=comp_ifilterbank_td(c,g,a,Ls,offset,ext);
%
%   Input parameters:
%         c    : Cell array of length M, each element is N(m)*W matrix.
%         g    : Filterbank filters - length M cell-array, each element is vector of length filtLen(m)
%         a    : Upsampling factors - array of length M.
%         Ls   : Output length.
%         offset : Delay of the filters - scalar or array of length M.
%         ext  : Border exension technique.
%
%   Output parameters:
%         f  : Output Ls*W array.
%
*/
void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    // printf("Filename: %s, Function name %s, %d \n.",__FILE__,__func__,mxIsDouble(prhs[0]));
    const mxArray* mxc = prhs[0];
    const mxArray* mxg = prhs[1];
    double* aDouble = mxGetPr(prhs[2]);
    double* Lsdouble = mxGetPr(prhs[3]);
    mwSize L = (mwSize) *Lsdouble;
    double* offsetDouble = mxGetPr(prhs[4]);
    ltfatExtType ext = ltfatExtStringToEnum( mxArrayToString(prhs[5]) );

    // number of channels
    mwSize W = mxGetN(mxGetCell(mxc,0));

    // filter number
    mwSize M = mxGetNumberOfElements(mxg);

    const LTFAT_TYPE* cPtrs[M];


    // filter lengths
    ltfat_int filtLen[M];
    ltfat_int a[M];
    ltfat_int offset[M];

    // allocate output
    plhs[0] = ltfatCreateMatrix(L, W,LTFAT_MX_CLASSID,LTFAT_MX_COMPLEXITY);


    // POINTER TO OUTPUT
    LTFAT_TYPE* fPtr = mxGetData(plhs[0]);

    // POINTER TO THE FILTERS
    const LTFAT_TYPE* gPtrs[M];

    //double skip[M];
    for(mwSize m=0; m<M; m++)
    {
        a[m] = (ltfat_int) aDouble[m];
        offset[m] = (ltfat_int) offsetDouble[m];
        filtLen[m] = (ltfat_int) mxGetNumberOfElements(mxGetCell(mxg,m));
        gPtrs[m] = mxGetData(mxGetCell(mxg, m));
        cPtrs[m] = mxGetData(mxGetCell(mxc, m));
    }

    LTFAT_NAME(ifilterbank_td)(cPtrs,gPtrs,L,filtLen,W,a,offset,M,fPtr,ext);

}
#endif
