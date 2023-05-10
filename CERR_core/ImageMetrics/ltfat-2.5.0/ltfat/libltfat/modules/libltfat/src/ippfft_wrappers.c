/**/
#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ipps.h"

#ifdef LTFAT_DOUBLE
#define IPP_NAME(name)         LTFAT_MAKE_NAME(Ipps,name,_64f)
#define IPP_NAME_COMPLEX(name) LTFAT_MAKE_NAME(Ipps,name,_64fc)
#elif LTFAT_SINGLE
#define IPP_NAME(name)         LTFAT_MAKE_NAME(Ipps,name,_32f)
#define IPP_NAME_COMPLEX(name) LTFAT_MAKE_NAME(Ipps,name,_32fc)
#endif

/****** FFT ******/
struct LTFAT_NAME(fft_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_COMPLEX* in;
    LTFAT_COMPLEX* out;
    LTFAT_COMPLEX* tmp;
    void* ipp_plan;
    int ispow2;
};

LTFAT_API int
LTFAT_NAME(fft)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                LTFAT_COMPLEX out[])
{
    LTFAT_NAME(fft_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(fft_init)(L, W, in, out, 0, &p));
    LTFAT_NAME(fft_execute)(p);
    LTFAT_NAME(fft_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_init)(ltfat_int L, ltfat_int W,
                     LTFAT_COMPLEX in[], LTFAT_COMPLEX out[],
                     unsigned UNUSED(flags), LTFAT_NAME(fft_plan)** p)
{
    LTFAT_NAME(fft_plan)* fftwp = NULL;
    int ispow2 = 0;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    ispow2 = ltfat_ispow2(L);

    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(fft_plan)) );
    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;
    fftwp->ispow2 = ispow2;

    if (ispow2)
    {
        ltfat_int Lbase = ltfat_pow2base(L);

// IppStatus ippsFFTGetSize_C_32fc(int order, int flag, IppHintAlgorithm hint, int*
// pSpecSize, int* pSpecBufferSize, int* pBufferSize );

// IppStatus ippsFFTInit_C_64fc(IppsFFTSpec_C_64fc** ppFFTSpec, int order, int flag,
// IppHintAlgorithm hint, Ipp8u* pSpec, Ipp8u* pSpecBuffer );



        IPP_NAME_COMPLEX(FFTGetSize_C)(Lbase,IPP_FFT_NODIV_BY_ANY,ippAlgHintNone,);
    }
    else
    {

    }

    fftwp->kiss_plan = LTFAT_KISS(fft_alloc)(L, inverse, NULL, NULL);
    CHECKINIT(fftwp->kiss_plan, "FFTW plan creation failed.");

    if (in == out)
        CHECKMEM( fftwp->tmp = LTFAT_NAME_COMPLEX(malloc)(L) );

    *p = fftwp;
    return status;
error:
    if (fftwp)
        LTFAT_NAME(fft_done)(&fftwp);
    *p = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_execute)(LTFAT_NAME(fft_plan)* p)
{
    return LTFAT_NAME(fft_execute_newarray)( p, p->in, p->out);
}

