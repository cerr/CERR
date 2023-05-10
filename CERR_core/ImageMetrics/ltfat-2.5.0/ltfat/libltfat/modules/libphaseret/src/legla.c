#include "phaseret/legla.h"
#include "phaseret/gla.h"
/* #include "dgtrealwrapper_private.h" */
#include "legla_private.h"
#include "ltfat/macros.h"

struct PHASERET_NAME(legla_plan)
{
    PHASERET_NAME(leglaupdate_plan)* updateplan;
    LTFAT_NAME(dgtreal_plan)* dgtplan;
    PHASERET_NAME(legla_callback_status)* status_callback;
    void* status_callback_userdata;
    PHASERET_NAME(legla_callback_cmod)* cmod_callback;
    void* cmod_callback_userdata;
// Storing magnitude
    LTFAT_REAL* s;
    const LTFAT_COMPLEX* cinit;
    LTFAT_COMPLEX* c;
    LTFAT_REAL* f;
// Used just for flegla
    int do_fast;
    double alpha;
    LTFAT_COMPLEX* t;
    int ptype;
};

struct PHASERET_NAME(leglaupdate_plan)
{
    ltfat_int kNo;
    LTFAT_COMPLEX** k;
    LTFAT_COMPLEX* buf;
    ltfat_int a;
    ltfat_int N;
    ltfat_int W;
    PHASERET_NAME(leglaupdate_plan_col)* plan_col;
};

struct PHASERET_NAME(leglaupdate_plan_col)
{
    phaseret_size ksize;
    phaseret_size ksize2;
    ltfat_int M;
    int flags;
};

PHASERET_API int
PHASERET_NAME(legla)(const LTFAT_COMPLEX cinit[], const LTFAT_REAL g[],
                     ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                     ltfat_int iter, LTFAT_COMPLEX cout[])
{
    PHASERET_NAME(legla_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        PHASERET_NAME(legla_init)(cinit, g, L, gl, W, a, M, 0.99, cout, NULL, &p));

    CHECKSTATUS( PHASERET_NAME(legla_execute)(p, iter));

error:
    if (p) PHASERET_NAME(legla_done)(&p);
    return status;
}


