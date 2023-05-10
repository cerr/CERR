#include "phaseret/gla.h"
#include "phaseret/utils.h"
#include "ltfat/macros.h"
/* #include "dgtrealwrapper_private.h" */

struct PHASERET_NAME(gla_plan)
{
    LTFAT_NAME(dgtreal_plan)* p;
    PHASERET_NAME(gla_callback_status)* status_callback;
    void* status_callback_userdata;
    PHASERET_NAME(gla_callback_cmod)* cmod_callback;
    void* cmod_callback_userdata;
    PHASERET_NAME(gla_callback_fmod)* fmod_callback;
    void* fmod_callback_userdata;
// For storing magnitude
    LTFAT_REAL* s;
    LTFAT_REAL* f;
// Storing cinit
    const LTFAT_COMPLEX* cinit;
    LTFAT_COMPLEX* c;
// Used just for fgla
    int do_fast;
    double alpha;
    LTFAT_COMPLEX* t;
};

PHASERET_API int
PHASERET_NAME(gla)(const LTFAT_COMPLEX cinit[], const int mask[], const LTFAT_REAL g[],
                   ltfat_int L,
                   ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int iter,
                   LTFAT_COMPLEX cout[])
{
    PHASERET_NAME(gla_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        PHASERET_NAME(gla_init)(cinit, g, L, gl, W, a, M, 0.99, cout, NULL, &p));

    CHECKSTATUS( PHASERET_NAME(gla_execute)(p, mask, iter));

error:
    if (p) PHASERET_NAME(gla_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_init)(const LTFAT_COMPLEX cinit[], const LTFAT_REAL g[],
                        ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a,
                        ltfat_int M, const double alpha, LTFAT_COMPLEX c[],
                        ltfat_dgt_params* params, PHASERET_NAME(gla_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gla_plan)* p = NULL;
    ltfat_int N = L / a;
    ltfat_int M2 = M / 2 + 1;

    CHECK(LTFATERR_BADARG, alpha >= 0.0, "alpha cannot be negative");
    CHECKMEM( p = (PHASERET_NAME(gla_plan)*) ltfat_calloc(1, sizeof * p));
    CHECKMEM( p->s = LTFAT_NAME_REAL(malloc)(M2 * N * W));
    CHECKMEM( p->f = LTFAT_NAME_REAL(malloc)(L * W));

    if (alpha > 0.0)
    {
        p->do_fast = 1;
        p->alpha = alpha;
        CHECKMEM( p->t = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W));
    }

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_init)(g, gl, L, W, a, M, p->f, c, params, &p->p));

    p->cinit = cinit; p->c = c;

    *pout = p;
    return status;
