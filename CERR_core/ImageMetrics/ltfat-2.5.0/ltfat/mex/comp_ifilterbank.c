#include "mex.h"
#include "ltfat/thirdparty/fftw3.h"
#include <string.h>
#include "ltfat.h"
#include "ltfat/macros.h"

/*
  Inside functions
*/
void ifilterbankAtExit();
void addToArray(mxArray* to, const mxArray* from);


static fftw_plan* p_double = NULL;
static fftwf_plan* p_float = NULL;

/*
Since the array is store for the lifetime of the MEX, we introduce limit od the array length.
2^20 ~ 16 MB of complex double
*/
#define MAXARRAYLEN 1048576
// Static pointer for holding the array the FFTW plan uses
static mxArray* mxF = NULL;

// Calling convention:
//  comp_ifilterbank(f,g,a,L);

/*
This will not add the imaginary part of from if to is real.
*/
void addToArray(mxArray* to, const mxArray* from)
{
#define ADDTOARRAY(to,from,L,T)   \
do{                               \
   for(mwIndex ii=0;ii<(L);ii++)    \
       ((to)[ii]) += (T) ((from)[ii]);       \
}while(0)

   mwSize nDimTO = mxGetNumberOfDimensions(to);
   mwSize nDimFROM = mxGetNumberOfDimensions(from);

   if (!mxIsComplex(to) && mxIsComplex(from))
   {
      mexErrMsgTxt("COMP_IFILTERBANK: Cannot add complex to real.");
   }

   if (nDimFROM != nDimTO)
   {
      mexErrMsgTxt("COMP_IFILTERBANK: Number of dimensions of arrays are not equal.");
   }

   const mwSize* dimsTO = mxGetDimensions(to);
   const mwSize* dimsFROM = mxGetDimensions(from);

   for (mwIndex ii = 0; ii < nDimTO; ii++)
   {
      if (dimsTO[ii] != dimsFROM[ii])
      {
         mexErrMsgTxt("COMP_IFILTERBANK: Dimensions of arrays are not equal.");
      }
   }
   mwSize L = mxGetNumberOfElements(to);

   if (mxIsDouble(to))
   {
      if (mxIsDouble(from))
      {
         ADDTOARRAY(mxGetPr(to), mxGetPr(from), L, double);

         if (mxIsComplex(to) && mxIsComplex(from))
         {
            ADDTOARRAY(mxGetPi(to), mxGetPi(from), L, double);
         }
      }
      else if (mxIsSingle(from))
      {
         ADDTOARRAY(mxGetPr(to), (float*)mxGetPr(from), L, float);
         if (mxIsComplex(to) && mxIsComplex(from))
         {
            ADDTOARRAY(mxGetPi(to), (float*)mxGetPi(from), L, float);
         }
      }
      else
      {
         mexErrMsgTxt("COMP_IFILTERBANK: Unsupported type.");
      }
   }
   else
   {
      if (mxIsDouble(from))
      {
         ADDTOARRAY((float*)mxGetPr(to), mxGetPr(from), L, float);

         if (mxIsComplex(to) && mxIsComplex(from))
         {
            ADDTOARRAY((float*)mxGetPi(to), mxGetPi(from), L, float);
         }
      }
      else if (mxIsSingle(from))
      {
         ADDTOARRAY((float*)mxGetPr(to), (float*)mxGetPr(from), L, float);
         if (mxIsComplex(to) && mxIsComplex(from))
         {
            ADDTOARRAY((float*)mxGetPi(to), (float*)mxGetPi(from), L, float);
         }
      }
      else
      {
         mexErrMsgTxt("COMP_IFILTERBANK: Unsupported type.");
      }
   }
#undef ADDTOARRAY
}

/*
  MEX exit fnc. are not called by Matlab
*/
void ifilterbankAtExit()
{
   if (mxF != NULL) mxDestroyArray(mxF);

   if (p_double != NULL)
   {
      fftw_destroy_plan(*p_double);
      free(p_double);
   }

   if (p_float != NULL)
   {
      fftwf_destroy_plan(*p_float);
      free(p_float);
   }

}

