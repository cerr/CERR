#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 7
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_nonsepdgt_shear.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
// c=comp_nonsepdgt_shear(f,g,a,M,s0,s1,br);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
  int a, M, N, L, W, s0, s1, br;

   // Get matrix dimensions.
   L  = mxGetM(prhs[0]);
   W  = mxGetN(prhs[0]);

   a  = (int)mxGetScalar(prhs[2]);
   M  = (int)mxGetScalar(prhs[3]);
   s0 = (int)mxGetScalar(prhs[4]);
   s1 = (int)mxGetScalar(prhs[5]);
   br = (int)mxGetScalar(prhs[6]);

   N  = L/a;

   mwSize dims[]={ M, N, W};
   mwSize ndim=W>1?3:2;
   plhs[0] = ltfatCreateNdimArray(ndim,dims,LTFAT_MX_CLASSID,mxCOMPLEX);
   const LTFAT_COMPLEX* f_combined = (const LTFAT_COMPLEX*) mxGetData(prhs[0]);
   const LTFAT_COMPLEX* g_combined = (const LTFAT_COMPLEX*) mxGetData(prhs[1]);
   LTFAT_COMPLEX* out_combined = (LTFAT_COMPLEX*) mxGetData(plhs[0]);

   LTFAT_NAME(dgt_shear)(f_combined,g_combined,L,W,a,M,s0,s1,br,out_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE*/
