#include "phaseret/spsi.h"
#include "phaseret/utils.h"
#include "ltfat/macros.h"
#include "float.h"

PHASERET_API int
PHASERET_NAME(spsi)(const LTFAT_REAL* s, ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                    LTFAT_REAL* initphase, LTFAT_COMPLEX* c)
{
    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;
    LTFAT_REAL* tmpphase = initphase;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(s); CHECKNULL(c);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");

    if (!initphase)
        CHECKMEM(tmpphase = LTFAT_NAME_REAL(calloc)(M2 * W));

    if (s == (LTFAT_REAL*)c)
    {
        // Inplace, move the abs. values to the second half of the array
        LTFAT_REAL* chalf = ((LTFAT_REAL*)c) + W * M2 * N;
        memcpy(chalf, s, W * M2 * N * sizeof * chalf);
        s = chalf;
    }

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_REAL* tmpphasecol = tmpphase + w * M2;
        for (ltfat_int n = 0; n < N; n++)
        {
            const LTFAT_REAL* scol = s + n * M2 + w * M2 * N;
            LTFAT_COMPLEX* ccol = c + n * M2 + w * M2 * N;

            PHASERET_NAME(spsiupdate)(scol, 1, a, M, tmpphasecol);

            for (ltfat_int m = 0; m < M2; m++)
                ccol[m] = scol[m] * exp(I * tmpphasecol[m]);
        }
    }

error:
    if (!initphase)
        ltfat_free(tmpphase);
    return status;
}

PHASERET_API int
PHASERET_NAME(spsi_withmask)(const LTFAT_COMPLEX* cinit, const int* mask, ltfat_int L,
                             ltfat_int W, ltfat_int a, ltfat_int M, LTFAT_REAL* initphase, LTFAT_COMPLEX* c)
{
    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;
    LTFAT_REAL* tmpphase = initphase;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(cinit);
    CHECKNULL(mask);
    CHECKNULL(c);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");

    if (!initphase)
        CHECKMEM(tmpphase = LTFAT_NAME_REAL(calloc)(M2 * W));

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_REAL* tmpphasecol = tmpphase + w * M2;
        for (ltfat_int n = 0; n < N; n++)
        {
            LTFAT_COMPLEX* ccol = c + n * M2 + w * M2 * N;
            const LTFAT_COMPLEX* cinitcol = cinit + n * M2 + w * M2 * N;
            const int* maskcol = mask + n * M2 + w * M2 * N;

            PHASERET_NAME(realimag2absangle)(cinitcol, M2, ccol);
            LTFAT_REAL* absptr = (LTFAT_REAL*)ccol;
            LTFAT_REAL* angleptr = ((LTFAT_REAL*)ccol) + 1;

            PHASERET_NAME(spsiupdate)(absptr, 2, a, M, tmpphasecol);

            /* Overwrite with known phase */
            for (ltfat_int m = 0; m < M2; m++)
                if (maskcol[m])
                    tmpphasecol[m] = angleptr[2 * m];

            for (ltfat_int m = 0; m < M2; m++)
                ccol[m] = absptr[2 * m] * exp(I * tmpphasecol[m]);
        }
    }

    if (!initphase)
        ltfat_free(tmpphase);

error:
    return status;
}

void
PHASERET_NAME(spsiupdate)(const LTFAT_REAL* scol, ltfat_int stride, ltfat_int a, ltfat_int M,
                          LTFAT_REAL* tmpphase)
{
    ltfat_int M2 = M / 2 + 1;

    for (ltfat_int m = 1; m < M2 - 1; m++)
    {
        if (scol[stride * m] > scol[stride * (m - 1)]
            && scol[stride * m] > scol[stride * (m + 1)])
        {
            LTFAT_REAL p;
            ltfat_int binup = m, bindown = m;
            LTFAT_REAL alpha = log(scol[stride * (m - 1)] + LTFAT_REAL_MIN);
            LTFAT_REAL beta = log(scol[stride * m] + LTFAT_REAL_MIN);
            LTFAT_REAL gamma = log(scol[stride * (m + 1)] + LTFAT_REAL_MIN);
            LTFAT_REAL denom = alpha - (LTFAT_REAL)(2.0) * beta + gamma;

            if (denom != 0.0)
                p = (LTFAT_REAL)(0.5) * (alpha - gamma) / denom;
            else
                p = 0;

            LTFAT_REAL instf = m + p;
            LTFAT_REAL peakPhase = tmpphase[m] + (LTFAT_REAL)( 2.0 * M_PI * a * instf) / M;
            tmpphase[m] = peakPhase;

            if (p > 0)
            {
                tmpphase[m + 1] = peakPhase;
                binup = m + 2;
                bindown = m - 1;
            }

            if (p < 0)
            {
                tmpphase[m - 1] = peakPhase;
                binup = m + 1;
                bindown = m - 2;
            }

            // Go towards low frequency bins
            ltfat_int bin = bindown;

            while (bin > 0 && scol[stride * bin] < scol[stride * (bin + 1)])
            {
                tmpphase[bin] = peakPhase;
                bin--;
            }

            // Go towards high frequency bins
            bin = binup;

            while (bin < M2 - 1 && scol[stride * bin] < scol[stride * (bin - 1)])
            {
                tmpphase[bin] = peakPhase;
                bin++;
            }
        }
    }
}
