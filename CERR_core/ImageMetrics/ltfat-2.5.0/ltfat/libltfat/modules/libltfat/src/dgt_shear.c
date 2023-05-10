#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

// long is only "at least 32 bit"
static inline long long ltfat_positiverem_long(long long a, long long b)
{
    const long long c = a % b;
    return (c < 0 ? c + b : c);
}


LTFAT_API void
LTFAT_NAME(pchirp)(const long long L, const long long n, LTFAT_COMPLEX* g)
{

    const long long LL = 2 * L;
    const long long Lponen = ltfat_positiverem_long((L + 1) * n, LL);

    for (long long m = 0; m < L; m++)
    {
        const long long idx = ltfat_positiverem_long(
                                  ltfat_positiverem_long(Lponen * m, LL) * m, LL);

        g[m] = exp(I * (LTFAT_REAL) M_PI * (LTFAT_REAL)idx / ((LTFAT_REAL) L));
    }


    /* const LTFAT_REAL LL=2.0*L; */
    /* const LTFAT_REAL Lpone=L+1; */

    /* for (ltfat_int m=0;m<L;m++) */
    /* { */
    /*    //g[m] = cexp(I*M_PI*fmod(Lpone*n*m*m,LL)/L); */
    /*    g[m] = cexp(I*M_PI*fmod(fmod(fmod(Lpone*n,LL)*m,LL)*m,LL)/L); */
    /* } */

}


