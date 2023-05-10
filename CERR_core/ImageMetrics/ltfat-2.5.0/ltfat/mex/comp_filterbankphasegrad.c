#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0, 1, 2
#define SINGLEARGS
#define COMPLEXARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_filterbankphasegrad.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
// [tgrad,fgrad,cs] = comp_filterbankphasegrad(c,ch,cd,L,minlvl);
//  or

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[])
{
   const mxArray* mxc = prhs[0];
   const mxArray* mxch = prhs[1];
   const mxArray* mxcd = prhs[2];
   const double L = mxGetScalar(prhs[3]);
   const double minlvl = mxGetScalar(prhs[4]);

   ltfat_int M = mxGetNumberOfElements(mxc);

   const LTFAT_COMPLEX* cPtr[M];
   const LTFAT_COMPLEX* chPtr[M];
   const LTFAT_COMPLEX* cdPtr[M];

   LTFAT_REAL* tgradPtr[M];
   LTFAT_REAL* fgradPtr[M];
   LTFAT_REAL* csPtr[M];

   ltfat_int N[M];

   mxArray* mxtgrad = plhs[0] = mxCreateCellMatrix(M, 1);
   mxArray* mxfgrad = plhs[1] = mxCreateCellMatrix(M, 1);
   mxArray* mxcs = plhs[2] = mxCreateCellMatrix(M, 1);

   for (ltfat_int m = 0; m < M; m++)
   {
      N[m] = mxGetM(mxGetCell(mxc, m));
      cPtr[m] = mxGetData(mxGetCell(mxc, m));
      chPtr[m] = mxGetData(mxGetCell(mxch, m));
      cdPtr[m] = mxGetData(mxGetCell(mxcd, m));

      mxSetCell(mxtgrad, m, ltfatCreateMatrix(N[m], 1, LTFAT_MX_CLASSID, mxREAL));
      mxSetCell(mxfgrad, m, ltfatCreateMatrix(N[m], 1, LTFAT_MX_CLASSID, mxREAL));
      mxSetCell(mxcs,    m, ltfatCreateMatrix(N[m], 1, LTFAT_MX_CLASSID, mxREAL));
      tgradPtr[m] = mxGetData(mxGetCell(mxtgrad, m));
      fgradPtr[m] = mxGetData(mxGetCell(mxfgrad, m));
      csPtr[m] = mxGetData(mxGetCell(mxcs, m));
   }

   LTFAT_NAME(filterbankphasegrad)(cPtr,chPtr,cdPtr,M,N,L,minlvl,
                                   tgradPtr,fgradPtr,csPtr);
}
#endif
