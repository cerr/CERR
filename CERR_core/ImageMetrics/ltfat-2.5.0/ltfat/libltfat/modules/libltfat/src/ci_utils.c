#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

// in might be equal to out
LTFAT_API int
LTFAT_NAME(circshift)(const LTFAT_TYPE in[], ltfat_int L,
                      ltfat_int shift, LTFAT_TYPE out[])
{
    ltfat_int p;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    // Fix shift
    p = (L - shift) % L;

    if (p < 0) p += L;

    if (in == out)
    {
        if (p) // Do nothing if no shift is needed
        {
            ltfat_int m, count, i, j;

            // Circshift inplace is magic!
            for (m = 0, count = 0; count != L; m++)
            {
                LTFAT_TYPE t = in[m];

                for (i = m, j = m + p; j != m;
                     i = j, j = j + p < L ? j + p : j + p - L, count++)
                    out[i] = out[j];

                out[i] = t; count++;
            }
        }
    }
    else
    {
        // Still ok if p==0
        memcpy(out, in + p, (L - p)*sizeof * out);
        memcpy(out + L - p, in, p * sizeof * out);
    }

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(circshiftcols)(const LTFAT_TYPE in[], ltfat_int Hin, ltfat_int Win,
                          ltfat_int shift, LTFAT_TYPE out[])
{
    ltfat_int p;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Hin > 0, "Hin must be positive");
    CHECK(LTFATERR_BADSIZE, Win > 0, "Win must be positive");

    // Fix shift
    p = (Win - shift) % Win;

    if (p < 0) p += Win;

    if (in == out)
    {
        if (p)
        {
            for (ltfat_int m = 0; m < Hin; m++ )
            {
                ltfat_int l, count, i, j;

                for (l = 0, count = 0; count != Win; l++)
                {
                    LTFAT_TYPE t = in[Hin * l + m];

                    for (i = l, j = l + p; j != l;
                         i = j, j = j + p < Win ? j + p : j + p - Win, count++)
                        out[Hin * i + m] = out[Hin * j + m];

                    out[Hin * i + m] = t; count++;
                }
            }
        }
    }
    else
    {
        // Still ok if p==0
        memcpy(out,     in + p * Hin, Hin * (Win - p) * sizeof * out);
        memcpy(out + (Win - p) * Hin, in, Hin * p * sizeof * out);
    }

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(circshift2)(const LTFAT_TYPE in[], ltfat_int Hin, ltfat_int Win,
                       ltfat_int shiftRow, ltfat_int shiftCol, LTFAT_TYPE out[])
{
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(circshiftcols)(in, Hin, Win, shiftCol, out));

    for (ltfat_int n = 0; n < Win; n++)
        LTFAT_NAME(circshift)(out + n * Hin, Hin, shiftRow, out + n * Hin);

error:
    return status;

}


// in might be equal to out
LTFAT_API int
LTFAT_NAME(fftshift)(const LTFAT_TYPE* in, ltfat_int L, LTFAT_TYPE* out)
{
    return LTFAT_NAME(circshift)(in, L, (L / 2), out);
}

// in might be equal to out
LTFAT_API int
LTFAT_NAME(ifftshift)(const LTFAT_TYPE* in, ltfat_int L, LTFAT_TYPE* out)
{
    return LTFAT_NAME(circshift)(in, L, -(L / 2), out);
}


LTFAT_API int
LTFAT_NAME(reverse_array)(const LTFAT_TYPE* in, ltfat_int L,
                          LTFAT_TYPE* out)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    if (in == out)
    {
        LTFAT_TYPE tmpVar = (LTFAT_TYPE) 0.0;

        for (ltfat_int ii = 0; ii < L / 2; ii++)
        {
            tmpVar = out[L - 1 - ii];
            out[L - 1 - ii] = out[ii];
            out[ii] = tmpVar;
        }
    }
    else
    {
        for (ltfat_int ii = 0; ii < L; ii++)
            out[ii] = in[L - 1 - ii];
    }

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(conjugate_array)(const LTFAT_TYPE* in, ltfat_int L,
                            LTFAT_TYPE* out)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

