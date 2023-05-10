#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtrealmp_private.h"


int
LTFAT_NAME(dgtrealmp_kernel_init)(
    const LTFAT_REAL* g[], ltfat_int gl[], ltfat_int a[], ltfat_int M[],
    ltfat_int L, LTFAT_REAL reltol, ltfat_phaseconvention ptype,
    LTFAT_NAME(kerns)** pout)
{
    ltfat_int modNo, amin, Mmax, lefttail0, righttail0, lefttail1, righttail1,
              Lshort, Nshort;
    LTFAT_REAL* g0tmp = NULL, *g1tmp = NULL;
    LTFAT_COMPLEX* kernlarge = NULL;
    LTFAT_NAME(kerns)* ktmp = NULL;
    ltfat_int kernskip = 1;
    LTFAT_COMPLEX* kvalwmid;
    int status = LTFATERR_SUCCESS;

    CHECKMEM( ktmp = LTFAT_NEW(LTFAT_NAME(kerns)) );
    ktmp->arat = 1.0; ktmp->Mrat = 1.0; ktmp->kSkip = 1;
    ktmp->ptype = ptype;

    ktmp->Mrat = ((double) M[0]) / M[1];
    ktmp->arat = ((double) a[1]) / a[0];

    amin = ltfat_imin(a[0], a[1]);
    Mmax = ltfat_imax(M[0], M[1]);

    LTFAT_NAME(dgtrealmp_essentialsupport)(g[0], gl[0], (LTFAT_REAL) 1e-6, &lefttail0,
                                           &righttail0);
    LTFAT_NAME(dgtrealmp_essentialsupport)(g[1], gl[1], (LTFAT_REAL) 1e-6, &lefttail1,
                                           &righttail1);

    Lshort = 2 * ltfat_imax(lefttail0, righttail0) +
             2 * ltfat_imax(lefttail1, righttail1);

    Lshort = ltfat_dgtlength( ltfat_imin(Lshort, L), amin, Mmax);
    /* Lshort = 2048; */

    Nshort = Lshort / amin;

    CHECKMEM(g0tmp     = LTFAT_NAME_REAL(malloc)(Lshort));
    CHECKMEM(g1tmp     = LTFAT_NAME_REAL(malloc)(Lshort));
    CHECKMEM(kernlarge = LTFAT_NAME_COMPLEX(malloc)(Mmax * Nshort));

    LTFAT_NAME(middlepad)(g[0], gl[0], LTFAT_WHOLEPOINT, Lshort, g0tmp);
    LTFAT_NAME(middlepad)(g[1], gl[1], LTFAT_WHOLEPOINT, Lshort, g1tmp);

    LTFAT_NAME_REAL(dgtreal_fb)(g0tmp, g1tmp, Lshort, Lshort, 1, amin, Mmax,
                                ptype, kernlarge);
    LTFAT_NAME_COMPLEX(dgtreal2dgt)(kernlarge,Mmax,Nshort,kernlarge);

    LTFAT_NAME(dgtrealmp_kernel_findsmallsize)(
        kernlarge, Mmax, Nshort, reltol, &ktmp->absthr, &ktmp->size, &ktmp->mid);

    LTFAT_NAME_COMPLEX(circshift2)(
        kernlarge, Mmax, Nshort, ktmp->mid.hmid, ktmp->mid.wmid, kernlarge);

    modNo = ltfat_lcm(amin, Mmax) / amin;

    ktmp->Mstep = ktmp->Mrat > 1 ? (ltfat_int) ktmp->Mrat : 1;
    ktmp->astep = ktmp->arat > 1 ? (ltfat_int) ktmp->arat : 1;

    if (ptype == LTFAT_FREQINV)
    {
        if (ktmp->arat < 1.0)
        {
            modNo = ltfat_lcm(amin, Mmax) / a[0];
            kernskip = (ltfat_int)(1.0 / ktmp->arat);//  a[0] / a[1];
        }
    }
    else if (ptype == LTFAT_TIMEINV)
    {
        if (ktmp->Mrat < 1.0)
        {
            modNo = (ltfat_int)(modNo * ktmp->Mrat);
            kernskip = (ltfat_int)(1.0/ktmp->Mrat);//M[1] / M[0];
        }
    }

    ktmp->kNo = modNo;

    DEBUG("h=%td,w=%td,hmid=%td,wmid=%td,kno=%td,a0=%td,a1=%td,M1=%td,M2=%td,"
          "astep=%td,Mstep=%td,arat=%.2f,Mrat=%.2f,Lmin=%td",
          ktmp->size.height, ktmp->size.width, ktmp->mid.hmid, ktmp->mid.wmid, modNo,
          a[0], a[1], M[0], M[1],
          ktmp->astep, ktmp->Mstep, ktmp->arat, ktmp->Mrat, Lshort);

    CHECKMEM( ktmp->kval =
                  LTFAT_NAME_COMPLEX(malloc)( ktmp->size.height * ktmp->size.width));
    CHECKMEM( ktmp->range =
                  LTFAT_NEWARRAY(krange, ktmp->size.width) );
    CHECKMEM( ktmp->srange =
                  LTFAT_NEWARRAY(krange, ktmp->size.width) );
    CHECKMEM( ktmp->mods = LTFAT_NEWARRAY(LTFAT_COMPLEX*, ktmp->kNo));

    if (ptype == LTFAT_FREQINV)
        for (ltfat_int k = 0; k < ktmp->kNo; k++)
            CHECKMEM(ktmp->mods[k] = LTFAT_NAME_COMPLEX(malloc)(ktmp->size.height));
    else if (ptype == LTFAT_TIMEINV)
        for (ltfat_int k = 0; k < ktmp->kNo; k++)
            CHECKMEM(ktmp->mods[k] = LTFAT_NAME_COMPLEX(malloc)(ktmp->size.width));

    // Copy the zero-th kernel
    for (ltfat_int n = 0; n < ktmp->size.width; n++)
        memcpy(ktmp->kval + n * ktmp->size.height,
               kernlarge + n * Mmax, ktmp->size.height * sizeof * kernlarge);

        /* LTFAT_COMPLEX kk = *( ktmp->kval + ktmp->mid.hmid + ktmp->mid.wmid * ktmp->size.height); */
        /* DEBUG("re=%.3f,im=%.3f", ltfat_real(kk),ltfat_imag(kk)); */


    if (ptype == LTFAT_FREQINV)
        for (ltfat_int n = 0; n < ktmp->kNo; n++)
            LTFAT_NAME(dgtrealmp_kernel_modfiexp)(
                ktmp->size, ktmp->mid, n * kernskip , amin, Mmax, ktmp->mods[n]);
    else if (ptype == LTFAT_TIMEINV)
        for (ltfat_int m = 0; m < ktmp->kNo; m++)
            LTFAT_NAME(dgtrealmp_kernel_modtiexp)(
                ktmp->size, ktmp->mid, m * kernskip, amin, Mmax, ktmp->mods[m]);


    // Compute ranges of values in the columns ...
    for (ltfat_int knidx = 0; knidx < ktmp->size.width; knidx++)
    {
        ktmp->range[knidx].start = 0;
        ktmp->range[knidx].end   = 0;
        LTFAT_COMPLEX* kcol      = ktmp->kval + knidx * ktmp->size.height;

        for (ltfat_int kmidx = 0; kmidx < ktmp->size.height; kmidx++)
            if ( ltfat_norm(kcol[kmidx]) > ktmp->absthr )
            { ktmp->range[knidx].start = kmidx; break; }

        for (ltfat_int kmidx = 0; kmidx < ktmp->size.height; kmidx++)
            if ( ltfat_norm(kcol[ktmp->size.height - 1 - kmidx ]) > ktmp->absthr )
            { ktmp->range[knidx].end = kmidx; break; }

        ktmp->srange[knidx].start = ktmp->range[knidx].start / ktmp->Mstep;
        ktmp->srange[knidx].end =   ktmp->range[knidx].end / ktmp->Mstep;
    }

    // Prepare inner products between conjugated atoms
    kvalwmid = &ktmp->kval[ktmp->size.height * ktmp->mid.wmid]; 
    ktmp->atprodsNo = ltfat_idivceil( ktmp->size.height, 2);
    CHECKMEM( ktmp->atprods = LTFAT_NAME_COMPLEX(calloc)( ktmp->atprodsNo  ));
    CHECKMEM( ktmp->oneover1minatprodnorms =
                  LTFAT_NAME_REAL(calloc)( ktmp->atprodsNo ));

    ktmp->atprodsNo = 1;
    for (ltfat_int m = ktmp->mid.hmid - 2;
         m >= ktmp->range[ktmp->mid.wmid].start;
         m -= 2, ktmp->atprodsNo++  )
    {
        ktmp->atprods[ktmp->atprodsNo] = kvalwmid[m];
        ktmp->oneover1minatprodnorms[ktmp->atprodsNo] = 
			(LTFAT_REAL)(1.0 / (1.0 - ltfat_norm(kvalwmid[m])));
    }
    ktmp->atprods[0] = 0.0;
    ktmp->oneover1minatprodnorms[0] = 1.0;


    *pout = ktmp;
    LTFAT_SAFEFREEALL(g0tmp, g1tmp, kernlarge);
    return status;
error:
    LTFAT_SAFEFREEALL(g0tmp, g1tmp, kernlarge);
    if (ktmp) LTFAT_NAME(dgtrealmp_kernel_done)(&ktmp);
    return status;
}

