#include "phaseret/utils.h"

int
PHASERET_NAME(shiftcolsleft)(LTFAT_REAL* cols, ltfat_int height, ltfat_int N,
                             const LTFAT_REAL* newcol)
{
    for (ltfat_int n = 0; n < N - 1; n++)
        memcpy(cols + n * height, cols + (n + 1)*height, height * sizeof * cols);

    if (newcol)
        memcpy(cols + (N - 1)*height, newcol, height * sizeof * cols);
    else
        memset(cols + (N - 1)*height, 0, height * sizeof * cols);

    return 0;
}

int
PHASERET_NAME_COMPLEX(shiftcolsleft)(LTFAT_COMPLEX cols[], ltfat_int height,
                                     ltfat_int N, const LTFAT_COMPLEX newcol[])
{
    for (ltfat_int n = 0; n < N - 1; n++)
        memcpy(cols + n * height, cols + (n + 1)*height, height * sizeof * cols);

    if (newcol)
        memcpy(cols + (N - 1)*height, newcol, height * sizeof * cols);
    else
        memset(cols + (N - 1)*height, 0, height * sizeof * cols);

    return 0;
}

int
PHASERET_NAME(force_magnitude)(LTFAT_COMPLEX* cin, const LTFAT_REAL* s,
                               ltfat_int L, LTFAT_COMPLEX* cout)
{
    LTFAT_REAL maglim = (LTFAT_REAL) 1e-10;

    for (ltfat_int m = 0; m < L; m++)
    {
        LTFAT_REAL olds = ltfat_abs(cin[m]);
        if (olds < maglim)
            cout[m] = s[m];
        else
            cout[m] = s[m] * cin[m] / olds;
    }

    /* The following is much slower, most probably because of ltfat_arg */
    /* for (ltfat_int ii = 0; ii < L; ii++) */
    /*     cout[ii] = s[ii] * exp(I * ltfat_arg(cin[ii])); */

    return 0;
}


void
PHASERET_NAME(realimag2absangle)(const LTFAT_COMPLEX* cin, ltfat_int L,
                                 LTFAT_COMPLEX* c)
{
    LTFAT_REAL* cplain = (LTFAT_REAL*) c;

    for (ltfat_int l = 0; l < L; l++)
    {
        LTFAT_COMPLEX cel = cin[l];
        cplain[2 * l] = ltfat_abs(cel);
        cplain[2 * l + 1] = ltfat_arg(cel);
    }
}

void
PHASERET_NAME(absangle2realimag)(const LTFAT_COMPLEX* cin, ltfat_int L,
                                 LTFAT_COMPLEX* c)
{
    LTFAT_REAL* cinplain = (LTFAT_REAL*) cin;

    for (ltfat_int l = 0; l < L; l++)
    {
        LTFAT_REAL absval = cinplain[2 * l];
        LTFAT_REAL phaseval = cinplain[2 * l + 1];
        c[l] = absval * exp(I * phaseval);
    }
}


PHASERET_API void
PHASERET_NAME(absangle2realimag_split2inter)(const LTFAT_REAL* s,
        const LTFAT_REAL* phase, ltfat_int L,
        LTFAT_COMPLEX* c)
{
    for (ltfat_int l = 0; l < L; l++)
    {
        LTFAT_REAL absval = s[l];
        LTFAT_REAL phaseval = phase[l];
        c[l] = absval * exp(I * phaseval);
    }
}