#ifdef LTFAT_COMPLEXTYPE
    for (ltfat_int ii = 0; ii < L; ii++)
        out[ii] = conj(in[ii]); // type-generic macro conj
#else
    if (in != out)
        memcpy(out, in, L * sizeof * out);
#endif

error:
    return status;

}

LTFAT_API int
LTFAT_NAME(periodize_array)(const LTFAT_TYPE* in, ltfat_int Lin,
                            ltfat_int Lout, LTFAT_TYPE* out )
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Lin > 0, "Lin must be positive");
    CHECK(LTFATERR_BADSIZE, Lout > 0, "Lout must be positive");

    /* Do nothing if there is no place where to put periodized samples */
    if ( Lout <= Lin )
    {
        if ( in != out )
            memcpy(out, in, Lout * sizeof * in);
    }
    else
    {
        ltfat_int periods =  Lout / Lin;
        ltfat_int lastL = Lout - periods * Lin;
        ltfat_int startPer = in == out ? 1 : 0;

        for (ltfat_int ii = startPer; ii < periods; ii++)
            memcpy(out + ii * Lin, in, Lin * sizeof * in);

        memcpy(out + periods * Lin, in, lastL * sizeof * in);
    }
error:
    return status;
}

/*
  *
 * If offset is not zero, the function performs:
 * fold_array(in,Lin,0,Lfold,out);
 * circshift(out,Lfold,offset,out);
 *
 * or equivalently
 *
 * circshift(in,Lin,offset,in);
 * fold_array(in,Lin,0,Lfold,out);
 *
 * without the intermediate step.
 * */
LTFAT_API int
LTFAT_NAME(fold_array)(const LTFAT_TYPE* in, ltfat_int Lin,
                       ltfat_int offset,
                       ltfat_int Lfold, LTFAT_TYPE* out)
{
    ltfat_int startIdx;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Lin > 0, "Lin must be positive");
    CHECK(LTFATERR_BADSIZE, Lfold > 0, "Lfold must be positive");

    // Sanitize offset.
    startIdx = ltfat_positiverem(offset, Lfold);

    // Clear output, we will use it as an accumulator
    if (in != out)
        LTFAT_NAME(clear_array)(out, Lfold); //memset(out, 0, Lfold * sizeof * out);
    else if (Lfold > Lin)
        LTFAT_NAME(clear_array)(out + Lin,
                                Lfold - Lin); //memset(out + Lin, 0, (Lfold - Lin)*sizeof * out);

    if (!startIdx)
    {
        // Common code for no offset
        ltfat_int startAt = in == out ? Lfold : 0;

        for (ltfat_int ii = startAt; ii < Lin;)
            for (ltfat_int kk = 0; ii < Lin && kk < Lfold; ii++, kk++)
                out[kk] += in[ii];

    }
    else
    {
        if (in == out)
        {
            // We cannot avoid the (slow) inplace circshift anyway.
            // Lets do it after the folding
            LTFAT_NAME(fold_array)(in, Lin, 0, Lfold, out);
            LTFAT_NAME(circshift)(in, Lfold, startIdx, out);
        }
        else
        {
            // We avoid the inplace circshift by effectivelly
            // doing circshift of all blocks
            for (ltfat_int ii = 0; ii < Lin;)
            {
                ltfat_int kk = startIdx;
                for (; kk < Lfold && ii < Lin; ii++, kk++)
                    out[kk] += in[ii];

                for (kk = 0; kk < startIdx && ii < Lin; ii++, kk++)
                    out[kk] += in[ii];
            }
        }
    }
error:
    return status;
}


LTFAT_API int
LTFAT_NAME(ensurecomplex_array)(const LTFAT_TYPE* in,  ltfat_int L,
                                LTFAT_COMPLEX* out)
{
#ifdef LTFAT_COMPLEXTYPE
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    if (in != (LTFAT_TYPE*)out)
        memcpy(out, in, L * sizeof * out);

error:
    return status;
#else
    return LTFAT_NAME_REAL(real2complex_array)(in, L, out);
#endif
}


