#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "heapint_private.h"


LTFAT_API LTFAT_NAME(heapinttask)*
LTFAT_NAME(heapinttask_init)(ltfat_int height, ltfat_int N,
                             ltfat_int initheapsize,
                             const LTFAT_REAL* s, int do_real)
{
    LTFAT_NAME(heapinttask)* hit = (LTFAT_NAME(heapinttask)*) ltfat_malloc(
                                       sizeof * hit);
    hit->height = height;
    hit->N = N;
    hit->donemask = (int*) ltfat_malloc(height * N * sizeof * hit->donemask);
    hit->heap = LTFAT_NAME(heap_init)(initheapsize, s);
    hit->do_real = do_real;

    if (do_real)
        hit->intfun = LTFAT_NAME(trapezheapreal);
    else
        hit->intfun = LTFAT_NAME(trapezheap);

    return hit;
}

LTFAT_API void
LTFAT_NAME(heapinttask_done)( LTFAT_NAME(heapinttask)* hit)
{
    if (hit->heap)
        LTFAT_NAME(heap_done)(hit->heap);

    ltfat_free(hit->donemask);
    ltfat_free(hit);
}

LTFAT_API int*
LTFAT_NAME(heapinttask_get_mask)( LTFAT_NAME(heapinttask)* hit)
{
    return hit->donemask;
}


LTFAT_API
void
LTFAT_NAME(heapinttask_resetmax)(LTFAT_NAME(heapinttask)* hit,
                                 const LTFAT_REAL* news,
                                 const LTFAT_REAL tol)
{
    ltfat_int Imax;
    LTFAT_REAL maxs;

    LTFAT_NAME(heap_reset)(hit->heap, news);

    // Find the biggest coefficient
    LTFAT_NAME_REAL(findmaxinarray)(news,  hit->height * hit->N , &maxs, &Imax);

    /* Mark all the small elements as done, they get zero phase.  */
    for (ltfat_int ii = 0; ii < hit->height * hit->N; ii++)
    {
        if (news[ii] <= tol * maxs)
            hit->donemask[ii] = LTFAT_MASK_BELOWTOL;
        else
            hit->donemask[ii] = LTFAT_MASK_UNKNOWN;
    }

    LTFAT_NAME(heap_insert)(hit->heap, Imax);
    hit->donemask[Imax] = LTFAT_MASK_STARTPOINT;
}

LTFAT_API
void
LTFAT_NAME(heapinttask_resetmask)(LTFAT_NAME(heapinttask)* hit,
                                  const int* mask,
                                  const LTFAT_REAL* news,
                                  const LTFAT_REAL tol,
                                  const int do_log)
{
    ltfat_int dummyImax;
    LTFAT_REAL maxs;

    LTFAT_NAME(heap_reset)(hit->heap, news);

    /* Copy known phase */
    for (ltfat_int w = 0; w < hit->height * hit->N; w++)
    {
        if (mask[w] > LTFAT_MASK_UNKNOWN)
            hit->donemask[w] = LTFAT_MASK_KNOWN;
        else
            hit->donemask[w] = LTFAT_MASK_UNKNOWN;
    }

    /* Just find max element */
    LTFAT_NAME_REAL(findmaxinarray)(news, hit->height * hit->N, &maxs, &dummyImax);

    /* Mark all the small elements as done, they get zero phase.
     * (But should get random phase instead)
     */
    if (do_log)
    {
        for (ltfat_int ii = 0; ii < hit->height * hit->N; ii++)
            if (news[ii] <= tol + maxs)
                hit->donemask[ii] = LTFAT_MASK_BELOWTOL;
    }
    else
    {
        for (ltfat_int ii = 0; ii < hit->height * hit->N; ii++)
            if (news[ii] <= tol * maxs)
                hit->donemask[ii] = LTFAT_MASK_BELOWTOL;
    }

    if (hit->do_real)
        LTFAT_NAME(borderstoheapreal)(hit->heap, hit->height, hit->N, hit->donemask);
    else
        LTFAT_NAME(borderstoheap)(hit->heap, hit->height, hit->N, hit->donemask);
}



