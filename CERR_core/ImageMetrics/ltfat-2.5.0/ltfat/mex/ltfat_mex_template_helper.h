/***********************************************************************************
This file serves as a helper for the MEX files. It helps with the following issues:

   1) Avoids code repetition by introducing type-independent code.
   2) Handles Matlab complex numbers arrays format conversion (split to interleaved)
      on-the-fly.
   3) (optionally) Exports alias for the mexFunction to avoid function names colision when working with several MEXs at once.

This header is meant to be included from a MEX file having MEX_FILE macro set to

#define MEX_FILE __BASE_FILE__

The MEX source file itself is not processed directly, but it is included from this
header possibly more than once. How the MEX file is treated depends on a control
macros which are set in the MEX source file. The supported are:

 ISNARGINEQ, ISNARGINLE, ISNARGINGE
    AT COMPILE-TIME:
    AT RUNTIME: Ensures correct number of the input parameters.
    WHEN MISSING: No input argument checks ale included in the final code.

#define ISNARGINEQ 5
 TYPEDEPARGS -- used when determining the data type (float, double, float _Complex, double _Complex)
 MATCHEDARGS -- used when determining the data type but only float and double
    AT COMPILE-TIME: Defines integer array from the specified values.
    AT RUNTIME: The array is used to identify input arguments to be checked/reformated. Accepted inputs are numeric arrays,
                cell arrays containing only numeric arrays, structures having at least one field beeing a numeric array.
    WHEN MISSING: No input modifications/checks are included in the code.

#define TYPEDEPARGS 0, 1
 SINGLEARGS
    AT COMPILE-TIME: Includes this file for the second time with TYPEDEPARGS input args. recast to float arrays (cells, structs).
    AT RUNTIME: If at least one of the TYPEDEPARGS input args. is float (single in MatLab), all TYPEDEPARGS are recast to floats.
    WHEN MISSING: TYPEDEPARGS input args can be only double arrays.

#define SINGLEARGS
 COMPLEXARGS, REALARGS
    AT COMPILE-TIME: (COMPLEXARGS) adds code for on-the-fly conversion from the Matlab complex number format to the
                     complex.h (interleaved) complex data format.
                     (REALARGS) and (COMPLEXARGS) allows both real and complex inputs. Have to be handled here.
    AT RUNTIME: (COMPLEXARGS) TYPEDEPARGS input args are recast to complex format even in they are real.
                (REALARGS) TYPEDEPARGS args are accepted only if they are real.
                (REALARGS) and (COMPLEXARGS) If at least one of the TYPEDEPARGS is complex do as (COMPLEXARGS), otherwise let
                the inputs untouched.
    WHEN MISSING: Real/Complex are not checked. No complex data format change.


 COMPLEXINDEPENDENT
    AT COMPILE-TIME: As if both COMPLEXARGS, REALARGS were defined.
    AT RUNTIME: As if both COMPLEXARGS, REALARGS were defined plus it is assumed that the called functions from the LTFAT
                backend are from ltfat_typecomplexindependent.h, e.i. there are
    WHEN MISSING: No input checks REAL/COMPLEX checks are included in the final code.


#define COMPLEXINDEPENDENT

NOCOMPLEXFMTCHANGE
    Macro overrides the default complex number format change.

************************************************************************************/
#if defined(_WIN32) || defined(__WIN32__)
#  define DLL_EXPORT_SYM __declspec(dllexport)
#  define EXPORT_SYM __declspec(dllexport)
#else
#  define EXPORT_EXTERN_C __attribute__((visibility("default")))
#  define EXPORT_SYM __attribute__((visibility("default")))
#  define DLL_EXPORT_SYM EXPORT_SYM
#endif


/** Allow including this file further only if MEX_FILE is defined */
#if defined(MEX_FILE)

/** Allow including this file only once */
#ifndef _LTFAT_MEX_TEMPLATEHELPER_H
#define _LTFAT_MEX_TEMPLATEHELPER_H 1

