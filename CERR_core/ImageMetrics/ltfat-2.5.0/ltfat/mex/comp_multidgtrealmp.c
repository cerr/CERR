#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 11
#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define REALARGS

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_multidgtrealmp.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

// Calling convention:  0 1 2 3     4       5     6     7     8                 9  10  
//  comp_multidgtrealmp(f,g,a,M,ptype,kernthr,errdb,maxit,maxat,do_pedanticsearch,alg);
//
//  
//

void LTFAT_NAME(ltfatMexFnc)( int nlhs, mxArray *plhs[],
                              int UNUSED(nrhs), const mxArray *prhs[] )
{
    LTFAT_NAME(dgtrealmp_parbuf)* pbuf = NULL;
    LTFAT_NAME(dgtrealmp_state)*  plan = NULL;
    char algstr[51];
    mxGetString(prhs[10],algstr,50);
    ltfat_dgtmp_alg alg = ltfat_dgtmp_alg_mp;

    
    if( 0 == strcmp("cyclicmp", algstr))
        alg = ltfat_dgtmp_alg_loccyclicmp;
    else if( 0 == strcmp("selfprojmp",algstr))
        alg = ltfat_dgtmp_alg_locselfprojmp;
    
    size_t atoms = 0;
    size_t iters = 0;
    int dec_status = 0;

    mwSize L  = mxGetNumberOfElements(prhs[0]);
    mwSize dictno = mxGetNumberOfElements(prhs[1]);
    double* aDouble = mxGetData(prhs[2]);
    double* MDouble = mxGetData(prhs[3]);
    int ptype = (int)mxGetScalar(prhs[4]) == 1 ? LTFAT_TIMEINV: LTFAT_FREQINV;;
    double kernthr = mxGetScalar(prhs[5]);
    double errdb = mxGetScalar(prhs[6]);
    size_t maxit = (size_t)mxGetScalar(prhs[7]);
    size_t maxat = (size_t)mxGetScalar(prhs[8]);
    int do_pedanticsearch = (int)mxGetScalar(prhs[9]);

    plhs[0] = mxCreateCellMatrix(dictno, 1);
    LTFAT_COMPLEX** cPtrs = mxMalloc(dictno*sizeof*cPtrs);

    for(mwIndex dIdx=0;dIdx<dictno;dIdx++)
    {
        mxSetCell(plhs[0], dIdx,
                  ltfatCreateMatrix(
                      ((mwSize) MDouble[dIdx])/2 + 1, (mwSize)(L/aDouble[dIdx]),
                      LTFAT_MX_CLASSID,mxCOMPLEX));
        cPtrs[dIdx] = mxGetData(mxGetCell(plhs[0],dIdx));
    }

    CHSTAT(LTFAT_NAME(dgtrealmp_parbuf_init)(&pbuf));

    for(mwIndex dIdx=0;dIdx<dictno;dIdx++)
    {
        CHSTAT(LTFAT_NAME(dgtrealmp_parbuf_add_genwin)(pbuf,
                mxGetData(mxGetCell(prhs[1],dIdx)),
                mxGetNumberOfElements(mxGetCell(prhs[1],dIdx)),
                (ltfat_int)aDouble[dIdx], (ltfat_int)MDouble[dIdx]));
    }

    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_phaseconv)(pbuf, ptype));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_pedanticsearch)(pbuf, do_pedanticsearch));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_snrdb)(pbuf, -errdb));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_kernrelthr)(pbuf, kernthr));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_maxatoms)(pbuf, maxat));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_maxit)(pbuf, maxit));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_iterstep)(pbuf, L));
    CHSTAT(LTFAT_NAME(dgtrealmp_setparbuf_alg)(pbuf, alg));

    CHSTAT(LTFAT_NAME(dgtrealmp_init)( pbuf, L, &plan));
    CHSTAT(dec_status = LTFAT_NAME(dgtrealmp_execute_decompose)(plan, mxGetData(prhs[0]), cPtrs));

    CHSTAT(LTFAT_NAME(dgtrealmp_get_numatoms)(plan, &atoms));
    CHSTAT(LTFAT_NAME(dgtrealmp_get_numiters)(plan, &iters));

error:
    if(nlhs>1) plhs[1] = mxCreateDoubleScalar((double)atoms);
    if(nlhs>2) plhs[2] = mxCreateDoubleScalar((double)iters);
    if(nlhs>3) plhs[3] = mxCreateDoubleScalar((double)dec_status);

    if(pbuf) LTFAT_NAME(dgtrealmp_parbuf_done)(&pbuf);
    if(plan) LTFAT_NAME(dgtrealmp_done)(&plan);
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */

