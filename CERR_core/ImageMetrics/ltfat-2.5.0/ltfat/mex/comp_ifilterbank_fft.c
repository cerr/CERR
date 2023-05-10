#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 3
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS
#define EXPORTALIAS comp_ifilterbank_fft

#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

#define MEX_FILE comp_ifilterbank_fft.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"
#include "math.h"
#include "config.h"

// Calling convention:
// c = comp_ifilterbank_fft(c,G,a)

static LTFAT_NAME(upconv_fft_plan)* LTFAT_NAME(oldPlans) = 0;
static mwSize* LTFAT_NAME(oldLc) = 0;
static mwSize LTFAT_NAME(oldM) = 0;
static mwSize LTFAT_NAME(oldW) = 0;

void LTFAT_NAME(ifftMexAtExitFnc)()
{
    if(LTFAT_NAME(oldPlans)!=0)
    {
        for(mwIndex m=0; m<LTFAT_NAME(oldM); m++)
        {
            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(upconv_fft_done)(LTFAT_NAME(oldPlans)[m]);
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
#ifdef _DEBUG
    mexPrintf("Exit fnc called: %s\n",__PRETTY_FUNCTION__);
#endif
}

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    static int atExitFncRegistered = 0;
    if(!atExitFncRegistered)
    {
        LTFAT_NAME(ltfatMexAtExit)(LTFAT_NAME(ifftMexAtExitFnc));
        atExitFncRegistered = 1;
    }

    const mxArray* mxc = prhs[0];
    const mxArray* mxG = prhs[1];
    double* aDouble = mxGetData(prhs[2]);

    // input data length
    mwSize L = mxGetM(mxGetCell(mxG,0));
    // number of channels
    mwSize W = mxGetN(mxGetCell(mxc,0));
    // filter number
    mwSize M = mxGetNumberOfElements(mxc);

    // input lengths
    mwSize inLen[M];

    // Hop sizes array
    mwSize a[M];

    plhs[0] = ltfatCreateMatrix(L, W,LTFAT_MX_CLASSID,mxCOMPLEX);

    // POINTER TO THE OUTPUT
    LTFAT_COMPLEX* FPtr = mxGetData(plhs[0]);


    // POINTERS TO THE FILTERS
    const LTFAT_COMPLEX* GPtrs[M];

    // POINTER TO INPUTS
    const LTFAT_COMPLEX* cPtrs[M]; // C99 feature


    if(M!=LTFAT_NAME(oldM) || W!=LTFAT_NAME(oldW))
    {
        LTFAT_NAME(ifftMexAtExitFnc)();
        LTFAT_NAME(oldM) = M;
        LTFAT_NAME(oldLc) = ltfat_calloc(M,sizeof(mwSize));
        LTFAT_NAME(oldPlans) = ltfat_calloc(M,sizeof*LTFAT_NAME(oldPlans));
    }

    for(mwIndex m =0; m<M; m++)
    {
        a[m] = (mwSize) aDouble[m];
        GPtrs[m] = mxGetData(mxGetCell(mxG, m));
        cPtrs[m] = mxGetData(mxGetCell(mxc,m));
        inLen[m] = mxGetM(mxGetCell(mxc,m));


        if(LTFAT_NAME(oldLc)[m]!=inLen[m])
        {
            LTFAT_NAME(oldLc)[m] = inLen[m];

            LTFAT_NAME(upconv_fft_plan) ptmp =
                LTFAT_NAME(upconv_fft_init)(L, W, a[m]);

            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(upconv_fft_done)(LTFAT_NAME(oldPlans)[m]);
            }
            LTFAT_NAME(oldPlans)[m]=ptmp;
        }
    }

    LTFAT_NAME(ifilterbank_fft_execute)(LTFAT_NAME(oldPlans),cPtrs,GPtrs,M, FPtr);

// LTFAT_NAME(ifilterbank_fft)(cPtrs,GPtrs,L,W,a,M, FPtr);


}
#endif




