#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

/**
* FFT filterbank routines
*/

struct LTFAT_NAME(convsub_fft_plan_struct)
{
    ltfat_int L;
    ltfat_int W;
    ltfat_int a;
    /* LTFAT_FFTW(plan) p_c; */
    LTFAT_NAME_REAL(ifft_plan)* p_c;
} ;

struct LTFAT_NAME(convsub_fftbl_plan_struct)
{
    ltfat_int L;
    ltfat_int Gl;
    ltfat_int W;
    double a;
    /* LTFAT_FFTW(plan) p_c; */
    LTFAT_NAME_REAL(ifft_plan)* p_c;
    LTFAT_COMPLEX* buf;
    ltfat_int bufLen;
};

LTFAT_API void
LTFAT_NAME(filterbank_fft)(const LTFAT_COMPLEX* F, const LTFAT_COMPLEX* G[],
                           ltfat_int L, ltfat_int W, ltfat_int a[], ltfat_int M,
                           LTFAT_COMPLEX* cout[])
{
    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(convsub_fft)(F, G[m], L, W, a[m], cout[m]);
    }
}


LTFAT_API void
LTFAT_NAME(filterbank_fft_execute)(LTFAT_NAME(convsub_fft_plan) p[],
                                   const LTFAT_COMPLEX* F, const LTFAT_COMPLEX* G[],
                                   ltfat_int M, LTFAT_COMPLEX* cout[])
{

    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(convsub_fft_execute)(p[m], F, G[m], cout[m]);
    }
}


LTFAT_API LTFAT_NAME(convsub_fft_plan)
LTFAT_NAME(convsub_fft_init)(ltfat_int L, ltfat_int W,
                             ltfat_int a, LTFAT_COMPLEX* cout)
{
    ltfat_int N = L / a;

    /* LTFAT_FFTW(complex)* coutNc = (LTFAT_FFTW(complex)*) cout; */
    /* LTFAT_FFTW(iodim64) dims; */
    /* dims.n = N; dims.is = 1; dims.os = 1; */
    /* LTFAT_FFTW(iodim64) howmany_dims; */
    /* howmany_dims.n = W; howmany_dims.is = N; howmany_dims.os = N; */
    /*  */
    /* LTFAT_FFTW(plan) p_many = */
    /*     LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims, */
    /*                                 coutNc, coutNc, */
    /*                                 FFTW_BACKWARD, FFTW_ESTIMATE); */
    LTFAT_NAME_REAL(ifft_plan)* p_many;
    LTFAT_NAME_REAL(ifft_init)(N, W, cout, cout, FFTW_ESTIMATE, &p_many);

    /* LTFAT_NAME(convsub_fft_plan_struct) p_struct; */
    /* p_struct.L = L; p_struct.a = a; p_struct.W = W; p_struct.p_c = p_many; */

    LTFAT_NAME(convsub_fft_plan) p =
        (LTFAT_NAME(convsub_fft_plan))ltfat_malloc(sizeof * p);
    p->L = L; p->a = a; p->W = W; p->p_c = p_many;
    /* memcpy(p, &p_struct, sizeof * p); */
    return p;
}

LTFAT_API void
LTFAT_NAME(convsub_fft_done)(LTFAT_NAME(convsub_fft_plan) p)
{
    /* LTFAT_FFTW(destroy_plan)(p->p_c); */
    LTFAT_NAME_REAL(ifft_done)(&p->p_c);
    ltfat_free(p);
}

LTFAT_API void
LTFAT_NAME(convsub_fft_execute)(const LTFAT_NAME(convsub_fft_plan) p,
                                const LTFAT_COMPLEX* F, const LTFAT_COMPLEX* G,
                                LTFAT_COMPLEX* cout)
{
    ltfat_int L = p->L;
    ltfat_int W = p->W;
    ltfat_int a = p->a;
    ltfat_int N = L / a;
    const LTFAT_REAL scalconst = (LTFAT_REAL) (1.0 / L);

    LTFAT_NAME_COMPLEX(clear_array)(cout, W * N);

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_COMPLEX* GPtrTmp = (LTFAT_COMPLEX*) G;
        LTFAT_COMPLEX* FPtrTmp = (LTFAT_COMPLEX*) (F + w * L);
        for (ltfat_int jj = 0; jj < a; jj++)
        {
            for (ltfat_int n = 0; n < N; n++)
            {
                cout[w * N + n] += *GPtrTmp++** FPtrTmp++;
            }
        }
    }

    for (ltfat_int ii = 0; ii < N * W; ii++)
    {
        cout[ii] *= scalconst;
    }

    /* LTFAT_FFTW(execute_dft)(p->p_c, (LTFAT_FFTW(complex)*)cout, */
    /*                         (LTFAT_FFTW(complex)*)cout); */
    LTFAT_NAME_REAL(ifft_execute_newarray)(p->p_c, cout, cout);

}

