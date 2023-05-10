#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"



LTFAT_API void
LTFAT_NAME(filterbankphasegrad)(const LTFAT_COMPLEX* c [],
                                const LTFAT_COMPLEX* ch[],
                                const LTFAT_COMPLEX* cd[],
                                ltfat_int          M,
                                ltfat_int        N[],
                                ltfat_int          L,
                                const LTFAT_REAL   minlvl,
                                LTFAT_REAL*        tgrad[],
                                LTFAT_REAL*        fgrad[],
                                LTFAT_REAL*           cs[])
{
#define FOREACHCOEF \
    for(ltfat_int m=0;m<M;++m){\
        for(ltfat_int ii=0;ii<N[m];++ii){

#define ARRAYEL(c) ((c)[m][ii])
#define ENDFOREACHCOEF }}

    LTFAT_REAL minlvlAlt = ltfat_abs(c[0][0]);

// Compute spectrogram from coefficients
// Keep max value
    FOREACHCOEF
    LTFAT_REAL en = ltfat_abs(ARRAYEL(c)) * ltfat_abs(ARRAYEL( c));
    ARRAYEL(cs) = en;
    if (en > minlvlAlt)
        minlvlAlt = en;
    ENDFOREACHCOEF

// Adjust minlvl
    minlvlAlt *= minlvl;

// Force spectrogram values less tha minLvlAlt to minlvlAlt
    FOREACHCOEF
    LTFAT_REAL csEl = ARRAYEL(cs);
    if (csEl < minlvlAlt)
        ARRAYEL(cs) = minlvlAlt;
    ENDFOREACHCOEF

// Instantaneous frequency
    FOREACHCOEF
    LTFAT_REAL tgradEl = ltfat_real( ARRAYEL(cd) * conj(ARRAYEL(c)) / ARRAYEL(cs)
                                   ) / L * 2;
    ARRAYEL(tgrad) = fabs(tgradEl) <= 2 ? tgradEl : 0.0f;
    ENDFOREACHCOEF


    FOREACHCOEF
    ARRAYEL(fgrad) = ltfat_imag( ARRAYEL(ch) * conj(ARRAYEL(c)) / ARRAYEL(cs));
    ENDFOREACHCOEF

#undef FOREACHCOEF
#undef ENDFOREACHCOEF
#undef ARRAYEL
}
