#include "mex.h"
#include "ltfat/thirdparty/fftw3.h"
#include <string.h>
#include "ltfat.h"
#include "ltfat/macros.h"

static fftw_plan* p_double = NULL;
static fftwf_plan* p_float = NULL;
/*
Since the array is stored for the lifetime of the MEX, we introduce limit od the array length.
2^20 ~ 16 MB of complex double
*/
#define MAXARRAYLEN 1048576
// Static pointer for holding the array the FFTW plan is
static mxArray* mxF = NULL;


/*
  MEX exit fnc. are not called by Matlab
*/
void filterbankAtExit()
{
   // mexPrintf("Exit fnc. called\n");
   if (mxF != NULL)
      mxDestroyArray(mxF);

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

// Calling convention:
//  comp_filterbank(f,g,a);
void mexFunction( int UNUSED(nlhs), mxArray *plhs[],
                  int UNUSED(nrhs), const mxArray *prhs[] )
{
   static int atExitRegistered = 0;
   if(!atExitRegistered)
   {
       atExitRegistered = 1;
       mexAtExit(filterbankAtExit);
   }

   const mxArray* mxf = prhs[0];
   const mxArray* mxg = prhs[1];
   const mxArray* mxa = prhs[2];

   // input data length
   const mwSize L = mxGetM(mxf);
   const mwSize W = mxGetN(mxf);

   // filter number
   const mwSize M = mxGetNumberOfElements(mxg);

   // a col count
   mwSize acols = mxGetN(mxa);

   // pointer to a
   double *a = (double*) mxGetData(mxa);


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

   // Cell output
   plhs[0] = mxCreateCellMatrix(M, 1);

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
         c=comp_filterbank_td(f,g,a,offset,ext);
         BEWARE OF THE AUTOMATIC DEALLOCATION!! by the Matlab engine.
         Arrays can be very easily freed twice causing segfaults.
         This happends particulary when using mxCreateCell* which stores
         pointers to other mxArray structs. Setting all such pointers to
         NULL after they are used seems to solve it.
      */
      mxArray* plhs_td[1];
      mxArray* prhs_td[5];
      prhs_td[0] = (mxArray*) mxf;
      prhs_td[1] = mxCreateCellMatrix(tdCount, 1);
      prhs_td[2] = mxCreateDoubleMatrix(tdCount, 1, mxREAL);
      double* aPtr = mxGetData(prhs_td[2]);
      prhs_td[3] = mxCreateDoubleMatrix(tdCount, 1, mxREAL);
      double* offsetPtr = mxGetData(prhs_td[3]);
      prhs_td[4] = mxCreateString("per");

      for (mwIndex m = 0; m < tdCount; m++)
      {
         mxArray * gEl = mxGetCell(mxg, tdArgsIdx[m]);
         mxSetCell(prhs_td[1], m, mxGetField(gEl, 0, "h"));
         // This has overhead
         //mxSetCell((mxArray*)prhs_td[1],m,mxDuplicateArray(mxGetField(gEl,0,"h")));

         aPtr[m] = a[tdArgsIdx[m]];
         offsetPtr[m] = mxGetScalar(mxGetField(gEl, 0, "offset"));
      }

      // Finally call it!
      // comp_filterbank_td(1,plhs_td,5, prhs_td);
      // This has overhead:
      mexCallMATLAB(1, plhs_td, 5, prhs_td, "comp_filterbank_td");

      // Copy pointers to a proper index in the output + unset all duplicate cell elements
      for (mwIndex m = 0; m < tdCount; m++)
      {
         mxSetCell(plhs[0], tdArgsIdx[m], mxGetCell(plhs_td[0], m));
         mxSetCell(plhs_td[0], m, NULL);
         mxSetCell(prhs_td[1], m, NULL);
      }
      mxDestroyArray(plhs_td[0]);
      mxDestroyArray(prhs_td[1]);
      mxDestroyArray(prhs_td[2]);
      mxDestroyArray(prhs_td[3]);
      mxDestroyArray(prhs_td[4]);

   }


   if (fftCount > 0 || fftblCount > 0)
   {
      // Need to do FFT of mxf
      mwIndex ndim = 2;
      const mwSize dims[] = {L, W};

      if (mxF == NULL || mxGetM(mxF) != L || mxGetN(mxF) != W || mxGetClassID(mxF) != mxGetClassID(mxf))
      {
         if (mxF != NULL)
         {
            mxDestroyArray(mxF);
            mxF = NULL;
            // printf("Should be called just once\n");
         }


         if (mxIsDouble(mxf))
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

            // FFTW_MEASURE sometimes hangs here
            *p_double = fftw_plan_guru_split_dft(
                           1, fftw_dims,
                           1, howmanydims,
                           mxGetData(mxF), mxGetImagData(mxF), mxGetData(mxF), mxGetImagData(mxF),
                           FFTW_ESTIMATE);

         }
         else if (mxIsSingle(mxf))
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
                          mxGetData(mxF), mxGetImagData(mxF),
                          mxGetData(mxF), mxGetImagData(mxF),
                          FFTW_ESTIMATE);

         }


      }

      if (mxIsDouble(mxf))
      {
         memcpy(mxGetPr(mxF), mxGetPr(mxf), L * W * sizeof(double));
         memset(mxGetPi(mxF), 0, L * W * sizeof(double));
         if (mxIsComplex(mxf))
            memcpy(mxGetPi(mxF), mxGetPi(mxf), L * W * sizeof(double));

         fftw_execute(*p_double);

      }
      else if (mxIsSingle(mxf))
      {
         memcpy(mxGetPr(mxF), mxGetPr(mxf), L * W * sizeof(float));
         memset(mxGetPi(mxF), 0, L * W * sizeof(float));
         if (mxIsComplex(mxf))
            memcpy(mxGetPi(mxF), mxGetPi(mxf), L * W * sizeof(float));

         fftwf_execute(*p_float);
      }
   }

   if (fftCount > 0)
   {
      mxArray* plhs_fft[1];
      mxArray* prhs_fft[3];
      prhs_fft[0] = mxF;
      prhs_fft[1] = mxCreateCellMatrix(fftCount, 1);
      prhs_fft[2] = mxCreateDoubleMatrix(fftCount, 1, mxREAL);
      double* aPtr = mxGetData(prhs_fft[2]);

      for (mwIndex m = 0; m < fftCount; m++)
      {
         mxArray * gEl = mxGetCell(mxg, fftArgsIdx[m]);
         mxSetCell(prhs_fft[1], m, mxGetField(gEl, 0, "H"));
         // This has overhead
         //mxSetCell((mxArray*)prhs_td[1],m,mxDuplicateArray(mxGetField(gEl,0,"h")));
         aPtr[m] = a[fftArgsIdx[m]];
      }

      //comp_filterbank_fft(1,plhs_fft,3, prhs_fft);
      mexCallMATLAB(1, plhs_fft, 3, prhs_fft, "comp_filterbank_fft");

      for (mwIndex m = 0; m < fftCount; m++)
      {
         mxSetCell(plhs[0], fftArgsIdx[m], mxGetCell(plhs_fft[0], m));
         mxSetCell(plhs_fft[0], m, NULL);
         mxSetCell(prhs_fft[1], m, NULL);
      }
      mxDestroyArray(plhs_fft[0]);
      mxDestroyArray(prhs_fft[1]);
      mxDestroyArray(prhs_fft[2]);
   }

   if (fftblCount > 0)
   {
      mxArray* plhs_fftbl[1];
      mxArray* prhs_fftbl[5];
      prhs_fftbl[0] = mxF;
      prhs_fftbl[1] = mxCreateCellMatrix(fftblCount, 1);
      prhs_fftbl[2] = mxCreateDoubleMatrix(fftblCount, 1, mxREAL);
      prhs_fftbl[3] = mxCreateDoubleMatrix(fftblCount, 2, mxREAL);
      prhs_fftbl[4] = mxCreateDoubleMatrix(fftblCount, 1, mxREAL);
      double* foffPtr = mxGetData(prhs_fftbl[2]);
      double* aPtr = mxGetData(prhs_fftbl[3]);
      double* realonlyPtr = mxGetData(prhs_fftbl[4]);
      // Set all realonly flags to zero
      memset(realonlyPtr, 0, fftblCount * sizeof * realonlyPtr);

      for (mwIndex m = 0; m < fftblCount; m++)
      {
         mxArray * gEl = mxGetCell(mxg, fftblArgsIdx[m]);
         mxSetCell(prhs_fftbl[1], m, mxGetField(gEl, 0, "H"));
         foffPtr[m] = mxGetScalar(mxGetField(gEl, 0, "foff"));
         aPtr[m] = a[fftblArgsIdx[m]];

         if (acols > 1)
            aPtr[m + fftblCount] = a[fftblArgsIdx[m] + M];
         else
            aPtr[m + fftblCount] = 1;

         // Only if realonly is specified
         mxArray* mxrealonly;
         if ((mxrealonly = mxGetField(gEl, 0, "realonly")))
            realonlyPtr[m] = mxGetScalar(mxrealonly);
      }

      // comp_filterbank_fftbl(1,plhs_fftbl,5, prhs_fftbl);
      mexCallMATLAB(1, plhs_fftbl, 5, prhs_fftbl, "comp_filterbank_fftbl");

      for (mwIndex m = 0; m < fftblCount; m++)
      {
         mxSetCell(plhs[0], fftblArgsIdx[m], mxGetCell(plhs_fftbl[0], m));
         mxSetCell(plhs_fftbl[0], m, NULL);
         mxSetCell(prhs_fftbl[1], m, NULL);
      }
      mxDestroyArray(plhs_fftbl[0]);
      mxDestroyArray(prhs_fftbl[1]);
      mxDestroyArray(prhs_fftbl[2]);
      mxDestroyArray(prhs_fftbl[3]);
      mxDestroyArray(prhs_fftbl[4]);
   }


   if (mxF != NULL)
      mexMakeArrayPersistent(mxF);

   if (L * W > MAXARRAYLEN && mxF != NULL)
   {
      //printf("Damn. Should not get here\n");
      mxDestroyArray(mxF);
      mxF = NULL;
   }

}
