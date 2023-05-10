#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ltfat/thirdparty/fftw3.h"

/****** FFT ******/
struct LTFAT_NAME(fft_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_COMPLEX* in;
    LTFAT_COMPLEX* out;
    LTFAT_FFTW(plan) p;
};

LTFAT_API int
LTFAT_NAME(fft)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                LTFAT_COMPLEX out[])
{
    LTFAT_NAME(fft_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(fft_init)(L, W, in, out, FFTW_ESTIMATE, &p));
    LTFAT_NAME(fft_execute)(p);
    LTFAT_NAME(fft_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_init)(ltfat_int L, ltfat_int W,
                     LTFAT_COMPLEX in[], LTFAT_COMPLEX out[],
                     unsigned flags, LTFAT_NAME(fft_plan)** p)
{
    LTFAT_FFTW(iodim64) dims;
    LTFAT_FFTW(iodim64) howmany_dims;
    LTFAT_NAME(fft_plan)* fftwp = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(fft_plan)) );

    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;

    dims.n = L; dims.is = 1; dims.os = 1;
    howmany_dims.n = W; howmany_dims.is = L; howmany_dims.os = L;

    fftwp->p = LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims,
                                           (LTFAT_FFTW(complex)*)  in,
                                           (LTFAT_FFTW(complex)*) out,
                                           FFTW_FORWARD, flags);

    CHECKINIT(fftwp->p, "FFTW plan creation failed.");
    *p = fftwp;
    return status;
error:
    if (fftwp)
    {
        if (fftwp->p) LTFAT_FFTW(destroy_plan)(fftwp->p);
        ltfat_free(fftwp);
    }
    *p = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_execute)(LTFAT_NAME(fft_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->in); CHECKNULL(p->out);
    LTFAT_FFTW(execute)(p->p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fft_execute_newarray)(LTFAT_NAME(fft_plan)* p,
                                 const LTFAT_COMPLEX in[], LTFAT_COMPLEX out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);
    LTFAT_FFTW(execute_dft)(p->p,
                            (LTFAT_FFTW(complex)*)in,
                            (LTFAT_FFTW(complex)*)out);
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
    LTFAT_FFTW(destroy_plan)(pp->p);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/******* IFFT ******/
struct LTFAT_NAME(ifft_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_COMPLEX* in;
    LTFAT_COMPLEX* out;
    LTFAT_FFTW(plan) p;
};

LTFAT_API int
LTFAT_NAME(ifft)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                 LTFAT_COMPLEX out[])
{
    LTFAT_NAME(ifft_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(ifft_init)(L, W, in, out, FFTW_ESTIMATE, &p));
    LTFAT_NAME(ifft_execute)(p);
    LTFAT_NAME(ifft_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifft_init)(ltfat_int L, ltfat_int W,
                      LTFAT_COMPLEX in[], LTFAT_COMPLEX out[],
                      unsigned flags, LTFAT_NAME(ifft_plan)** p)
{
    LTFAT_FFTW(iodim64) dims;
    LTFAT_FFTW(iodim64) howmany_dims;
    LTFAT_NAME(ifft_plan)* fftwp = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(ifft_plan)) );

    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;

    dims.n = L; dims.is = 1; dims.os = 1;
    howmany_dims.n = W; howmany_dims.is = L; howmany_dims.os = L;

    fftwp->p = LTFAT_FFTW(plan_guru64_dft)(1, &dims, 1, &howmany_dims,
                                           (LTFAT_FFTW(complex)*)  in,
                                           (LTFAT_FFTW(complex)*) out,
                                           FFTW_BACKWARD, flags);

    CHECKINIT(fftwp->p, "FFTW plan creation failed.");
    *p = fftwp;
    return status;
