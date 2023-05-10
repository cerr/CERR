#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "heapint_private.h"
#include "fbheapint_private.h"

void
LTFAT_NAME(borderstoheapneighs)(struct LTFAT_NAME(heap)* h,
                                const ltfat_int Nsum, const ltfat_int neighs[], int* donemask)
{
    for (ltfat_int n = 0; n < Nsum; n++)
    {
        if (donemask[n] && donemask[n] != 5)
        {
            const ltfat_int* wneigh = neighs + 6 * n;
            for (ltfat_int ii = 0; ii < 6; ii++)
            {
                if ( !donemask[wneigh[ii]] )
                {
                    donemask[n] = 11; // Code of a good border coefficient
                    LTFAT_NAME(heap_insert)(h, n);
                    break;
                }
                // Do nothing if none of the neighbors is unknown
            }
        }
    }
}

/*--------------------------------FILTERBANK HEAP INTEGRATION---------------------------------*/
LTFAT_API
struct LTFAT_NAME(heapinttask_ufb)*
LTFAT_NAME(heapinttask_init_ufb)(const ltfat_int height, const ltfat_int N,
                                 const ltfat_int initheapsize,
                                 const LTFAT_REAL* s, int do_real)
{
    struct LTFAT_NAME(heapinttask_ufb)* fbhit = LTFAT_NEW(struct LTFAT_NAME(heapinttask_ufb));
    //ltfat_malloc(sizeof * fbhit);
    fbhit->hit = LTFAT_NAME(heapinttask_init)( height, N, initheapsize, s, do_real);
    if (do_real)
        fbhit->intfun = LTFAT_NAME(trapezheapreal_ufb);
    else
        fbhit->intfun = LTFAT_NAME(trapezheap_ufb);
    return fbhit;
}
/* Execute the Heap Integration */
LTFAT_API
void LTFAT_NAME(heapint_execute_ufb)(struct LTFAT_NAME(heapinttask_ufb)* fbhit,
                                     const LTFAT_REAL* tgradw,
                                     const LTFAT_REAL* fgradw,
                                     const LTFAT_REAL* cfreq,
                                     LTFAT_REAL* phase)
{
    /* Declarations */
    ltfat_int Imax;
    ltfat_int w;
    LTFAT_REAL maxs;
    int* donemask = fbhit->hit->donemask;
    struct LTFAT_NAME(heap)* h = fbhit->hit->heap;
    while (1)
    {
        /* Inner loop processing all connected coefficients */
        /* Extract largest (first) element from heap and delete it. */
        while ((w = LTFAT_NAME(heap_delete)(h)) >= 0)
        {
            /* Spread the current phase value to 4 direct neighbors */
            (*fbhit->intfun)(fbhit->hit, tgradw, fgradw, cfreq, w, phase);
        }
        if (!LTFAT_NAME_REAL(findmaxinarraywrtmask)(
                LTFAT_NAME(heap_getdataptr)(h), donemask,
                fbhit->hit->height * fbhit->hit->N, &maxs, &Imax))
            break;
        /* Put maximal element onto the heap and mark that it is done. */
        LTFAT_NAME(heap_insert)(h, Imax);
        donemask[Imax] = 6;
    }
}
/* Trapezoidal integration rule, filterbank case with full frequency range */
void LTFAT_NAME(trapezheap_ufb)(const struct LTFAT_NAME(heapinttask) *hit,
                                const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                                const LTFAT_REAL* cfreq,
                                const ltfat_int w,
                                LTFAT_REAL* phase)
{
    const ltfat_int M = hit->height;
    const ltfat_int N = hit->N;
    struct LTFAT_NAME(heap)* h = hit->heap;
    int* donemask = hit->donemask;
    ltfat_int w_E, w_W, w_N, w_S, col, row;
    /* Try and put the four neighbours onto the heap.
     * Integration by trapezoidal rule */
    /* When integrating across frequencies, the difference of the associated
     * center frequencies has to be taken into account*/
    col = w / N;
    row = w % N;
    /* Inside a channel */
    /* South -> Backwards time */
    w_S = SOUTHFROMW(w, N, M);
    if (!donemask[w_S] && row != 0)
    {
        phase[w_S] = phase[w] - (tgradw[w] + tgradw[w_S]) / 2;
        donemask[w_S] = 3;
        LTFAT_NAME(heap_insert)(h, w_S);
    }
    /* North -> Forwards time */
    w_N = NORTHFROMW(w, N, M);
    if (!donemask[w_N] && row != N-1)
    {
        phase[w_N] = phase[w] + (tgradw[w] + tgradw[w_N]) / 2;
        donemask[w_N] = 4;
        LTFAT_NAME(heap_insert)(h, w_N);
    }
    /* Across channels */
    /* West -> Lower frequency */
    w_W = WESTFROMW(w, N, M);
    if (!donemask[w_W])
    {
        LTFAT_REAL step = cfreq[w_W / N] - cfreq[col];
        if (step > 0)
            step -= 2;
        phase[w_W] = phase[w] + step * (fgradw[w] + fgradw[w_W]) / 2;
        donemask[w_W] = 1;
        LTFAT_NAME(heap_insert)(h, w_W);
    }
    /* East -> Higher frequency */
    w_E = EASTFROMW(w, N, M);
    if (!donemask[w_E])
    {
        LTFAT_REAL step = cfreq[w_E / N] - cfreq[col];
        if (step < 0)
            step += 2;
        phase[w_E] = phase[w] + step * (fgradw[w] + fgradw[w_E]) / 2;
        donemask[w_E] = 2;
        LTFAT_NAME(heap_insert)(h, w_E);
    }    
}
/* Trapezoidal integration rule, filterbank case with partial frequency range -> Standard case*/
void LTFAT_NAME(trapezheapreal_ufb)(const struct LTFAT_NAME(heapinttask) *hit,
                                    const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                                    const LTFAT_REAL* cfreq,
                                    const ltfat_int w,
                                    LTFAT_REAL* phase)
{
    const ltfat_int M = hit->height;
    const ltfat_int N = hit->N;
    int* donemask = hit->donemask;
    struct LTFAT_NAME(heap) *h = hit->heap;
    ltfat_int w_E, w_W, w_N, w_S, row, col;    
    /* Try and put the four neighbours onto the heap.
     * Integration by trapezoidal rule */
    /* When integrating across frequencies, the difference of the associated
     * center frequencies has to be taken into account*/
    col = w / N;
    row = w % N;
    /* Inside a channel */
    /* South -> Backwards time */
    w_S = SOUTHFROMW(w, N, M);
    if (!donemask[w_S] && row != 0)
    {
        phase[w_S] = phase[w] - (tgradw[w] + tgradw[w_S]) / 2;
        donemask[w_S] = 3;
        LTFAT_NAME(heap_insert)(h, w_S);
    }
    /* North -> Forwards time*/
    w_N = NORTHFROMW(w, N, M);
    if (!donemask[w_N] && row != N-1)
    {
        phase[w_N] = phase[w] + (tgradw[w] + tgradw[w_N]) / 2;
        donemask[w_N] = 4;
        LTFAT_NAME(heap_insert)(h, w_N);
    }
    /* Across channels */
    /* West -> Lower frequency */
    w_W = WESTFROMW(w, N, M);
    if (!donemask[w_W] && col != 0)
    {
        LTFAT_REAL step = cfreq[w_W / N] - cfreq[col];
        if (step > 0)
            step -= 2;
        phase[w_W] = phase[w] + step * (fgradw[w] + fgradw[w_W]) / 2;
        donemask[w_W] = 1;
        LTFAT_NAME(heap_insert)(h, w_W);
    }
    /* East -> Higher frequency */
    w_E = EASTFROMW(w, N, M);
    if (!donemask[w_E] && col != M-1)
    {
        LTFAT_REAL step = cfreq[w_E / N] - cfreq[col];
        if (step < 0)
            step += 2;
        phase[w_E] = phase[w] + step * (fgradw[w] + fgradw[w_E]) / 2;
        donemask[w_E] = 2;
        LTFAT_NAME(heap_insert)(h, w_E);
    }    
}
/* Conversion of tgrad and fgrad to correct convention and scaling */
void
LTFAT_NAME(gradsamptorad_ufb)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                              const LTFAT_REAL* cfreq,
                              ltfat_int a, ltfat_int M, ltfat_int L, ltfat_int W,
                              LTFAT_REAL* tgradw, LTFAT_REAL* fgradw)
{
    ltfat_int N = L / a;
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* tgradchan = tgrad + w * M * N;
        const LTFAT_REAL* fgradchan = fgrad + w * M * N;
        LTFAT_REAL* tgradwchan = tgradw + w * M * N;
        LTFAT_REAL* fgradwchan = fgradw + w * M * N;
        for (ltfat_int m = 0; m < M; m++)
        {
            for (ltfat_int n = 0; n < N; n++)
            {
                /*In contrast to Gabor, tgrad is not in samples, but in ]-1,1]*/
                tgradwchan[n + m * N] =    a * (tgradchan[n + m * N] + cfreq[m]) *
                                           M_PI;
                /*In contrast to Gabor, fgrad has to be weighted by the channel difference
                *DURING the integration. However, cfreq ranges in ]-1,1], so fgrad is 			*only scaled by PI.*/
                fgradwchan[n + m * N] =  - ( fgradchan[n + m * N] ) * M_PI;
            }
        }
    }
}
/* Interfacing functions for the various cases*/
LTFAT_API
void LTFAT_NAME(ufilterbankheapint)(const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             const LTFAT_REAL* cfreq,
                             const ltfat_int a, const ltfat_int M,
                             const ltfat_int L, const ltfat_int W,
			     const int do_real, const LTFAT_REAL tol,  
		             LTFAT_REAL* phase)
{
    /* Declarations */
    struct LTFAT_NAME(heapinttask_ufb)* fbhit;
    // Width of s
    ltfat_int N = L / a;
    /* Set the phase to zero initially */
    memset(phase, 0, M * N * W * sizeof * phase);
    // Init plan
    fbhit = LTFAT_NAME(heapinttask_init_ufb)( M, N, M * log((double)M) , s, do_real);
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * M * N;
        const LTFAT_REAL* tgradwchan = tgradw + w * M * N;
        const LTFAT_REAL* fgradwchan = fgradw + w * M * N;
        LTFAT_REAL* phasechan = phase + w * M * N;
        LTFAT_NAME(heapinttask_resetmax)(fbhit->hit, schan, tol);
        LTFAT_NAME(heapint_execute_ufb)(fbhit, tgradwchan, fgradwchan, cfreq,
                                        phasechan);
    }
    LTFAT_NAME(heapinttask_done)(fbhit->hit);
    ltfat_free(fbhit);
}
LTFAT_API
void LTFAT_NAME(ufilterbankmaskedheapint)(const LTFAT_REAL* s,
                                   const LTFAT_REAL* tgradw,
                                   const LTFAT_REAL* fgradw,
                                   const LTFAT_REAL* cfreq,
                                   const int* mask,
                                   const ltfat_int a, const ltfat_int M,
                                   const ltfat_int L, const ltfat_int W,
				   const int do_real,
                                   const LTFAT_REAL tol,
                                   LTFAT_REAL* phase)
{
    /* Declarations */
    struct LTFAT_NAME(heapinttask_ufb)* fbhit;
    ltfat_int N = L / a;
    /* Main body */
    fbhit = LTFAT_NAME(heapinttask_init_ufb)( M, N, M * log((double)M) , s, do_real);
    // Set all phases outside of the mask to zeros, do not modify the rest
    for (ltfat_int ii = 0; ii < M * N * W; ii++)
        if (!mask[ii])
            phase[ii] = 0;
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * M * N;
        const LTFAT_REAL* tgradwchan = tgradw + w * M * N;
        const LTFAT_REAL* fgradwchan = fgradw + w * M * N;
        const int* maskchan = mask + w * M * N;
        LTFAT_REAL* phasechan = phase + w * M * N;
        // Empty heap and fill it with the border coefficients from the mask
        LTFAT_NAME(heapinttask_resetmask)(fbhit->hit, maskchan, schan, tol, 0);
        LTFAT_NAME(borderstoheap)(fbhit->hit->heap, fbhit->hit->N, fbhit->hit->height,
                                  fbhit->hit->donemask);
        LTFAT_NAME(heapint_execute_ufb)(fbhit, tgradwchan, fgradwchan, cfreq,
                                        phasechan);
    }
    LTFAT_NAME(heapinttask_done)(fbhit->hit);
    ltfat_free(fbhit);
}
	/*  The _relgrad versions are just wrappers.
	 *  They convert the relative phase gradients in samples to
	 *  absolute phase gradinets in radians. */
