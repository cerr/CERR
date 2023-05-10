#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(upconv_fft_plan_struct)
{
    ltfat_int L;
    ltfat_int W;
    ltfat_int a;
    /* LTFAT_FFTW(plan) p_c; */
    LTFAT_NAME_REAL(fft_plan)* p_c;
    LTFAT_COMPLEX* buf;
    ltfat_int bufLen;
};

struct LTFAT_NAME(upconv_fftbl_plan_struct)
{
    ltfat_int L;
    ltfat_int Gl;
    ltfat_int W;
    double a;
    /* LTFAT_FFTW(plan) p_c; */
    LTFAT_NAME_REAL(fft_plan)* p_c;
    LTFAT_COMPLEX* buf;
    ltfat_int bufLen;
};

LTFAT_API void
LTFAT_NAME(ifilterbank_fft)(const LTFAT_COMPLEX* cin[],
                            const LTFAT_COMPLEX* G[],
                            ltfat_int L, ltfat_int W, ltfat_int a[],
                            ltfat_int M, LTFAT_COMPLEX* F)
{
    // This is necessary since F us used as an accumulator
    LTFAT_NAME_COMPLEX(clear_array)(F, L * W);
    //memset(F, 0, L * W * sizeof * F);

    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(upconv_fft)(cin[m], G[m], L, W, a[m], F);
    }
}

LTFAT_API void
LTFAT_NAME(ifilterbank_fft_execute)(LTFAT_NAME(upconv_fft_plan) p[],
                                    const LTFAT_COMPLEX* cin[],
                                    const LTFAT_COMPLEX* G[],
                                    ltfat_int M,
                                    LTFAT_COMPLEX* F )
{
    ltfat_int L = p[0]->L;
    ltfat_int W = p[0]->W;
    // This is necessary since F us used as an accumulator
    LTFAT_NAME_COMPLEX(clear_array)(F, L * W);
    //memset(F, 0, W * L * sizeof * F);

    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(upconv_fft_execute)(p[m], cin[m], G[m], F);
    }
}


// Inverse
LTFAT_API void
LTFAT_NAME(upconv_fft)(const LTFAT_COMPLEX* cin, const LTFAT_COMPLEX* G,
                       ltfat_int L, ltfat_int W, ltfat_int a,
                       LTFAT_COMPLEX* F)
{
    LTFAT_NAME(upconv_fft_plan) p =
        LTFAT_NAME(upconv_fft_init)(L, W, a);

    LTFAT_NAME(upconv_fft_execute)(p, cin, G, F);

    LTFAT_NAME(upconv_fft_done)(p);
}

LTFAT_API LTFAT_NAME(upconv_fft_plan)
LTFAT_NAME(upconv_fft_init)(ltfat_int L, ltfat_int W,
                            ltfat_int a)
{
    ltfat_int N = L / a;

    LTFAT_COMPLEX* buf = LTFAT_NAME_COMPLEX(malloc)(W * N);

    /* LTFAT_FFTW(iodim64) dims; */
    /* dims.n = N; dims.is = 1; dims.os = 1; */
    /* LTFAT_FFTW(iodim64) howmany_dims; */
    /* howmany_dims.n = W; howmany_dims.is = N; howmany_dims.os = N; */
    /*  */
    /* LTFAT_FFTW(plan) p_many = */
    /*     LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims, */
    /*                                 (LTFAT_FFTW(complex)*) buf, */
    /*                                 (LTFAT_FFTW(complex)*) buf, */
    /*                                 FFTW_FORWARD, FFTW_ESTIMATE); */

    LTFAT_NAME_REAL(fft_plan)* p_many;
    LTFAT_NAME_REAL(fft_init)(N, W, buf, buf, FFTW_ESTIMATE, &p_many);

    /* struct LTFAT_NAME(upconv_fft_plan_struct) p_struct = */
    /* { .L = L, .a = a, .W = W, .p_c = p_many, .buf = buf, .bufLen = W * N }; */

    LTFAT_NAME(upconv_fft_plan) p =
        (LTFAT_NAME(upconv_fft_plan))ltfat_malloc( sizeof * p);
    p->L = L; p->a = a; p->W = W; p->p_c = p_many; p->buf = buf; p->bufLen = W * N;
    /* memcpy(p, &p_struct, sizeof * p); */
    return p;
}