/**
    __delspec(dllexport)
       Adds symbol exporting function decorator to mexFunction (see mex.h).
       On Windows, a separate def file is no longer needed. For MinGW, it
       suppresses the default "export-all-symbols" behavior.

    __attribute__((visibility("default")))
       Only for Linux. In conjuction with compiler flag -fvisibility=hidden
       export symbols of functions only with EXPORT_EXTERN_C (used also in mex.h).
 **/

/** Template macros */
#define LTFAT_CAT(prefix,name) prefix##name
#define LTFAT_TEMPLATE(prefix,name) LTFAT_CAT(prefix,name)

/** Undefine LTFAT_DOUBLE, LTFAT_SINGLE and LTFAT_COMPLEXTYPE if they are set */
#ifdef LTFAT_DOUBLE
#  undef LTFAT_DOUBLE
#endif
#ifdef LTFAT_SINGLE
#  undef LTFAT_SINGLE
#endif
#ifdef LTFAT_COMPLEXTYPE
#  undef LTFAT_COMPLEXTYPE
#endif

/** Helper MACROS */
#ifdef _DEBUG
#define DEBUGINFO  mexPrintf("File: %s, func: %s \n",__BASE_FILE__,__func__);
#else
#define DEBUGINFO
#endif

#include "ltfat_mex_includes.h"
/* This is just for the case when we want to skip registration of the atExit function */
EXPORT_SYM
void mexFunctionInner( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
/** C99 headers for a generic complex number manipulations */


ptrdiff_t mexstatus = 0;
char mexerrormsg[500] = {0};
#define CHSTAT(A) do{ ptrdiff_t checkstatustmp=(A); if(checkstatustmp<0){ mexstatus = checkstatustmp; goto error;}}while(0)

// Storing function pointers to exitFunctions
#define MEXEXITFNCCOUNT 4
void ltfatMexAtExitGlobal(void);
static void (*exitFncPtr[MEXEXITFNCCOUNT])(void) = {0};


void ltfatMexAtExitGlobal(void)
{
   for (int ii = 0; ii < MEXEXITFNCCOUNT; ii++)
   {
      if (exitFncPtr[ii] != 0)
         (*exitFncPtr[ii])();
   }

#ifdef _DEBUG
   mexPrintf("Global Exit fnc called: %s\n", __PRETTY_FUNCTION__);
#endif
}

void cust_ltfat_error_handler (int ltfat_errno, const char* file, int line,
                            const char* funcname, const char* reason)
{
    snprintf(mexerrormsg, 500, "[ERROR %d]: (%s:%d): [%s]: %s\n",
             -ltfat_errno, file, line, funcname, reason );
}


/** Helper function headers.
    Defined here to allow them to be used in the MEX_FILE */
/*
Replacement for:
mxArray *mxCreateNumericMatrix(mwSize m, mwSize n, mxClassID classid, mxComplexity ComplexFlag);
*/
mxArray *ltfatCreateMatrix(mwSize M, mwSize N, mxClassID classid, mxComplexity complexFlag);
/*
Replacement for:
mxArray *mxCreateNumericArray(mwSize ndim, const mwSize *dims, mxClassID classid, mxComplexity ComplexFlag);
*/
mxArray *ltfatCreateNdimArray(mwSize ndim, const mwSize *dims, mxClassID classid, mxComplexity complexFlag);
/*
The following work exactly as size(in,2) in Matlab.
The mxGetN(const mxArray *pm) has different behavior.
It returns product of sizes of all dimensions >=2.
*/
mwSize ltfatGetN(const mxArray* in);
/**
Include MEX source code (MEX_FILE) for each template data type according to the control macros:

    TYPEDEPARGS
    COMPLEXARGS
    REALARGS
    COMPLEXINDEPENDENT

For each inclusion a whole set of macros is defined (see src/ltfat/types.h):

    MACRO SETS (from ltfat/types.h)
          MACRO                                     EXPANDS TO
                              (double)           (single)           (complex double)      (complex single)
    ------------------------------------------------------------------------------------------------------
    LTFAT_REAL                double             float              double                float
    LTFAT_COMPLEX             double _Complex    float _Complex     double _Complex       float _Complex
    LTFAT_TYPE                LTFAT_REAL         LTFAT_REAL         LTFAT_COMPLEX        LTFAT_COMPLEX
    LTFAT_MX_CLASSID          mxDOUBLE_CLASS     mxSINGLE_CLASS     mxDOUBLE_CLASS        mxSINGLE_CLASS
    LTFAT_MX_COMPLEXITY       mxREAL             mxREAL             mxCOMPLEX             mxCOMPLEX
    LTFAT_FFTW(name)          fftw_##name        fftwf_##name       fftw_##name           fftwf_##name
    LTFAT_NAME(name)          name_d             name_s             name_cd               name_cs
    LTFAT_COMPLEXH(name)      name               namef              name                  namef
    LTFAT_NAME_COMPLEX(name)  name_cd            name_cs            name_cd               name_cs
    By default, a macro set (double) is used.
*/

#define MEX_FILE_STRINGIFY(x) #x
#define MEX_FILE_STR(x) MEX_FILE_STRINGIFY(x)
#define MEX_FILE_S MEX_FILE_STR(MEX_FILE)


#define LTFAT_DOUBLE
#include "ltfat/types.h"
#include "ltfat_mex_typeindependent.h"
#include "ltfat_mex_typecomplexindependent.h"
void LTFAT_NAME(ltfatMexFnc)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
#include MEX_FILE_S
#ifdef COMPLEXINDEPENDENT
#  define LTFAT_COMPLEXTYPE
#  include "ltfat/types.h"
#  include "ltfat_mex_typecomplexindependent.h"
void LTFAT_NAME(ltfatMexFnc)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
#  include MEX_FILE_S
#  undef LTFAT_COMPLEXTYPE
#endif
#undef LTFAT_DOUBLE

#ifdef SINGLEARGS
#  define LTFAT_SINGLE
#  include "ltfat/types.h"
#  include "ltfat_mex_typeindependent.h"
#  include "ltfat_mex_typecomplexindependent.h"
void LTFAT_NAME(ltfatMexFnc)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
#  include MEX_FILE_S
#  ifdef COMPLEXINDEPENDENT
#    define LTFAT_COMPLEXTYPE
#    include "ltfat/types.h"
#    include "ltfat_mex_typecomplexindependent.h"
void LTFAT_NAME(ltfatMexFnc)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
#    include MEX_FILE_S
#    undef LTFAT_COMPLEXTYPE
#  endif
#  undef LTFAT_SINGLE
#endif

/**
* MACRO-FU
*/
#define LTFAT_MEXERRMSG(s,...)                 \
        do{                                    \
        char sChars[256];                      \
        snprintf(sChars,255,(s),__VA_ARGS__);  \
        mexErrMsgTxt(sChars);                  \
        }while(0)

#define FOREACH(item, array)                            \
        for(size_t keep = 1,                            \
            count = 0,                                  \
            size = sizeof (array) / sizeof *(array);    \
        keep && count != size;                          \
        keep = !keep, count++)                          \
        for(item = (array) + count; keep; keep = !keep)


#define FORSUBSET(item, array, subset)                            \
        for(size_t keep = 1,                                      \
            count = 0,                                            \
            size = sizeof (subset) / sizeof *(subset);            \
        keep && count != size;                                    \
        keep = !keep, count++)                                    \
        for(item = (array) + (subset)[count]; keep; keep = !keep)

#define FORSUBSETIDX(itemIdx, array, subset)                 \
        for(size_t keep = 1,                                      \
            count = 0,                                            \
            size = sizeof (subset) / sizeof *(subset);            \
        keep && count != size;                                    \
        keep = !keep, count++)                                    \
        for(itemIdx=&(subset)[count]; keep; keep = !keep)


/** Private Function prototypes */

int checkIsReal(const mxArray *prhsEl);

int checkIsSingle(const mxArray *prhsEl);

mxArray* recastToSingle(mxArray* prhsEl);

void checkArgs(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

// Returns size of datatype defined by classid in bytes
mwSize sizeofClassid(mxClassID classid);

void
clearPRHScopy( mxArray* prhsAlt, const mxArray* prhs);


mwSize sizeofClassid(mxClassID classid)
{
   switch (classid)
   {
   case mxSINGLE_CLASS:
      return sizeof(float);
   case mxDOUBLE_CLASS:
      return sizeof(double);
   case mxUNKNOWN_CLASS:
   case mxCELL_CLASS:
   case mxSTRUCT_CLASS:
   case mxFUNCTION_CLASS:
   default:
      mexErrMsgTxt("Usnupported data type. Add more if you need..");
      return 0;
      break;
   }
}

mwSize ltfatGetN(const mxArray* in)
{
   // mxGetN returns product of sizes of all dimensions > 2
   return mxGetDimensions(in)[1];
}

mxArray *ltfatCreateMatrix(mwSize M, mwSize N, mxClassID classid, mxComplexity complexFlag)
{
   const mwSize dims[] = {M, N};
   return ltfatCreateNdimArray(2, dims, classid, complexFlag);
}

mxArray*
ltfatCreateNdimArray(mwSize ndim, const mwSize *dims, mxClassID classid, mxComplexity complexFlag)
{
   mxArray* out = NULL;

   if (complexFlag == mxREAL)
       out = mxCreateNumericArray( ndim, dims, classid, mxREAL);
#if (MX_HAS_INTERLEAVED_COMPLEX) || defined(NOCOMPLEXFMTCHANGE) 
   else if (complexFlag == mxCOMPLEX)
       out = mxCreateNumericArray( ndim, dims, classid, mxCOMPLEX);
#else
   else if (complexFlag == mxCOMPLEX)
   {
       mwIndex dummyndim = 1;
       const mwSize dummyDims[] = {0};
      // Ugly...
      out = mxCreateNumericArray(dummyndim, dummyDims, classid, mxCOMPLEX);
      // Set correct dimensions
      mxSetDimensions(out, dims, ndim);
      mwSize L = mxGetNumberOfElements(out);

      if(L) // Only if L>0
      {
         mwSize LL = L * 2 * sizeofClassid(classid);
         void* data = mxMalloc(LL);
         if(!data)
             mexErrMsgTxt("Out of memory");

         mxSetData(out, data);
          /*
          Allocate array of length 1 to keep the array beeing identified as complex and to avoid automatic deallocation
          issue.
          */
         mxSetImagData(out, (void*)mxCalloc(1, sizeofClassid(classid)));
      }
   }
#endif
   else
   {
      mexErrMsgTxt("Sanity check failed. Complex flag is neither mxREAL or mxCOMPLEX");
   }

   return out;
}

void checkArgs(int UNUSED(nlhs), mxArray *UNUSED(plhs[]), int nrhs, const mxArray *UNUSED(prhs[]))
{
#ifdef ISNARGINEQ
   if (nrhs != ISNARGINEQ)
   {
      LTFAT_MEXERRMSG("Expected %i input arguments. Only %i passed.", ISNARGINEQ, nrhs);
   }
#endif
#if defined(ISNARGINLE)&&!defined(ISNARGINEQ)
   if (nrhs <= ISNARGINLE)
   {
      LTFAT_MEXERRMSG("Too many input arguments. Expected %i or less input arguments. Passed %i arg.", ISNARGINLE, nrhs);
   }
#endif
#if defined(ISNARGINGE)&&!defined(ISNARGINEQ)
   if (nrhs < ISNARGINGE)
   {
      LTFAT_MEXERRMSG("Too few input arguments. Expected %i or more input arguments. Passed %i arg.", ISNARGINGE, nrhs);
   }
#endif
   // If none of the previous applies, we want to avoid compiler warning
   (void) nrhs;
}

/* Helper recasting functions */
mxArray* recastToSingle(mxArray* prhsEl)
{
   // if the input is cell array, cast all it's elements to single
   if (mxIsCell(prhsEl))
   {
      mxArray* tmpCell = mxCreateCellMatrix(mxGetM(prhsEl), mxGetN(prhsEl));
      for (mwIndex jj = 0; jj < mxGetNumberOfElements(prhsEl); jj++)
      {
         mxArray* cEl = mxGetCell(prhsEl, jj);
         // if (checkIsSingle(cEl))
         // {
         //    // Elements of cell-arrays need to be duplicated to avoid double-free
         //    // issue which occures when copying only a pointer.
         //    mxSetCell(tmpCell, (mwIndex) jj, mxDuplicateArray(cEl));
         // }
         // else
         // {
            mxSetCell(tmpCell, (mwIndex) jj, recastToSingle(cEl));
         // }
      }
      return tmpCell;
   }

   // return the input pointer if the input parameter already contains single prec. data
   if (checkIsSingle(prhsEl))
   {
      return prhsEl;
   }

   // Structures are not s upported
   if (mxIsStruct(prhsEl))
   {
      mexErrMsgTxt("Structures are not supported!");
   }


   // Just copy pointer if the element is not numeric.
   if (!mxIsNumeric(prhsEl))
   {
      return prhsEl;
   }

   mwSize ndim = mxGetNumberOfDimensions(prhsEl);
   const mwSize* dims = mxGetDimensions(prhsEl);
   mxArray* tmpEl = 0;
   mwSize elToCopy = mxGetNumberOfElements(prhsEl);

   if (mxIsComplex(prhsEl))
      tmpEl = mxCreateNumericArray(ndim, dims, mxSINGLE_CLASS, mxCOMPLEX);
   else
      tmpEl = mxCreateNumericArray(ndim, dims, mxSINGLE_CLASS, mxREAL);

   double* prhsElPtr = (double*) mxGetData(prhsEl);
   float* tmpElPtr = (float*) mxGetData(tmpEl);

   for (mwIndex jj = 0; jj < elToCopy; jj++)
      *(tmpElPtr++) = (float)( *(prhsElPtr++) );

   if (mxIsComplex(prhsEl))
   {
#if (MX_HAS_INTERLEAVED_COMPLEX)
       for (mwIndex jj = elToCopy; jj < 2*elToCopy; jj++)
           *(tmpElPtr++) = (float)( *(prhsElPtr++) );
#else
      double* prhsElPtr_i = (double*) mxGetImagData(prhsEl);
      float* tmpElPtr_i = (float*) mxGetImagData(tmpEl);

      for (mwIndex jj = 0; jj < elToCopy; jj++)
         *(tmpElPtr_i++) = (float)( *(prhsElPtr_i++) );
#endif
   }

   return tmpEl;
}

int checkIsSingle(const mxArray *prhsEl)
{
   if (mxIsCell(prhsEl))
   {
      for (mwIndex jj = 0; jj < mxGetNumberOfElements(prhsEl); jj++)
      {
         if (checkIsSingle(mxGetCell(prhsEl, jj)))
            return 1;
      }
      return 0;
   }

   if (mxIsStruct(prhsEl))
   {
      mexErrMsgTxt("Structures are not supported!");
   }

   return mxIsSingle(prhsEl);
}

int checkIsReal(const mxArray *prhsEl)
{
   if (mxIsCell(prhsEl))
   {
      int isAllReal = 0;
      for (mwIndex jj = 0; jj < mxGetNumberOfElements(prhsEl); jj++)
      {
         if (!(isAllReal = checkIsReal(mxGetCell(prhsEl, jj))))
            break;
      }
      return isAllReal;
   }

   return !mxIsComplex(prhsEl);
}

/** MEX entry function
    Handles recasting all defined inputs to a defined data type
 */

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
   static int exitFncRegistered = 0;
   if (!exitFncRegistered)
   {
      // This fails when mexFunction is not called directly from Matlab or another MEX function
      mexAtExit(ltfatMexAtExitGlobal);
      ltfat_set_error_handler(cust_ltfat_error_handler);
      exitFncRegistered = 1;
   }

   mexFunctionInner(nlhs, plhs, nrhs, prhs);

}

void mexFunctionInner(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#ifdef MEX_BEGINNING_HOOK
   MEX_BEGINNING_HOOK
#endif
#if defined(ISNARGINEQ) || defined(ISNARGINLE) || defined(ISNARGINGE)
   checkArgs(nlhs, plhs, nrhs, prhs);
#endif



#ifndef TYPEDEPARGS
   LTFAT_NAME_DOUBLE(ltfatMexFnc)(nlhs, plhs, nrhs, prhs); // pass trough
#else
   plhs[0] = 0;

   // Create array of indexes to be checked
   int prhsToCheckIfComplex[] = { TYPEDEPARGS };
#ifndef MATCHEDARGS
   int prhsToCheckIfSingle[] = { TYPEDEPARGS };
#else
   int prhsToCheckIfSingle[] = { TYPEDEPARGS, MATCHEDARGS };
#endif


   // Check if any of the indexes is less than nrhs
   int maxPrhsToCheck = 0;
   FOREACH(int * valPr, prhsToCheckIfSingle)
   if (*valPr + 1 > maxPrhsToCheck)
      maxPrhsToCheck = *valPr;

   if (!((maxPrhsToCheck) < nrhs))
      LTFAT_MEXERRMSG("To few input arguments. Expected at least %i args.", maxPrhsToCheck + 1);

   // Indicator array defining which input arg. should be reformated.
   int recastToComplexIndArr[nrhs];
   memset(recastToComplexIndArr, 0, sizeof(recastToComplexIndArr));


   int isAnyComplex = 0;
   FORSUBSET(const mxArray **prhsElPtr, prhs, prhsToCheckIfComplex)
   if ( (isAnyComplex = !checkIsReal(*prhsElPtr))) break;



#if !defined(COMPLEXARGS) && defined(REALARGS) && !defined(COMPLEXINDEPENDENT)
   if (isAnyComplex)
   {
      mexErrMsgTxt("Complex input arguments are not alowed.");
      return;
   }
#endif
#if (defined(COMPLEXARGS) && !defined(REALARGS)) && !defined(COMPLEXINDEPENDENT)
   FORSUBSETIDX(int *  prhsElIdx, prhs, prhsToCheckIfComplex)
   recastToComplexIndArr[*prhsElIdx] = 1;
#endif

#if (defined(COMPLEXARGS) && defined(REALARGS)) || defined(COMPLEXINDEPENDENT)
   if (isAnyComplex)
      FORSUBSETIDX(int *  prhsElIdx, prhs, prhsToCheckIfComplex)
      recastToComplexIndArr[*prhsElIdx] = 1;
#endif

   // Copy input parameters
   mxArray **prhsAlt = mxMalloc(nrhs * sizeof(mxArray *));
   memcpy((void *)prhsAlt, (void *)prhs, nrhs * sizeof(mxArray *));

   int isAnySingle = 0;
#ifdef SINGLEARGS
   FORSUBSET(const mxArray **prhsElPtr, prhs, prhsToCheckIfSingle)
   if ( (isAnySingle = checkIsSingle(*prhsElPtr))) break;


   if (isAnySingle)
   {
      FORSUBSETIDX(int *  prhsElIdx, prhs, prhsToCheckIfSingle)
      prhsAlt[*prhsElIdx] = recastToSingle((mxArray *)prhs[*prhsElIdx]);

#ifndef NOCOMPLEXFMTCHANGE
      for (int ii = 0; ii < nrhs; ii++)
         if (recastToComplexIndArr[ii])
            prhsAlt[ii] = LTFAT_NAME_SINGLE(mexSplit2combined)(prhsAlt[ii] ,prhs[ii]);
#endif

#if defined(COMPLEXINDEPENDENT)

      int isAllReal = 0;
      int isAllComplex = 0;

      FORSUBSET(mxArray **prhsElPtr, prhsAlt, prhsToCheckIfComplex)
      if ( !(isAllReal = checkIsReal(*prhsElPtr))) break;

      FORSUBSET(mxArray **prhsElPtr, prhsAlt, prhsToCheckIfComplex)
      if ( !(isAllComplex = !checkIsReal(*prhsElPtr))) break;

      if (!(isAllReal ^ isAllComplex))
         mexErrMsgTxt("Template subsystem error. My bad .");

      if (isAllReal)
         LTFAT_NAME_SINGLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);
      else if (isAllComplex)
         LTFAT_NAME_COMPLEXSINGLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);
#else
      LTFAT_NAME_SINGLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);
