
#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

/** ISNARGINEQ, ISNARGINLE, ISNARGINGE
    AT COMPILE-TIME:
    AT RUNTIME: Ensures correct number of the input parameters.
    WHEN MISSING: No input argument checks ale included in the final code.
*/
#define ISNARGINEQ 5
/** TYPEDEPARGS
    AT COMPILE-TIME: Defines integer array from the specified values.
    AT RUNTIME: The array is used to identify input arguments to be checked/reformated. Accepted inputs are numeric arrays,
                cell arrays containing only numeric arrays, structures having at least one field beeing numeric array.
    WHEN MISSING: No input modifications/checks are included in the code.
*/
#define TYPEDEPARGS 0, 1
/** SINGLEARGS
    AT COMPILE-TIME: Includes this file for the second time with TYPEDEPARGS input args. recast to float arrays (cells, structs).
    AT RUNTIME: If at least one of the TYPEDEPARGS input args. is float (single in MatLab), all TYPEDEPARGS are recast to floats.
    WHEN MISSING: TYPEDEPARGS input args can be only double arrays.
*/
#define SINGLEARGS
/** COMPLEXARGS, REALARGS
    AT COMPILE-TIME: (COMPLEXARGS) adds code for on-the-fly conversion from the Matlab complex number format to the
                     complex.h (interleaved) complex data format.
                     (REALARGS) and (COMPLEXARGS) allows both real and complex inputs. Have to be handled here.
    AT RUNTIME: (COMPLEXARGS) TYPEDEPARGS input args are recast to complex format even in they are real.
                (REALARGS) TYPEDEPARGS args are accepted only if they are real.
                (REALARGS) and (COMPLEXARGS) If at least one of the TYPEDEPARGS is complex do as (COMPLEXARGS), otherwise let
                the inputs untouched.
    WHEN MISSING: Real/Complex are not checked. No complex data format change.
*/

/** COMPLEXINDEPENDENT
    AT COMPILE-TIME: As if both COMPLEXARGS, REALARGS were defined.
    AT RUNTIME: As if both COMPLEXARGS, REALARGS were defined plus it is assumed that the called functions from the LTFAT
                backend are from ltfat_typecomplexindependent.h, e.i. there are
    WHEN MISSING: No input checks REAL/COMPLEX checks are included in the final code.
*/
#define COMPLEXINDEPENDENT
#define EXPORTALIAS comp_filterbank_td

#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

/* Obtain this filename. */
#define MEX_FILE comp_filterbank_td.c
#include "ltfat_mex_template_helper.h"


#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"
/** USER DEFINED HEADERS **/
#include "math.h"

/*
%COMP_FILTERBANK_TD   Non-uniform filterbank
%   Usage:  c=comp_filterbank_td(f,g,a,offset,ext);
%
%   Input parameters:
%         f   : Input data - L*W array.
%         g   : Filterbank filters - length M cell-array of vectors of lengths filtLen(m).
%         a   : Subsampling factors - array of length M.
%         offset: Offset of the filters - scalar or array of length M.
%         ext : Border exension technique.
%
%   Output parameters:
%         c  : Cell array of length M. Each element is N(m)*W array.
*/

void
LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                         int UNUSED(nrhs), const mxArray *prhs[] )
{
    const mxArray* mxf = prhs[0];
    const mxArray* mxg = prhs[1];
    double* aDouble = (double*) mxGetData(prhs[2]);
    double* offsetDouble = (double*) mxGetData(prhs[3]);
    ltfatExtType ext = ltfatExtStringToEnum( mxArrayToString(prhs[4]) );


    // input data length
    mwSize L = mxGetM(mxf);
    // number of channels
    mwSize W = mxGetN(mxf);
    // filter number
    mwSize M = mxGetNumberOfElements(mxg);

    // POINTER TO THE INPUT
    LTFAT_TYPE* fPtr =  mxGetData(prhs[0]);

    // POINTER TO THE FILTERS
    const LTFAT_TYPE* gPtrs[M];
    ltfat_int filtLen[M];
    ltfat_int a[M];
    ltfat_int offset[M];

    // POINTER TO OUTPUTS
    LTFAT_TYPE* cPtrs[M]; // C99 feature
    plhs[0] = mxCreateCellMatrix(M, 1);
    for(mwIndex m=0; m<M; ++m)
    {
        a[m]= (ltfat_int) aDouble[m];
        offset[m] = (ltfat_int) offsetDouble[m];
        filtLen[m] = (ltfat_int) mxGetNumberOfElements(mxGetCell(mxg,m));
        mwSize outLen = (mwSize) filterbank_td_size(L,a[m],filtLen[m],
                                                offset[m],ext);
        mxSetCell(plhs[0], m,
                  ltfatCreateMatrix(outLen,
                                    W,LTFAT_MX_CLASSID,
                                    LTFAT_MX_COMPLEXITY));
        cPtrs[m] = mxGetData(mxGetCell(plhs[0],m));
        gPtrs[m] = mxGetData(mxGetCell(mxg, m));
    }


    LTFAT_NAME(filterbank_td)(fPtr,gPtrs,L,filtLen,W,a,offset,M,cPtrs,ext);

}
#endif