LTFAT_API void
LTFAT_NAME(dgtphaselockhelper)(LTFAT_TYPE* cin, ltfat_int L,
                               ltfat_int W, ltfat_int a,
                               ltfat_int M, ltfat_int M2,
                               LTFAT_TYPE* cout)
{
    ltfat_int N = L / a;

    for (ltfat_int w = 0; w < W; w++)
    {
        for (ltfat_int n = 0; n < N; n++)
        {
            ltfat_int offset = w * N * M + n * M;
            LTFAT_TYPE* cintmp = cin + offset;
            LTFAT_TYPE* couttmp = cout + offset;
            LTFAT_NAME(circshift)(cintmp, M2, -a * n, couttmp);
        }

    }

}

LTFAT_API void
LTFAT_NAME(dgtphaseunlockhelper)(LTFAT_TYPE* cin, ltfat_int L,
                                 ltfat_int W, ltfat_int a,
                                 ltfat_int M, ltfat_int M2,
                                 LTFAT_TYPE* cout)
{
    ltfat_int N = L / a;

    for (ltfat_int w = 0; w < W; w++)
    {
        for (ltfat_int n = 0; n < N; n++)
        {
            ltfat_int offset = w * N * M + n * M;
            LTFAT_TYPE* cintmp = cin + offset;
            LTFAT_TYPE* couttmp = cout + offset;
            LTFAT_NAME(circshift)(cintmp, M2, a * n, couttmp);
        }

    }

}

LTFAT_API void
LTFAT_NAME(findmaxinarray)(const LTFAT_TYPE* in, ltfat_int L,
                           LTFAT_TYPE* max, ltfat_int* idx)
{
    *max = in[0];
    *idx = 0;

    for (ltfat_int ii = 1; ii < L; ++ii)
    {
#ifdef LTFAT_COMPLEXTYPE

        if ( ltfat_abs(in[ii]) > ltfat_abs(*max) )
#else
        if (in[ii] > *max)
#endif
        {
            *max = in[ii];
            *idx = ii;
        }
    }
}

LTFAT_API int
LTFAT_NAME(findmaxinarraywrtmask)(const LTFAT_TYPE* in, const int* mask,
                                  ltfat_int L, LTFAT_TYPE* max, ltfat_int* idx)
{
    int found = 0;
    *max = (LTFAT_REAL) - 1e99;
    *idx = 0;

    for (ltfat_int ii = 0; ii < L; ++ii)
    {
#ifdef LTFAT_COMPLEXTYPE
        if (!mask[ii] && ltfat_abs(in[ii]) > ltfat_abs(*max))
#else
        if (!mask[ii] && in[ii] > *max)
#endif
        {
            *max = in[ii];
            *idx = ii;
            found = 1;
        }
    }

    return found;
}

LTFAT_API void
LTFAT_NAME(findmaxincols)(const LTFAT_TYPE* in, ltfat_int M, ltfat_int M2,
                          ltfat_int N, LTFAT_TYPE* max, ltfat_int* idx)
{
    for (ltfat_int n = 0; n < N; n++)
        LTFAT_NAME(findmaxinarray)(in + n * M, M2, max + n, idx + n);
}