error:
    if (fftwp)
    {
        if (fftwp->p) LTFAT_FFTW(destroy_plan)(fftwp->p);
        ltfat_free(fftwp);
    }
    *p = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(ifft_execute)(LTFAT_NAME(ifft_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->in); CHECKNULL(p->out);
    LTFAT_FFTW(execute)(p->p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifft_execute_newarray)(LTFAT_NAME(ifft_plan)* p,
                                  const LTFAT_COMPLEX in[], LTFAT_COMPLEX out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);
    LTFAT_FFTW(execute_dft)(p->p,
                            (LTFAT_FFTW(complex)*)in,
                            (LTFAT_FFTW(complex)*)out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifft_done)(LTFAT_NAME(ifft_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(ifft_plan)* pp = NULL;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    LTFAT_FFTW(destroy_plan)(pp->p);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/****** FFTREAL ******/
struct LTFAT_NAME(fftreal_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_REAL* in;
    LTFAT_COMPLEX* out;
    LTFAT_FFTW(plan) p;
};

LTFAT_API int
LTFAT_NAME(fftreal)(LTFAT_REAL in[], ltfat_int L, ltfat_int W,
                    LTFAT_COMPLEX out[])
{
    LTFAT_NAME(fftreal_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(fftreal_init)(L, W, in, out, FFTW_ESTIMATE, &p));
    LTFAT_NAME(fftreal_execute)(p);
    LTFAT_NAME(fftreal_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fftreal_init)(ltfat_int L, ltfat_int W,
                         LTFAT_REAL in[], LTFAT_COMPLEX out[],
                         unsigned flags, LTFAT_NAME(fftreal_plan)** p)
{
    LTFAT_FFTW(iodim64) dims;
    LTFAT_FFTW(iodim64) howmany_dims;
    ltfat_int M2;
    LTFAT_NAME(fftreal_plan)* fftwp = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(fftreal_plan)) );

    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;

    M2 = L / 2 + 1;
    dims.n = L; dims.is = 1; dims.os = 1;
    howmany_dims.n = W;  howmany_dims.os = M2;

    if (in != (LTFAT_REAL*) out )
        howmany_dims.is = L;
    else
        howmany_dims.is = 2 * M2;

    fftwp->p =
        LTFAT_FFTW(plan_guru64_dft_r2c)(1, &dims, 1, &howmany_dims,
                                        in, (LTFAT_FFTW(complex)*) out,
                                        flags);

    CHECKINIT(fftwp->p, "FFTW plan creation failed.");
    *p = fftwp;
    return status;
error:
    if (fftwp)
    {
        if (fftwp->p) LTFAT_FFTW(destroy_plan)(fftwp->p);
        ltfat_free(fftwp);
    }
    *p = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(fftreal_execute)(LTFAT_NAME(fftreal_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->in); CHECKNULL(p->out);
    LTFAT_FFTW(execute)(p->p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(fftreal_execute_newarray)(LTFAT_NAME(fftreal_plan)* p,
                                     const LTFAT_REAL in[], LTFAT_COMPLEX out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);
    LTFAT_FFTW(execute_dft_r2c)(p->p,  (LTFAT_REAL*)in, (LTFAT_FFTW(complex)*) out);
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
    LTFAT_FFTW(destroy_plan)(pp->p);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/******* IFFTREAL ******/
struct LTFAT_NAME(ifftreal_plan)
{
    ltfat_int L;
    ltfat_int W;
    LTFAT_COMPLEX* in;
    LTFAT_REAL* out;
    LTFAT_FFTW(plan) p;
};

LTFAT_API int
LTFAT_NAME(ifftreal)(LTFAT_COMPLEX in[], ltfat_int L, ltfat_int W,
                     LTFAT_REAL out[])
{
    LTFAT_NAME(ifftreal_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(ifftreal_init)(L, W, in, out, FFTW_ESTIMATE, &p));
    LTFAT_NAME(ifftreal_execute)(p);
    LTFAT_NAME(ifftreal_done)(&p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_init)(ltfat_int L, ltfat_int W,
                          LTFAT_COMPLEX in[], LTFAT_REAL out[],
                          unsigned flags, LTFAT_NAME(ifftreal_plan)** p)
{
    LTFAT_FFTW(iodim64) dims;
    LTFAT_FFTW(iodim64) howmany_dims;
    ltfat_int M2;
    LTFAT_NAME(ifftreal_plan)* fftwp = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECKMEM( fftwp = LTFAT_NEW(LTFAT_NAME(ifftreal_plan)) );

    M2 = L / 2 + 1;

    fftwp->L = L; fftwp->W = W; fftwp->in = in; fftwp->out = out;

    dims.n = L; dims.is = 1; dims.os = 1;
    howmany_dims.n = W; howmany_dims.is = L / 2 + 1;

    if (in != (LTFAT_COMPLEX*) out )
        howmany_dims.os = L;
    else
        howmany_dims.os = 2 * M2;

    fftwp->p =
        LTFAT_FFTW(plan_guru64_dft_c2r)(1, &dims, 1, &howmany_dims,
                                        (LTFAT_FFTW(complex)*)  in,
                                        out, flags);

    CHECKINIT(fftwp->p, "FFTW plan creation failed.");
    *p = fftwp;
    return status;
error:
    if (fftwp)
    {
        if (fftwp->p) LTFAT_FFTW(destroy_plan)(fftwp->p);
        ltfat_free(fftwp);
    }
    *p = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_execute)(LTFAT_NAME(ifftreal_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->in); CHECKNULL(p->out);
    LTFAT_FFTW(execute)(p->p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_execute_newarray)(LTFAT_NAME(ifftreal_plan)* p,
                                      const LTFAT_COMPLEX in[], LTFAT_REAL out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);
    LTFAT_FFTW(execute_dft_c2r)(p->p, (LTFAT_FFTW(complex)*)in, out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(ifftreal_done)(LTFAT_NAME(ifftreal_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(ifftreal_plan)* pp = NULL;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    LTFAT_FFTW(destroy_plan)(pp->p);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}
