#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 2
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define NOCOMPLEXFMTCHANGE

#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

/* Assuming __BASE_FILE__ is known by the compiler.
   Otherwise specify this filename
   e.g. #define MEX_FILE "comp_col2diag.c"  */
#define MEX_FILE vect2cell.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// LTFAT_COMPLEXTYPE, LTFAT_SINGLE, LTFAT_DOUBLE

/* Calling convention:
 *  c=vect2cell(x,idx);
 */
void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
   mwSize L = mxGetM(prhs[0]);
   mwSize W = mxGetN(prhs[0]);
   mwSize M = mxGetNumberOfElements(prhs[1]);
   double* Lc = mxGetData(prhs[1]);

   /* Sanity check */
   mwSize sumLc = (mwSize) Lc[0];
   for (mwIndex ii = 1; ii < M; ii++)
      sumLc += (mwSize) Lc[ii];
   if (sumLc != L)
      mexErrMsgTxt("VECT2CELL: Sizes do not comply.");


   plhs[0] = mxCreateCellMatrix(M, 1);
   LTFAT_REAL* cPr[M];
#if defined(LTFAT_COMPLEXTYPE) && !(MX_HAS_INTERLEAVED_COMPLEX)
   LTFAT_REAL* cPi[M];
#endif

   for (mwIndex ii = 0; ii < M; ii++)
   {
      mxArray* tmpA = ltfatCreateMatrix((mwSize)Lc[ii], W, LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY);
      mxSetCell(plhs[0], ii, tmpA);
      cPr[ii] = mxGetData(tmpA);
#if defined(LTFAT_COMPLEXTYPE) && !(MX_HAS_INTERLEAVED_COMPLEX)
      cPi[ii] = mxGetImagData(tmpA);
#endif
   }

   LTFAT_REAL* xPr = mxGetData(prhs[0]);

#if defined(LTFAT_COMPLEXTYPE) && (MX_HAS_INTERLEAVED_COMPLEX)
   L *= 2;
   for (mwIndex ii = 0; ii < M; ii++) Lc[ii] *= 2;
#endif

   for (mwIndex w = 0; w < W; w++)
   {
      LTFAT_REAL* xTmp = xPr + w * L;
      for (mwIndex ii = 0; ii < M; ii++)
      {
         mwSize LcTmp = (mwSize)Lc[ii];
         LTFAT_REAL* cTmp = cPr[ii] + w * LcTmp;
         memcpy(cTmp, xTmp, LcTmp * sizeof * cTmp);
         xTmp += LcTmp;
      }
   }

#if defined(LTFAT_COMPLEXTYPE) && !(MX_HAS_INTERLEAVED_COMPLEX)
   LTFAT_REAL* xPi = mxGetImagData(prhs[0]);
   for (mwIndex w = 0; w < W; w++)
   {
      LTFAT_REAL* xTmp = xPi + w * L;
      for (mwIndex ii = 0; ii < M; ii++)
      {
         mwSize LcTmp = (mwSize)Lc[ii];
         LTFAT_REAL* cTmp = cPi[ii] + w * LcTmp;
         memcpy(cTmp, xTmp, LcTmp * sizeof * cTmp);
         xTmp += LcTmp;
      }
   }
#endif

}
#endif