LTFAT_API int
LTFAT_NAME(fir2long)(const LTFAT_TYPE* in, ltfat_int Lfir,
                     ltfat_int Llong, LTFAT_TYPE* out)
{
    ltfat_div_t domod;
    ltfat_int ss;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Llong > 0, "Llong must be positive");
    CHECK(LTFATERR_BADSIZE, Lfir > 0, "Lfir must be positive");
    CHECK(LTFATERR_BADREQSIZE, Lfir <= Llong, "Lfir <= Llong does not hold");

    domod = ltfat_idiv(Lfir, 2);

    /* ---- In the odd case, the additional element is kept in the first half. ---*/

    // Copy first half
    if (in != out)
        memcpy(out, in, (domod.quot + domod.rem)*sizeof * out);

    ss = Llong - Lfir;
    // Copy second half from the back
    for (ltfat_int ii = Lfir - 1; ii >= domod.quot + domod.rem; ii--)
        out[ii + ss] = in[ii];

    // Zero out the middle
    for (ltfat_int ii = domod.quot + domod.rem; ii < Llong - domod.quot ; ii++)
        out[ii] = 0.0;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(long2fir)(const LTFAT_TYPE* in, ltfat_int Llong,
                     ltfat_int Lfir, LTFAT_TYPE* out)
{
    ltfat_div_t domod;
    ltfat_int ss;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Llong > 0, "Llong must be positive");
    CHECK(LTFATERR_BADSIZE, Lfir > 0, "Lfir must be positive");
    CHECK(LTFATERR_BADREQSIZE, Lfir <= Llong, "Lfir <= Llong does not hold");

    domod = ltfat_idiv(Lfir, 2);

    /* ---- In the odd case, the additional element is kept in the first half. ---*/

    ss = Llong - Lfir;

    if (in != out)
        memcpy(out, in, (domod.quot + domod.rem)*sizeof * out);

    for (ltfat_int ii = domod.quot + domod.rem; ii < Lfir; ii++)
        out[ii] = in[ii + ss];

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(middlepad)(const LTFAT_TYPE* in, ltfat_int Lin, ltfat_symmetry_t sym,
                      ltfat_int Lout, LTFAT_TYPE* out)
{
    int status = LTFATERR_FAILED;
    LTFAT_TYPE middlepoint;
    LTFAT_REAL oneover2 = (LTFAT_REAL) (1.0 / 2.0);

    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Lin > 0, "Lin must be positive");
    CHECK(LTFATERR_BADSIZE, Lout > 0, "Lout must be positive");

    CHECK(LTFATERR_BADSIZE, !( Lin == 1 && sym == LTFAT_HALFPOINT ),
          "HP symmetry not supported for Lin=1");

    if (Lin == Lout)
    {
        if (in != (const LTFAT_TYPE*) out)
            memcpy(out, in, Lout * sizeof * out);

        return LTFATERR_SUCCESS;
    }

    if (Lin == 1)
    {
        out[0] = in[0];
        LTFAT_NAME(clear_array)(out + 1,
                                Lout - 1);//memset(out + 1, 0, (Lout - 1) * sizeof * out);
        return LTFATERR_SUCCESS;
    }

    switch (sym)
    {
    case LTFAT_HALFPOINT:
        if (Lin > Lout)
        {
            if ( Lout % 2 == 1 )
            {
                middlepoint = oneover2 * ( in[(Lout + 1) / 2 - 1] + in[Lin -
                                           (Lout - 1) / 2 - 1] );
                LTFAT_NAME(long2fir)(in, Lin, Lout, out);
                out[(Lout - 1) / 2] = middlepoint;
            }
            else
                LTFAT_NAME(long2fir)(in, Lin, Lout, out);
        }
        else
        {
            if ( Lin % 2 == 1 )
            {
                middlepoint = in[Lin / 2] * oneover2;
                LTFAT_NAME(fir2long)(in, Lin, Lout, out);
                out[(Lin + 1) / 2 - 1] = middlepoint;
                out[Lout  - (Lin - 1) / 2 - 1] = middlepoint;
            }
            else
                LTFAT_NAME(fir2long)(in, Lin, Lout, out);
        }
        break;
    case LTFAT_WHOLEPOINT:
    default:
        if (Lin > Lout)
        {
            if ( Lout % 2 == 0 )
            {
                middlepoint = oneover2 * ( in[Lout / 2] + in[Lin - Lout / 2] );
                LTFAT_NAME(long2fir)(in, Lin, Lout, out);
                out[Lout / 2] = middlepoint;
            }
            else
                LTFAT_NAME(long2fir)(in, Lin, Lout, out);
        }
        else
        {
            if ( Lin % 2 == 0 )
            {
                middlepoint = in[Lin / 2] * oneover2;
                LTFAT_NAME(fir2long)(in, Lin, Lout, out);
                out[Lin / 2] = middlepoint;
                out[Lout  - Lin / 2] = middlepoint;
            }
            else
                LTFAT_NAME(fir2long)(in, Lin, Lout, out);
        }
        break;
    }

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(reflect)(const LTFAT_TYPE* in, ltfat_int L,
                    LTFAT_TYPE* out)
{
    int status = LTFATERR_SUCCESS;
    CHECKSTATUS( LTFAT_NAME(reverse_array)(in + 1, L, out + 1));
    if ( in != out) out[0] = in[0];
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(involute)(const LTFAT_TYPE* in, ltfat_int L,
                     LTFAT_TYPE* out)
{
    int status = LTFATERR_SUCCESS;
    CHECKSTATUS(LTFAT_NAME(reflect)(in, L, out));
    LTFAT_NAME(conjugate_array)(in, L, out);
error:
    return status;
}

/* LTFAT_API int */
/* LTFAT_NAME(middlepad2d)(const LTFAT_TYPE* in, ltfat_int Hin, ltfat_int Win, */
/*                         ltfat_symmetry_t sym, ltfat_int Hout, ltfat_int Wout, */
/*                         LTFAT_TYPE* out) */
/* { */
/*     int status = LTFATERR_SUCCESS; */
/*  */
/*  */
/*  */
/* error: */
/*     return status; */
/* } */

LTFAT_API int
LTFAT_NAME(norm)(const LTFAT_TYPE* in, ltfat_int L,
                 ltfat_norm_t flag, LTFAT_REAL* norm)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(norm);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    *norm = 0.0;

    switch (flag)
    {
    case LTFAT_NORM_ENERGY:
    {
        for (ltfat_int ii = 0; ii < L; ii++)
        {
#ifdef LTFAT_COMPLEXTYPE
            LTFAT_REAL inAbs = ltfat_abs(in[ii]);
#else
            LTFAT_REAL inAbs = in[ii]; // We dont need abs here
#endif
            *norm += inAbs * inAbs;
        }

        *norm = sqrt(*norm);
        break;
    }
    case LTFAT_NORM_AREA:
    {
        for (ltfat_int ii = 0; ii < L; ii++)
        {
            LTFAT_REAL inAbs = ltfat_abs(in[ii]);
            *norm += inAbs;
        }
        break;
    }
    case LTFAT_NORM_PEAK:
    {

        for (ltfat_int ii = 0; ii < L; ii++)
        {
            LTFAT_REAL inAbs = ltfat_abs(in[ii]);
            if (inAbs > *norm)
                *norm = inAbs;
        }
        break;

    }
    break;
    case LTFAT_NORM_NULL:
        *norm = 1.0;
        break;
    default:
        CHECKCANTHAPPEN("Unknown normalization flag");
    };

error:
    return status;
}