LTFAT_API void
LTFAT_NAME(ufilterbankheapint_relgrad)(const LTFAT_REAL* s,
                                const LTFAT_REAL* tgrad,
                                const LTFAT_REAL* fgrad,
                                const LTFAT_REAL* cfreq,
                                const ltfat_int a, const ltfat_int M,
                                const ltfat_int L, const ltfat_int W,
			        const int do_real,
                                const LTFAT_REAL tol,
                                LTFAT_REAL* phase)
{
    ltfat_int N = L / a;
    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(M * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(M * N * W);
    /* Rescale the derivatives such that they are in radians and the step is 1 in time
     * direction. The step in frequency direction is multiplied by the difference of the center
     * frequencies during integration.*/
    LTFAT_NAME(gradsamptorad_ufb)(tgrad, fgrad, cfreq, a, M, L, W, tgradw, fgradw);
    LTFAT_NAME(ufilterbankheapint)(s, tgradw, fgradw, cfreq, a, M, L, W, do_real, tol, phase);
    LTFAT_SAFEFREEALL(tgradw, fgradw);
}
LTFAT_API void
LTFAT_NAME(ufilterbankmaskedheapint_relgrad)(const LTFAT_REAL* s,
                                      const LTFAT_REAL* tgrad,
                                      const LTFAT_REAL* fgrad,
                                      const LTFAT_REAL* cfreq,
                                      const int* mask,
                                      const ltfat_int a, const ltfat_int M,
                                      const ltfat_int L, const ltfat_int W,
				      const int do_real,
                                      const LTFAT_REAL tol,
                                      LTFAT_REAL* phase)
{
    ltfat_int N = L / a;
    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc) (M * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc) (M * N * W);
    /* Rescale the derivatives such that they are in radians and the step is 1 in time
     * direction. The step in frequency direction is multiplied by the difference of the center
     * frequencies during integration.*/
    LTFAT_NAME(gradsamptorad_ufb)(tgrad, fgrad, cfreq, a, M, L, W, tgradw, fgradw);
    LTFAT_NAME(ufilterbankmaskedheapint)(s, tgradw, fgradw, cfreq, mask, a, M, L, W, do_real, tol,
                                  phase);
    LTFAT_SAFEFREEALL(tgradw, fgradw);
}
/*--------------------------------GENERAL FILTER BANKS---------------------------------*/
LTFAT_API
struct LTFAT_NAME(heapinttask_fb)*
LTFAT_NAME(heapinttask_init_fb)(const ltfat_int height,
                                const ltfat_int initheapsize,
                                const LTFAT_REAL* s,
                                const ltfat_int* N,
                                const double* a,
                                const LTFAT_REAL* cfreq,
                                const ltfat_int* neigh,
                                const LTFAT_REAL* posInfo,
                                int do_real)
{
    struct LTFAT_NAME(heapinttask_fb)* fbhit = LTFAT_NEW(struct LTFAT_NAME(heapinttask_fb));
        //ltfat_malloc(sizeof * fbhit);
    fbhit->hit = LTFAT_NAME(heapinttask_init)( height, 1, initheapsize, s, do_real);
    fbhit->intfun = LTFAT_NAME(trapezheap_fb);
    fbhit->N = (ltfat_int*) N;
    fbhit->a = (double*) a;
    fbhit->cfreq = (LTFAT_REAL*) cfreq;
    fbhit->neigh = (ltfat_int*) neigh;
    fbhit->posInfo = (LTFAT_REAL*) posInfo;
    return fbhit;
}
/* Execute the Heap Integration */
LTFAT_API
void LTFAT_NAME(heapint_execute_fb)(struct LTFAT_NAME(heapinttask_fb)* fbhit,
                                    const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                                    LTFAT_REAL* phase)
{
    /* Declarations */
    ltfat_int Imax;
    ltfat_int w;
    LTFAT_REAL maxs;
    int* donemask = fbhit->hit->donemask;
    struct LTFAT_NAME(heap)* h = fbhit->hit->heap;
    
    while (1)
    {
        /* Inner loop processing all connected coefficients */
        while ((w = LTFAT_NAME(heap_delete)(h)) >= 0)
        {
            /* Spread the current phase value to 4 direct neighbors */
            (*fbhit->intfun)(fbhit, tgradw, fgradw, w, phase);
        }
        if (!LTFAT_NAME_REAL(findmaxinarraywrtmask)(
                LTFAT_NAME(heap_getdataptr)(h), donemask,
                fbhit->hit->height * fbhit->hit->N, &maxs, &Imax))
            break;
        /* Put maximal element onto the heap and mark that it is done. */
        LTFAT_NAME(heap_insert)(h, Imax);
        donemask[Imax] = 6;
    }
}
/* Trapeziodal rule for general filter banks */
void LTFAT_NAME(trapezheap_fb)(const struct LTFAT_NAME(heapinttask_fb) *fbhit,
                               const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                               const ltfat_int w, LTFAT_REAL* phase)
{
    struct LTFAT_NAME(heapinttask) * hit = fbhit->hit;
    struct LTFAT_NAME(heap)* h = hit->heap;
    int* donemask = hit->donemask;
    ltfat_int w_TMP;
    const ltfat_int* wneigh = fbhit->neigh + 6 * w;
    const LTFAT_REAL* posInfo = fbhit->posInfo;
    double* a = fbhit->a;
    const LTFAT_REAL* cfreq = fbhit->cfreq;
    /* Try and put all neighbors onto the heap, starting with neighbors in
     * the same channel, then next lower channel, finally next higher channel.
     * Integration by trapezoidal rule */
    /* When integrating across frequencies, the difference of the associated
     * center frequencies has to be taken into account*/
    /* Inside the channel */
    ltfat_int wchan = posInfo[2 * w];
    ltfat_int ii = 0;
    for (ii = 0; ii < 2; ++ii )
    {
        w_TMP = wneigh[ii];
        if (w_TMP >= 0 && !donemask[w_TMP])
        {
            phase[w_TMP] = phase[w] + a[wchan] * (w_TMP - w) *
                           (tgradw[w] + tgradw[w_TMP]) / 2;
            donemask[w_TMP] = 3;
            LTFAT_NAME(heap_insert)(h, w_TMP);
        }
    }
    /* Channel below */
    for (ii = 2; ii < 6; ++ii)
    {
        w_TMP = wneigh[ii];
        if (w_TMP >= 0 && !donemask[w_TMP])
        {
            phase[w_TMP] = phase[w] +
                           (posInfo[2 * w_TMP + 1] - posInfo[2 * w + 1] ) * (tgradw[w] + tgradw[w_TMP]) / 2
                           + (cfreq[(ltfat_int)posInfo[2 * w_TMP]] - cfreq[(ltfat_int)posInfo[2 * w]]) *
                           (fgradw[w] + fgradw[w_TMP]) / 2;
            donemask[w_TMP] = 3;
            LTFAT_NAME(heap_insert)(h, w_TMP);
        }
    }
}
/* Conversion of tgrad and fgrad to correct convention and scaling */
void
LTFAT_NAME(gradsamptorad_fb)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                             const LTFAT_REAL* cfreq,
                             const ltfat_int M,
                             const ltfat_int N[], const ltfat_int Nsum,
                             const ltfat_int W,
                             LTFAT_REAL* tgradw, LTFAT_REAL* fgradw)
{
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* tgradchan = tgrad + w * Nsum;
        const LTFAT_REAL* fgradchan = fgrad + w * Nsum;
        LTFAT_REAL* tgradwchan = tgradw + w * Nsum;
        LTFAT_REAL* fgradwchan = fgradw + w * Nsum;
        ltfat_int chanStart = 0;
        for (ltfat_int m = 0; m < M; m++)
        {
            for (ltfat_int n = 0; n < N[m]; n++)
            {                
                /*In contrast to Gabor, tgrad is not in samples, but in ]-1,1]*/
                tgradwchan[n + chanStart] =    (tgradchan[n + chanStart] +
                                                cfreq[m]) * M_PI;
                /*In contrast to Gabor, fgrad has to be weighted by the channel difference
                *DURING the integration. However, cfreq ranges in ]-1,1], so fgrad is
                *only scaled by PI.*/
                fgradwchan[n + chanStart] =  - ( fgradchan[n + chanStart] ) * M_PI;
            }
            chanStart += N[m];
        }
    }
}
/* Interfacing functions for the various cases*/
LTFAT_API
void LTFAT_NAME(filterbankheapint)(const LTFAT_REAL* s,
                            const LTFAT_REAL* tgradw,
                            const LTFAT_REAL* fgradw,
                            const ltfat_int neigh[],
                            const LTFAT_REAL posInfo[],
                            const LTFAT_REAL cfreq[],
                            const double a[], const ltfat_int M, const ltfat_int N[],
                            const ltfat_int Nsum, const ltfat_int W,
                            LTFAT_REAL tol,  LTFAT_REAL* phase)
{
    /* Declarations */
    struct LTFAT_NAME(heapinttask_fb)* fbhit;
    /* Set the phase to zero initially */
    memset(phase, 0, Nsum * W * sizeof * phase);
    // Init plan
    fbhit = LTFAT_NAME(heapinttask_init_fb)( Nsum, M * log((double)M) , s, N, a,
            cfreq, neigh, posInfo, 0);
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * Nsum;
        const LTFAT_REAL* tgradwchan = tgradw + w * Nsum;
        const LTFAT_REAL* fgradwchan = fgradw + w * Nsum;
        LTFAT_REAL* phasechan = phase + w * Nsum;
        LTFAT_NAME(heapinttask_resetmax)(fbhit->hit, schan, tol);
        LTFAT_NAME(heapint_execute_fb)(fbhit, tgradwchan, fgradwchan, phasechan);
    }
    LTFAT_NAME(heapinttask_done)(fbhit->hit);
    ltfat_free(fbhit);
}
LTFAT_API void
LTFAT_NAME(filterbankmaskedheapint)(const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             const int* mask,
                             const ltfat_int neigh[],
                             const LTFAT_REAL posInfo[],
                             const LTFAT_REAL* cfreq,
                             const double* a,
                             const ltfat_int M,
                             const ltfat_int N[], const ltfat_int Nsum,
                             const ltfat_int W,
                             LTFAT_REAL tol,  LTFAT_REAL* phase)
{
    /* Declarations */
    struct LTFAT_NAME(heapinttask_fb)* fbhit;
    // Init plan
    fbhit = LTFAT_NAME(heapinttask_init_fb)( Nsum, M * log((double)M), s, N, a,
            cfreq, neigh, posInfo, 0);
    // Set all phases outside of the mask to zeros, do not modify the rest
    for (ltfat_int ii = 0; ii < W * Nsum; ii++)
        if (!mask[ii])
            phase[ii] = 0;
    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * Nsum;
        const LTFAT_REAL* tgradwchan = tgradw + w * Nsum;
        const LTFAT_REAL* fgradwchan = fgradw + w * Nsum;
        LTFAT_REAL* phasechan = phase + w * Nsum;
        const int* maskchan = mask + w * Nsum;
        LTFAT_NAME(heapinttask_resetmask)(fbhit->hit, maskchan, schan, tol, 0);
        LTFAT_NAME(borderstoheapneighs)(fbhit->hit->heap, Nsum, neigh,
                                        fbhit->hit->donemask);
        LTFAT_NAME(heapint_execute_fb)(fbhit, tgradwchan, fgradwchan, phasechan);
    }
    LTFAT_NAME(heapinttask_done)(fbhit->hit);
    ltfat_free(fbhit);
}
/*
 *  The _relgrad versions are just wrappers.
 *  They convert the relative phase gradients in samples to
 *  absolute phase gradinets in radians.
 * */