#endif //COMPLEXINDEPENDENT

   }
#endif // SINGLEARGS
   if (!isAnySingle)
   {

#ifndef NOCOMPLEXFMTCHANGE
      for (int ii = 0; ii < nrhs; ii++)
         if (recastToComplexIndArr[ii])
            prhsAlt[ii] = LTFAT_NAME_DOUBLE(mexSplit2combined)(prhsAlt[ii] ,prhs[ii]);

#endif


#if defined(COMPLEXINDEPENDENT)

      int isAllReal = 0;
      int isAllComplex = 0;

      FORSUBSET(mxArray **prhsElPtr, prhsAlt, prhsToCheckIfComplex)
      if ( !(isAllReal = checkIsReal(*prhsElPtr))) break;

      FORSUBSET( mxArray **prhsElPtr, prhsAlt, prhsToCheckIfComplex)
      if ( !(isAllComplex = !checkIsReal(*prhsElPtr))) break;

      if (isAllReal == isAllComplex)
         mexErrMsgTxt("Template subsystem error. My bad...");

      if (isAllReal)
         LTFAT_NAME_DOUBLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);
      else if (isAllComplex)
         LTFAT_NAME_COMPLEXDOUBLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);

#else
      LTFAT_NAME_DOUBLE(ltfatMexFnc)(nlhs, plhs, nrhs, (const mxArray**)prhsAlt);