LTFAT_API LTFAT_NAME(dgt_shear_plan)
LTFAT_NAME(dgt_shear_init)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                           ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                           ltfat_int s0, ltfat_int s1, ltfat_int br,
                           LTFAT_COMPLEX* cout,
                           unsigned flags)
{
    LTFAT_NAME(dgt_shear_plan) plan;

    plan.a = a;
    plan.M = M;
    plan.L = L;
    plan.W = W;

    plan.s0 = s0;
    plan.s1 = s1;
    plan.br = br;

    ltfat_int b = L / M;
    ltfat_int N = L / a;

    ltfat_int ar = a * b / br;
    ltfat_int Mr = L / br;
    ltfat_int Nr = L / ar;

    plan.f     = (LTFAT_COMPLEX*)f;
    plan.fwork = (LTFAT_COMPLEX*)f;
    plan.gwork = (LTFAT_COMPLEX*)g;
    plan.cout  = cout;

    plan.c_rect = LTFAT_NAME_COMPLEX(malloc)(M * N * W);

    LTFAT_COMPLEX* f_before_fft = (LTFAT_COMPLEX*)f;
    LTFAT_COMPLEX* g_before_fft = (LTFAT_COMPLEX*)g;

    if ((s0 != 0) || (s1 != 0))
    {
        plan.fwork = LTFAT_NAME_COMPLEX(malloc)(L * W);
        plan.gwork = LTFAT_NAME_COMPLEX(malloc)(L);
    }


    if (s1)
    {
        plan.p1 = LTFAT_NAME_COMPLEX(malloc)(L);

        LTFAT_NAME(pchirp)(L, s1, plan.p1);

        for (ltfat_int l = 0; l < L; l++)
        {
            plan.gwork[l] = g[l] * plan.p1[l];
        }

        f_before_fft = plan.fwork;
        g_before_fft = plan.gwork;

    }

    if (s0 == 0)
    {

        /* Call the rectangular computation in the time domain */
        /* LTFAT_NAME(dgt_long)(plan.fwork,plan.gwork,L,W,ar,Mr,plan.c_rect); */

        /* plan.rect_plan = LTFAT_NAME(dgt_long_init)(plan.fwork, plan.gwork, */
        /*                  L, W, ar, Mr, plan.c_rect, 0, flags); */
        LTFAT_NAME_COMPLEX(dgt_long_init)( plan.gwork,
                                           L, W, ar, Mr, plan.fwork, plan.c_rect, LTFAT_FREQINV, flags, &plan.rect_plan);
    }
    else
    {

        /* Allocate memory and compute the pchirp */
        plan.p0 = LTFAT_NAME_COMPLEX(malloc)(L);
        LTFAT_NAME(pchirp)(L, -s0, plan.p0);

        /* if data has already been copied to the working arrays, use
         * inline FFTs. Otherwise, if this is the first time they are
         * being used, do the copying using the fft. */

        // Downcasting to int
        /* int Lint = (int) L; */
        /* plan.f_plan = LTFAT_FFTW(plan_many_dft)(1, &Lint, (int)W, */
        /*                                         (LTFAT_FFTW(complex)*)f_before_fft, NULL, 1, Lint, */
        /*                                         (LTFAT_FFTW(complex)*)plan.fwork, NULL, 1, Lint, */
        /*                                         FFTW_FORWARD, flags); */
        /*  */
        /* plan.g_plan = LTFAT_FFTW(plan_dft_1d)(Lint, (LTFAT_FFTW(complex)*)g_before_fft, */
        /*                                       (LTFAT_FFTW(complex)*)plan.gwork, FFTW_FORWARD, */
        /*                                       flags); */
        /* #<{(| Execute the FFTs |)}># */
        /* LTFAT_FFTW(execute)(plan.g_plan); */
        LTFAT_NAME_REAL(fft_init)(L, W, f_before_fft, plan.fwork, flags, &plan.f_plan );
        LTFAT_NAME_REAL(fft_init)(L, 1, g_before_fft, plan.gwork, flags, &plan.g_plan );
        LTFAT_NAME_REAL(fft_execute)( plan.g_plan);

        /* Multiply g by the chirp and scale by 1/L */
        for (ltfat_int l = 0; l < L; l++)
        {
            plan.gwork[l] = plan.gwork[l] * plan.p0[l] / ((LTFAT_REAL) L);
        }

        /* Call the rectangular computation in the frequency domain*/
        /* LTFAT_NAME(dgt_long)(plan.fwork,plan.gwork,L,W,br,Nr,plan.c_rect); */
        /* Call the rectangular computation in the frequency domain*/
        /* plan.rect_plan = LTFAT_NAME(dgt_long_init)(plan.fwork, plan.gwork, L, W, */
        /*                  br, Nr, plan.c_rect, 0, flags); */
        LTFAT_NAME_COMPLEX(dgt_long_init)( plan.gwork, L, W,
                                           br, Nr, plan.fwork, plan.c_rect, LTFAT_FREQINV, flags, &plan.rect_plan);

    }

    plan.finalmod = LTFAT_NAME_COMPLEX(malloc)(2 * N);

    for (ltfat_int n = 0; n < 2 * N; n++)
    {
        plan.finalmod[n] = exp(I * (LTFAT_REAL) M_PI * (LTFAT_REAL)n / ((
                                   LTFAT_REAL) N));
    }

    return plan;

}