LTFAT_API void
LTFAT_NAME(upconv_fft_execute)(LTFAT_NAME(upconv_fft_plan) p,
                               const LTFAT_COMPLEX* cin, const LTFAT_COMPLEX* G,
                               LTFAT_COMPLEX* F)
{
    ltfat_int L = p->L;
    ltfat_int a = p->a;
    ltfat_int W = p->W;
    LTFAT_COMPLEX* buf = p->buf;
    ltfat_int N = L / a;
    memcpy(buf, cin, W * N * sizeof * cin);


    // New array execution, inplace
    /* LTFAT_FFTW(execute_dft)(p->p_c, */
    /*                         (LTFAT_FFTW(complex)*) buf, */
    /*                         (LTFAT_FFTW(complex)*) buf); */
    LTFAT_NAME_REAL(fft_execute_newarray)(p->p_c, buf, buf);

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_COMPLEX* FPtr = F + w * L;
        LTFAT_COMPLEX* GPtr = (LTFAT_COMPLEX*) G;
        for (ltfat_int jj = 0; jj < a; jj++)
        {
            for (ltfat_int ii = 0; ii < N; ii++)
            {
                // Really readable ;)
                *FPtr++ += conj(*GPtr++) * buf[ii + N * w];
            }
        }
    }
}

LTFAT_API void
LTFAT_NAME(upconv_fft_done)(LTFAT_NAME(upconv_fft_plan) p)
{
    /* LTFAT_FFTW(destroy_plan)(p->p_c); */
    LTFAT_NAME_REAL(fft_done)(&p->p_c);
    ltfat_free(p->buf);
}


LTFAT_API void
LTFAT_NAME(ifilterbank_fftbl)(const LTFAT_COMPLEX* cin[],
                              const LTFAT_COMPLEX* G[],
                              ltfat_int L, const ltfat_int Gl[],
                              ltfat_int W, const double a[], ltfat_int M,
                              const ltfat_int foff[], const int realonly[],
                              LTFAT_COMPLEX* F)
{
    // This is necessary since F us used as an accumulator
    LTFAT_NAME_COMPLEX(clear_array)(F, L * W);
    //memset(F, 0, W * L * sizeof * F);

    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(upconv_fftbl)(cin[m], G[m], L, Gl[m], W, a[m], foff[m],
                                 realonly[m], F);
    }
}

LTFAT_API void
LTFAT_NAME(ifilterbank_fftbl_execute)(LTFAT_NAME(upconv_fftbl_plan) p[],
                                      const LTFAT_COMPLEX* cin[],
                                      const LTFAT_COMPLEX* G[],
                                      ltfat_int M, ltfat_int foff[],
                                      const int realonly[],
                                      LTFAT_COMPLEX* F)
{
    ltfat_int L = p[0]->L;
    ltfat_int W = p[0]->W;
    // This is necessary since F us used as an accumulator
    LTFAT_NAME_COMPLEX(clear_array)(F, L * W);
    //memset(F, 0, W * L * sizeof * F);

    for (ltfat_int m = 0; m < M; m++)
    {
        LTFAT_NAME(upconv_fftbl_execute)(p[m], cin[m], G[m], foff[m], realonly[m], F);
    }

}


LTFAT_API void
LTFAT_NAME(upconv_fftbl)(const LTFAT_COMPLEX* cin, const LTFAT_COMPLEX* G,
                         ltfat_int L, ltfat_int Gl, ltfat_int W,
                         const double a,
                         ltfat_int foff, const int realonly,
                         LTFAT_COMPLEX* F)
{
    LTFAT_NAME(upconv_fftbl_plan) p =
        LTFAT_NAME(upconv_fftbl_init)( L, Gl, W, a);

    LTFAT_NAME(upconv_fftbl_execute)(p, cin, G, foff, realonly, F);

    LTFAT_NAME(upconv_fftbl_done)( p);
}

LTFAT_API LTFAT_NAME(upconv_fftbl_plan)
LTFAT_NAME(upconv_fftbl_init)( ltfat_int L, ltfat_int Gl,
                               ltfat_int W, const double a)
{
    ltfat_int N = (ltfat_int) floor(L / a + 0.5);
    ltfat_int bufLen =  N > Gl ? N : Gl ;

    LTFAT_COMPLEX* buf = LTFAT_NAME_COMPLEX(malloc)(bufLen * W);

    /* LTFAT_FFTW(iodim64) dims; */
    /* dims.n = N; dims.is = 1; dims.os = 1; */
    /* LTFAT_FFTW(iodim64) howmany_dims; */
    /* howmany_dims.n = W; howmany_dims.is = bufLen; howmany_dims.os = bufLen; */
    /*  */
    /* LTFAT_FFTW(plan) p_many = */
    /*     LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims, */
    /*                                 (LTFAT_FFTW(complex)*)buf, */
    /*                                 (LTFAT_FFTW(complex)*)buf, */
    /*                                 FFTW_FORWARD, FFTW_ESTIMATE); */

    LTFAT_NAME_REAL(fft_plan)* p_many;
    LTFAT_NAME_REAL(fft_init)(N, 1, buf, buf, FFTW_ESTIMATE, &p_many);

    /* struct LTFAT_NAME(upconv_fftbl_plan_struct) p_struct = */
    /* { */
    /*     .L = L, .Gl = Gl, .a = a, .W = W, */
    /*     .p_c = p_many, .buf = buf, .bufLen = bufLen */
    /* }; */

    LTFAT_NAME(upconv_fftbl_plan) p =
        (LTFAT_NAME(upconv_fftbl_plan)) ltfat_malloc(sizeof * p);
    p->L = L; p->Gl = Gl; p->a = a; p->W = W;
    p->p_c = p_many; p->buf = buf; p->bufLen = bufLen;

    /* memcpy(p, &p_struct, sizeof * p); */
    return p;
}


