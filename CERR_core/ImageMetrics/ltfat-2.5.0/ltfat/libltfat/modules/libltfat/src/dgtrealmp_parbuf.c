#include "dgtrealmp_private.h"


LTFAT_API ltfat_int
LTFAT_NAME(dgtrealmp_getparbuf_dictno)( LTFAT_NAME(dgtrealmp_parbuf) * p)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return p->P;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(dgtrealmp_getparbuf_siglen)(
    LTFAT_NAME(dgtrealmp_parbuf) * p, ltfat_int L)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, p->P > 0, "No Gabor system defined in the plan");
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive (passed %td)", L);

    for (ltfat_int pidx = 0; pidx < p->P; pidx++)
        CHECK(LTFATERR_BADARG, p->gl[pidx] <= L,
              "gl[%td]<=L failed. L must be higher than the length of the"
              " longest window. passed (%td, %td)", pidx, p->gl[pidx], L);

    return ltfat_dgtlengthmulti(L, p->P, p->a, p->M);
error:
    return status;
}

LTFAT_API ptrdiff_t
LTFAT_NAME(dgtrealmp_getparbuf_coeflen)(
    LTFAT_NAME(dgtrealmp_parbuf) * p, ltfat_int L, ltfat_int dictid)
{
    ptrdiff_t Llong = 0;
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, dictid >= 0 && dictid < p->P,
          "Dictionary %td is not in the plan. There is %td dicts.", dictid, p->P);

    Llong = LTFAT_NAME(dgtrealmp_getparbuf_siglen)( p, L);
    CHECKSTATUS(Llong);
    return (p->M[dictid] / 2 + 1) * (Llong / p->a[dictid]);
error:
    return status;
}

LTFAT_API ptrdiff_t
LTFAT_NAME(dgtrealmp_getparbuf_coeflen_compact)(
    LTFAT_NAME(dgtrealmp_parbuf) * p, ltfat_int L)
{
    ltfat_int W = 0;
    ptrdiff_t N = 0;
    int status = LTFATERR_FAILED;
    CHECKSTATUS( LTFAT_NAME(dgtrealmp_getparbuf_dictno)(p));

    for(ltfat_int w = 0; w < W; w++)
    {
        ptrdiff_t Ntmp = LTFAT_NAME(dgtrealmp_getparbuf_coeflen)(p,L,w);
        CHECKSTATUS(Ntmp); N += Ntmp;
    }

    return N;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_init)(LTFAT_NAME(dgtrealmp_parbuf)** p)
{
    int status = LTFATERR_FAILED;
    LTFAT_NAME(dgtrealmp_parbuf)* ploc = NULL;
    CHECKNULL(p);
    CHECKMEM(ploc = LTFAT_NEW( LTFAT_NAME(dgtrealmp_parbuf) ));
    CHECKMEM(ploc->params = ltfat_dgtmp_params_allocdef());
    CHECKMEM(ploc->g  = LTFAT_NEW(LTFAT_REAL*));
    CHECKMEM(ploc->gl = LTFAT_NEW(ltfat_int));
    CHECKMEM(ploc->a  = LTFAT_NEW(ltfat_int));
    CHECKMEM(ploc->M  = LTFAT_NEW(ltfat_int));
    CHECKMEM(ploc->chanmask  = LTFAT_NEW(int));

    *p = ploc;
    return LTFATERR_SUCCESS;
error:
    if (ploc)
        LTFAT_NAME(dgtrealmp_parbuf_done)(&ploc);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_done)(LTFAT_NAME(dgtrealmp_parbuf)** p)
{
    LTFAT_NAME(dgtrealmp_parbuf)* pp = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECKNULL(*p);
    pp = *p;

    if (pp->params)
        ltfat_dgtmp_params_free(pp->params);

    for (ltfat_int pidx = 0; pidx < pp->P; pidx++)
        ltfat_safefree(pp->g[pidx]);

    LTFAT_SAFEFREEALL(pp->g, pp->gl, pp->a, pp->M, pp->chanmask);

    ltfat_free(pp);
    *p = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_firwin)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, LTFAT_FIRWIN win, ltfat_int gl,
    ltfat_int a, ltfat_int M)
{
    LTFAT_REAL* g = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKNULL(parbuf);
    CHECK(LTFATERR_NOTPOSARG, gl > 0, "gl must be positive (passed %td)", gl);
    CHECKMEM( g = LTFAT_NAME(malloc)(gl));
    CHECKSTATUS( LTFAT_NAME(firwin)(win, gl, g));
    CHECKSTATUS( LTFAT_NAME(normalize)(g, gl, LTFAT_NORM_ENERGY, g));

    CHECKSTATUS(
        LTFAT_NAME(dgtrealmp_parbuf_add_genwin)( parbuf, (const LTFAT_REAL*) g, gl, a,
                M ));
error:
    ltfat_safefree(g);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_gausswin)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, ltfat_int a, ltfat_int M)
{
    LTFAT_REAL* g = NULL;
    ltfat_int gl = 0;
    double thr = 1e-4;
    int status = LTFATERR_SUCCESS;

    CHECKNULL(parbuf);
    CHECKSTATUS( gl = ltfat_mtgausslength(a,M,thr));
    CHECKMEM( g = LTFAT_NAME(malloc)(gl));
    CHECKSTATUS( LTFAT_NAME(mtgauss)(a, M, thr, g));
    CHECKSTATUS( LTFAT_NAME(normalize)(g, gl, LTFAT_NORM_ENERGY, g));

    CHECKSTATUS(
        LTFAT_NAME(dgtrealmp_parbuf_add_genwin)( parbuf, (const LTFAT_REAL*) g, gl, a,
                M ));
error:
    ltfat_safefree(g);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_genwin)(LTFAT_NAME(dgtrealmp_parbuf) * p,
                                        const LTFAT_REAL g[], ltfat_int gl,
                                        ltfat_int a, ltfat_int M)
{
    ltfat_int amax = 0, Mmax = 0;
    int status = LTFATERR_FAILED;

    CHECKNULL(p);
    p->P++;
    CHECK(LTFATERR_NOTPOSARG, gl > 0, "gl must be positive (passed %td)", gl);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive (passed %td)", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive (passed %td)", M);
    CHECK(LTFATERR_NOTAFRAME, M >= a, "M>=a failed.(passed (%td,%td))", M, a);
    CHECK(LTFATERR_BADARG, M % a == 0 && M / a > 1, "M must be divisible by a and M/a>=2. Passed (%td,%td)", M, a);

    p->gl[p->P - 1] = gl;
    p->a[p->P - 1]  = a;
    p->M[p->P - 1]  = M;
    p->chanmask[p->P - 1] = 1;

    amax = p->a[0]; Mmax = p->M[0];

    for (ltfat_int pidx = 1; pidx < p->P; pidx++)
    {
        if (p->a[pidx] > amax) amax = p->a[pidx];
        if (p->M[pidx] > Mmax) Mmax = p->M[pidx];
    }

    for (ltfat_int pidx = 0; pidx < p->P; pidx++)
    {
        CHECK(LTFATERR_BADARG, amax % p->a[pidx] == 0,
              "a[%td] not divisible by amax=%td (passed %td)", pidx, amax, p->a[pidx]);
        CHECK(LTFATERR_BADARG, Mmax % p->M[pidx] == 0,
              "M[%td] not divisible by Mmax=%td (passed %td)", pidx, Mmax, p->M[pidx]);
    }

    CHECKMEM(p->g[p->P - 1] = LTFAT_NAME(malloc)(gl));
    memcpy(p->g[p->P - 1], g, gl * sizeof * g);

    CHECKMEM( p->g  = LTFAT_POSTPADARRAY(LTFAT_REAL*, p->g, p->P, p->P + 1));
    CHECKMEM( p->gl = LTFAT_POSTPADARRAY(ltfat_int, p->gl, p->P, p->P + 1));
    CHECKMEM( p->a  = LTFAT_POSTPADARRAY(ltfat_int, p->a, p->P, p->P + 1));
    CHECKMEM( p->M  = LTFAT_POSTPADARRAY(ltfat_int, p->M, p->P, p->P + 1));
    CHECKMEM( p->chanmask  = LTFAT_POSTPADARRAY(int, p->chanmask, p->P, p->P + 1));

    return LTFATERR_SUCCESS;
