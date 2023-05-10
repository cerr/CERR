#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

LTFAT_API void
LTFAT_NAME(fbmagphasegrad)(const LTFAT_REAL logs[], const LTFAT_REAL sqtfr[],
                           const ltfat_int N[], const double a[], const double fc[], ltfat_int M,
                           const ltfat_int neigh[], const double posInfo[], LTFAT_REAL gderivweight,
                           int do_tfrdiff, LTFAT_REAL tgrad[], LTFAT_REAL fgrad[])
{
    LTFAT_REAL L = a[0] * N[0];
    ltfat_int chStart = 0;
    for (ltfat_int m = 0; m < M; m++)
    {
        const LTFAT_REAL* logsCol = logs + chStart;
        LTFAT_REAL* fgradCol = fgrad + chStart;
        for (ltfat_int n = 1; n < N[m] - 1; n++)
        {
            fgradCol[n] = (logsCol[n + 1] - logsCol[n - 1]) / 2.0;
        }
        fgradCol[0]        = (logsCol[1] - logsCol[N[m] - 1]) / 2.0;
        fgradCol[N[m] - 1] = (logsCol[0] - logsCol[N[m] - 2]) / 2.0;
        chStart += N[m];
    }
    chStart = 0;
    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_REAL* tgradCol = tgrad + chStart;
        //LTFAT_REAL* fgradCol = fgrad + chStart;
        LTFAT_REAL aboveNom = 0, aboveDenom = 1, belowNom = 0, belowDenom = 1;
        LTFAT_REAL denom = sqtfr[m] * sqtfr[m] * (M_PI * L);
        if (m < M - 1)
        {
            if (do_tfrdiff)
                aboveNom = gderivweight * (sqtfr[m + 1] - sqtfr[m]) / sqtfr[m];
            aboveDenom = fc[m + 1] - fc[m];
        }
        if ( m > 0)
        {
            if (do_tfrdiff)
                belowNom = gderivweight * (sqtfr[m] - sqtfr[m - 1]) / sqtfr[m];
            belowDenom = fc[m] - fc[m - 1];
        }
        for (ltfat_int n = 0; n < N[m]; n++)
        {
            ltfat_int w = chStart + n;
            const ltfat_int* neighCol = neigh + 6*w;
            LTFAT_REAL tempValAbove = 0;
            LTFAT_REAL tempValBelow = 0;
            int numNeigh = 0;
            for (int jj = 0; jj < 2; jj++)
            {
                ltfat_int oneneigh = neighCol[4 + jj];
                if (oneneigh >= 0)
                {
                    tempValAbove += logs[oneneigh] - logs[w] -
                                    fgrad[w] * (posInfo[oneneigh * 2 + 1] - posInfo[w * 2 + 1]) / a[m];
                    numNeigh++;
                }
            }
            if (numNeigh)
                tempValAbove /= (LTFAT_REAL) numNeigh;
            numNeigh = 0;
            for (int jj = 0; jj < 2; jj++)
            {
                ltfat_int oneneigh = neighCol[2 + jj];
                if (oneneigh >= 0)
                {
                    tempValBelow += logs[w] - logs[oneneigh] -
                                    fgrad[w] * (posInfo[oneneigh * 2 + 1] - posInfo[w * 2 + 1]) / a[m];
                    numNeigh++;
                }
            }
            if (numNeigh)
                tempValBelow /= (LTFAT_REAL) numNeigh;
            tgradCol[n] = (tempValAbove + aboveNom) / aboveDenom +
                          (tempValBelow + belowNom) / belowDenom;
            tgradCol[n] /= denom;
        }
        chStart += N[m];
    }
    // And adjust fgrad
    chStart = 0;
    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_REAL* fgradCol = fgrad + chStart;
        LTFAT_REAL fac = sqtfr[m] * sqtfr[m] * N[m] / (2.0 * M_PI);
        for (ltfat_int n = 0; n < N[m]; n++)
            fgradCol[n] *= fac;
        chStart += N[m];
    }
}