LTFAT_API int
LTFAT_NAME(fft_execute_newarray)(LTFAT_NAME(fft_plan)* p,
                                 const LTFAT_COMPLEX in[], LTFAT_COMPLEX out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);

    if (in == out)
    {
        CHECKNULL(p->tmp);

        for (ltfat_int w = 0; w < p->W; w++)
        {
            memcpy(p->tmp, in + w * p->L, p->L * sizeof * p->tmp);
            LTFAT_KISS(fft)(p->kiss_plan,
                            (const kiss_fft_cpx*) p->tmp,
                            (kiss_fft_cpx*) out + w * p->L);
        }
    }
    else
    {
        for (ltfat_int w = 0; w < p->W; w++)
            LTFAT_KISS(fft)(p->kiss_plan,
                            (const kiss_fft_cpx*) in + w * p->L,
                            (kiss_fft_cpx*) out + w * p->L);
    }

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_done)(LTFAT_NAME(fft_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(fft_plan)* pp = NULL;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    if (pp->tmp) ltfat_free(pp->tmp);
    if (pp->kiss_plan) ltfat_free(pp->kiss_plan);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/******* IFFT ******/
struct LTFAT_NAME(ifft_plan)
{
    struct LTFAT_NAME(fft_plan) inplan;
};

LTFAT_API int
LTFAT_NAME(ifft)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                 LTFAT_COMPLEX out[])
{
    LTFAT_NAME(ifft_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(ifft_init)(L, W, in, out, 0, &p));

    LTFAT_NAME(ifft_execute)(p);
    LTFAT_NAME(ifft_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifft_init)(ltfat_int L, ltfat_int W,
                      LTFAT_COMPLEX in[], LTFAT_COMPLEX out[],
                      unsigned UNUSED(flags), LTFAT_NAME(ifft_plan)** p)
{
    return LTFAT_NAME(fft_init_common)(L, W, in, out, 1,
                                       (LTFAT_NAME(fft_plan)**) p);
}

LTFAT_API int
LTFAT_NAME(ifft_execute)(LTFAT_NAME(ifft_plan)* p)
{
    return LTFAT_NAME(fft_execute)((LTFAT_NAME(fft_plan)*) p);
}

LTFAT_API int
LTFAT_NAME(ifft_execute_newarray)(LTFAT_NAME(ifft_plan)* p,
                                  const LTFAT_COMPLEX in[], LTFAT_COMPLEX out[])
{
    return LTFAT_NAME(fft_execute_newarray)((LTFAT_NAME(fft_plan)*) p, in, out);

}

LTFAT_API int
LTFAT_NAME(ifft_done)(LTFAT_NAME(ifft_plan)** p)
{
    return LTFAT_NAME(fft_done)((LTFAT_NAME(fft_plan)**) p);
}

/****** FFTREAL ******/
struct LTFAT_NAME(fftreal_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_REAL* in;
    LTFAT_REAL* out;
    LTFAT_COMPLEX* tmp;
    LTFAT_KISS(fft_cfg) kiss_plan_cpx;
    LTFAT_KISS(fftr_cfg) kiss_plan;
};

LTFAT_API int
LTFAT_NAME(fftreal)(LTFAT_REAL in[], ltfat_int L, ltfat_int W,
                    LTFAT_COMPLEX out[])
{
    LTFAT_NAME(fftreal_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(fftreal_init)(L, W, in, out, 0, &p));

    LTFAT_NAME(fftreal_execute)(p);
    LTFAT_NAME(fftreal_done)(&p);
error:
    return status;
}

static int
LTFAT_NAME(fftreal_init_common)(ltfat_int L, ltfat_int W,
                                LTFAT_REAL in[], LTFAT_REAL out[],
                                unsigned inverse, LTFAT_NAME(fftreal_plan)** p)
{
    LTFAT_NAME(fftreal_plan)* fftwp = NULL;
    ltfat_int M2;
    ltfat_int nextfastL;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, L > 0, "L must be even positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    M2 = L / 2 + 1;

    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(fftreal_plan)) );
    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;

    nextfastL = ltfat_nextfastfft(L);

    if (L != nextfastL)
    {
        DEBUG("Warning: L=%td is a \"slow\" FFT lengh. "
              "Next fast FFT lenght is L=%td. See ltfat_nextfastfft. "
              "Moreover, some dynamic memory allocation will occur "
              "during execution.", L, nextfastL);
    }

    if (L % 2)
    {
        if (L != nextfastL)
        {
            DEBUGNOTE("Warning: Odd L is a \"very slow\" FFT lengh. Full FFT will be performed.");
        }
        // Workaround for odd-length transforms
        fftwp->kiss_plan_cpx = LTFAT_KISS(fft_alloc)(L, inverse, NULL, NULL);
        CHECKINIT(fftwp->kiss_plan_cpx, "FFTW plan creation failed.");
        CHECKMEM( fftwp->tmp = LTFAT_NAME_COMPLEX(malloc)(4 * M2 ) );
    }
    else
    {
        fftwp->kiss_plan = LTFAT_KISS(fftr_alloc)(L, inverse, NULL, NULL);
        CHECKINIT(fftwp->kiss_plan, "FFTW plan creation failed.");

        if (in == out)
            CHECKMEM( fftwp->tmp = LTFAT_NAME_COMPLEX(malloc)(L / 2 + 1) );
    }
    *p = fftwp;
    return status;
error:
    if (fftwp)
        LTFAT_NAME(fftreal_done)(&fftwp);
    *p = NULL;
    return status;
}


LTFAT_API int
LTFAT_NAME(fftreal_init)(ltfat_int L, ltfat_int W,
                         LTFAT_REAL in[], LTFAT_COMPLEX out[],
                         unsigned UNUSED(flags), LTFAT_NAME(fftreal_plan)** p)
{
    return  LTFAT_NAME(fftreal_init_common)(L, W, in, (LTFAT_REAL*) out, 0, p);
}

LTFAT_API int
LTFAT_NAME(fftreal_execute)(LTFAT_NAME(fftreal_plan)* p)
{
    return LTFAT_NAME(fftreal_execute_newarray)( p, p->in,
            (LTFAT_COMPLEX*) p->out);
}