void LTFAT_NAME(trapezheap)(const LTFAT_NAME(heapinttask) *hit,
                            const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                            ltfat_int w,
                            LTFAT_REAL* phase)
{
    ltfat_int M = hit->height;
    ltfat_int N = hit->N;
    LTFAT_NAME(heap)* h = hit->heap;
    int* donemask = hit->donemask;
    ltfat_int w_E, w_W, w_N, w_S;
    LTFAT_REAL oneover2 = (LTFAT_REAL) (1.0 / 2.0);

    /* Try and put the four neighbours onto the heap.
     * Integration by trapezoidal rule */

    /* North */
    w_N = NORTHFROMW(w, M, N);

    if (!donemask[w_N])
    {
        phase[w_N] = phase[w] + (fgradw[w] + fgradw[w_N]) * oneover2;
        donemask[w_N] = LTFAT_MASK_WENTNORTH;
        LTFAT_NAME(heap_insert)(h, w_N);
    }

    /* South */
    w_S = SOUTHFROMW(w, M, N);

    if (!donemask[w_S])
    {
        phase[w_S] = phase[w] - (fgradw[w] + fgradw[w_S]) * oneover2;
        donemask[w_S] = LTFAT_MASK_WENTSOUTH;
        LTFAT_NAME(heap_insert)(h, w_S);
    }

    /* East */
    w_E = EASTFROMW(w, M, N);

    if (!donemask[w_E])
    {
        phase[w_E] = phase[w] + (tgradw[w] + tgradw[w_E]) * oneover2;
        donemask[w_E] = LTFAT_MASK_WENTEAST;
        LTFAT_NAME(heap_insert)(h, w_E);
    }

    /* West */
    w_W = WESTFROMW(w, M, N);

    if (!donemask[w_W])
    {
        phase[w_W] = phase[w] - (tgradw[w] + tgradw[w_W]) * oneover2;
        donemask[w_W] = LTFAT_MASK_WENTWEST;
        LTFAT_NAME(heap_insert)(h, w_W);
    }
}


void
LTFAT_NAME(gradsamptorad)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                          ltfat_int a, ltfat_int M, ltfat_int L, ltfat_int W,
                          ltfat_phaseconvention phasetype, int do_real,
                          LTFAT_REAL* tgradw, LTFAT_REAL* fgradw)
{
    ltfat_int N = L / a;
    LTFAT_REAL b = ((LTFAT_REAL) L) / M;
    LTFAT_REAL sampToRadConst = (LTFAT_REAL)( 2.0 * M_PI / L);

    ltfat_int height = do_real ? M / 2 + 1 : M;

    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* tgradchan = tgrad + w * height * N;
        const LTFAT_REAL* fgradchan = fgrad + w * height * N;
        LTFAT_REAL* tgradwchan = tgradw + w * height * N;
        LTFAT_REAL* fgradwchan = fgradw + w * height * N;

        for (ltfat_int n = 0; n < N; n++)
        {
            for (ltfat_int m = 0; m < height; m++)
            {
                if (phasetype == LTFAT_FREQINV)
                {
                    tgradwchan[m + n * height] =    a * tgradchan[m + n * height] * sampToRadConst;
                    fgradwchan[m + n * height] =  - b * ( fgradchan[m + n * height] + n * a ) *
                                                  sampToRadConst;
                }
                else if (phasetype == LTFAT_TIMEINV)
                {
                    tgradwchan[m + n * height] =    a * (tgradchan[m + n * height] + m * b) *
                                                    sampToRadConst;
                    fgradwchan[m + n * height] =  - b * ( fgradchan[m + n * height] ) *
                                                  sampToRadConst;
                }
            }
        }
    }
}

LTFAT_API
void LTFAT_NAME(heapint)(const LTFAT_REAL* s,
                         const LTFAT_REAL* tgradw,
                         const LTFAT_REAL* fgradw,
                         ltfat_int a, ltfat_int M,
                         ltfat_int L, ltfat_int W,
                         LTFAT_REAL tol,  LTFAT_REAL* phase)
{
    /* Declarations */
    LTFAT_NAME(heapinttask)* hit;

    // Width of s
    ltfat_int N = L / a;

    /* Set the phase to zero initially */
    memset(phase, 0, M * N * W * sizeof * phase);

    // Init plan
    hit = LTFAT_NAME(heapinttask_init)( M, N, (ltfat_int)( M * log((double)M)) , s,
                                        0);

    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * M * N;
        const LTFAT_REAL* tgradwchan = tgradw + w * M * N;
        const LTFAT_REAL* fgradwchan = fgradw + w * M * N;
        LTFAT_REAL* phasechan = phase + w * M * N;

        LTFAT_NAME(heapinttask_resetmax)(hit, schan, tol);

        LTFAT_NAME(heapint_execute)(hit, schan, tgradwchan, fgradwchan, phasechan);
    }

    LTFAT_NAME(heapinttask_done)(hit);
}