LTFAT_API void
LTFAT_NAME(upconv_fftbl_execute)(const LTFAT_NAME(upconv_fftbl_plan) p,
                                 const LTFAT_COMPLEX* cin, const LTFAT_COMPLEX* G,
                                 ltfat_int foff,
                                 const int realonly, LTFAT_COMPLEX* F)
{
    ltfat_int Gl = p->Gl;
    if (!Gl) return; // Bail out if filter has zero bandwidth
    ltfat_int bufLen = p->bufLen;
    ltfat_int L = p->L;
    ltfat_int W = p->W;
    const double a = p->a;
    LTFAT_COMPLEX* cbuf = p->buf;

    ltfat_int N = (ltfat_int) floor(L / a + 0.5);

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_COMPLEX* cbuf_col = cbuf + w * bufLen;
        memcpy(cbuf_col, cin + w * N, N * sizeof * cin);
        LTFAT_NAME_REAL(fft_execute_newarray)(p->p_c, cbuf_col, cbuf_col);
    }
    /* LTFAT_FFTW(execute_dft)(p->p_c, (LTFAT_FFTW(complex)*)cbuf, */
    /*                         (LTFAT_FFTW(complex)*)cbuf); */
    /* LTFAT_NAME_REAL(fft_execute_newarray)(p->p_c, cbuf, cbuf); */

    for (ltfat_int w = 0; w < W; w++)
    {

        LTFAT_NAME_COMPLEX(circshift)(cbuf + w * bufLen, N, -foff, cbuf + w * bufLen);
        // This does nothing if bufLen == N
        LTFAT_NAME_COMPLEX(periodize_array)(cbuf + w * bufLen, N, bufLen,
                                            cbuf + w * bufLen);

        const LTFAT_COMPLEX* GPtrTmp = G;
        LTFAT_COMPLEX* FPtrTmp = F + w * L;
        LTFAT_COMPLEX* CPtrTmp = cbuf + w * bufLen;
        ltfat_int Gltmp = Gl;

        // Determine range of G
        ltfat_int foffTmp = foff;

        ltfat_int over = 0;
        if (foffTmp + Gltmp > (ltfat_int)L)
        {
            over = foffTmp + Gltmp - (ltfat_int)L;
        }


        if (foffTmp < 0)
        {
            ltfat_int toCopy = (-foffTmp) < Gltmp ? -foffTmp : Gltmp;
            FPtrTmp = F + (w + 1) * L + foffTmp;
            for (ltfat_int ii = 0; ii < toCopy; ii++)
            {
                LTFAT_COMPLEX tmp = *CPtrTmp++ * conj(*GPtrTmp++);
                FPtrTmp[ii] += tmp;
            }

            Gltmp -= toCopy;
            foffTmp = 0;
        }

        FPtrTmp = F + w * L + foffTmp;
        for (ltfat_int ii = 0; ii < Gltmp - over; ii++)
        {
            LTFAT_COMPLEX tmp = *CPtrTmp++ * conj(*GPtrTmp++);
            FPtrTmp[ii] += tmp;
        }

        FPtrTmp = F + w * L;
        for (ltfat_int ii = 0; ii < over; ii++)
        {
            LTFAT_COMPLEX tmp = (*CPtrTmp++ * conj(*GPtrTmp++));
            FPtrTmp[ii] += tmp;
        }
    }


    if (realonly)
    {
        ltfat_int foffconj = -L + ltfat_positiverem(L - foff - Gl, L) + 1;
        LTFAT_COMPLEX* Gconj = LTFAT_NAME_COMPLEX(malloc)(Gl);
        LTFAT_NAME_COMPLEX(reverse_array)(G, Gl, Gconj);
        LTFAT_NAME_COMPLEX(conjugate_array)(Gconj, Gl, Gconj);

        LTFAT_NAME(upconv_fftbl_execute)(p, cin, Gconj, foffconj, 0, F);
        ltfat_free(Gconj);
    }

}


LTFAT_API void
LTFAT_NAME(upconv_fftbl_done)(LTFAT_NAME(upconv_fftbl_plan) p)
{
    /* LTFAT_FFTW(destroy_plan)(p->p_c); */
    LTFAT_NAME_REAL(fft_done)(&p->p_c);
    if (p->buf) ltfat_free(p->buf);
}
