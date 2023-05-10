#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0
#define MATCHEDARGS 1, 2
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_filterbankreassign.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:
//  cout=comp_filterbankreassign(s,tgrad,fgrad,a,cfreq);
//  or
//  [cout,repos]=comp_filterbankreassign(s,tgrad,fgrad,a,cfreq);

void LTFAT_NAME(ltfatMexFnc)( int nlhs, mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[])
{
   const mxArray* mxs = prhs[0];
   const mxArray* mxtgrad = prhs[1];
   const mxArray* mxfgrad = prhs[2];
   const mxArray* mxa = prhs[3];
   const mxArray* mxcfreq = prhs[4];

   ltfat_int M = mxGetNumberOfElements(mxs);

   const LTFAT_TYPE* sPtr[M];
   const LTFAT_REAL* tgradPtr[M];
   const LTFAT_REAL* fgradPtr[M];
   double aPtr[M];
   double cfreqPtr[M];
   LTFAT_TYPE* srPtr[M];

   ltfat_int N[M];
   mxArray* mxsr = mxCreateCellMatrix(M, 1);
   plhs[0] = mxsr;

   const double* a = mxGetPr(mxa);
   const double* cfreq = mxGetPr(mxcfreq);

   memcpy(aPtr, a, M * sizeof * a);
   memcpy(cfreqPtr, cfreq, M * sizeof * cfreq);

   for (ltfat_int m = 0; m < M; m++)
   {
      N[m] = mxGetM(mxGetCell(mxs, m));
      sPtr[m] = mxGetData(mxGetCell(mxs, m));
      tgradPtr[m] = mxGetData(mxGetCell(mxtgrad, m));
      fgradPtr[m] = mxGetData(mxGetCell(mxfgrad, m));

      mxSetCell(mxsr, m,
                ltfatCreateMatrix(N[m], 1, LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY));
      srPtr[m] = mxGetData(mxGetCell(mxsr, m));
   }

   // This function uses optional output arguments
fbreassOptOut* optout = NULL;
   mxArray* repos;
   ltfat_int sumN = 0;
   if (nlhs > 1)
   {
      for (ltfat_int ii = 0; ii < M; ii++)
      {
         sumN += N[ii];
      }
      repos = mxCreateCellMatrix(sumN, 1);
      plhs[1] = repos;
      optout = fbreassOptOut_init(sumN, 16 );
   }


   // Adjust a
   ltfat_int acols = mxGetN(mxa);
   if (acols > 1)
   {
      for (ltfat_int m = 0; m < M; m++)
      {
         aPtr[m] /= a[M + m];
      }
   }

   // Run it
   LTFAT_NAME(filterbankreassign)(sPtr, tgradPtr, fgradPtr,
                                  N, a, cfreqPtr, M, srPtr,
                                  REASS_DEFAULT, optout);

   // Process the optional output
   if (optout != NULL)
   {
      for (ltfat_int ii = 0; ii < sumN; ii++)
      {
         ltfat_int l = optout->reposl[ii];

         // Create  an array of a proper length. even an empty one
         mxArray* cEl = mxCreateDoubleMatrix( l , l > 0 ? 1 : 0, mxREAL);
         mxSetCell(repos, ii, cEl);
         double* cElPtr = mxGetPr(cEl);
         // Convert to double and +1 to Matlab indexes...
         for (ltfat_int jj = 0; jj < optout->reposl[ii]; jj++)
         {
            cElPtr[jj] = (double) (optout->repos[ii][jj] + 1.0);
         }

      }
      fbreassOptOut_destroy(optout);
   }
}
#endif