int
LTFAT_NAME(dgtrealmp_kernel_done)(LTFAT_NAME(kerns)** k)
{
    LTFAT_NAME(kerns)* kk;
    int status = LTFATERR_SUCCESS;

    CHECKNULL(k); CHECKNULL(*k);
    kk = *k;

    /* for (ltfat_int kIdx = 0; kIdx < kk->kNo; kIdx++) */
    /*     ltfat_safefree( kk->kval[kIdx] ); */

    if(kk->cloned == 0)
    {
        ltfat_safefree(kk->kval);
    LTFAT_SAFEFREEALL( kk->range, kk->srange, kk->atprods,
                      kk->oneover1minatprodnorms);

    if (kk->mods)
    {
        for (ltfat_int kIdx = 0; kIdx < kk->kNo; kIdx++)
            ltfat_safefree( kk->mods[kIdx] );
        ltfat_free(kk->mods);
    }
    

    ltfat_safefree(kk);
    }
    *k = NULL;
error:
    return status;
}

int
LTFAT_NAME(dgtrealmp_kernel_modfiexp)(
    ksize size, kanchor mid, ltfat_int n, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod)
{
    for (ltfat_int m = 0; m < size.height; m++ )
    {
        ltfat_int xval = m - mid.hmid;
        LTFAT_REAL exparg = (LTFAT_REAL) ( -2.0 * M_PI * n * xval * a / ((double) M));
        kmod[m] = exp( I * exparg);
    }
    return 0;
}