LTFAT_API
void LTFAT_NAME(maskedheapint)(const LTFAT_REAL* s,
                               const LTFAT_REAL* tgradw,
                               const LTFAT_REAL* fgradw,
                               const int* mask,
                               ltfat_int a, ltfat_int M,
                               ltfat_int L, ltfat_int W,
                               LTFAT_REAL tol,
                               LTFAT_REAL* phase)
{
    /* Declarations */
    LTFAT_NAME(heapinttask)* hit;

    ltfat_int N = L / a;

    /* Main body */
    hit = LTFAT_NAME(heapinttask_init)( M, N, (ltfat_int)( M * log((double)M) ), s,
                                        0);

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
        LTFAT_NAME(heapinttask_resetmask)(hit, maskchan, schan, tol, 0);


        LTFAT_NAME(heapint_execute)(hit, schan, tgradwchan, fgradwchan, phasechan);
    }

    LTFAT_NAME(heapinttask_done)(hit);

}

void
LTFAT_NAME(borderstoheap)(LTFAT_NAME(heap)* h,
                          ltfat_int height, ltfat_int N,
                          int* donemask)
{
    for (ltfat_int w = 0; w < height * N ; w++)
    {
        // Is it a coefficient with known phase and is it big enough?
        // 5 is code of coefficients below tol
        if (donemask[w] == LTFAT_MASK_KNOWN)
        {
            // Is it a border coefficient?
            // i.e. is any of the 4 neighbors not reliable?
            if ( !donemask[NORTHFROMW(w, height, N)] ||
                 !donemask[ EASTFROMW(w, height, N)] ||
                 !donemask[SOUTHFROMW(w, height, N)] ||
                 !donemask[ WESTFROMW(w, height, N)] )
            {
                donemask[w] = LTFAT_MASK_BORDERPOINT; // Code of a good border coefficient
                LTFAT_NAME(heap_insert)(h, w);
            }
        }
    }
}



/*
 *  REAL-versions of the previous
 *
 *
 * */
void
LTFAT_NAME(borderstoheapreal)(LTFAT_NAME(heap)* h,
                              ltfat_int height, ltfat_int N,
                              int* donemask)
{

    for (ltfat_int w = 0; w < height * N ; w++)
    {
        // Is it a coefficient with known phase and is it big enough?
        if (donemask[w] == LTFAT_MASK_KNOWN)
        {
            ltfat_int col = w / height;
            ltfat_int row = w % height;

            // Is it a border coefficient?
            // i.e. is any of the 4 neighbors not reliable?
            if ( ( row != height - 1   && !donemask[NORTHFROMW(w, height, N)])  ||
                 ( col != N - 1    && !donemask[ EASTFROMW(w, height, N)])  ||
                 ( row != 0        && !donemask[SOUTHFROMW(w, height, N)])  ||
                 ( col != 0        && !donemask[ WESTFROMW(w, height, N)]) )
            {
                donemask[w] = LTFAT_MASK_BORDERPOINT; // Code of a good border coefficient
                LTFAT_NAME(heap_insert)(h, w);
            }
        }
    }
}

void LTFAT_NAME(trapezheapreal)(const LTFAT_NAME(heapinttask) *hit,
                                const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                                ltfat_int w,
                                LTFAT_REAL* phase)
{
    ltfat_int M2 = hit->height;
    ltfat_int N = hit->N;
    int* donemask = hit->donemask;
    LTFAT_NAME(heap) *h = hit->heap;
    ltfat_int w_E, w_W, w_N, w_S, row, col;

    /* North */
    w_N = NORTHFROMW(w, M2, N);
    /* South */
    w_S = SOUTHFROMW(w, M2, N);
    /* East */
    w_E = EASTFROMW(w, M2, N);
    /* West */
    w_W = WESTFROMW(w, M2, N);

    col = w / M2;
    row = w % M2;

    /* Try and put the four neighbours onto the heap.
     * Integration by trapezoidal rule */

    if (!donemask[w_N] && row != M2 - 1 )
    {
        phase[w_N] = phase[w] + (fgradw[w] + fgradw[w_N]) / 2;
        donemask[w_N] = LTFAT_MASK_WENTNORTH;
        LTFAT_NAME(heap_insert)(h, w_N);
    }

    if (!donemask[w_S] && row != 0)
    {
        phase[w_S] = phase[w] - (fgradw[w] + fgradw[w_S]) / 2;
        donemask[w_S] = LTFAT_MASK_WENTSOUTH;
        LTFAT_NAME(heap_insert)(h, w_S);
    }

    if (!donemask[w_E] && col != N - 1)
    {
        phase[w_E] = phase[w] + (tgradw[w] + tgradw[w_E]) / 2;
        donemask[w_E] = LTFAT_MASK_WENTEAST;
        LTFAT_NAME(heap_insert)(h, w_E);
    }

    if (!donemask[w_W] && col != 0)
    {
        phase[w_W] = phase[w] - (tgradw[w] + tgradw[w_W]) / 2;
        donemask[w_W] = LTFAT_MASK_WENTWEST;
        LTFAT_NAME(heap_insert)(h, w_W);
    }

}