LTFAT_API int
LTFAT_NAME(fftreal_execute_newarray)(LTFAT_NAME(fftreal_plan)* p,
                                     const LTFAT_REAL in[], LTFAT_COMPLEX out[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M2;

    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);

    M2 = p->L / 2 + 1;

    if (p->L % 2)
    {
        ltfat_int step = p->L;
        if (in == (const LTFAT_REAL*) out)
            step = 2 * M2;

        for (ltfat_int w = 0; w < p->W; w++)
        {
            LTFAT_NAME(real2complex_array)(in + w * step, p->L, p->tmp);

            LTFAT_KISS(fft)(p->kiss_plan_cpx,
                            (const kiss_fft_cpx*) p->tmp,
                            (kiss_fft_cpx*) p->tmp + 2 * M2);

            memcpy(out + w * M2, p->tmp + 2 * M2, M2 * sizeof * out);
        }
    }
    else
    {
        if ( in == (const LTFAT_REAL*) out )
        {
            CHECKNULL(p->tmp);

            for (ltfat_int w = 0; w < p->W; w++)
            {
                memcpy(p->tmp, in + w * 2 * M2, p->L * sizeof * p->in);
                LTFAT_KISS(fftr)(p->kiss_plan,
                                 (const kiss_fft_scalar*) p->tmp,
                                 (kiss_fft_cpx*) out + w * M2);
            }
        }
        else
        {
            for (ltfat_int w = 0; w < p->W; w++)
                LTFAT_KISS(fftr)(p->kiss_plan,
                                 (const kiss_fft_scalar*) in + w * p->L,
                                 (kiss_fft_cpx*) out + w * M2);
        }
    }
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fftreal_done)(LTFAT_NAME(fftreal_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(fftreal_plan)* pp = NULL;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    if (pp->tmp) ltfat_free(pp->tmp);
    if (pp->kiss_plan) ltfat_free(pp->kiss_plan);
    if (pp->kiss_plan_cpx) ltfat_free(pp->kiss_plan_cpx);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/******* IFFTREAL ******/
struct LTFAT_NAME(ifftreal_plan)
{
    struct LTFAT_NAME(fftreal_plan) inplan;
};

LTFAT_API int
LTFAT_NAME(ifftreal)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                     LTFAT_REAL out[])
{
    LTFAT_NAME(ifftreal_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(ifftreal_init)(L, W, in, out, 0, &p));

    LTFAT_NAME(ifftreal_execute)(p);
    LTFAT_NAME(ifftreal_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_init)(ltfat_int L, ltfat_int W,
                          LTFAT_COMPLEX in[], LTFAT_REAL out[],
                          unsigned UNUSED(flags), LTFAT_NAME(ifftreal_plan)** p)
{
    return LTFAT_NAME(fftreal_init_common)(L, W, (LTFAT_REAL*)in, out, 1,
                                           (LTFAT_NAME(fftreal_plan)**) p);
}

LTFAT_API int
LTFAT_NAME(ifftreal_execute)(LTFAT_NAME(ifftreal_plan)* pin)
{
    LTFAT_NAME(fftreal_plan)* p = (LTFAT_NAME(fftreal_plan)*) pin;
    return LTFAT_NAME(ifftreal_execute_newarray)( pin, (const LTFAT_COMPLEX*) p->in,
            p->out);
}

LTFAT_API int
LTFAT_NAME(ifftreal_execute_newarray)(LTFAT_NAME(ifftreal_plan)* pin,
                                      const LTFAT_COMPLEX in[], LTFAT_REAL out[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M2;
    LTFAT_NAME(fftreal_plan)* p;
    CHECKNULL(pin); CHECKNULL(in); CHECKNULL(out);
    p = (LTFAT_NAME(fftreal_plan)*) pin;

    M2 = p->L / 2 + 1;

    if (p->L % 2)
    {
        ltfat_int step = p->L;
        if (in == (const LTFAT_COMPLEX*) out)
            step = 2 * M2;

        for (ltfat_int w = 0; w < p->W; w++)
        {
            const LTFAT_COMPLEX* inTmp = in + w * M2;
            memcpy(p->tmp, inTmp, M2 * sizeof * in);

            for (ltfat_int ii = p->L - 1, jj = 1; ii >= M2; ii--, jj++)
                p->tmp[ii] = conj(inTmp[jj]);

            LTFAT_KISS(fft)(p->kiss_plan_cpx,
                            (const kiss_fft_cpx*) p->tmp,
                            (kiss_fft_cpx*) p->tmp + 2 * M2);

            LTFAT_NAME(complex2real_array)( p->tmp + 2 * M2, p->L, out + w * step);
        }
    }
    else
    {
        if (in == (const LTFAT_COMPLEX*) out)
        {
            CHECKNULL(p->tmp);

            for (ltfat_int w = 0; w < p->W; w++)
            {
                memcpy(p->tmp, in + w * M2, M2 * sizeof * in);
                LTFAT_KISS(fftri)(p->kiss_plan,
                                  (const kiss_fft_cpx*) p->tmp,
                                  (kiss_fft_scalar*) out + w * 2 * M2);
            }
        }
        else
        {
            for (ltfat_int w = 0; w < p->W; w++)
                LTFAT_KISS(fftri)(p->kiss_plan,
                                  (const kiss_fft_cpx*) in + w * M2,
                                  (kiss_fft_scalar*) out + w * p->L);
        }
    }
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_done)(LTFAT_NAME(ifftreal_plan)** p)
{
    return LTFAT_NAME(fftreal_done)((LTFAT_NAME(fftreal_plan)**) p);
}