int
LTFAT_NAME(dgtrealmp_kernel_modtiexp)(
    ksize size, kanchor mid, ltfat_int m, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod)
{
    for (ltfat_int nn = 0; nn < size.width; nn++)
    {
        ltfat_int xval = nn - mid.wmid;
        LTFAT_REAL exparg = (LTFAT_REAL) (2.0 * M_PI * m * xval * a / ((double) M));
        kmod[nn] = exp( I * exparg );
    }
    return 0;
}

int
LTFAT_NAME(dgtrealmp_essentialsupport)(
    const LTFAT_REAL g[], ltfat_int gl, LTFAT_REAL reltol,
    ltfat_int* lefttail, ltfat_int* righttail)
{
    ltfat_int gl2 = gl / 2 + 1;
    LTFAT_REAL gthr;
    LTFAT_TYPE gmax;
    ltfat_int gmaxPos;

    LTFAT_NAME_REAL(findmaxinarray)(g, gl, &gmax, &gmaxPos);
    gthr = gmax * reltol;

    *righttail = 0;
    *lefttail  = 0;

    for (ltfat_int l = 0; l < gl2; l++)
        if (g[l] > gthr)
            *righttail = l + 1;

    for (ltfat_int l = gl - 1; l >= gl2; l--)
        if (g[l] > gthr)
            *lefttail = gl - l;

    return 0;
}

