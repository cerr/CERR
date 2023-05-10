#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define NARGINEQ 4
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_atrousfilterbank_td.c
#include "ltfat_mex_template_helper.h"
#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

/*
%COMP_ATROUSFILTERBANK_TD   Uniform filterbank by conv2
%   Usage:  c=comp_atrousfilterbank_td(f,g,a,offset);
%
%   Input parameters:
%         f   : Input data - L*W array.
%         g   : Filterbank filters - filtLen*M array.
%         a   : Filter upsampling factor - scalar.
%         offset: Delay of the filters - scalar or array of length M.
%
%   Output parameters:
%         c  : L*M*W array of coefficients
%
*/
void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   const mxArray* mxf = prhs[0];
   const mxArray* mxg = prhs[1];
   double* aDouble = mxGetPr(prhs[2]);
   double* offsetDouble = mxGetPr(prhs[3]);

   // input data length
   mwSize L = mxGetM(mxf);
   // number of channels
   mwSize W = mxGetN(mxf);
   // filter number
   mwSize M = mxGetN(mxg);
   // filter length
   mwSize filtLen = mxGetM(mxg);

   // POINTER TO THE INPUT
   LTFAT_TYPE* fPtr = mxGetData(prhs[0]);

   // POINTER TO THE FILTERS
   const LTFAT_TYPE* gPtrs[M];
   ltfat_int offset[M];
   ltfat_int a[M];
   ltfat_int filtLens[M];
   for(mwSize m=0; m<M; m++)
   {
      filtLens[m] = filtLen;
      a[m] = *aDouble;
      offset[m] = offsetDouble[m];
      gPtrs[m] = ((LTFAT_TYPE*) mxGetData(mxg)) + m*filtLen;
   }

   mwSize ndim = 3;
   mwSize dims[]= {L, M, W};
   plhs[0] = ltfatCreateNdimArray(ndim,dims,
                 LTFAT_MX_CLASSID,LTFAT_MX_COMPLEXITY);
   LTFAT_TYPE* cPtr = mxGetData(plhs[0]);

   LTFAT_NAME(atrousfilterbank_td)(fPtr, gPtrs, L, filtLens,
                                   W, a, offset, M, cPtr, PER);

}
#endif /* LTFAT_DOUBLE or LTFAT_SINGLE */