LTFAT_API void
LTFAT_NAME(heapint_execute)( LTFAT_NAME(heapinttask)* hit,
                             const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             LTFAT_REAL* phase)
{
    /* Declarations */
    ltfat_int Imax;
    ltfat_int w;
    LTFAT_REAL maxs;
    int* donemask = hit->donemask;
    LTFAT_NAME(heap)* h = hit->heap;

    while (1)
    {
        /* Inner loop processing all connected coefficients */
        /* Extract largest (first) element from heap and delete it. */
        while ((w = LTFAT_NAME(heap_delete)(h)) >= 0)
        {
            /* Spread the current phase value to 4 direct neighbors */
            (*hit->intfun)(hit, tgradw, fgradw, w, phase);
        }

        if (!LTFAT_NAME_REAL(findmaxinarraywrtmask)(s, donemask,
                hit->height * hit->N, &maxs, &Imax))
            break;

        /* Put maximal element onto the heap and mark that it is done. */
        LTFAT_NAME(heap_insert)(h, Imax);
        donemask[Imax] = LTFAT_MASK_STARTPOINT;
    }
}

/*
 * tgradw and fgradw must be in radians and scaled such that the step is 1
 */
LTFAT_API
void LTFAT_NAME(heapintreal)(const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             ltfat_int a, ltfat_int M,
                             ltfat_int L, ltfat_int W,
                             LTFAT_REAL tol, LTFAT_REAL* phase)
{
    /* Declarations */
    LTFAT_NAME(heapinttask)* hit;

    // Height of s
    ltfat_int M2 = M / 2 + 1;
    // Width of s
    ltfat_int N = L / a;

    /* Set the phase to zero initially */
    memset(phase, 0, M2 * N * W * sizeof * phase);

    // Init plan
    hit = LTFAT_NAME(heapinttask_init)( M2, N, (ltfat_int)( M2 * log((double)M2)),
                                        s,
                                        1);

    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * M2 * N;
        const LTFAT_REAL* tgradwchan = tgradw + w * M2 * N;
        const LTFAT_REAL* fgradwchan = fgradw + w * M2 * N;
        LTFAT_REAL* phasechan = phase + w * M2 * N;

        // empty heap and add max element to it
        LTFAT_NAME(heapinttask_resetmax)(hit, schan, tol);

        LTFAT_NAME(heapint_execute)(hit, schan, tgradwchan, fgradwchan, phasechan);
    }

    LTFAT_NAME(heapinttask_done)(hit);
}

LTFAT_API
void LTFAT_NAME(maskedheapintreal)(const LTFAT_REAL* s,
                                   const LTFAT_REAL* tgradw,
                                   const LTFAT_REAL* fgradw,
                                   const int* mask,
                                   ltfat_int a, ltfat_int M,
                                   ltfat_int L, ltfat_int W,
                                   LTFAT_REAL tol, LTFAT_REAL* phase)
{
    /* Declarations */
    LTFAT_NAME(heapinttask)* hit;

    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;

    // Initialize plan
    hit = LTFAT_NAME(heapinttask_init)( M2, N, (ltfat_int)( M2 * log((double) M2)),
                                        s, 1);

    // Set all phases outside of the mask to zeros, do not modify the rest
    for (ltfat_int ii = 0; ii < M2 * N * W; ii++)
        if (mask[ii] <= LTFAT_MASK_UNKNOWN)
            phase[ii] = 0;

    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_REAL* schan = s + w * M2 * N;
        const LTFAT_REAL* tgradwchan = tgradw + w * M2 * N;
        const LTFAT_REAL* fgradwchan = fgradw + w * M2 * N;
        const int* maskchan = mask + w * M2 * N;
        LTFAT_REAL* phasechan = phase + w * M2 * N;

        // Empty heap and fill it with the border coefficients from the mask
        LTFAT_NAME(heapinttask_resetmask)(hit, maskchan, schan, tol, 0);

        LTFAT_NAME(heapint_execute)(hit, schan, tgradwchan, fgradwchan, phasechan);
    }

    LTFAT_NAME(heapinttask_done)(hit);
}

/*
 *  The _relgrad versions are just wrappers.
 *  They convert the relative phase gradients in samples to
 *  absolute phase gradinets in radians.
 * */
LTFAT_API void
LTFAT_NAME(maskedheapint_relgrad)(const LTFAT_REAL* s,
                                  const LTFAT_REAL* tgrad,
                                  const LTFAT_REAL* fgrad,
                                  const int* mask,
                                  ltfat_int a, ltfat_int M,
                                  ltfat_int L, ltfat_int W,
                                  const LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                                  LTFAT_REAL* phase)
{
    ltfat_int N = L / a;

    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(M * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(M * N * W);

    /* Rescale the derivatives such that they are in radians and the step is 1 in both
     * directions */
    LTFAT_NAME(gradsamptorad)(tgrad, fgrad, a, M, L, W, phasetype, 0, tgradw,
                              fgradw);

    LTFAT_NAME(maskedheapint)(s, tgradw, fgradw, mask, a, M, L, W, tol, phase);

    LTFAT_SAFEFREEALL(tgradw, fgradw);
}

LTFAT_API void
LTFAT_NAME(heapint_relgrad)(const LTFAT_REAL* s,
                            const LTFAT_REAL* tgrad,
                            const LTFAT_REAL* fgrad,
                            ltfat_int a, ltfat_int M,
                            ltfat_int L, ltfat_int W,
                            const LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                            LTFAT_REAL* phase)
{
    ltfat_int N = L / a;

    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(M * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(M * N * W);

    /* Rescale the derivatives such that they are in radians and the step is 1 in both
     * directions */
    LTFAT_NAME(gradsamptorad)(tgrad, fgrad, a, M, L, W, phasetype, 0, tgradw,
                              fgradw);

    LTFAT_NAME(heapint)(s, tgradw, fgradw, a, M, L, W, tol, phase);

    LTFAT_SAFEFREEALL(tgradw, fgradw);
}

LTFAT_API void
LTFAT_NAME(maskedheapintreal_relgrad)(const LTFAT_REAL* s,
                                      const LTFAT_REAL* tgrad,
                                      const LTFAT_REAL* fgrad,
                                      const int* mask,
                                      ltfat_int a, ltfat_int M,
                                      ltfat_int L, ltfat_int W,
                                      LTFAT_REAL tol, ltfat_phaseconvention phasetype, LTFAT_REAL* phase)
{
    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;

    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(M2 * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(M2 * N * W);

    /* Rescale the derivatives such that they are in radians and the step is 1 in both
     * directions */
    LTFAT_NAME(gradsamptorad)(tgrad, fgrad, a, M, L, W, phasetype, 1, tgradw,
                              fgradw);

    LTFAT_NAME(maskedheapintreal)(s, tgradw, fgradw, mask, a, M, L, W, tol, phase);

    LTFAT_SAFEFREEALL(tgradw, fgradw);

}

LTFAT_API
void LTFAT_NAME(heapintreal_relgrad)(const LTFAT_REAL* s,
                                     const LTFAT_REAL* tgrad,
                                     const LTFAT_REAL* fgrad,
                                     ltfat_int a, ltfat_int M,
                                     ltfat_int L, ltfat_int W,
                                     LTFAT_REAL tol, ltfat_phaseconvention phasetype, LTFAT_REAL* phase)
{
    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;

    /* Allocate new arrays, we need to rescale the derivatives */
    LTFAT_REAL* tgradw = LTFAT_NAME_REAL(malloc)(M2 * N * W);
    LTFAT_REAL* fgradw = LTFAT_NAME_REAL(malloc)(M2 * N * W);

    /* Rescale the derivatives such that they are in radians and the step is 1 in both
     * directions */
    LTFAT_NAME(gradsamptorad)(tgrad, fgrad, a, M, L, W, phasetype, 1, tgradw,
                              fgradw);

    LTFAT_NAME(heapintreal)(s, tgradw, fgradw, a, M, L, W, tol, phase);

    LTFAT_SAFEFREEALL(tgradw, fgradw);
}

/* #undef NORTHFROMW */
/* #undef SOUTHFROMW */
/* #undef WESTFROMW */
/* #undef EASTFROMW */
