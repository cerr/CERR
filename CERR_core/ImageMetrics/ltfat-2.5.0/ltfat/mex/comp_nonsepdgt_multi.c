#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS

/*
int ltfat_round(double x)
{
  return (int)(x+.5);
}
*/

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_nonsepdgt_multi.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//    c=comp_nonsepdgt_multi(f,g,a,M,lt);

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   ltfat_int a, M, N, L, W, Lg, lt1, lt2;

   double *lt;

   // Get matrix dimensions.
   L  = mxGetM(prhs[0]);
   W  = mxGetN(prhs[0]);
   Lg = mxGetM(prhs[1]);

   a=(ltfat_int)mxGetScalar(prhs[2]);
   M=(ltfat_int)mxGetScalar(prhs[3]);

   // Read the values of lt and round them to integers.
   lt = mxGetPr(prhs[4]);
   lt1 = ltfat_round(lt[0]);
   lt2 = ltfat_round(lt[1]);

   N  = L/a;

   mwSize dims[] = { M, N, W};
   mwSize ndim=W>1?3:2;

   plhs[0] = ltfatCreateNdimArray(ndim,dims,LTFAT_MX_CLASSID,mxCOMPLEX);
   const LTFAT_COMPLEX* f_combined = mxGetData(prhs[0]);
   const LTFAT_COMPLEX* g_combined = mxGetData(prhs[1]);
   LTFAT_COMPLEX* out_combined = mxGetData(plhs[0]);

   LTFAT_NAME(dgt_multi)(f_combined,g_combined,L,Lg,W,a,M,lt1,lt2, out_combined);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