error:
    if (p)
    {
        p->P--;
        if (p->g) ltfat_safefree(p->g[p->P]);
    }
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_modparbuf_lasttight)(
    LTFAT_NAME(dgtrealmp_parbuf)* p)
{
    int status = LTFATERR_FAILED;
    ltfat_int plast = 0;
    CHECKNULL(p);
    CHECK( LTFATERR_EMPTY, p->P > 0, "No Gabor system present.");
    plast = p->P - 1;

    CHECKSTATUS(
            LTFAT_NAME(gabtight_painless)(
                p->g[plast], p->gl[plast], p->a[plast], p->M[plast], p->g[plast]));

    CHECKSTATUS(
           LTFAT_NAME(normalize)(p->g[plast], p->gl[plast], LTFAT_NORM_ENERGY,  p->g[plast]));

    return LTFATERR_SUCCESS;
error:
    return status;
}

/* LTFAT_API int */
/* LTFAT_NAME(dgtrealmp_parbuf_add_gausswin)( */
/*     LTFAT_NAME(dgtrealmp_parbuf) * parbuf, LTFAT_REAL tfr, ltfat_int a, ltfat_int M); */
/*  */
/* LTFAT_API int */
/* LTFAT_NAME(dgtrealmp_parbuf_add_hermwin)( */
/*     LTFAT_NAME( dgtrealmp_parbuf) * parbuf, ltfat_int order, LTFAT_REAL tfr, */
/*     ltfat_int a, ltfat_int M); */

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_phaseconv)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, ltfat_phaseconvention pconv)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_phaseconv(p->params, pconv);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_atprodreltoldb)(
        LTFAT_NAME(dgtrealmp_parbuf)* p, double atprodreltoldb)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_atprodreltoldb(p->params, atprodreltoldb);
error:
    return status;

}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_maxatoms)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, size_t maxatoms)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_maxatoms(p->params, maxatoms);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_maxit)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, size_t maxit)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_maxit(p->params, maxit);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_errtoldb)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, double errtoldb)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_errtoldb(p->params, errtoldb);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_snrdb)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, double snrdb)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_snrdb(p->params, snrdb);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_kernrelthr)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, double thr)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_kernrelthr(p->params, thr);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_iterstep)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, size_t iterstep)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_iterstep(p->params, iterstep);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_iterstepcallback)(
    LTFAT_NAME(dgtrealmp_parbuf)* p,
    LTFAT_NAME(dgtrealmp_iterstep_callback)* callback, void* userdata)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);

    p->iterstepcallback = callback;
    p->iterstepcallbackdata = userdata;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_alg)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, ltfat_dgtmp_alg alg)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_alg(p->params, alg);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_pedanticsearch)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, int do_pedantic)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return ltfat_dgtmp_setpar_pedanticsearch(p->params, do_pedantic);
error:
    return status;
}
