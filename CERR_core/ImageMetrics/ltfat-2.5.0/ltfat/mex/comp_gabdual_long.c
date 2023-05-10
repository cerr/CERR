#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 3
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_gabdual_long.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_gabdual_long(g,a,M);

void 
LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                         int UNUSED(nrhs), const mxArray *prhs[] )
{

   mwSignedIndex L, R, a, M;

   // Get matrix dimensions.
   L=(mwSignedIndex)mxGetM(prhs[0]);
   R=(mwSignedIndex)mxGetN(prhs[0]);
   a=(mwSignedIndex)mxGetScalar(prhs[1]);
   M=(mwSignedIndex)mxGetScalar(prhs[2]);

   plhs[0] = ltfatCreateMatrix(L, R,LTFAT_MX_CLASSID,LTFAT_MX_COMPLEXITY);
   LTFAT_TYPE* gd_combined = mxGetData(plhs[0]);
   const LTFAT_TYPE* g_combined = mxGetData(prhs[0]);

   LTFAT_NAME(multiwingabdual_long)(g_combined, L, R, a, M, gd_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