PHASERET_API int
PHASERET_NAME(legla_init)(const LTFAT_COMPLEX cinit[], const LTFAT_REAL g[],
                          ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                          const double alpha, LTFAT_COMPLEX c[],
                          phaseret_legla_params* params, PHASERET_NAME(legla_plan)** pout)
{
    PHASERET_NAME(legla_plan)* p = NULL;
    phaseret_legla_params pLoc;
    phaseret_size ksize;
    LTFAT_COMPLEX* kernsmall = NULL;
    ltfat_int M2 = M / 2 + 1;
    ltfat_int N = L / a;

    int status = LTFATERR_SUCCESS;

    CHECKNULL(c); CHECKNULL(pout);
    CHECK(LTFATERR_BADARG, alpha >= 0, "alpha must be bigger or equal to zero.");

    if (params)
    {
        /* CHECK(LTFATERR_CANNOTHAPPEN, */
        /*       params->private_hash_do_not_use == phaseret_legla_params_hash, */
        /*       "params were not initialized with phaseret_legla_params_defaults"); */
        CHECK(LTFATERR_NOTINRANGE, params->relthr >= 0 && params->relthr <= 1,
              "relthr must be in range [0-1]");

        pLoc = *params;
    }
    else
        phaseret_legla_params_defaults(&pLoc);

    ksize = pLoc.ksize;

    CHECK(LTFATERR_BADSIZE, (ksize.width <= N && ksize.height <= M) ||
          (ksize.width >= 0 && ksize.height >= 0),
          "Bad kernel size {.width=%d,.height=%d}.", ksize.width, ksize.height);

    if (pLoc.relthr == 0.0)
    {
        // Use kernel size directly
        CHECK(LTFATERR_BADSIZE, ksize.width > 0 && ksize.height > 0,
              "Bad kernel size {.width=%d,.height=%d}.", ksize.width, ksize.height);
    }
    else
    {
        CHECK(LTFATERR_BADSIZE, !(ksize.width == 0 && ksize.height > 0) ||
              !(ksize.width > 0 && ksize.height == 0),
              "Kernel size is zero in one direction {.width=%d,.height=%d}.",
              ksize.width, ksize.height);

        if (ksize.width == 0 && ksize.height == 0)
        {
            ksize.width = (ltfat_int) ( 2 * ceil(((double)M) / a) - 1 );
            ksize.height = (ltfat_int) ( 2 * ceil(((double)M) / a) - 1);
        }
    }

    CHECKMEM( p = (PHASERET_NAME(legla_plan)*) ltfat_calloc(1, sizeof * p));
    p->ptype = ltfat_dgt_getpar_phaseconv(pLoc.dparams);  // Store the user defined phase convention
    // Copy and overwrite phase convention
    ltfat_dgt_setpar_phaseconv(pLoc.dparams, LTFAT_FREQINV);
    /* pLoc.dparams->ptype = LTFAT_FREQINV; */
    CHECKMEM( p->s = LTFAT_NAME_REAL(malloc)(M2 * N * W));
    CHECKMEM( p->f = LTFAT_NAME_REAL(malloc)(L));

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_init)(g, gl, L, W, a, M, p->f, c, pLoc.dparams, &p->dgtplan));

    // Get the "impulse response" and crop it
    memset(c, 0, M2 * N * W * sizeof * c);
    c[0] = 1.0;
    LTFAT_NAME(dgtreal_execute_proj)(p->dgtplan, c, p->f, c);
    phaseret_size bigsize;
    bigsize.width = N; bigsize.height = M;

    if ( pLoc.relthr != 0.0)
        PHASERET_NAME(legla_findkernelsize)(c, bigsize, pLoc.relthr, &ksize);

    DEBUG("Kernel size: {.width=%d,.height=%d}", ksize.width, ksize.height);

    CHECKMEM( kernsmall =
                  LTFAT_NAME_COMPLEX(malloc)(ksize.width * (ksize.height / 2 + 1)));

    PHASERET_NAME(legla_big2small_kernel)(c, bigsize, ksize, kernsmall);

    CHECKSTATUS(
        PHASERET_NAME(leglaupdate_init)( kernsmall, ksize, L, W, a, M, pLoc.leglaflags,
                                         &p->updateplan));

    if (alpha > 0.0)
    {
        p->do_fast = 1;
        p->alpha = alpha;
        CHECKMEM( p->t = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W));
    }

    ltfat_free(kernsmall);
    p->cinit = cinit; p->c = c;
    *pout = p;
    return status;