void mexFunction( int UNUSED(nlhs), mxArray *plhs[],
                  int UNUSED(nrhs), const mxArray *prhs[] )
{
   static int atExitregistered = 0;
   if(!atExitregistered)
   {
       atExitregistered = 1;
       mexAtExit(ifilterbankAtExit);
   }

   const mxArray* mxc = prhs[0];
   const mxArray* mxg = prhs[1];
   const mxArray* mxa = prhs[2];
   mxArray* tmpF = NULL;
   plhs[0] = NULL;

   // input data length
   const mwSize L = (mwSize) mxGetScalar(prhs[3]);
   const mwSize W = mxGetN(mxGetCell(mxc, 0));

   // filter number
   const mwSize M = mxGetNumberOfElements(mxg);

   // a col count
   mwSize acols = mxGetN(mxa);

   // pointer to a
   double *a = mxGetData(mxa);


   if (acols > 1)
   {
      int isOnes = 1;
      for (mwIndex m = 0; m < M; m++)
      {
         isOnes = isOnes && a[M + m] == 1;
      }

      if (isOnes)
      {
         acols = 1;
      }
   }

   // Stuff for sorting the filters
   mwSize tdCount = 0;
   mwSize fftCount = 0;
   mwSize fftblCount = 0;
   mwIndex tdArgsIdx[M];
   mwIndex fftArgsIdx[M];
   mwIndex fftblArgsIdx[M];

   // WALK the filters to determine what has to be done
   for (mwIndex m = 0; m < M; m++)
   {
      mxArray * gEl = mxGetCell(mxg, m);
      if (mxGetField(gEl, 0, "h") != NULL)
      {
         tdArgsIdx[tdCount++] = m;
         continue;
      }

      if (mxGetField(gEl, 0, "H") != NULL)
      {
         if (acols == 1 && L == mxGetNumberOfElements(mxGetField(gEl, 0, "H")))
         {
            fftArgsIdx[fftCount++] = m;
            continue;
         }
         else
         {
            fftblArgsIdx[fftblCount++] = m;
            continue;
         }
      }
   }

   if (tdCount > 0)
   {
      /*
         Here, we have to reformat the inputs and pick up results to comply with:
         f=comp_ifilterbank_td(c,g,a,Ls,offset,ext);
         BEWARE OF THE AUTOMATIC DEALLOCATION!! by the Matlab engine.
         Arrays can be very easily freed twice causing segfaults.
         This happends particulary when using mxCreateCell* which stores
         pointers to other mxArray structs. Setting all such pointers to
         NULL after they are used seems to solve it.
      */
      mxArray* plhs_td[1];
      mxArray* prhs_td[6];
      prhs_td[0] = mxCreateCellMatrix(tdCount, 1);
      prhs_td[1] = mxCreateCellMatrix(tdCount, 1);
      prhs_td[2] = mxCreateDoubleMatrix(tdCount, 1, mxREAL);
      prhs_td[3] = mxCreateDoubleScalar(L);
      double* aPtr = mxGetData(prhs_td[2]);
      prhs_td[4] = mxCreateDoubleMatrix(tdCount, 1, mxREAL);
      double* offsetPtr = mxGetData(prhs_td[4]);
      prhs_td[5] = mxCreateString("per");

      for (mwIndex m = 0; m < tdCount; m++)
      {
         // Pick related subbands
         mxSetCell(prhs_td[0], m, mxGetCell(mxc, tdArgsIdx[m]));
         // Pick related filters
         mxArray * gEl = mxGetCell(mxg, tdArgsIdx[m]);
         mxSetCell(prhs_td[1], m, mxGetField(gEl, 0, "h"));
         aPtr[m] = a[tdArgsIdx[m]];
         offsetPtr[m] = mxGetScalar(mxGetField(gEl, 0, "offset"));
      }

      // Finally call it!
      // comp_ifilterbank_td(1,plhs_td,6, prhs_td);
      mexCallMATLAB(1, plhs_td, 6, prhs_td, "comp_ifilterbank_td");


      // Copy pointers to a proper index in the output + unset all duplicate cell elements
      for (mwIndex m = 0; m < tdCount; m++)
      {
         mxSetCell(prhs_td[0], m, NULL);
         mxSetCell(prhs_td[1], m, NULL);
      }
      // Copy pointer to output
      plhs[0] = plhs_td[0];
      mxDestroyArray(prhs_td[0]);
      mxDestroyArray(prhs_td[1]);
      mxDestroyArray(prhs_td[2]);
      mxDestroyArray(prhs_td[3]);
      mxDestroyArray(prhs_td[4]);
      mxDestroyArray(prhs_td[5]);

   }

   if (fftCount > 0)
   {
      mxArray* plhs_fft[1];
      mxArray* prhs_fft[3];
      prhs_fft[0] = mxCreateCellMatrix(fftCount, 1);
      prhs_fft[1] = mxCreateCellMatrix(fftCount, 1);
      prhs_fft[2] = mxCreateDoubleMatrix(fftCount, 1, mxREAL);
      double* aPtr = mxGetData(prhs_fft[2]);

      for (mwIndex m = 0; m < fftCount; m++)
      {
         // Pick related subbands
         mxSetCell(prhs_fft[0], m, mxGetCell(mxc, fftArgsIdx[m]));

         mxArray * gEl = mxGetCell(mxg, fftArgsIdx[m]);
         mxSetCell(prhs_fft[1], m, mxGetField(gEl, 0, "H"));
         // This has overhead
         //mxSetCell((mxArray*)prhs_td[1],m,mxDuplicateArray(mxGetField(gEl,0,"h")));
         aPtr[m] = a[fftArgsIdx[m]];
      }

      // comp_ifilterbank_fft(1,plhs_fft,3, prhs_fft);
      mexCallMATLAB(1, plhs_fft, 3, prhs_fft, "comp_ifilterbank_fft");

      for (mwIndex m = 0; m < fftCount; m++)
      {
         mxSetCell(prhs_fft[0], m, NULL);
         mxSetCell(prhs_fft[1], m, NULL);
      }
      /* This might be a real array on Octave */
      tmpF = plhs_fft[0];

      mxDestroyArray(prhs_fft[0]);
      mxDestroyArray(prhs_fft[1]);
      mxDestroyArray(prhs_fft[2]);
   }

   if (fftblCount > 0)
   {
      mxArray* plhs_fftbl[1];
      mxArray* prhs_fftbl[5];
      prhs_fftbl[0] = mxCreateCellMatrix(fftblCount, 1);;
      prhs_fftbl[1] = mxCreateCellMatrix(fftblCount, 1);
      prhs_fftbl[2] = mxCreateDoubleMatrix(fftblCount, 1, mxREAL);
      prhs_fftbl[3] = mxCreateDoubleMatrix(fftblCount, 2, mxREAL);
      prhs_fftbl[4] = mxCreateDoubleMatrix(fftblCount, 1, mxREAL);
      double* foffPtr = mxGetData(prhs_fftbl[2]);
      double* aPtr = mxGetData(prhs_fftbl[3]);
      double* realonlyPtr = mxGetData(prhs_fftbl[4]);
      memset(realonlyPtr, 0, fftblCount * sizeof * realonlyPtr);

      for (mwIndex m = 0; m < fftblCount; m++)
      {
         // Pick related subbands
         mxSetCell(prhs_fftbl[0], m, mxGetCell(mxc, fftblArgsIdx[m]));

         mxArray * gEl = mxGetCell(mxg, fftblArgsIdx[m]);
         mxSetCell(prhs_fftbl[1], m, mxGetField(gEl, 0, "H"));
         foffPtr[m] = mxGetScalar(mxGetField(gEl, 0, "foff"));
         aPtr[m] = a[fftblArgsIdx[m]];

         if (acols > 1)
            aPtr[m + fftblCount] = a[fftblArgsIdx[m] + M];
         else
            aPtr[m + fftblCount] = 1;

         mxArray* mxrealonly;
         if ((mxrealonly = mxGetField(gEl, 0, "realonly")))
            realonlyPtr[m] = mxGetScalar(mxrealonly);
      }


      //comp_ifilterbank_fftbl(1,plhs_fftbl,5, prhs_fftbl);
      mexCallMATLAB(1, plhs_fftbl, 5, prhs_fftbl, "comp_ifilterbank_fftbl");

      for (mwIndex m = 0; m < fftblCount; m++)
      {
         mxSetCell(prhs_fftbl[0], m, NULL);
         mxSetCell(prhs_fftbl[1], m, NULL);
      }

      if (tmpF == NULL)
      {
         /* On Octave, this might be real array because of the 
          * automatic complex number simplification */
         tmpF = plhs_fftbl[0];
      }
      else
      {
         addToArray(tmpF, plhs_fftbl[0]);
      }

      mxDestroyArray(prhs_fftbl[0]);
      mxDestroyArray(prhs_fftbl[1]);
      mxDestroyArray(prhs_fftbl[2]);
      mxDestroyArray(prhs_fftbl[3]);
      mxDestroyArray(prhs_fftbl[4]);
   }

   mwIndex ndim = 2;
   const mwSize dims[] = {L, W};

   if (fftCount > 0 || fftblCount > 0)
   {
      // Need to do IFFT of mxF

      if (mxF == NULL || mxGetM(mxF) != L || mxGetN(mxF) != W || mxGetClassID(mxF) != mxGetClassID(tmpF))
      {
         if (mxF != NULL)
         {
            mxDestroyArray(mxF);
            mxF = NULL;
            // printf("Should be called just once\n");
         }


         if (mxIsDouble(tmpF))
         {
            mxF = mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxCOMPLEX);
            fftw_iodim fftw_dims[1];
            fftw_iodim howmanydims[1];

            fftw_dims[0].n = L;
            fftw_dims[0].is = 1;
            fftw_dims[0].os = 1;

            howmanydims[0].n = W;
            howmanydims[0].is = L;
            howmanydims[0].os = L;

            if (p_double == NULL)
               p_double = (fftw_plan*) malloc(sizeof(fftw_plan));
            else
               fftw_destroy_plan(*p_double);


            *p_double = fftw_plan_guru_split_dft(
                           1, fftw_dims,
                           1, howmanydims,
                           mxGetPi(mxF), mxGetPr(mxF), mxGetPi(mxF), mxGetPr(mxF),
                           FFTW_ESTIMATE);

         }
         else if (mxIsSingle(tmpF))
         {
            mxF = mxCreateNumericArray(ndim, dims, mxSINGLE_CLASS, mxCOMPLEX);
            // mexPrintf("M= %i, N= %i\n",mxGetM(mxF),mxGetN(mxF));
            fftwf_iodim fftw_dims[1];
            fftwf_iodim howmanydims[1];

            fftw_dims[0].n = L;
            fftw_dims[0].is = 1;
            fftw_dims[0].os = 1;

            howmanydims[0].n = W;
            howmanydims[0].is = L;
            howmanydims[0].os = L;

            if (p_float == NULL)
               p_float = (fftwf_plan*) malloc(sizeof(fftwf_plan));
            else
               fftwf_destroy_plan(*p_float);

            *p_float = fftwf_plan_guru_split_dft(
                          1, fftw_dims,
                          1, howmanydims,
                          (float*)mxGetPi(mxF), (float*)mxGetPr(mxF),
                          (float*) mxGetPi(mxF), (float*)mxGetPr(mxF),
                          FFTW_ESTIMATE);

         }


      }




      if (mxIsDouble(tmpF))
      {
         if (!mxIsComplex(tmpF))
         {
            // tmpF might not be complex array because of the automatic complex 
            // type simplification on Octave.
            mxArray* tmpF2 = mxCreateNumericArray(ndim,dims,mxDOUBLE_CLASS, mxCOMPLEX);
            memcpy(mxGetData(tmpF2),mxGetData(tmpF), L * W * sizeof(double));
            memset(mxGetImagData(tmpF2), 0, L * W * sizeof(double));
            mxDestroyArray(tmpF);
            tmpF = tmpF2;
         }

         double* mxFPtr = mxGetData(mxF);
         double* mxFPti = mxGetImagData(mxF);
         memcpy(mxFPtr, mxGetData(tmpF), L * W * sizeof * mxFPtr);
         memcpy(mxFPti, mxGetImagData(tmpF), L * W * sizeof * mxFPti);

         fftw_execute(*p_double);
         double oneOverL = 1.0 / ((double) L);
         for (mwIndex ii = 0; ii < L * W; ii++)
         {
            mxFPtr[ii] *= oneOverL;
            mxFPti[ii] *= oneOverL;
         }
      }
      else if (mxIsSingle(tmpF))
      {
         if (!mxIsComplex(tmpF))
         {
            // tmpF might not be complex array because of the automatic complex 
            // type simplification on Octave.
            mxArray* tmpF2 = mxCreateNumericArray(ndim,dims,mxSINGLE_CLASS, mxCOMPLEX);
            memcpy(mxGetData(tmpF2),mxGetData(tmpF), L * W * sizeof(float));
            memset(mxGetImagData(tmpF2), 0, L * W * sizeof(float));
            mxDestroyArray(tmpF);
            tmpF = tmpF2;
         }

         float* mxFPtr = mxGetData(mxF);
         float* mxFPti = mxGetImagData(mxF);
         memcpy(mxFPtr, mxGetData(tmpF), L * W * sizeof * mxFPtr);
         memcpy(mxFPti, mxGetImagData(tmpF), L * W * sizeof * mxFPti);

         fftwf_execute(*p_float);

         float oneOverL = 1.0 / ((float) L);
         for (mwIndex ii = 0; ii < L * W; ii++)
         {
            mxFPtr[ii] *= oneOverL;
            mxFPti[ii] *= oneOverL;
         }
      }

      if (mxIsDouble(mxF))
      {
         memcpy(mxGetData(tmpF), mxGetData(mxF), L * W * sizeof(double));
         memcpy(mxGetImagData(tmpF), mxGetImagData(mxF), L * W * sizeof(double));
      }
      else if (mxIsSingle(mxF))
      {
         memcpy(mxGetData(tmpF), mxGetData(mxF), L * W * sizeof(float));
         memcpy(mxGetImagData(tmpF), mxGetImagData(mxF), L * W * sizeof(float));
      }

      if (plhs[0] != NULL)
      {
         addToArray(tmpF, plhs[0]);
      }
      plhs[0] = tmpF;
   }


   if (mxF != NULL)
      mexMakeArrayPersistent(mxF);

   if (L * W > MAXARRAYLEN && mxF != NULL)
   {
      //printf("Damn. Should not get here\n");
      mxDestroyArray(mxF);
      mxF = NULL;
   }


//int prd = 0;
}
