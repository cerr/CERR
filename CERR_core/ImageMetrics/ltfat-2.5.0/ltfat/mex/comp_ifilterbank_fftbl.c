#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 5
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS
#define EXPORTALIAS comp_ifilterbank_fftbl

#endif // _LTFAT_MEX_FILE - INCLUDED ONCE

#define MEX_FILE comp_ifilterbank_fftbl.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"
#include <math.h>
#include "config.h"

static LTFAT_NAME(upconv_fftbl_plan)* LTFAT_NAME(oldPlans) = 0;
static mwSize* LTFAT_NAME(oldLc) = 0;
static mwSize* LTFAT_NAME(oldGl) = 0;
static mwSize LTFAT_NAME(oldM) = 0;
static mwSize LTFAT_NAME(oldW) = 0;

void LTFAT_NAME(fftblMexAtExitFnc)()
{
    if(LTFAT_NAME(oldPlans)!=0)
    {
        for(mwIndex m=0; m<LTFAT_NAME(oldM); m++)
        {
            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(upconv_fftbl_done)(LTFAT_NAME(oldPlans)[m]);
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

    if(LTFAT_NAME(oldGl)!=0)
    {
        ltfat_free(LTFAT_NAME(oldGl));
        LTFAT_NAME(oldGl) = 0;
    }

    LTFAT_NAME(oldM) = 0;
    LTFAT_NAME(oldW) = 0;
#ifdef _DEBUG
    mexPrintf("Exit fnc called: %s\n",__PRETTY_FUNCTION__);
#endif
}

// Calling convention:
// c = comp_ifilterbank_fftbl(c,G,foff,a,realonly)

void LTFAT_NAME(ltfatMexFnc)( int UNUSED(nlhs), mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{

    static int atExitFncRegistered = 0;
    if(!atExitFncRegistered)
    {
        LTFAT_NAME(ltfatMexAtExit)(LTFAT_NAME(fftblMexAtExitFnc));
        atExitFncRegistered = 1;
    }

    const mxArray* mxc = prhs[0];
    const mxArray* mxG = prhs[1];
    double* foffDouble = mxGetData(prhs[2]);
    double* a = mxGetData(prhs[3]);
    double* realonlyDouble = mxGetData(prhs[4]);

    // number of channels
    mwSize W = mxGetN(mxGetCell(mxc,0));
    // filter number
    mwSize M = mxGetNumberOfElements(mxG);

    //
    mwSize acols = mxGetN(prhs[3]);

    double afrac[M];
    memcpy(afrac,a,M*sizeof(double));
    if(acols>1)
    {
        for(mwIndex m=0; m<M; m++)
        {
            afrac[m] = afrac[m]/a[M+m];
        }
    }

    // POINTER TO THE FILTERS
    const LTFAT_COMPLEX* GPtrs[M];
    // input lengths
    mwSize inLen[M];
    mwSignedIndex foff[M];
    int realonly[M];
    // POINTER TO INPUTS
    const LTFAT_COMPLEX* cPtrs[M];
    // filter lengths
    mwSize Gl[M];

    if(M!=LTFAT_NAME(oldM) || W!=LTFAT_NAME(oldW))
    {
        LTFAT_NAME(fftblMexAtExitFnc)();
        LTFAT_NAME(oldM) = M;
        LTFAT_NAME(oldW) = W;
        LTFAT_NAME(oldLc) = ltfat_calloc(M,sizeof(mwSize));
        LTFAT_NAME(oldGl) = ltfat_calloc(M,sizeof(mwSize));
        LTFAT_NAME(oldPlans) = ltfat_calloc(M,sizeof*LTFAT_NAME(oldPlans));
    }

    // output data length
    mwSize L = (mwSize) floor(afrac[0]*mxGetM(mxGetCell(mxc, 0)) + 0.5);

    // over all channels
    for(mwIndex m =0; m<M; m++)
    {
        foff[m] = (mwSignedIndex) foffDouble[m];
        realonly[m] = (realonlyDouble[m]>1e-3);
        cPtrs[m] = mxGetData(mxGetCell(mxc,m));
        inLen[m] = (mwSize) mxGetM(mxGetCell(mxc, m));
        GPtrs[m] =  mxGetData(mxGetCell(mxG, m));
        Gl[m] = (mwSize) mxGetNumberOfElements(mxGetCell(mxG, m));

        if(LTFAT_NAME(oldLc)[m]!=inLen[m] || LTFAT_NAME(oldGl)[m]!=Gl[m])
        {
            LTFAT_NAME(oldLc)[m] = inLen[m];
            LTFAT_NAME(oldGl)[m] = Gl[m];
            LTFAT_NAME(upconv_fftbl_plan) ptmp =
                LTFAT_NAME(upconv_fftbl_init)(L, Gl[m], W, afrac[m]);

            if(LTFAT_NAME(oldPlans)[m]!=0)
            {
                LTFAT_NAME(upconv_fftbl_done)(LTFAT_NAME(oldPlans)[m]);
            }
            LTFAT_NAME(oldPlans)[m]=ptmp;
        }
    }


    plhs[0] = ltfatCreateMatrix(L, W, LTFAT_MX_CLASSID, mxCOMPLEX);
    mxArray* mxF = plhs[0];
    LTFAT_COMPLEX* FPtr = mxGetData(mxF);

   LTFAT_NAME(ifilterbank_fftbl_execute)( LTFAT_NAME(oldPlans), cPtrs, GPtrs,
                                          M, foff, realonly, FPtr);
}
#endif