int
LTFAT_NAME(dgtrealmp_kernel_findsmallsize)(
    const LTFAT_COMPLEX kernlarge[], ltfat_int M, ltfat_int N, LTFAT_REAL reltol,
    LTFAT_REAL* absthr, ksize* size, kanchor* anchor)
{
    LTFAT_COMPLEX maxcoef;
    ltfat_int maxcoefIdx, lastrow = 0, lastcol1 = 0, lastcol2 = -1, M2;
    size->width = 0; size->height = 0;
    anchor->hmid = 0; anchor->wmid = 0;
    M2 = M / 2 + 1; 

    LTFAT_NAME_COMPLEX(findmaxinarray)(kernlarge, M * N, &maxcoef, &maxcoefIdx);

    *absthr = reltol * reltol * ltfat_norm(maxcoef);

    for (ltfat_int n = 0; n < N; n++)
    {
        const LTFAT_COMPLEX* kernlargeCol = kernlarge + n * M;

        for (ltfat_int m = 0; m < M2; m++)
            if ( ltfat_norm(kernlargeCol[m]) > *absthr && m > lastrow )
                lastrow = m;
    }

    for (ltfat_int m = 0; m <= lastrow; m++)
    {
        const LTFAT_COMPLEX* kernlargeRow1 = kernlarge + m;
        const LTFAT_COMPLEX* kernlargeRow2 = kernlarge + (N - 1) * M + m;

        for (ltfat_int n = lastcol1; n < N / 2 + N % 2; n++)
        {
            if ( ltfat_norm(kernlargeRow1[n * M]) > *absthr && n > lastcol1 )
            {
                lastcol1 = n;
            }
        }

        for (ltfat_int n = lastcol2 + 1; n < N / 2; n++)
        {
            if ( ltfat_norm(kernlargeRow2[-n * M]) > *absthr && n > lastcol2 )
            {
                lastcol2 = n;
            }
        }
    }

    size->height = ltfat_imin( 2 * (lastrow + 1) - 1  , M);
    size->width  = ltfat_imin( lastcol1 + lastcol2 + 2 , N);

    anchor->hmid = lastrow;
    anchor->wmid = lastcol2 + 1;


    return 0;
}

/* int */
/* LTFAT_NAME(dgtrealmp_kernel_cloneconj)( */
/*     LTFAT_NAME(kerns)* kin, LTFAT_NAME(kerns)** kout) */
/* { */
/*     LTFAT_NAME(kerns)* ktmp = NULL; */
/*     int status = LTFATERR_FAILED; */
/*  */
/*     CHECKMEM( ktmp = LTFAT_NEW(LTFAT_NAME(kerns)) ); */
/*     *ktmp = *kin; */
/*  */
/*     #<{(| CHECKMEM( ktmp->kval = LTFAT_NAME_COMPLEX(malloc)(ktmp->size.width * ktmp->size.height) ); |)}># */
/*  */
/*     #<{(| LTFAT_NAME_COMPLEX(conjugate_array)(kin->kval,ktmp->size.width * ktmp->size.height,ktmp->kval ); |)}># */
/*     ktmp->Mrat = 1.0 / ktmp->Mrat; */
/*     ktmp->arat = 1.0 / ktmp->arat; */
/*     ktmp->Mstep = ktmp->Mrat > 1 ? (ltfat_int) ktmp->Mrat : 1; */
/*     ktmp->astep = ktmp->arat > 1 ? (ltfat_int) ktmp->arat : 1; */
/*  */
/*     if (ktmp->ptype == LTFAT_FREQINV) */
/*         if (ktmp->arat < 1.0) */
/*             ktmp->kSkip = (ltfat_int)(1.0 / ktmp->arat);//  a[0] / a[1]; */
/*     else if (ktmp->ptype == LTFAT_TIMEINV) */
/*         if (ktmp->Mrat < 1.0) */
/*             ktmp->kSkip = (ltfat_int)(1.0/ktmp->Mrat);//M[1] / M[0]; */
/*  */
/*     ktmp->cloned = 1; */
/*  */
/*     *kout = ktmp; */
/*     return LTFATERR_SUCCESS; */
/* error: */
/*     return status; */
/* } */
