#include "ltfat.h"
#include "ltfat/macros.h"

LTFAT_API void
ltfat_fftindex(ltfat_int N, ltfat_int* indexout)
{
    ltfat_int ii;

    if (N % 2 == 0)
    {
        for (ii = 0; ii < N / 2 + 1; ii++)
        {
            indexout[ii] = ii;
        }
        for (ii = N / 2; ii < N - 1; ii++)
        {
            indexout[ii + 1] = -N + ii + 1;
        }
    }
    else
    {
        for (ii = 0; ii < (N - 1) / 2 + 1; ii++)
        {
            indexout[ii] = ii;
        }
        for (ii = (N - 1) / 2; ii < N - 1; ii++)
        {
            indexout[ii + 1] = -N + ii + 1;
        }
    }
}

LTFAT_API ltfat_int
ltfat_imax(ltfat_int a, ltfat_int b)
{
    return (a > b ? a : b);
}

LTFAT_API ltfat_int
ltfat_imin(ltfat_int a, ltfat_int b)
{
    return (a < b ? a : b);
}

LTFAT_API ltfat_div_t
ltfat_idiv(ltfat_int a, ltfat_int b)
{
    ltfat_div_t ret;
    ret.quot = a / b;
    ret.rem = a % b;
    return ret;
}

LTFAT_API ltfat_int
ltfat_idivceil(ltfat_int a, ltfat_int b)
{
    return a / b + (a % b > 0);
}

LTFAT_API ltfat_int
makelarger(ltfat_int L, ltfat_int K)
{
    /* This is a floor operation */
    ltfat_int o = (L / K) * K;

    /* Make it a ceil */
    if (L % K > 0)
    {
        o += K;
    }

    return o;
}

/* Extended Euclid algorithm. */
LTFAT_API ltfat_int
ltfat_gcd (ltfat_int a, ltfat_int b, ltfat_int* r, ltfat_int* s )
{
    ltfat_int a1 = a;
    ltfat_int b1 = b;
    ltfat_int a2 = 1;
    ltfat_int b2 = 0;
    ltfat_int a3 = 0;
    ltfat_int b3 = 1;
    ltfat_int c, d;
    while ( b1 != 0 )
    {
        d = a1 / b1;
        c = a1;
        a1 = b1;
        b1 = c - d * b1;

        c = a2;
        a2 = b2;
        b2 = c - d * b2;

        c = a3;
        a3 = b3;
        b3 = c - d * b3;

    }

    *r = a2;
    *s = a3;
    return a1;
}

LTFAT_API ltfat_int
ltfat_lcm(ltfat_int a, ltfat_int b)
{
    ltfat_int junk_r, junk_s;

    ltfat_int c = ltfat_gcd(a, b, &junk_r, &junk_s);

    return (a * b / c);
}

LTFAT_API ltfat_int
ltfat_dgtlength(ltfat_int Ls, ltfat_int a, ltfat_int M)
{
    ltfat_int minL = ltfat_lcm(a, M);
    ltfat_int nminL = (Ls + minL - 1) / minL; // This is ceil of Ls/minL
    return nminL * minL;
}

LTFAT_API ltfat_int
ltfat_dgtlengthmulti(ltfat_int Ls, ltfat_int P, ltfat_int a[], ltfat_int M[])
{
    ltfat_int minL = ltfat_lcm( a[0], M[0]);

    for (ltfat_int p = 1; p < P; p++)
    {
        minL = ltfat_lcm( minL, a[p]);
        minL = ltfat_lcm( minL, M[p]);
    }

    ltfat_int nminL = (Ls + minL - 1) / minL; // This is ceil of Ls/minL
    return nminL * minL;
}


LTFAT_API void
gabimagepars(ltfat_int Ls, ltfat_int x, ltfat_int y,
             ltfat_int* a, ltfat_int* M, ltfat_int* L, ltfat_int* N, ltfat_int* Ngood)
{


    *M = ltfat_imin(y, Ls);
    *N = ltfat_imax(x, Ls);

    /* Determine the minimum transform size. */
    ltfat_int K = ltfat_lcm(*M, *N);

    /* This L is good, but is it not the same as DGT will choose. */
    ltfat_int Llong = makelarger(Ls, K);

    /* Fix a from the long L */
    *a = Llong / (*N);

    /* Now we have fixed a and M, so we can use the standard method of choosing L. */
    ltfat_int Lsmallest = ltfat_lcm(*a, *M);
    *L = makelarger(Ls, Lsmallest);

    /* We did not get N as desired. */
    *N = *L / (*a);

    /* Number of columns to display */
    *Ngood = (Ls / (*a));
}

/* Determine the size of the output array of wfacreal and iwfacreal */
LTFAT_API ltfat_int
wfacreal_size(ltfat_int L, ltfat_int a, ltfat_int M)
{

    ltfat_int h_a, h_m;

    ltfat_int b = L / M;
    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int d = b / p;

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    return d2 * p * M;

}