#endif
   }

   for (int n = 0; n < nrhs; n++)
    {
        // mexPrintf("%d, Equal? %d\n" ,n,prhsAlt[n] == prhs[n]);
       clearPRHScopy(prhsAlt[n],prhs[n]);
    }

   mxFree(prhsAlt);


#endif // TYPEDEPARGS


#ifndef NOCOMPLEXFMTCHANGE
   if (plhs[0] != 0)
   {
      if (checkIsSingle(plhs[0]))
      {
#ifdef SINGLEARGS
         if (!checkIsReal(plhs[0]))
            plhs[0] = LTFAT_NAME_SINGLE(mexCombined2split)(plhs[0]);
#endif
      }
      else
      {
         if (!checkIsReal(plhs[0]))
            plhs[0] = LTFAT_NAME_DOUBLE(mexCombined2split)(plhs[0]);
      }
   }

#endif


   if (mexstatus < 0)
   {
        mexstatus = 0;
        mexErrMsgIdAndTxt("libltfat:internal", mexerrormsg);
   }
}

void
clearPRHScopy( mxArray* prhsAlt, const mxArray* prhs)
{

    if (prhs != prhsAlt)
    {
        if( mxIsCell(prhsAlt) )
        {
            // mexPrintf("This is cell\n");
            for( mwSize k = 0; k < mxGetNumberOfElements(prhsAlt); k++ )
            {
                mxArray* altEl = mxGetCell(prhsAlt,k);
                mxArray* origEl = mxGetCell(prhs,k);
                // mexPrintf("Element %d, Equal? %d\n" , k, altEl == origEl);
                clearPRHScopy(altEl, origEl);

                mxSetCell( prhsAlt, k, NULL);
            }
        }
        // mexPrintf("Deleting\n");
        mxDestroyArray(prhsAlt);
    }
}

#endif // _LTFAT_MEX_TEMPLATEHELPER_H
#endif // defined(MEX_FILE)


