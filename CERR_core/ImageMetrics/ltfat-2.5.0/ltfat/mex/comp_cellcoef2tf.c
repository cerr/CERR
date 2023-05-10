#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINGE 1
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_cellcoef2tf.c
#include "ltfat_mex_template_helper.h"


#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

/*
COMP_CELLCOEF2TF Cell to a tf-layout
   Usage: coef = comp_cellcoef2tf(coef,maxLen)
*/

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int nrhs, const mxArray *prhs[] )
{
   const mxArray* mxCoef = prhs[0];

   double maxLen = 0.0;
   if(nrhs>1)
   {
       maxLen = mxGetScalar(prhs[1]);
   }


   mwSize M = mxGetNumberOfElements(mxCoef);
   
   mwSize maxCoefElLen = 0;
   mwSize coefElLen[M];
   const LTFAT_TYPE* coefElPtr[M];
   LTFAT_TYPE* coefOutPtr;
  
   for(mwIndex ii=0;ii<M;ii++)
   {
      mxArray* mxCoefEl = mxGetCell(mxCoef,ii); 
      coefElPtr[ii] = mxGetData(mxCoefEl);
      coefElLen[ii] = mxGetM(mxCoefEl);
      if(maxCoefElLen<coefElLen[ii])
      {
         maxCoefElLen = coefElLen[ii];
      }
   }

   if(maxLen>0.0)
   {
        maxCoefElLen = maxLen<maxCoefElLen?maxLen:maxCoefElLen;
   }

   plhs[0] = ltfatCreateMatrix(M, maxCoefElLen ,LTFAT_MX_CLASSID,LTFAT_MX_COMPLEXITY);
   coefOutPtr = mxGetData(plhs[0]);
  
   for(mwIndex m=0;m<M;m++)
   {
      const LTFAT_TYPE* coefElPtrTmp = coefElPtr[m];
      LTFAT_TYPE* coefOutPtrTmp = coefOutPtr+m;
      double lenRatio = ((double)coefElLen[m]-1)/((double)maxCoefElLen-1);
      for(mwIndex ii=0;ii<maxCoefElLen;ii++)
      {
         *coefOutPtrTmp = coefElPtrTmp[(mwIndex)((ii*lenRatio)+0.5)];
         coefOutPtrTmp += M;
      }
   }
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */

