#ifndef KISS_FFT_H
#define KISS_FFT_H

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

#include "ltfat/types.h"
#include "ltfat/memalloc.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef USE_SIMD
# include <xmmintrin.h>
# define kiss_fft_scalar __m128
// #define KISS_FFT_MALLOC(nbytes) _mm_malloc(nbytes,16)
// #define KISS_FFT_FREE _mm_free
// #else
#endif

#define KISS_FFT_MALLOC ltfat_malloc
#define KISS_FFT_FREE ltfat_free

#ifdef FIXED_POINT
#include <sys/types.h>
# if (FIXED_POINT == 32)
#  define kiss_fft_scalar int32_t
# else
#  define kiss_fft_scalar int16_t
# endif
#else
# ifndef kiss_fft_scalar
/*  default is float */
#   define kiss_fft_scalar LTFAT_REAL
# endif
#endif

typedef struct
{
    kiss_fft_scalar r;
    kiss_fft_scalar i;
} kiss_fft_cpx;

typedef struct LTFAT_KISS(fft_plan) LTFAT_KISS(fft_plan);

/*
 *  kiss_fft_alloc
 *
 *  Initialize a FFT (or IFFT) algorithm's cfg/state buffer.
 *
 *  typical usage:      kiss_fft_plan mycfg=kiss_fft_alloc(1024,0,NULL,NULL);
 *
 *  The return value from fft_alloc is a cfg buffer used internally
 *  by the fft routine or NULL.
 *
 *  If lenmem is NULL, then kiss_fft_alloc will allocate a cfg buffer using malloc.
 *  The returned value should be free()d when done to avoid memory leaks.
 *
 *  The state can be placed in a user supplied buffer 'mem':
 *  If lenmem is not NULL and mem is not NULL and *lenmem is large enough,
 *      then the function places the cfg in mem and the size used in *lenmem
 *      and returns mem.
 *
 *  If lenmem is not NULL and ( mem is NULL or *lenmem is not large enough),
 *      then the function returns NULL and places the minimum cfg
 *      buffer size in *lenmem.
 * */

LTFAT_KISS(fft_plan)*
LTFAT_KISS(fft_alloc)(int nfft, int inverse_fft, void * mem, size_t * lenmem);

/*
 * kiss_fft(cfg,in_out_buf)
 *
 * Perform an FFT on a complex input buffer.
 * for a forward FFT,
 * fin should be  f[0] , f[1] , ... ,f[nfft-1]
 * fout will be   F[0] , F[1] , ... ,F[nfft-1]
 * Note that each element is complex and can be accessed like
    f[k].r and f[k].i
 * */
void
LTFAT_KISS(fft)(LTFAT_KISS(fft_plan)* cfg, const kiss_fft_cpx *fin, kiss_fft_cpx *fout);

/*
 A more generic version of the above function. It reads its input from every Nth sample.
 * */
void
LTFAT_KISS(fft_stride)(LTFAT_KISS(fft_plan)* cfg, const kiss_fft_cpx *fin, kiss_fft_cpx *fout, int fin_stride);

/* If kiss_fft_alloc allocated a buffer, it is one contiguous
   buffer and can be simply free()d when no longer needed*/

/*
 Real optimized version can save about 45% cpu time vs. complex fft of a real seq.
 */

typedef struct LTFAT_KISS(fftr_plan) LTFAT_KISS(fftr_plan);


LTFAT_KISS(fftr_plan)*
LTFAT_KISS(fftr_alloc)(int nfft, int inverse_fft, void * mem, size_t * lenmem);
/*
 nfft must be even

 If you don't care to allocate space, use mem = lenmem = NULL
*/


void
LTFAT_KISS(fftr)(LTFAT_KISS(fftr_plan)* cfg, const kiss_fft_scalar *timedata, kiss_fft_cpx *freqdata);
/*
 input timedata has nfft scalar points
 output freqdata has nfft/2+1 complex points
*/

void
LTFAT_KISS(fftri)(LTFAT_KISS(fftr_plan)* cfg, const kiss_fft_cpx *freqdata, kiss_fft_scalar *timedata);
/*
 input freqdata has  nfft/2+1 complex points
 output timedata has nfft scalar points
*/

/*
 * Returns the smallest integer k, such that k>=n and k has only "fast" factors (2,3,5)
 */
//int kiss_fft_next_fast_size(int n);

/* for real ffts, we need an even size */
/* #define kiss_fftr_next_fast_size_real(n) \
         (kiss_fft_next_fast_size( ((n)+1)>>1)<<1)*/

#ifdef __cplusplus
}
#endif

#endif
