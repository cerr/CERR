#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 4
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXARGS

#endif /* _LTFAT_MEX_FILE */ 

#define MEX_FILE comp_iwfac.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_iwfac(gf,L,a,M)

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   int L, R, a, M;

   L=(int)mxGetScalar(prhs[1]);
   a=(int)mxGetScalar(prhs[2]);
   M=(int)mxGetScalar(prhs[3]);
   R=mxGetM(prhs[0])*mxGetN(prhs[0])/L;

   plhs[0] = ltfatCreateMatrix(L,R,LTFAT_MX_CLASSID,mxCOMPLEX);
   const LTFAT_COMPLEX* gf_combined = (const LTFAT_COMPLEX*) mxGetData(prhs[0]);
   LTFAT_COMPLEX* g_combined = (LTFAT_COMPLEX*) mxGetData(plhs[0]);

   LTFAT_NAME_COMPLEX(iwfac)(gf_combined, L, R, a, M, g_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
