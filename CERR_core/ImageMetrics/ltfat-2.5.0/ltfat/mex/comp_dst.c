#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 2

#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_dst.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

void
LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                         int UNUSED(nrhs), const mxArray *prhs[] )
{
   dct_kind kind = DSTI;

   mwIndex L = mxGetM(prhs[0]);
   mwIndex W = mxGetN(prhs[0]);
   mwIndex type = (mwIndex) mxGetScalar(prhs[1]);

   plhs[0] = ltfatCreateMatrix(L, W, LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY);

   switch (type)
   {
   case 1: kind = DSTI; break;
   case 2: kind = DSTII; break;
   case 3: kind = DSTIII; break;
   case 4: kind = DSTIV; break;
   default: mexErrMsgTxt("Unknown type.");
   }

   LTFAT_NAME(dst)( mxGetData(prhs[0]), L, W,  mxGetData(plhs[0]), kind);
}
#endif

