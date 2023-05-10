#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 3
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS

#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

#define MEX_FILE comp_filterbank_fft.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"
#include "math.h"
#include "config.h"

static LTFAT_NAME(convsub_fft_plan)* LTFAT_NAME(oldPlans) = 0;
static mwSize* LTFAT_NAME(oldLc) = 0;
static mwSize LTFAT_NAME(oldM) = 0;
static mwSize LTFAT_NAME(oldW) = 0;

// Calling convention:
// c = comp_filterbank_fft(F,G,a)

void LTFAT_NAME(fftMexAtExitFnc)()
{
#ifdef _DEBUG
    mexPrintf("Exit fnc called: %s\n",__PRETTY_FUNCTION__);
#endif
    if(LTFAT_NAME(oldPlans)!=0)
    {
        for(mwIndex m=0; m<LTFAT_NAME(oldM); m++)
        {
            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(convsub_fft_done)(LTFAT_NAME(oldPlans)[m]);
            }
        }
        ltfat_free(LTFAT_NAME(oldPlans));
        LTFAT_NAME(oldPlans) = 0;
    }

    if(LTFAT_NAME(oldLc)!=0)
    {
        ltfat_free(LTFAT_NAME(oldLc));
        LTFAT_NAME(oldLc) = 0;
    }
    LTFAT_NAME(oldM) = 0;
    LTFAT_NAME(oldW) = 0;
}

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    static int atExitFncRegistered = 0;
    if(!atExitFncRegistered)
    {
        LTFAT_NAME(ltfatMexAtExit)(LTFAT_NAME(fftMexAtExitFnc));
        atExitFncRegistered = 1;
    }

    const mxArray* mxF = prhs[0];
    const mxArray* mxG = prhs[1];
    double* aDouble = mxGetData(prhs[2]);

    // input data length
    mwSize L = mxGetM(mxF);
    // number of channels
    mwSize W = mxGetN(mxF);
    // filter number
    mwSize M = mxGetNumberOfElements(mxG);

    // output lengths
    mwSize outLen[M];
    // Hop sizes
    mwSize a[M];
    // Filter pointer array
    const LTFAT_COMPLEX* GPtrs[M];
    // POINTER TO THE INPUT
    const LTFAT_COMPLEX* FPtr = mxGetData(prhs[0]);
    // POINTER TO OUTPUTS
    LTFAT_COMPLEX* cPtrs[M]; // C99 feature
    plhs[0] = mxCreateCellMatrix(M, 1);

    if(M!=LTFAT_NAME(oldM) || W != LTFAT_NAME(oldW) )
    {
        LTFAT_NAME(fftMexAtExitFnc)();
        LTFAT_NAME(oldM) = M;
        LTFAT_NAME(oldW) = W;
        LTFAT_NAME(oldLc) = ltfat_calloc(M,sizeof(mwSize));
        LTFAT_NAME(oldPlans) = ltfat_calloc(M,sizeof*LTFAT_NAME(oldPlans));
    }

    for(mwIndex m=0; m<M; ++m)
    {
        a[m] = (mwSize) aDouble[m];
        outLen[m] = (mwSize) ceil( L/a[m] );
        GPtrs[m] = mxGetData(mxGetCell(mxG, m));
        mxSetCell(plhs[0], m,
                  ltfatCreateMatrix(outLen[m], W, LTFAT_MX_CLASSID,mxCOMPLEX));
        cPtrs[m] = mxGetData(mxGetCell(plhs[0],m));

        if(LTFAT_NAME(oldLc)[m]!=outLen[m])
        {
            LTFAT_NAME(oldLc)[m] = outLen[m];
            LTFAT_NAME(convsub_fft_plan) ptmp =
            LTFAT_NAME(convsub_fft_init)( L, W, a[m], cPtrs[m]);

            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(convsub_fft_done)(LTFAT_NAME(oldPlans)[m]);
            }
            LTFAT_NAME(oldPlans)[m]=ptmp;
        }
    }

    LTFAT_NAME(filterbank_fft_execute)(LTFAT_NAME(oldPlans), FPtr, GPtrs,
                                       M, cPtrs);
//    LTFAT_NAME(filterbank_fft)(FPtr, GPtrs, L, W, a, M, cPtrs);


}
#endif