LTFAT_API void
LTFAT_NAME(dgt_shear_execute)(const LTFAT_NAME(dgt_shear_plan) plan)
{

    ltfat_int a = plan.a;
    ltfat_int M = plan.M;
    ltfat_int L = plan.L;

    ltfat_int b = plan.L / plan.M;
    ltfat_int N = plan.L / plan.a;
    const long long s0 = plan.s0;
    const long long s1 = plan.s1;

    ltfat_int ar = plan.a * b / plan.br;
    ltfat_int Mr = plan.L / plan.br;
    ltfat_int Nr = plan.L / ar;


    if (s1)
    {
        for (ltfat_int w = 0; w < plan.W; w++)
        {
            for (ltfat_int l = 0; l < plan.L; l++)
            {
                plan.fwork[l + w * plan.L] = plan.f[l + w * plan.L] * plan.p1[l];
            }
        }

    }


    if (s0 == 0)
    {

        ltfat_int twoN = 2 * N;

        /* In this case, cc1=1 */

        const long long cc3 = ltfat_positiverem_long(s1 * (L + 1), twoN);

        const long long tmp1 = ltfat_positiverem_long(cc3 * a, twoN);

        LTFAT_NAME_COMPLEX(dgt_long_execute)(plan.rect_plan);

        for (ltfat_int k = 0; k < N; k++)
        {
            long long phsidx = ltfat_positiverem_long((tmp1 * k) % twoN * k, twoN);
            const long long part1 = ltfat_positiverem_long(-s1 * k * a, L);
            for (ltfat_int m = 0; m < M; m++)
            {
                /* The line below has a hidden floor operation when dividing with the last b */
                ltfat_int idx2 = ((part1 + b * m) % L) / b;

                ltfat_int inidx  =    m + k * M;
                ltfat_int outidx = idx2 + k * M;
                for (ltfat_int w = 0; w < plan.W; w++)
                {
                    plan.cout[outidx + w * M * N] = plan.c_rect[inidx + w * M * N] *
                                                    plan.finalmod[phsidx];
                }
            }
        }


    }
    else
    {

        ltfat_int twoN = 2 * N;
        const long long cc1 = ar / a;
        const long long cc2 = ltfat_positiverem_long(-s0 * plan.br / a, twoN);
        const long long cc3 = ltfat_positiverem_long(a * s1 * (L + 1), twoN);
        const long long cc4 = ltfat_positiverem_long(cc2 * plan.br * (L + 1), twoN);
        const long long cc5 = ltfat_positiverem_long(2 * cc1 * plan.br, twoN);
        const long long cc6 = ltfat_positiverem_long((s0 * s1 + 1) * plan.br, L);

        // LTFAT_FFTW(execute)(plan.f_plan);
        LTFAT_NAME_REAL(fft_execute)(plan.f_plan);

        for (ltfat_int w = 0; w < plan.W; w++)
        {
            for (ltfat_int l = 0; l < plan.L; l++)
            {

                plan.fwork[l + w * plan.L] = plan.fwork[l + w * plan.L] * plan.p0[l];
            }
        }

        LTFAT_NAME_COMPLEX(dgt_long_execute)(plan.rect_plan);

        for (ltfat_int k = 0; k < Nr; k++)
        {
            const long long part1 = ltfat_positiverem_long(-s1 * k * ar, L);
            for (ltfat_int m = 0; m < Mr; m++)
            {
                const long long sq1 = k * cc1 + cc2 * m;

                long long phsidx = ltfat_positiverem_long(
                                       (cc3 * sq1 * sq1) % twoN - (m * (cc4 * m + k * cc5)) % twoN, twoN);

                /* The line below has a hidden floor operation when dividing with the last b */
                ltfat_int idx2 = ((part1 + cc6 * m) % L) / b;

                ltfat_int inidx  = ltfat_positiverem(-k, Nr) + m * Nr;
                ltfat_int outidx = idx2 + (sq1 % N) * M;
                for (ltfat_int w = 0; w < plan.W; w++)
                {
                    plan.cout[outidx + w * M * N] = plan.c_rect[inidx + w * M * N] *
                                                    plan.finalmod[phsidx];

                }
            }
        }

    }
}


LTFAT_API void
LTFAT_NAME(dgt_shear_done)(LTFAT_NAME(dgt_shear_plan) plan)
{
    LTFAT_NAME_COMPLEX(dgt_long_done)(&plan.rect_plan);
    LTFAT_NAME_REAL(fft_done)(&plan.f_plan);
    LTFAT_NAME_REAL(fft_done)(&plan.g_plan);
    LTFAT_SAFEFREEALL(plan.finalmod, plan.c_rect, plan.fwork, plan.gwork, plan.p0,
                      plan.p1);
}


LTFAT_API void
LTFAT_NAME(dgt_shear)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                      ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                      ltfat_int s0, ltfat_int s1, ltfat_int br,
                      LTFAT_COMPLEX* cout)
{

    LTFAT_NAME(dgt_shear_plan) plan = LTFAT_NAME(dgt_shear_init)(
                                          f, g, L, W, a, M, s0, s1, br, cout, FFTW_ESTIMATE);

    LTFAT_NAME(dgt_shear_execute)(plan);

    LTFAT_NAME(dgt_shear_done)(plan);

}