error:
    if (p) PHASERET_NAME(gla_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_done)(PHASERET_NAME(gla_plan)** p)
{
    PHASERET_NAME(gla_plan)* pp = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    if (pp->p)
        CHECKSTATUS(
            LTFAT_NAME(dgtreal_done)(&pp->p));

    ltfat_safefree(pp->t);
    ltfat_safefree(pp->s);
    ltfat_safefree(pp->f);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_execute_newarray)(PHASERET_NAME(gla_plan)* p,
                                    const LTFAT_COMPLEX cinit[], const int mask[], ltfat_int iter,
                                    LTFAT_COMPLEX cout[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M, L, W, a, M2, N;
    LTFAT_COMPLEX* cinit2 = NULL;
    CHECKNULL(p); CHECKNULL(cinit); CHECKNULL(cout);
    // Shallow copy the plan and replace c
    CHECK(LTFATERR_NOTPOSARG, iter > 0,
          "At least one iteration is requred. Passed %d.", iter);

    M = LTFAT_NAME(dgtreal_get_M)(p->p);
    L = LTFAT_NAME(dgtreal_get_L)(p->p);
    W = LTFAT_NAME(dgtreal_get_W)(p->p);
    a = LTFAT_NAME(dgtreal_get_a)(p->p);
    M2 = M / 2 + 1;
    N = L / a;

    // Store the magnitude
    for (ltfat_int ii = 0; ii < N * M2 * W; ii++)
        p->s[ii] = ltfat_abs(cinit[ii]);

    // Copy to the output array if we are not working inplace
    if (cinit != cout)
    {
        memcpy(cout, cinit, (N * M2 * W) * sizeof * cout);
    }
    else
    {
        // If inplace with mask, allocate a temorary variable
        if(mask)
        {
            CHECKMEM(cinit2 = LTFAT_NAME_COMPLEX(malloc)(N*M2*W));
            memcpy(cinit2, cinit, (N * M2 * W) * sizeof * cout);
        }
    }

    // Inicialize the "acceleration" array
    if (p->do_fast)
        memcpy(p->t, cout, (N * M2 * W) * sizeof * p->t );

    for (ltfat_int ii = 0; ii < iter; ii++)
    {
        // Perform idgtreal
        CHECKSTATUS( LTFAT_NAME(dgtreal_execute_syn_newarray)(p->p, cout, p->f));

        // Optional signal modification
        if (p->fmod_callback)
            CHECKSTATUS(
                p->fmod_callback(p->fmod_callback_userdata, p->f, L, W, a, M));

        // Perform dgtreal
        CHECKSTATUS( LTFAT_NAME(dgtreal_execute_ana_newarray)(p->p, p->f, cout));

        PHASERET_NAME(force_magnitude)(cout, p->s, N * M2 * W, cout);

        if(mask)
            for(ltfat_int w = 0;w < W; w++)
                for(ltfat_int jj = 0; jj < N * M2; jj++)
                    if(mask[jj])
                    {
                        if(cinit2)
                            cout[jj + w * M2 * N] = cinit2[jj + w * M2 * N];
                        else
                            cout[jj + w * M2 * N] = cinit[jj + w * M2 * N];
                    }

        // The acceleration step
        if (p->do_fast)
            PHASERET_NAME(fastupdate)(cout, p->t, p->alpha, N * M2 * W );

        // Optional coefficient modification
        if (p->cmod_callback)
            CHECKSTATUS(
                p->cmod_callback(p->cmod_callback_userdata, cout, L, W, a, M));

        // Status callback, optional premature exit
        if (p->status_callback)
        {
            int retstatus = p->status_callback(p->p, p->status_callback_userdata,
                                               cout, L, W, a, M, &p->alpha, ii);
            if (retstatus > 0)
                break;
            else
                CHECKSTATUS(retstatus);

            CHECK(LTFATERR_BADARG, p->alpha >= 0.0, "alpha cannot be negative");

            if (p->alpha > 0.0 && !p->do_fast)
            {
                // The plan was not inicialized with acceleration but
                // nonzero alpha was set in the status callback.
                p->do_fast = 1;
                CHECKMEM( p->t = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W));
                memcpy(p->t, cout, (N * M2 * W) * sizeof * p->t );
            }
        }
    }

error:
    ltfat_safefree(cinit2);
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_execute)(PHASERET_NAME(gla_plan)* p, const int mask[], ltfat_int iter)
{
    int status = LTFATERR_SUCCESS;
    CHECKSTATUS(PHASERET_NAME(gla_execute_newarray)(p,p->cinit,mask,iter,p->c));
error:
    return status;
}


PHASERET_API int
PHASERET_NAME(gla_set_status_callback)(PHASERET_NAME(gla_plan)* p,
                                       PHASERET_NAME(gla_callback_status)* callback,
                                       void* userdata)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(callback);

    p->status_callback = callback;
    p->status_callback_userdata = userdata;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_set_cmod_callback)(PHASERET_NAME(gla_plan)* p,
                                     PHASERET_NAME(gla_callback_cmod)* callback,
                                     void* userdata)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(callback);

    p->cmod_callback = callback;
    p->cmod_callback_userdata = userdata;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gla_set_fmod_callback)(PHASERET_NAME(gla_plan)* p,
                                     PHASERET_NAME(gla_callback_fmod)* callback,
                                     void* userdata)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(callback);

    p->fmod_callback = callback;
    p->fmod_callback_userdata = userdata;
error:
    return status;
}

int
PHASERET_NAME(fastupdate)(LTFAT_COMPLEX* c, LTFAT_COMPLEX* t, double alpha,
                          ltfat_int L)
{
    for (ltfat_int ii = 0; ii < L; ii++)
    {
        LTFAT_COMPLEX cold = c[ii];
        c[ii] = c[ii] + ((LTFAT_REAL)alpha) * (c[ii] - t[ii]);
        t[ii] = cold;
    }
    return 0;
}