LTFAT_API int
LTFAT_NAME(snr)(const LTFAT_TYPE* in, const LTFAT_TYPE* rec,
                ltfat_int L, LTFAT_REAL* snr)
{
    int status = LTFATERR_SUCCESS;
    long double innorm = 0.0;
    long double errnorm = 0.0;
    CHECKNULL(in); CHECKNULL(rec); CHECKNULL(snr);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");
    *snr = 0.0;

    for (ltfat_int ii = 0; ii < L; ii++)
    {
#ifdef LTFAT_COMPLEXTYPE
        LTFAT_REAL inAbs = ltfat_abs(in[ii]);
#else
        LTFAT_REAL inAbs = in[ii]; // We dont need abs here
#endif
        innorm += inAbs * inAbs;
    }

    for (ltfat_int ii = 0; ii < L; ii++)
    {
#ifdef LTFAT_COMPLEXTYPE
        LTFAT_REAL errAbs = ltfat_abs(in[ii] - rec[ii]);
#else
        LTFAT_REAL errAbs = in[ii] - rec[ii]; // We dont need abs here
#endif
        errnorm += errAbs * errAbs;
    }


    *snr = (LTFAT_REAL) (10.0 * log10l( innorm / errnorm));
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(normalize)(const LTFAT_TYPE* in, ltfat_int L,
                      ltfat_norm_t flag, LTFAT_TYPE* out)
{
    LTFAT_REAL normfac;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    normfac = 1.0;

    CHECKSTATUS(LTFAT_NAME(norm)(in, L, flag, &normfac));

    normfac = (LTFAT_REAL)(1.0) / normfac;

    for (ltfat_int ii = 0; ii < L; ii++)
        out[ii] = normfac * in[ii];

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(peakpad)(const LTFAT_TYPE* in, ltfat_int Lin, ltfat_int Lout,
                    LTFAT_TYPE* out)
{
    int status = LTFATERR_FAILED;
    ltfat_div_t domod;

    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, Lin > 0, "Lin must be positive");
    CHECK(LTFATERR_BADSIZE, Lout > 0, "Lout must be positive");

    if (Lout > Lin)
    {
        domod = ltfat_idiv(Lout - Lin, 2);
        LTFAT_TYPE initpoint = in[0];
        if (in != (const LTFAT_TYPE*) out)
            memcpy(out +  domod.quot, in, Lin * sizeof * out);
        else
            for (ltfat_int l = 0; l < Lin; l++)
                out[Lout - domod.quot - l] = out[Lin - 1 - l];

        for (ltfat_int l = 0; l < domod.quot; l++)
            out[l] = initpoint;

        for (ltfat_int l = 0; l < domod.quot; l++)
            out[Lout - domod.quot + l] = initpoint;

    }
    else if (Lout < Lin)
    {
        domod = ltfat_idiv(Lin - Lout, 2);
        if (in != (const LTFAT_TYPE*) out)
            memcpy(out, in + domod.quot, Lout * sizeof * out);
        else
            for (ltfat_int l = 0; l < Lout; l++)
                out[l] = out[l + domod.quot];
    }
    else if (in != (const LTFAT_TYPE*) out)
        memcpy(out, in, Lin * sizeof * in);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(log_array)(const LTFAT_TYPE in[], ltfat_int L, LTFAT_TYPE out[])
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");

    for (ltfat_int l = 0; l < L; l++ )
        out[l] = log(in[l] + LTFAT_REAL_MIN);

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(clear_array)(LTFAT_TYPE* in, ltfat_int L)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(in);
    CHECK(LTFATERR_BADSIZE, L >= 0, "L must be nonegative");
    if (L == 0) return status;

#ifdef __cplusplus
    std::fill(in, in + L, LTFAT_TYPE {} );
#else
    memset(in, 0, L * sizeof * in);
#endif

error:
    return status;
}


/* LTFAT_API int */
/* LTFAT_NAME(postpad)(const LTFAT_TYPE* in, ltfat_int Ls, ltfat_int W, */
/*                     ltfat_int L, LTFAT_TYPE* out) */
/* { */
/*     int status = LTFATERR_SUCCESS; */
/*     CHECKNULL(in); CHECKNULL(out); */
/*     CHECK(LTFATERR_NOTPOSARG, Ls > 0, "Ls must be positive"); */
/*     CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive"); */
/*     CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive"); */
/*  */
/*     if (in == out) */
/*     { */
/*         LTFAT_TYPE* outTmp = ltfat_malloc(L * W * sizeof * out); */
/*         CHECKMEM(outTmp); */
/*     } */
/*     else */
/*     { */
/*         outTmp = out; */
/*     } */
/*  */
/*     ltfat_int Lcom = (Ls < L ? Ls : L); */
/*     ltfat_int Lrem = L - Lcom; */
/*  */
/*     for (ltfat_int w = 0; w < W; w++) */
/*     { */
/*         memcpy(outTmp + w * L, in + w * Ls, Lcom * sizeof * out); */
/*         memset(outTmp + w * L + Ls, 0, Lrem * sizeof * out); */
/*     } */
/*  */
/*     if (in == out) */
/*     { */
/*         ltfat_free(in); */
/*         out = outTmp; */
/*     } */
/*  */
/* error: */
/*     return status; */
/* } */



/* LTFAT_API LTFAT_REAL */
/* LTFAT_NAME(norm)(const LTFAT_TYPE in[], ltfat_int L, */
/*                  ltfat_norm_t flag) */
/* { */
/*     double retNorm = 0.0; */
/*  */
/*     switch (flag) */
/*     { */
/*     case LTFAT_NORM_ENERGY: */
/*     { */
/*         for (ltfat_int ii = 0; ii < L; ii++) */
/*         { */
/* #ifdef LTFAT_COMPLEXTYPE */
/*             double inTmp = fabs(in[ii]); */
/*             retNorm += in[ii] * in[ii]; */
/* #else */
/*             retNorm += in[ii] * in[ii]; */
/* #endif */
/*         } */
/*     } */
/*     }; */
/*  */
/*     return (LTFAT_REAL) sqrt(retNorm); */
/* } */
