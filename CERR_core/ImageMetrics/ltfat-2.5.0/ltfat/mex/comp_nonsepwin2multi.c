#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXARGS

/*
int ltfat_round(double x)
{
  return (int)(x+.5);
}
*/

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_nonsepwin2multi.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  comp_nonsepwin2multi(g,a,M,lt,L);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   ltfat_int a, M, L, Lg, lt1, lt2;
   double *lt;

   // Get matrix dimensions.
   Lg = mxGetM(prhs[0]);

   a=(ltfat_int)mxGetScalar(prhs[1]);
   M=(ltfat_int)mxGetScalar(prhs[2]);
   L=(ltfat_int)mxGetScalar(prhs[4]);

   // Read the values of lt and round them to integers.
   lt = mxGetPr(prhs[3]);
   lt1 = ltfat_round(lt[0]);
   lt2 = ltfat_round(lt[1]);

   plhs[0] = ltfatCreateMatrix(L, lt2,LTFAT_MX_CLASSID,mxCOMPLEX);
   const LTFAT_COMPLEX* g_combined = (const LTFAT_COMPLEX*) mxGetData(prhs[0]);
   LTFAT_COMPLEX* out_combined = (LTFAT_COMPLEX*) mxGetData(plhs[0]);

   LTFAT_NAME(nonsepwin2multi)(g_combined,L,Lg,a,M,lt1,lt2,out_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