LTFAT_API void
LTFAT_NAME(filterbankheapint_relgrad)(const LTFAT_REAL* s,
                               const LTFAT_REAL* tgrad,
                               const LTFAT_REAL* fgrad,
                               const ltfat_int* neigh,
                               const LTFAT_REAL* posInfo,
                               const LTFAT_REAL* cfreq,
                               const double* a, const ltfat_int M,
                               const ltfat_int N[], const ltfat_int Nsum,
                               const ltfat_int W,
                               LTFAT_REAL tol,  LTFAT_REAL* phase)
{
    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(Nsum * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(Nsum * W);
    /* Rescale the derivatives such that they are in radians and the step is 1 in time
     * direction. The step in frequency direction is multiplied by the difference of the center
     * frequencies during integration.*/
    LTFAT_NAME(gradsamptorad_fb)(tgrad, fgrad, cfreq, M, N, Nsum, W,
                                 tgradw, fgradw);
    LTFAT_NAME(filterbankheapint)(s, tgradw, fgradw, neigh, posInfo, cfreq, a, M, N, Nsum,
                           W, tol, phase);
    LTFAT_SAFEFREEALL(tgradw, fgradw);
}
LTFAT_API void
LTFAT_NAME(filterbankmaskedheapint_relgrad)(const LTFAT_REAL* s,
                                     const LTFAT_REAL* tgrad,
                                     const LTFAT_REAL* fgrad,
                                     const int* mask,
                                     const ltfat_int neigh[],
                                     const LTFAT_REAL posInfo[],
                                     const LTFAT_REAL* cfreq,
                                     const double* a,
                                     const ltfat_int M,
                                     const ltfat_int N[], const ltfat_int Nsum,
                                     const ltfat_int W,
                                     LTFAT_REAL tol,  LTFAT_REAL* phase)
{
    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(Nsum * W );
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(Nsum * W );
    /* Rescale the derivatives such that they are in radians and the step is 1 in time
     * direction. The step in frequency direction is multiplied by the difference of the center
     * frequencies during integration.*/
    LTFAT_NAME(gradsamptorad_fb)(tgrad, fgrad, cfreq, M, N, Nsum, W,
                                 tgradw, fgradw);
    LTFAT_NAME(filterbankmaskedheapint)(s, tgradw, fgradw, mask, neigh, posInfo, cfreq, a, M,
                                 N, Nsum, W, tol, phase);
    LTFAT_SAFEFREEALL(tgradw, fgradw);
}