LTFAT_API void
LTFAT_NAME(convsub_fft)(const LTFAT_COMPLEX* F, const LTFAT_COMPLEX* G,
                        ltfat_int L, ltfat_int W,
                        ltfat_int a, LTFAT_COMPLEX* cout)
{
    LTFAT_NAME(convsub_fft_plan) p = LTFAT_NAME(convsub_fft_init)(L, W, a, cout);
    LTFAT_NAME(convsub_fft_execute)(p, F, G, cout);
    LTFAT_NAME(convsub_fft_done)(p);
}

LTFAT_API void
LTFAT_NAME(filterbank_fftbl)(const LTFAT_COMPLEX* F, const LTFAT_COMPLEX* G[],
                             ltfat_int L, ltfat_int Gl[],
                             ltfat_int W, const double a[], ltfat_int M,
                             ltfat_int foff[], const int realonly[],
                             LTFAT_COMPLEX* cout[])
{
    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(convsub_fftbl)(F, G[m], L, Gl[m], W, a[m],
                                  foff[m], realonly[m], cout[m]);
    }
}

LTFAT_API void
LTFAT_NAME(filterbank_fftbl_execute)(LTFAT_NAME(convsub_fftbl_plan) p[],
                                     const LTFAT_COMPLEX* F,
                                     const LTFAT_COMPLEX* G[],
                                     ltfat_int M, ltfat_int foff[],
                                     const int realonly[], LTFAT_COMPLEX* cout[])
{
    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(convsub_fftbl_execute)(p[m], F, G[m], foff[m], realonly[m], cout[m]);
    }

}


LTFAT_API LTFAT_NAME(convsub_fftbl_plan)
LTFAT_NAME(convsub_fftbl_init)( ltfat_int L, ltfat_int Gl,
                                ltfat_int W, const double a,
                                LTFAT_COMPLEX* cout)
{
    ltfat_int N = (ltfat_int) floor(L / a + 0.5);

    /* LTFAT_FFTW(iodim64) dims; */
    /* dims.n = N; dims.is = 1; dims.os = 1; */
    /* LTFAT_FFTW(iodim64) howmany_dims; */
    /* howmany_dims.n = W; howmany_dims.is = N; howmany_dims.os = N; */
    /*  */
    /* LTFAT_FFTW(complex)* coutNc = (LTFAT_FFTW(complex)*) cout; */
    /* LTFAT_FFTW(plan) p_many = */
    /*     LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims, */
    /*                                 coutNc, coutNc, */
    /*                                 FFTW_BACKWARD, FFTW_ESTIMATE); */

    LTFAT_NAME_REAL(ifft_plan)* p_many;
    LTFAT_NAME_REAL(ifft_init)(N, W, cout, cout, FFTW_ESTIMATE, &p_many);

    ltfat_int bufLen = (ltfat_int) ceil(Gl / ((double)N)) * N;

    LTFAT_COMPLEX* buf = NULL;
    if (bufLen)
        buf = LTFAT_NAME_COMPLEX(malloc)(bufLen);

    /* LTFAT_NAME(convsub_fftbl_plan_struct) p_struct; */
    /* p_struct.L = L; p_struct.Gl = Gl; p_struct.a = a; p_struct.W = W; */
    /* p_struct.p_c = p_many; p_struct.bufLen = bufLen; p_struct.buf = buf; */

    LTFAT_NAME(convsub_fftbl_plan) p =
        (LTFAT_NAME(convsub_fftbl_plan))ltfat_malloc( sizeof * p);
    p->L = L; p->Gl = Gl; p->a = a; p->W = W;
    p->p_c = p_many; p->bufLen = bufLen; p->buf = buf;

    /* memcpy(p, &p_struct, sizeof * p); */
    return p;
}

LTFAT_API void
LTFAT_NAME(convsub_fftbl_done)( LTFAT_NAME(convsub_fftbl_plan) p)
{
    /* LTFAT_FFTW(destroy_plan)(p->p_c); */
    LTFAT_NAME_REAL(ifft_done)(&p->p_c);
    if (p->buf != NULL) ltfat_free(p->buf);
    ltfat_free(p);
}


