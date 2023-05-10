#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 2
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */ 

#define MEX_FILE comp_idwilt.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_idwilt(c,g);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   int M, N, L, gl, W;

   // Get matrix dimensions.
   M = mxGetM(prhs[0])/2;
   // This is woraround to het number of columns
   N = 2*ltfatGetN(prhs[0]);
   gl= mxGetNumberOfElements(prhs[1]);
   W = mxGetNumberOfElements(prhs[0])/(M*N);

   L=N*M;

   plhs[0] = ltfatCreateMatrix(L,W,LTFAT_MX_CLASSID,LTFAT_MX_COMPLEXITY);

   const LTFAT_TYPE* c = (const LTFAT_TYPE*) mxGetData(prhs[0]);
   const LTFAT_TYPE* g = (const LTFAT_TYPE*) mxGetData(prhs[1]);
   LTFAT_TYPE* f = (LTFAT_TYPE*) mxGetData(plhs[0]);

   if(gl<L)
   {
      LTFAT_NAME(idwilt_fb)(c,g,L,gl,W,M,f);
   }
   else
   {
      LTFAT_NAME(idwilt_long)(c,g,L,W,M,f);
   }
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