LTFAT_API ltfat_int
ltfat_nextpow2(ltfat_int y)
{
    ltfat_int x = (ltfat_int) y;
    ltfat_int bits = sizeof(x) * 8;

    if (x == 0)
        return 1;

    x--;
    for (ltfat_int ii = 1; ii < bits; ii = ii << 1)
        (x) = ((x) >> ii)  | (x);

    /* (x) = ((x) >> 1)  | (x); */
    /* (x) = ((x) >> 2)  | (x); */
    /* (x) = ((x) >> 4)  | (x); */
    /* (x) = ((x) >> 8)  | (x); */
    /* (x) = ((x) >> 16) | (x); */
    /* if (bits > 32) */
    /*     (x) = ((x) >> 32) | (x); */

    (x)++;
    return x;
}

LTFAT_API ltfat_int
ltfat_nextfastfft(ltfat_int x)
{
    ltfat_int xtmp = x;
    while (1)
    {
        ltfat_int m = xtmp;

        while ((m % 2) == 0)
            m /= 2;
        while ((m % 3) == 0)
            m /= 3;
        while ((m % 5) == 0)
            m /= 5;
        if (m <= 1)
            break;                    /* n is completely factorable by twos, threes, and fives */
        xtmp++;
    }
    return xtmp;
}

LTFAT_API ltfat_int
ltfat_pow2(ltfat_int x)
{
    return (((ltfat_int)1) << (x));
}

LTFAT_API int
ltfat_ispow2(ltfat_int x)
{
    return x == ltfat_nextpow2(x);
}


LTFAT_API ltfat_int
ltfat_modpow2(ltfat_int x, ltfat_int pow2var)
{
    return ((x) & (pow2var - 1));
}

LTFAT_API ltfat_int
ltfat_pow2base(ltfat_int x)
{
    ltfat_int y = 0;
    ltfat_int xtmp = x;
    while (xtmp > 0 && !(xtmp & 1))
    {
        xtmp >>= 1;
        y++;
    }

    return y;
}




/* LTFAT_API int */
/* isPow2(ltfat_int x) */
/* { */
/*     return x == ltfat_nextpow2(x); */
/* } */
/*  */
/* LTFAT_API ltfat_int */
/* ilog2(ltfat_int x) */
/* { */
/*     ltfat_int tmp = 0; */
/*     ltfat_int xtmp = x; */
/*     while (xtmp >>= 1) ++tmp; */
/*     return tmp; */
/* } */
/*  */
/* // integer power by squaring */
/* LTFAT_API ltfat_int */
/* ipow(ltfat_int base, ltfat_int exp) */
/* { */
/*     ltfat_int baseTmp = (ltfat_int) base; */
/*     ltfat_int expTmp = (ltfat_int) exp; */
/*     ltfat_int result = 1; */
/*  */
/*     while (expTmp) */
/*     { */
/*         if (expTmp & 1) */
/*             result *= baseTmp; */
/*         expTmp >>= 1; */
/*         baseTmp *= baseTmp; */
/*     } */
/*  */
/*     return result; */
/* } */

LTFAT_API ltfat_int
filterbank_td_size(ltfat_int L, ltfat_int a, ltfat_int gl,
                   ltfat_int offset, const ltfatExtType ext)
{
    ltfat_int Lc = 0;
    if (ext == PER)
    {
        Lc = (ltfat_int) ceil( L / ((double)a) );
    }
    else if (ext == VALID)
    {
        Lc = (ltfat_int) ceil( (L - (gl - 1)) / ((double)a) );

    }
    else
    {
        Lc = (ltfat_int) ceil( (L + gl - 1 + offset ) / ((double)a) );
    }
    return Lc;
}

LTFAT_API ltfat_int
ltfat_round(const double x)
{
    if (x < 0.0)
        return (ltfat_int)(x - 0.5);
    else
        return (ltfat_int)(x + 0.5);
}

LTFAT_API ltfat_int
ltfat_positiverem(ltfat_int a, ltfat_int b)
{
    ltfat_int c = a % b;
    return (c < 0 ? c + b : c);
}

LTFAT_API ltfat_int
ltfat_posnumfastmod(ltfat_int a, ltfat_int b)
{
#ifndef NDEBUG
    int status = LTFATERR_SUCCESS;
    CHECK(LTFATERR_BADARG, a >= 0 && b >= 0, "Negative number passed.");
    return ( a >= b ? a % b : a);
error:
    return status;
#endif
    return ( a >= b ? a % b : a);
}

LTFAT_API ltfat_int
ltfat_rangelimit(ltfat_int a, ltfat_int amin, ltfat_int amax)
{
    ltfat_int c = a < amin ? amin : a;
    c = c > amax ? amax : c;
    return c;
}
