#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 3
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_wfac.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_wfac(g,a,M);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   int L, R, N, c, d, p, q;
   ltfat_int a,M,h_a,h_m;

   // Get matrix dimensions.
   L = mxGetM(prhs[0]);
   R = mxGetN(prhs[0]);

   a=(ltfat_int)mxGetScalar(prhs[1]);
   M=(ltfat_int)mxGetScalar(prhs[2]);

   N=L/a;

   c=ltfat_gcd(a, M, &h_a, &h_m);
   p=a/c;
   q=M/c;
   d=N/q;

   plhs[0] = ltfatCreateMatrix(p*q*R, c*d,LTFAT_MX_CLASSID,mxCOMPLEX);
   LTFAT_COMPLEX* gf_combined = mxGetData(plhs[0]);
   const LTFAT_TYPE* g_combined = mxGetData(prhs[0]);
   LTFAT_NAME(wfac)(g_combined, L, R, a, M, gf_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