error:
    if (kernsmall) ltfat_free(kernsmall);
    if (p) PHASERET_NAME(legla_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(legla_done)(PHASERET_NAME(legla_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(legla_plan)* pp;
    CHECKMEM(p); CHECKMEM(*p);
    pp = *p;

    if (pp->dgtplan) LTFAT_NAME(dgtreal_done)(&pp->dgtplan);
    if (pp->updateplan) PHASERET_NAME(leglaupdate_done)(&pp->updateplan);
    LTFAT_SAFEFREEALL(pp->s,pp->t,pp->f);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(legla_execute_newarray)(PHASERET_NAME(legla_plan)* p,
                                      const LTFAT_COMPLEX cinit[],
                                      ltfat_int iter, LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M, L, W, a, M2, N;
    LTFAT_NAME(dgtreal_plan)* pp = NULL;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, iter > 0, "At least one iteration is required");
    CHECKNULL(cinit); CHECKNULL(c);
    pp = p->dgtplan;
    M = LTFAT_NAME(dgtreal_get_M)(pp);
    L = LTFAT_NAME(dgtreal_get_L)(pp);
    W = LTFAT_NAME(dgtreal_get_W)(pp);
    a = LTFAT_NAME(dgtreal_get_a)(pp);
    M2 = M / 2 + 1;
    N = L / a;

    // Store the magnitude
    for (ltfat_int ii = 0; ii < N * M2 * W; ii++)
        p->s[ii] = ltfat_abs(cinit[ii]);

    // Copy to the output array if we are not working inplace
    if (cinit != c)
        memcpy(c, cinit, (N * M2 * W) * sizeof * c);

    if (p->do_fast)
        memcpy(p->t, c, (N * M2 * W) * sizeof * p->t );

    for (ltfat_int ii = 0; ii < iter; ii++)
    {
        PHASERET_NAME(leglaupdate_execute)(p->updateplan, p->s, c, c);

        if (p->do_fast)
            PHASERET_NAME(fastupdate)(c, p->t, p->alpha, N * M2 * W );

        // Optional coefficient modification
        if (p->cmod_callback)
            CHECKSTATUS(
                p->cmod_callback(p->cmod_callback_userdata, c, L, W, a, M));

        // Status callback, optional premature exit
        if (p->status_callback)
        {
            int status2 = p->status_callback(pp, p->status_callback_userdata,
                                             c, L, W, a, M, &p->alpha, ii);
            if (status2 > 0)
                break;
            else
                CHECKSTATUS(status2);

            CHECK(LTFATERR_BADARG, p->alpha >= 0.0, "alpha cannot be negative");

            if (p->alpha > 0.0 && !p->do_fast)
            {
                // The plan was not inicialized with acceleration but
                // nonzero alpha was set in the status callback.
                p->do_fast = 1;
                CHECKMEM( p->t = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W));
                memcpy(p->t, c, (N * M2 * W) * sizeof * p->t );
            }

        }
    }

    if (p->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_COMPLEX(dgtreal_phaselock)(c, L, W, a, M, c);
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(legla_execute)(PHASERET_NAME(legla_plan)* p, ltfat_int iter)
{
    int status = LTFATERR_SUCCESS;
    CHECKSTATUS(PHASERET_NAME(legla_execute_newarray)(p,p->cinit, iter, p->c));
error:
    return status;
}

int
PHASERET_NAME(legla_big2small_kernel)(LTFAT_COMPLEX* bigc,
                                      phaseret_size bigsize,
                                      phaseret_size ksize, LTFAT_COMPLEX* smallc)
{
    ltfat_div_t wmod = ltfat_idiv(ksize.width, 2);
    ltfat_div_t hmod = ltfat_idiv(ksize.height, 2);
    ltfat_int kernh2 = hmod.quot + 1;

    ltfat_int M2 = bigsize.height / 2 + 1;

    for (ltfat_int ii = 0; ii < wmod.quot + wmod.rem; ii++)
    {
        LTFAT_COMPLEX* smallcCol = smallc + kernh2 * ii;
        LTFAT_COMPLEX* bigcCol = bigc + M2 * ii;

        memcpy(smallcCol, bigcCol, kernh2 * sizeof * smallcCol);
    }

    for (ltfat_int ii = 1; ii < wmod.quot + 1; ii++)
    {
        LTFAT_COMPLEX* smallcCol = smallc + kernh2 * ( ksize.width - ii);
        LTFAT_COMPLEX* bigcCol = bigc + M2 * ( bigsize.width - ii);

        memcpy(smallcCol, bigcCol, kernh2 * sizeof * smallcCol);
    }
    return LTFATERR_SUCCESS;
}

int
PHASERET_NAME(legla_findkernelsize)(LTFAT_COMPLEX* bigc, phaseret_size bigsize,
                                    double relthr, phaseret_size* ksize)

{
    double thr = relthr * ltfat_abs(bigc[0]);
    ltfat_int realHeight = bigsize.height / 2 + 1;
    ltfat_div_t wmod = ltfat_idiv(ksize->width, 2);
    ltfat_div_t hmod = ltfat_idiv(ksize->height, 2);

    ltfat_int lastrow = 0;
    for (ltfat_int n = 0; n < wmod.quot + wmod.rem - 1; n++)
        for (ltfat_int m = 1; m < hmod.quot + hmod.rem - 1; m++)
            if ( ltfat_abs(bigc[n * realHeight + m]) > thr && m > lastrow )
                lastrow = m;

    ksize->height = 2 * lastrow + 1;
    hmod = ltfat_idiv(ksize->height, 2);

    // Kernel is always symmetric in the horizontal direction
    ltfat_int lastcol = 0;
    for (ltfat_int m = 0; m <  hmod.quot + hmod.rem - 1; m++)
        for (ltfat_int n = 1; n < wmod.quot + wmod.rem - 1; n++)
            if ( ltfat_abs(bigc[n * realHeight + m]) > thr && n > lastcol )
                lastcol = n;

    ksize->width = 2 * lastcol + 1;

    return LTFATERR_SUCCESS;
}




PHASERET_API int
PHASERET_NAME(leglaupdate_col_init)( ltfat_int M, phaseret_size ksize, int flags,
                                     PHASERET_NAME(leglaupdate_plan_col)** pout)
{
    PHASERET_NAME(leglaupdate_plan_col)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKMEM( p = (PHASERET_NAME(leglaupdate_plan_col)*) ltfat_calloc(1,
                  sizeof * p));
    phaseret_size ksize2;
    ksize2.width = ksize.width / 2 + 1;
    ksize2.height = ksize.height / 2 + 1;
    p->M = M; p->flags = flags; p->ksize = ksize; p->ksize2 = ksize2;

    // Sanitize flags (set defaults)
    if (p->flags & (MOD_FRAMEWISE | MOD_COEFFICIENTWISE))
    {
        p->flags &= ~MOD_STEPWISE; // For safety, clear the default flag.

        // Clear also lower priority flags
        if (p->flags & MOD_COEFFICIENTWISE)
            p->flags &= ~MOD_FRAMEWISE;
    }
    else
        p->flags |= MOD_STEPWISE; // Set the default flag if none of the others is set

    if (p->flags & (ORDER_REV))
        p->flags &= ~ORDER_FWD;
    else
        p->flags |= ORDER_FWD;

    if (p->flags & (EXT_UPDOWN))
        p->flags &= ~EXT_BOTH;
    else
        p->flags |= EXT_BOTH;

    *pout = p;

    return status;
error:
    if (p) ltfat_free(p);
    return status;
}

PHASERET_API int
PHASERET_NAME(leglaupdate_col_done)( PHASERET_NAME(leglaupdate_plan_col)** p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(*p);
    ltfat_free(*p);
    *p = NULL;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(leglaupdate_init)(const LTFAT_COMPLEX kern[], phaseret_size ksize,
                                ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int flags,
                                PHASERET_NAME(leglaupdate_plan)** pout)
{
    ltfat_int N = L / a;
    ltfat_int M2 = M / 2 + 1;
    ltfat_int kernh2;
    int status = LTFATERR_SUCCESS;

    PHASERET_NAME(leglaupdate_plan)* p = NULL;
    LTFAT_COMPLEX* ktmp = NULL;

    CHECKMEM( p = (PHASERET_NAME(leglaupdate_plan)*) ltfat_calloc (1, sizeof * p));

    CHECKSTATUS( PHASERET_NAME(leglaupdate_col_init)( M, ksize, flags,
                 &p->plan_col));

    // N
    p->N = (flags & EXT_UPDOWN) ? N - (ksize.width - 1) : N;
    p->a = a;
    p->W = W;

    p->kNo = ltfat_lcm(M, a) / a;

    CHECKMEM( p->k = (LTFAT_COMPLEX**) ltfat_malloc( p->kNo * sizeof * p->k));

    CHECKMEM( p->buf =
                  LTFAT_NAME_COMPLEX(malloc)( ((M2 + ksize.height - 1) * (p->N + ksize.width -
                          1))));

    kernh2 = ksize.height / 2 + 1;

    CHECKMEM( ktmp = LTFAT_NAME_COMPLEX(calloc)( ksize.width * kernh2));
    // Involute
    for (ltfat_int ii = 0; ii < kernh2; ii++)
    {
        const LTFAT_COMPLEX* kRow = kern + ii;
        LTFAT_COMPLEX* kmodRow = ktmp + ii;

        kmodRow[0] = kRow[0];
        for (ltfat_int jj = 1; jj < ksize.width; jj++)
            kmodRow[jj * kernh2] = conj(kRow[(ksize.width - jj) * kernh2]);
    }

    if (flags & MOD_MODIFIEDUPDATE) ktmp[0] = LTFAT_COMPLEX(0, 0);

    for (ltfat_int n = 0; n < p->kNo; n++)
    {
        CHECKMEM( p->k[n] = LTFAT_NAME_COMPLEX(calloc)( ksize.width * kernh2));
        PHASERET_NAME(kernphasefi)(ktmp, ksize, n, a, M, p->k[n]);
    }

    ltfat_free(ktmp);

    *pout = p;
    return status;
error:
    if (ktmp) ltfat_free(ktmp);
    if (p) PHASERET_NAME(leglaupdate_done)(&p);
    return status;
}

PHASERET_API void
PHASERET_NAME(leglaupdate_done)(PHASERET_NAME(leglaupdate_plan)** plan)
{

    PHASERET_NAME(leglaupdate_plan)* pp = *plan;
    for (ltfat_int n = 0; n < pp->kNo; n++)
        ltfat_safefree(pp->k[n]);

    ltfat_safefree(pp->k);
    ltfat_safefree(pp->buf);

    if (pp->plan_col) PHASERET_NAME(leglaupdate_col_done)(&pp->plan_col);
    ltfat_free(pp);
    pp = NULL;
}

void
PHASERET_NAME(kernphasefi)(const LTFAT_COMPLEX kern[], phaseret_size ksize,
                           ltfat_int n, ltfat_int a, ltfat_int M, LTFAT_COMPLEX kernmod[])
{
    /* ltfat_int kernh2 = ksize.height / 2 + 1; */
    /* ltfat_int kernw2 = ksize.width / 2; */
    ltfat_div_t wmod = ltfat_idiv(ksize.width, 2);
    ltfat_div_t hmod = ltfat_idiv(ksize.height, 2);
    ltfat_int kernh2 = hmod.quot + 1;
    /*Modulate */
    /* double idx = - ( ksize.height - kernh2); */

    for (ltfat_int ii = 0; ii < hmod.quot + hmod.rem; ii++)
    {
        const LTFAT_COMPLEX* kRow = kern + ii;
        LTFAT_COMPLEX* kmodRow = kernmod + ii;
        LTFAT_REAL arg = (LTFAT_REAL) ( -2.0 * M_PI * n * a / M * (ii) );

        // fftshift
        for (ltfat_int jj = 0; jj < wmod.quot + wmod.rem - 1; jj++)
            kmodRow[(jj + wmod.quot)*kernh2] = exp(I * arg) * kRow[jj * kernh2];

        for (ltfat_int jj = 0; jj < wmod.quot; jj++)
            kmodRow[jj * kernh2] = exp(I * arg) * kRow[(jj + wmod.quot + wmod.rem) *
                                   kernh2];
    }
}

PHASERET_API void
PHASERET_NAME(leglaupdate_execute)(PHASERET_NAME(leglaupdate_plan)* plan,
                                   const LTFAT_REAL s[],
                                   LTFAT_COMPLEX c[], LTFAT_COMPLEX cout[])
{
    PHASERET_NAME(leglaupdate_plan_col)* p = plan->plan_col;
    ltfat_int M2 = p->M / 2 + 1;
    ltfat_int N = plan->N;
    ltfat_int W = plan->W;
    //ltfat_int kernh2 = p->ksize2.height;
    //ltfat_int kernw = p->ksize.width;
    ltfat_int M2buf = M2 + p->ksize.height - 1;
    int do_onthefly = p->flags & MOD_COEFFICIENTWISE;
    int do_framewise = p->flags & MOD_FRAMEWISE;
    //int do_revorder = p->flags & ORDER_REV;

    LTFAT_COMPLEX** k = plan->k;
    LTFAT_COMPLEX* buf = plan->buf;

    ltfat_int nfirst;

    for (ltfat_int w = 0; w < W; w++)
    {
        const LTFAT_REAL* sChan =  s + w * M2 * N;
        LTFAT_COMPLEX* cChan = c + w * M2 * N;
        LTFAT_COMPLEX* coutChan = cout + w * M2 * N;

        PHASERET_NAME(extendborders)(plan->plan_col, cChan, N, buf);

        /* Outside loop over columns */
        for (nfirst = 0; nfirst < N; nfirst++)
        {
            /* Pick the right kernel */
            LTFAT_COMPLEX* actK = k[nfirst % plan->kNo];
            /* Go to the n-th col in output*/
            LTFAT_COMPLEX* cColFirst = buf + nfirst * M2buf;
            LTFAT_COMPLEX* coutCol = coutChan + nfirst * M2;

            const LTFAT_REAL* sCol = sChan + nfirst * M2;

            PHASERET_NAME(leglaupdate_col_execute)(plan->plan_col, sCol,
                                                   actK, cColFirst, coutCol);
        }

        if (!do_onthefly && !do_framewise)
        {
            /* Update the phase only after the projection has been done. */
            for (ltfat_int n = 0; n < N * M2; n++)
                coutChan[n] = sChan[n] * exp(I * ltfat_arg(coutChan[n]));
        }
    }
}

PHASERET_API void
PHASERET_NAME(leglaupdate_col_execute)(
    PHASERET_NAME( leglaupdate_plan_col)* plan,
    const LTFAT_REAL sCol[],
    const LTFAT_COMPLEX actK[],
    LTFAT_COMPLEX cColFirst[],
    LTFAT_COMPLEX coutCol[])
{
    ltfat_int m, mfirst, mlast;
    ltfat_int M2 = plan->M / 2 + 1;
    ltfat_int kernh = plan->ksize.height;
    ltfat_int kernw = plan->ksize.width;
    ltfat_int kernh2 = plan->ksize2.height;
    ltfat_int kernw2 = plan->ksize2.width;
    ltfat_int M2buf = M2 + kernh - 1;
    ltfat_int kernhMidId = kernh2 - 1;
    ltfat_int kernwMidId = kernw2 - 1;

    /* mwSignedIndex Nbuf = N + kernw -1; */
    int do_onthefly = plan->flags & MOD_COEFFICIENTWISE;
    int do_framewise = plan->flags & MOD_FRAMEWISE;

    /* Outside loop over rows */
    for (m = kernh2 - 1, mfirst = 0, mlast = kernh - 1; mfirst < M2;
         m++, mfirst++, mlast++)
    {
        LTFAT_COMPLEX accum = LTFAT_COMPLEX(0, 0);

        /* inner loop over all cols of the kernel*/
        for (ltfat_int kn = 0; kn < kernw; kn++)
        {
            /* mexPrintf("kn-loop: %d\n",kn); */
            const LTFAT_COMPLEX* actKCol = actK + kn * kernh2 +  kernh2 - 1;
            LTFAT_COMPLEX* cCol = cColFirst + kn * M2buf;

            /* Inner loop over half of the rows of the kernel excluding the middle row */
            for (ltfat_int km = 0; km < kernh2 - 1; km++)
            {
                /* Doing the complex conjugated kernel elements simulteneously */
                LTFAT_REAL ar  = ltfat_real(actKCol[-km]);
                LTFAT_REAL ai  = ltfat_imag(actKCol[-km]);
                LTFAT_REAL br  = ltfat_real(cCol[mfirst + km]);
                LTFAT_REAL bi  = ltfat_imag(cCol[mfirst + km]);
                LTFAT_REAL bbr = ltfat_real(cCol[mlast - km]);
                LTFAT_REAL bbi = ltfat_imag(cCol[mlast - km]);
                accum += ar * (br + bbr) - ai * (bi - bbi)
                         + I * ( ar * (bi + bbi) + ai * (br - bbr));
            }

            /* The middle row is real*/
            accum += actKCol[-kernhMidId] * cCol[m];
        }

        coutCol[mfirst] = accum;

        if (do_onthefly)
        {
            /* Update the phase of a coefficient immediatelly */
            coutCol[mfirst] = sCol[mfirst] * exp(I * ltfat_arg(coutCol[mfirst]));
            cColFirst[kernwMidId * M2buf + m] = coutCol[mfirst];
        }

    }

    /* Update the phase of a single column */
    if (do_framewise)
    {
        for (m = kernh2 - 1, mfirst = 0; mfirst < M2; m++, mfirst++)
        {
            coutCol[mfirst] = sCol[mfirst] * exp(I * ltfat_arg(coutCol[mfirst]));
            cColFirst[kernwMidId * M2buf + m] = coutCol[mfirst];
        }
    }
}

PHASERET_API void
PHASERET_NAME(extendborders)(PHASERET_NAME(leglaupdate_plan_col)* plan,
                             const LTFAT_COMPLEX c[], ltfat_int N, LTFAT_COMPLEX buf[])
{
    ltfat_int m, n;
    ltfat_int M2 = plan->M / 2 + 1;
    ltfat_int kernh = plan->ksize.height;
    ltfat_int kernw = plan->ksize.width;
    ltfat_int kernh2 = plan->ksize2.height;
    ltfat_int kernw2 = plan->ksize2.width;
    ltfat_int M2buf = M2 + kernh - 1;
    ltfat_int Nbuf = N + kernw - 1;

    if ( plan->flags & EXT_UPDOWN) Nbuf = N;

    if ( !(plan->flags & EXT_UPDOWN))
    {
        /* Copy input to the center of the buffer */
        for (n = 0; n < N; n++)
        {
            LTFAT_COMPLEX* bufstart = buf + (n + kernw2 - 1) * M2buf + kernh2 - 1;
            const LTFAT_COMPLEX* cstart = c + n * M2;
            memcpy(bufstart, cstart, M2 * sizeof * bufstart);
        }

        /* Periodically extend the left side */
        for (m = 0; m < M2; m++)
        {
            LTFAT_COMPLEX* buftarget = buf + kernh2 - 1 + m;
            LTFAT_COMPLEX* bufsource = buf + (N) * M2buf + kernh2 - 1 + m;

            for (n = 0; n < kernw2 - 1; n++)
                buftarget[n * M2buf] = bufsource[n * M2buf];
        }

        /* Periodically extend the right side*/
        for (m = 0; m < M2; m++)
        {
            LTFAT_COMPLEX* bufsource = buf + (kernw2 - 1) * M2buf + kernh2 - 1 + m;
            LTFAT_COMPLEX* buftarget = buf + (N + kernw2 - 1) * M2buf + kernh2 - 1 + m;

            for (n = 0; n < kernw2 - 1; n++)
                buftarget[n * M2buf] = bufsource[n * M2buf];
        }
    }
    else if (plan->flags & EXT_UPDOWN)
    {
        /* Copy input to the center of the buffer */
        for (n = 0; n < N; n++)
        {
            LTFAT_COMPLEX* bufstart = buf + n * M2buf + kernh2 - 1;
            const LTFAT_COMPLEX* cstart = c + n * M2;
            memcpy(bufstart, cstart, M2 * sizeof * bufstart);
        }
    }

    /* Conjugated odd-symmetric extention of the top border*/
    for (n = 0; n < Nbuf; n++)
    {
        LTFAT_COMPLEX* bufsource = buf + n * M2buf + kernh2;
        LTFAT_COMPLEX* buftarget = bufsource - 2;

        for (m = 0; m < kernh2 - 1; m++)
            buftarget[-m] = conj(bufsource[m]);
    }

    /* Conjugated odd or even symmetry extension of the bottom border.
     * Depending whether M is odd or even
     * */
    for (n = 0; n < Nbuf; n++)
    {
        LTFAT_COMPLEX* buftarget = buf + n * M2buf + kernh2 - 1 + M2;
        LTFAT_COMPLEX* bufsource = buftarget - 2 + plan->M % 2;

        for (m = 0; m < kernh2 - 1; m++)
            buftarget[m] = conj(bufsource[-m]);
    }

}

PHASERET_API int
PHASERET_NAME(legla_set_status_callback)(PHASERET_NAME(legla_plan)* p,
        PHASERET_NAME(legla_callback_status)* callback, void* userdata)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    p->status_callback = callback;
    p->status_callback_userdata = userdata;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(legla_set_cmod_callback)(PHASERET_NAME(legla_plan)* p,
                                       PHASERET_NAME(legla_callback_cmod)* callback,
                                       void* userdata)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    p->cmod_callback = callback;
    p->cmod_callback_userdata = userdata;
error:
    return status;
}
