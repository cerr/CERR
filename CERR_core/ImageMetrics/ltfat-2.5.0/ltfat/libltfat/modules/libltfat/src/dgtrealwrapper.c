#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtrealwrapper_private.h"

LTFAT_API ltfat_int
LTFAT_NAME(dgtreal_get_M)(LTFAT_NAME(dgtreal_plan)* p)
{
    if(p) return p->M;
    else return LTFATERR_NULLPOINTER;
}

LTFAT_API ltfat_int
LTFAT_NAME(dgtreal_get_a)(LTFAT_NAME(dgtreal_plan)* p)
{
    if(p) return p->a;
    else return LTFATERR_NULLPOINTER;
}

LTFAT_API ltfat_int
LTFAT_NAME(dgtreal_get_W)(LTFAT_NAME(dgtreal_plan)* p)
{
    if(p) return p->W;
    else return LTFATERR_NULLPOINTER;
}

LTFAT_API int
LTFAT_NAME(dgtreal_get_phaseconv)(LTFAT_NAME(dgtreal_plan)* p)
{
    if(p) return p->ptype;
    else return LTFATERR_NULLPOINTER;
}

LTFAT_API ltfat_int
LTFAT_NAME(dgtreal_get_L)(LTFAT_NAME(dgtreal_plan)* p)
{
    if(p) return p->L;
    else return LTFATERR_NULLPOINTER;
}

int
LTFAT_NAME(idgtreal_long_execute_wrapper)(void* plan,
        const LTFAT_COMPLEX* c, ltfat_int UNUSED(L), ltfat_int UNUSED(W), LTFAT_REAL* f)
{
    return LTFAT_NAME(idgtreal_long_execute_newarray)(
               (LTFAT_NAME(idgtreal_long_plan)*) plan, c, f);
}

int
LTFAT_NAME(dgtreal_long_execute_wrapper)(void* plan,
        const LTFAT_REAL* f, ltfat_int UNUSED(L), ltfat_int UNUSED(W), LTFAT_COMPLEX* c)
{
    return LTFAT_NAME(dgtreal_long_execute_newarray)(
               (LTFAT_NAME(dgtreal_long_plan)*) plan, f, c);
}

int
LTFAT_NAME(idgtreal_fb_execute_wrapper)(void* plan,
                                        const LTFAT_COMPLEX* c, ltfat_int L, ltfat_int W, LTFAT_REAL* f)
{
    return LTFAT_NAME(idgtreal_fb_execute)(
               (LTFAT_NAME(idgtreal_fb_plan)*) plan, c, L, W, f);
}

int
LTFAT_NAME(dgtreal_fb_execute_wrapper)(void* plan,
                                       const LTFAT_REAL* f, ltfat_int L, ltfat_int W, LTFAT_COMPLEX* c)
{
    return LTFAT_NAME(dgtreal_fb_execute)(
               (LTFAT_NAME(dgtreal_fb_plan)*) plan, f, L, W, c);
}

int
LTFAT_NAME(idgtreal_long_done_wrapper)(void** plan)
{
    return LTFAT_NAME(idgtreal_long_done)( (LTFAT_NAME(idgtreal_long_plan)**) plan);
}

int
LTFAT_NAME(dgtreal_long_done_wrapper)(void** plan)
{
    return LTFAT_NAME(dgtreal_long_done)( (LTFAT_NAME(dgtreal_long_plan)**) plan);
}

int
LTFAT_NAME(idgtreal_fb_done_wrapper)(void** plan)
{
    return LTFAT_NAME(idgtreal_fb_done)((LTFAT_NAME(idgtreal_fb_plan)**) plan);
}

int
LTFAT_NAME(dgtreal_fb_done_wrapper)(void** plan)
{
    return LTFAT_NAME(dgtreal_fb_done)((LTFAT_NAME(dgtreal_fb_plan)**) plan);
}