LTFAT_API void
LTFAT_NAME(convsub_fftbl_execute)(const LTFAT_NAME(convsub_fftbl_plan) p,
                                  const LTFAT_COMPLEX* F,
                                  const LTFAT_COMPLEX* G,
                                  ltfat_int foff,
                                  const int realonly,
                                  LTFAT_COMPLEX* cout)
{

    ltfat_int L = p->L;
    ltfat_int Gl = p->Gl;
    ltfat_int W = p->W;
    const double a = p->a;
    // Output length
    ltfat_int N = (ltfat_int) floor(L / a + 0.5);
    // Bail out in degenerate case
    if (!Gl)
    {
        LTFAT_NAME_COMPLEX(clear_array)(cout, W * N);
        //memset(cout, 0, W * N * sizeof * cout);
        return;
    }

    LTFAT_COMPLEX* tmp = p->buf;
    ltfat_int tmpLen = p->bufLen;
    //ltfat_int tmpLen = (ltfat_int) ceil(Gl/((double)N))*N;
    const LTFAT_REAL scalconst = (LTFAT_REAL) 1.0 / (L);
    // LTFAT_COMPLEX *tmp = ltfat_calloc(tmpLen,sizeof*tmp);


    for (ltfat_int w = 0; w < W; w++)
    {
        // First Gl elements of tmp is copied from F so,
        // zero only the part which wont be written to.
        LTFAT_NAME_COMPLEX(clear_array)(tmp + Gl, tmpLen - Gl);
        /* memset(tmp + Gl, 0, (tmpLen - Gl)*sizeof * tmp); */
        LTFAT_COMPLEX* tmpPtr = tmp;
        ltfat_int foffTmp = foff;
        ltfat_int tmpLg = Gl;

        // Copy samples of F according to range of G
        if (foffTmp < 0)
        {
            ltfat_int toCopy = ltfat_imin(-foffTmp, tmpLg);
            memcpy(tmpPtr, F + (w + 1)*L + foffTmp, toCopy * sizeof * F);
            tmpPtr += toCopy;
            tmpLg -= toCopy;
            foffTmp = 0;
        }

        if (foffTmp + tmpLg > L)
        {
            ltfat_int over = foffTmp + tmpLg - L;
            memcpy(tmpPtr + Gl - over, F + w * L, over * sizeof * F);
            tmpLg -= over;
        }

        memcpy(tmpPtr, F + w * L + foffTmp, tmpLg * sizeof * F);

        // Do the filtering
        for (ltfat_int ii = 0; ii < Gl; ii++)
        {
            tmp[ii] *= G[ii];
        }

        // Do the folding
        for (ltfat_int jj = 1; jj < tmpLen / N; jj++)
        {
            for (ltfat_int ii = 0; ii < N; ii++)
            {
                tmp[ii] += tmp[jj * N + ii];
            }
        }

        // Do the circshift
        LTFAT_NAME_COMPLEX(circshift)(tmp, N, foff, cout + w * N);
        //LTFAT_NAME_COMPLEX(circshift)(tmp,cout+w*N,N,-Gl/2);
        // memcpy(cout+w*N,tmp,N*sizeof*cout);
    }

    for (ltfat_int ii = 0; ii < W * N; ii++)
    {
        cout[ii] *= scalconst;
    }

    // ifft
    /* LTFAT_FFTW(execute_dft)(p->p_c, (LTFAT_FFTW(complex)*)cout, */
    /*                         (LTFAT_FFTW(complex)*) cout); */
    LTFAT_NAME_REAL(ifft_execute_newarray)(p->p_c, cout, cout);

    if (realonly)
    {
        // Involute the filter and call the function again
        ltfat_int foffconj = -L + ltfat_positiverem(L - foff - Gl, L) + 1;
        LTFAT_COMPLEX* Gconj = LTFAT_NAME_COMPLEX(malloc)(Gl);
        LTFAT_COMPLEX* cout2 = LTFAT_NAME_COMPLEX(malloc)(W * N);

        for (ltfat_int ii = 0; ii < Gl; ii++)
        {
            Gconj[ii] = (LTFAT_COMPLEX) conj(G[Gl - 1 - ii]);
        }

        LTFAT_NAME(convsub_fftbl_execute)(p, F, Gconj, foffconj, 0, cout2);

        // Scale
        for (ltfat_int ii = 0; ii < W * N; ii++)
        {
            cout[ii] = (cout[ii] + cout2[ii]) / ((LTFAT_REAL) 2.0);
        }
        ltfat_free(Gconj);
        ltfat_free(cout2);
    }
}


