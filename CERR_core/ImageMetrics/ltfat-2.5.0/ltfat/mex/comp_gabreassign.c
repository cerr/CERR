#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 4
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define MATCHEDARGS 0, 1, 2

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_gabreassign.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  cout=comp_gabreassign(s,itime,ifreq,a);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   mwSignedIndex a, M, N, L;
   const LTFAT_REAL *tgrad, *fgrad;
   const LTFAT_TYPE *s;
   LTFAT_TYPE *sr;

   // Get matrix dimensions.
   M = mxGetM(prhs[0]);
   N = mxGetN(prhs[0]);
   a = (mwSignedIndex)mxGetScalar(prhs[3]);
   L = N*a;

   s     =  mxGetData(prhs[0]);
   tgrad =  mxGetData(prhs[1]);
   fgrad =  mxGetData(prhs[2]);

   plhs[0] = ltfatCreateMatrix(M,N, LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY);
   sr      = mxGetData(plhs[0]);

   LTFAT_NAME(gabreassign)(s,tgrad,fgrad,L,1,a,M,sr);
}
#endif