LTFAT_API int
LTFAT_NAME(dgtreal_execute_proj)(
    LTFAT_NAME(dgtreal_plan)* p, const LTFAT_COMPLEX cin[],
    LTFAT_REAL fbuffer[], LTFAT_COMPLEX cout[])
{
    int status = LTFATERR_SUCCESS;
    LTFAT_REAL* ftmp;

    CHECKNULL(p);
    ftmp = p->f;
    CHECK(LTFATERR_NULLPOINTER, !(fbuffer == NULL && p->f == NULL),
          "fbuffer cannot be NULL when the plan was created without f");

    if (fbuffer != NULL)
        ftmp = fbuffer;

    CHECKSTATUS( p->backtra(p->backtra_userdata, cin, p->L, p->W, ftmp));
    CHECKSTATUS( p->fwdtra(p->fwdtra_userdata, ftmp, p->L, p->W,  cout));
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_execute_syn_newarray)(
    LTFAT_NAME(dgtreal_plan)* p, const LTFAT_COMPLEX c[], LTFAT_REAL f[])
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return p->backtra(p->backtra_userdata, c, p->L, p->W, f);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_execute_syn)( LTFAT_NAME(dgtreal_plan)* p)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return p->backtra(p->backtra_userdata, p->c, p->L, p->W, p->f);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_execute_ana_newarray)(
    LTFAT_NAME(dgtreal_plan)* p, const LTFAT_REAL f[], LTFAT_COMPLEX c[])
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return p->fwdtra(p->fwdtra_userdata, f, p->L, p->W,  c);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_execute_ana)(LTFAT_NAME(dgtreal_plan)* p)
{
    int status = LTFATERR_FAILED; CHECKNULL(p);
    return p->fwdtra(p->fwdtra_userdata, p->f, p->L, p->W, p->c);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_done)(LTFAT_NAME(dgtreal_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(dgtreal_plan)* pp;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    if (pp->fwdtra_userdata)
        CHECKSTATUS( pp->fwddonefunc(&pp->fwdtra_userdata));

    if (pp->backtra_userdata)
        CHECKSTATUS( pp->backdonefunc(&pp->backtra_userdata));

    //ltfat_safefree(pp->f);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}


LTFAT_API int
LTFAT_NAME(dgtreal_init)(const LTFAT_REAL g[], ltfat_int gl, ltfat_int L,
                         ltfat_int W, ltfat_int a, ltfat_int M,
                         LTFAT_REAL f[], LTFAT_COMPLEX c[],
                         ltfat_dgt_params* params, LTFAT_NAME(dgtreal_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    int ispainless = gl <= M;
    LTFAT_REAL* g2 = NULL;
    ltfat_int g2l = 0;

    ltfat_int minL = ltfat_lcm(a, M);

    CHECK(LTFATERR_BADTRALEN, !(L % minL),
          "L must divisible by lcm(a,M)=%d.", minL);

    if (ispainless)
    {
        // The length of the dual window is guaranteed to be gl
        g2l = gl;
        CHECKMEM( g2 = LTFAT_NAME_REAL(malloc)(gl));
        CHECKSTATUS( LTFAT_NAME(gabdual_painless)(g, gl, a, M, g2));
    }
    else
    {
#ifndef NOBLASLAPACK
        g2l = L;
        CHECKMEM( g2 = LTFAT_NAME_REAL(malloc)(L));
        LTFAT_NAME(fir2long)(g, gl, L, g2);
        CHECKSTATUS( LTFAT_NAME(gabdual_long)(g, L, a, M, g2));
#else
        CHECK( LTFATERR_NOTSUPPORTED, 0, "Non-painless support was not compiled.");
#endif
    }

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_init_gen)(g, gl, g2, g2l, L, W, a, M, f, c, params, pout));

    ltfat_free(g2);
    return status;
error:
    ltfat_safefree(g2);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_init_gen)(const LTFAT_REAL ga[], ltfat_int gal,
                             const LTFAT_REAL gs[], ltfat_int gsl,
                             ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                             LTFAT_REAL f[], LTFAT_COMPLEX c[],
                             ltfat_dgt_params* params, LTFAT_NAME(dgtreal_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(dgtreal_plan)* p = NULL;
    ltfat_dgt_params paramsLoc;

    LTFAT_REAL* g2 = NULL;

    ltfat_int minL = ltfat_lcm(a, M);

    if (params)
        paramsLoc = *params;
    else
        ltfat_dgt_params_defaults(&paramsLoc);

    CHECKNULL( pout );
    CHECK(LTFATERR_BADTRALEN, !(L % minL),
          "L must divisible by lcm(a,M)=%d.", minL);

    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(dgtreal_plan)) );
    p->M = M, p->a = a, p->L = L, p->W = W, p->c = c; p->f = f;

    if (ltfat_dgt_long == paramsLoc.hint)
    {
        // Make the dual window longer if it is not already
        CHECKMEM( g2 = LTFAT_NAME_REAL(malloc)(L) );
        LTFAT_NAME(fir2long)(gs, gsl, L, g2);

        p->backtra = &LTFAT_NAME(idgtreal_long_execute_wrapper);
        p->backdonefunc = &LTFAT_NAME(idgtreal_long_done_wrapper);

        LTFAT_NAME(idgtreal_long_plan)* backtra_tmp = NULL;
        CHECKSTATUS(
            LTFAT_NAME(idgtreal_long_init)( g2, L, W, a, M, c, p->f, paramsLoc.ptype,
                                            paramsLoc.fftw_flags,
                                            &backtra_tmp));

        LTFAT_NAME(idgtreal_long_set_overwriteoutarray)(
            backtra_tmp, paramsLoc.do_synoverwrites);
        p->backtra_userdata = (void*) backtra_tmp;

        p->fwdtra = &LTFAT_NAME(dgtreal_long_execute_wrapper);
        p->fwddonefunc = &LTFAT_NAME(dgtreal_long_done_wrapper);

        // Ensure the original window is long enough
        LTFAT_NAME(fir2long)(ga, gal, L, g2);

        CHECKSTATUS(
            LTFAT_NAME(dgtreal_long_init)( g2, L, W, a, M, p->f, c, paramsLoc.ptype,
                                           paramsLoc.fftw_flags,
                                           (LTFAT_NAME(dgtreal_long_plan)**)&p->fwdtra_userdata));

        ltfat_safefree(g2);
    }
    else if ( ltfat_dgt_fb == paramsLoc.hint )
    {
        // Use _fb functions only
        p->backtra = &LTFAT_NAME(idgtreal_fb_execute_wrapper);
        p->backdonefunc = &LTFAT_NAME(idgtreal_fb_done_wrapper);

        LTFAT_NAME(idgtreal_fb_plan)* backtra_tmp = NULL;
        CHECKSTATUS(
            LTFAT_NAME(idgtreal_fb_init)( gs, gsl, a, M, paramsLoc.ptype,
                                          paramsLoc.fftw_flags,
                                          &backtra_tmp));

        LTFAT_NAME(idgtreal_fb_set_overwriteoutarray)(backtra_tmp,
                paramsLoc.do_synoverwrites);
        p->backtra_userdata = (void*) backtra_tmp;

        p->fwdtra = &LTFAT_NAME(dgtreal_fb_execute_wrapper);
        p->fwddonefunc = &LTFAT_NAME(dgtreal_fb_done_wrapper);

        CHECKSTATUS(
            LTFAT_NAME(dgtreal_fb_init)( ga, gal, a, M, paramsLoc.ptype,
                                         paramsLoc.fftw_flags,
                                         (LTFAT_NAME(dgtreal_fb_plan)**)&p->fwdtra_userdata));

    }
    else if ( ltfat_dgt_auto == paramsLoc.hint )
    {
        // Decide whether to use _fb or _long depending on the window lengths
        if (gsl < L)
        {
            p->backtra = &LTFAT_NAME(idgtreal_fb_execute_wrapper);
            p->backdonefunc = &LTFAT_NAME(idgtreal_fb_done_wrapper);

            LTFAT_NAME(idgtreal_fb_plan)* backtra_tmp = NULL;
            LTFAT_NAME(idgtreal_fb_init)( gs, gsl, a, M, paramsLoc.ptype,
                                          paramsLoc.fftw_flags,
                                          &backtra_tmp);

            LTFAT_NAME(idgtreal_fb_set_overwriteoutarray)(backtra_tmp,
                    paramsLoc.do_synoverwrites);
            p->backtra_userdata = (void*) backtra_tmp;
        }
        else
        {
            p->backtra = &LTFAT_NAME(idgtreal_long_execute_wrapper);
            p->backdonefunc = &LTFAT_NAME(idgtreal_long_done_wrapper);

            CHECKMEM( g2 = LTFAT_NAME_REAL(malloc)(L) );
            LTFAT_NAME(fir2long)(gs, gsl, L, g2);

            LTFAT_NAME(idgtreal_long_plan)* backtra_tmp = NULL;
            LTFAT_NAME(idgtreal_long_init)(g2, L, W, a, M, c, p->f, paramsLoc.ptype,
                                           paramsLoc.fftw_flags, &backtra_tmp);

            LTFAT_NAME(idgtreal_long_set_overwriteoutarray)(
                backtra_tmp, paramsLoc.do_synoverwrites);
            p->backtra_userdata = (void*) backtra_tmp;

            ltfat_safefree(g2);
        }

        if (gal < L)
        {
            p->fwdtra = &LTFAT_NAME(dgtreal_fb_execute_wrapper);
            p->fwddonefunc = &LTFAT_NAME(dgtreal_fb_done_wrapper);

            LTFAT_NAME(dgtreal_fb_init)(ga, gal, a, M, paramsLoc.ptype,
                                        paramsLoc.fftw_flags,
                                        (LTFAT_NAME(dgtreal_fb_plan)**)&p->fwdtra_userdata);

        }
        else
        {
            p->fwdtra = &LTFAT_NAME(dgtreal_long_execute_wrapper);
            p->fwddonefunc = &LTFAT_NAME(dgtreal_long_done_wrapper);

            CHECKMEM( g2 = LTFAT_NAME_REAL(malloc)(L) );
            LTFAT_NAME(fir2long)(ga, gal, L, g2);


            LTFAT_NAME(dgtreal_long_init)( g2, L, W, a, M, p->f, c, paramsLoc.ptype,
                                           paramsLoc.fftw_flags,
                                           (LTFAT_NAME(dgtreal_long_plan)**)&p->fwdtra_userdata);

            ltfat_safefree(g2);
        }
    }
    else
    {
        CHECKCANTHAPPEN("No such dgtreal hint");
    }

    *pout = p;

    return status;
error:
    ltfat_safefree(g2);
    if (p) LTFAT_NAME(dgtreal_done)(&p);
    return status;


}
