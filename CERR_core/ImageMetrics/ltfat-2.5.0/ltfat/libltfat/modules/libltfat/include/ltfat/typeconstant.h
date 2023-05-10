#ifndef _LTFAT_TYPECONSTANT_H
#define _LTFAT_TYPECONSTANT_H
// #include "ltfat.h"
#include "memalloc.h"
#include "dgt_common.h"
#include "dgtwrapper_typeconstant.h"

typedef struct
{
    ltfat_int quot;
    ltfat_int rem;
} ltfat_div_t;

/* -------- Define routines that do not change between single/double-- */
LTFAT_API ltfat_div_t
ltfat_idiv(ltfat_int a, ltfat_int b);

LTFAT_API ltfat_int
ltfat_idivceil(ltfat_int a, ltfat_int b);

LTFAT_API ltfat_int
ltfat_gcd(ltfat_int a, ltfat_int b, ltfat_int *r, ltfat_int *s );

LTFAT_API void
ltfat_fftindex(ltfat_int N, ltfat_int *indexout);

LTFAT_API
ltfat_int makelarger(ltfat_int L, ltfat_int K);

LTFAT_API
ltfat_int ltfat_imax(ltfat_int a, ltfat_int b);

LTFAT_API
ltfat_int ltfat_imin(ltfat_int a, ltfat_int b);

/** \addtogroup utils
 * @{
 */
/** Find least common multiple of a and b
 */
LTFAT_API
ltfat_int ltfat_lcm(ltfat_int a, ltfat_int b);

/** Find next suitable L for signal length Ls and Gabor lattice parameters a and M
 */
LTFAT_API ltfat_int
ltfat_dgtlength(ltfat_int Ls, ltfat_int a, ltfat_int M);
/** @}*/

LTFAT_API ltfat_int
ltfat_pow2base(ltfat_int x);

LTFAT_API int
ltfat_ispow2(ltfat_int x);

LTFAT_API ltfat_int
ltfat_dgtlengthmulti(ltfat_int Ls, ltfat_int P, ltfat_int a[], ltfat_int M[]);

LTFAT_API
void gabimagepars(ltfat_int Ls, ltfat_int x, ltfat_int y,
                  ltfat_int *a, ltfat_int *M, ltfat_int *L, ltfat_int *N, ltfat_int *Ngood);

LTFAT_API
ltfat_int wfacreal_size(ltfat_int L, ltfat_int a, ltfat_int M);

LTFAT_API ltfat_int
ltfat_nextfastfft(ltfat_int x);

LTFAT_API ltfat_int
ltfat_pow2(ltfat_int x);

LTFAT_API ltfat_int
ltfat_nextpow2(ltfat_int x);

LTFAT_API ltfat_int
ltfat_modpow2(ltfat_int x, ltfat_int pow2var);

LTFAT_API ltfat_int
ltfat_round(const double x);

LTFAT_API ltfat_int
ltfat_positiverem(ltfat_int a, ltfat_int b);


LTFAT_API ltfat_int
ltfat_posnumfastmod(ltfat_int a, ltfat_int b);

LTFAT_API ltfat_int
ltfat_rangelimit(ltfat_int a, ltfat_int amin, ltfat_int amax);

// Custom headers are down here
#include "reassign_typeconstant.h"

#endif /* _LTFAT_TYPECONSTANT */