LTFAT_API void
LTFAT_NAME(convsub_fftbl)(const LTFAT_COMPLEX* F,  const LTFAT_COMPLEX* G,
                          ltfat_int L, ltfat_int Gl, ltfat_int W,
                          const double a, ltfat_int foff,
                          const int realonly, LTFAT_COMPLEX* cout)
{
    LTFAT_NAME(convsub_fftbl_plan) p =
        LTFAT_NAME(convsub_fftbl_init)( L, Gl, W, a, cout);

    LTFAT_NAME(convsub_fftbl_execute)(p, F, G, foff, realonly, cout);

    LTFAT_NAME(convsub_fftbl_done)(p);
}


/* LTFAT_API void */
/* LTFAT_NAME(ufilterbank_fft)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g, */
/*                             ltfat_int L, ltfat_int Gl, */
/*                             ltfat_int W, ltfat_int a, ltfat_int M, */
/*                             LTFAT_COMPLEX* cout) */
/* { */
/*  */
/*     #<{(| ----- Initialization ------------ |)}># */
/*  */
/*     ltfat_int N = L / a; */
/*  */
/*     #<{(| Downcasting to ints |)}># */
/*     int Lint = (int) L; */
/*     int Nint = (int) N; */
/*     int Mint = (int) M; */
/*     int MWint = (int) (M * W); */
/*  */
/*     LTFAT_COMPLEX* gwork = LTFAT_NAME_COMPLEX(malloc)(L * M); */
/*  */
/*     LTFAT_COMPLEX* work = LTFAT_NAME_COMPLEX(malloc)(L); */
/*  */
/*     LTFAT_FFTW(plan) plan_g = */
/*         LTFAT_FFTW(plan_many_dft)(1, &Lint, Mint, */
/*                                   (LTFAT_FFTW(complex)*)gwork, NULL, */
/*                                   1, Lint, */
/*                                   (LTFAT_FFTW(complex)*)gwork, NULL, */
/*                                   1, Lint, */
/*                                   FFTW_FORWARD, FFTW_ESTIMATE); */
/*  */
/*     LTFAT_FFTW(plan_dft_1d)(Lint, (LTFAT_FFTW(complex)*)gwork, */
/*                             (LTFAT_FFTW(complex)*)gwork, FFTW_FORWARD, FFTW_ESTIMATE); */
/*  */
/*     LTFAT_FFTW(plan) plan_w = */
/*         LTFAT_FFTW(plan_dft_1d)(Lint, (LTFAT_FFTW(complex)*)work, */
/*                                 (LTFAT_FFTW(complex)*)work, FFTW_FORWARD, FFTW_ESTIMATE); */
/*  */
/*     LTFAT_FFTW(plan) plan_c = */
/*         LTFAT_FFTW(plan_many_dft)(1, &Nint, MWint, */
/*                                   (LTFAT_FFTW(complex)*)cout, NULL, */
/*                                   1, Nint, */
/*                                   (LTFAT_FFTW(complex)*)cout, NULL, */
/*                                   1, Nint, */
/*                                   FFTW_BACKWARD, FFTW_ESTIMATE); */
/*  */
/*     const LTFAT_REAL scalconst = (const LTFAT_REAL) (1.0 / L); */
/*  */
/*     #<{(| ----- Main -------------------------- |)}># */
/*  */
/*     #<{(| Extend g and copy to work buffer |)}># */
/*     for (ltfat_int m = 0; m < M; m++) */
/*     { */
/*         LTFAT_NAME_COMPLEX(fir2long)(g + m * Gl, Gl, L, gwork + m * L); */
/*     } */
/*  */
/*     LTFAT_FFTW(execute)(plan_g); */
/*  */
/*     for (ltfat_int w = 0; w < W; w++) */
/*     { */
/*         memcpy(work, f + L * w, sizeof(LTFAT_COMPLEX)*L); */
/*         LTFAT_FFTW(execute)(plan_w); */
/*  */
/*         for (ltfat_int m = 0; m < M; m++) */
/*         { */
/*             for (ltfat_int n = 0; n < N; n++) */
/*             { */
/*                 cout[n + m * N + w * N * M] = (LTFAT_COMPLEX) 0.0; */
/*  */
/*                 for (ltfat_int k = 0; k < a; k++) */
/*                 { */
/*                     ltfat_int l = n + k * N; */
/*                     cout[n + m * N + w * N * M] += work[l] * gwork[l + m * L] * scalconst; */
/*                 } */
/*             } */
/*         } */
/*     } */
/*  */
/*  */
/*     LTFAT_FFTW(execute)(plan_c); */
/*  */
/*  */
/*     LTFAT_SAFEFREEALL(work, gwork); */
/* } */
