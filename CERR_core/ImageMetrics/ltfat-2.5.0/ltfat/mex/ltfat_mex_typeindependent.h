#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include <complex.h>
// #include "fftw3.h"
#include "ltfat/types.h"
#include "mex.h"




mxArray* LTFAT_NAME(mexSplit2combined)( mxArray *parg, const mxArray *pargorig);

mxArray* LTFAT_NAME(mexCombined2split)( const mxArray *parg);

mxArray* LTFAT_NAME(mexReal2Complex)( const mxArray *parg);

mxArray* LTFAT_NAME(mexReal2Complex)( const mxArray *parg)
{
   if(mxIsCell(parg))
   {
      mxArray* tmpCell = mxCreateCellMatrix(mxGetM(parg), mxGetN(parg));
      for(unsigned int jj=0;jj<mxGetNumberOfElements(parg);jj++)
      {
         mxSetCell(tmpCell, (mwIndex) jj, LTFAT_NAME(mexReal2Complex)(mxGetCell(parg, jj)));
      }
      return tmpCell;
   }

   // just copy pointer if the element is not numeric
   if(!mxIsNumeric(parg))
   {
      return (mxArray*)parg;
   }

   if (mxIsComplex(parg))
       return (mxArray*) parg;

   mwIndex ndim = mxGetNumberOfDimensions(parg);
   const mwSize *dims = mxGetDimensions(parg);

   mxArray* out = ltfatCreateNdimArray(ndim,dims,LTFAT_MX_CLASSID,mxCOMPLEX);
   mwSize L = mxGetNumberOfElements(parg);

   #if defined(NOCOMPLEXFMTCHANGE) && !(MX_HAS_INTERLEAVED_COMPLEX)
    LTFAT_REAL *i_r = mxGetData(parg);
    LTFAT_REAL *o_r = mxGetData(out);
    LTFAT_REAL *o_i = mxGetImagData(out);
    for(mwIndex jj=0;jj<L;jj++)
    {
        o_r[jj]= i_r[jj];
        o_i[jj]= (LTFAT_REAL )0.0;
    }
   #else
    LTFAT_REAL *i_r = mxGetData(parg);
    LTFAT_REAL *o_r = mxGetData(out);
    for(mwIndex jj=0;jj<L;jj++)
    {
        o_r[2*jj]= i_r[jj];
        o_r[2*jj+1]= (LTFAT_REAL )0.0;
    }
   #endif

   return out;
}


mxArray* LTFAT_NAME(mexSplit2combined)( mxArray *parg, const mxArray *pargorig)
{
   if(mxIsCell(parg))
   {
      mxArray* tmpCell = parg;
      if (pargorig == parg)
          tmpCell = mxCreateCellMatrix(mxGetM(parg), mxGetN(parg));

      for(mwSize jj=0;jj<mxGetNumberOfElements(parg);jj++)
      {
         mxArray* tmpCellEl = LTFAT_NAME(mexSplit2combined)( mxGetCell(parg, jj), mxGetCell(pargorig, jj));

         mxSetCell(tmpCell, jj, tmpCellEl);
      }

      return tmpCell;
   }

   // just copy pointer if the element is not numeric
   if(!mxIsNumeric(parg))
      return (mxArray*)parg;

   mxArray* out = NULL;
#if (MX_HAS_INTERLEAVED_COMPLEX)
   if (mxIsComplex(parg))
       out = (mxArray*) parg;
   else
       out = LTFAT_NAME(mexReal2Complex)(parg);
#else
   mwIndex ndim = mxGetNumberOfDimensions(parg);
   const mwSize *dims = mxGetDimensions(parg);

   out = ltfatCreateNdimArray(ndim,dims,LTFAT_MX_CLASSID,mxCOMPLEX);
   mwSize L = mxGetNumberOfElements(parg);

   LTFAT_COMPLEX* outc = mxGetData(out);
   LTFAT_REAL *i_r= mxGetData(parg);

   if (mxIsComplex(parg))
   {
      LTFAT_REAL *i_i= mxGetImagData(parg);

      for (mwIndex ii=0;ii<L; ii++)
         outc[ii] = i_r[ii] + i_i[ii]*I;
   }
   else
   {
      /* No imaginary part */
      for (mwIndex ii=0;ii<L; ii++)
	    outc[ii] = i_r[ii];
   }

#endif
   if (parg != pargorig && out != parg)
       mxDestroyArray(parg);
   return out;
}

mxArray* LTFAT_NAME(mexCombined2split)( const mxArray *parg)
{
#if !(MX_HAS_INTERLEAVED_COMPLEX)
   if(mxIsCell(parg))
   {
      mxArray* tmpCell = mxCreateCellMatrix(mxGetM(parg), mxGetN(parg));
      for(unsigned int jj=0;jj<mxGetNumberOfElements(parg);jj++)
      {
         mxSetCell(tmpCell, (mwIndex) jj, LTFAT_NAME(mexCombined2split)(mxGetCell(parg, jj)));
      }
      return tmpCell;
   }

   // just copy pointer if the element is not numeric or is real
   if(!mxIsNumeric(parg) || !mxIsComplex(parg))
   {
      return (mxArray*)parg;
   }

   LTFAT_COMPLEX *pargc = (LTFAT_COMPLEX *) mxGetData(parg);
   mwIndex ndim = mxGetNumberOfDimensions(parg);
   const mwSize *dims = mxGetDimensions(parg);
   mxArray*out = mxCreateNumericArray(ndim,dims,LTFAT_MX_CLASSID,mxCOMPLEX);

   LTFAT_REAL *outr=(LTFAT_REAL *)mxGetPr(out);
   LTFAT_REAL *outi=(LTFAT_REAL *)mxGetPi(out);

   mwSize L = mxGetNumberOfElements(parg);

   for (mwIndex ii=0;ii<L; ii++)
   {
      outr[ii] = __real__ pargc[ii];
      outi[ii] = __imag__ pargc[ii];
   }
   return out;
#else // NOOP in the new memory layout
   return (mxArray*) parg;
#endif
}

#endif
