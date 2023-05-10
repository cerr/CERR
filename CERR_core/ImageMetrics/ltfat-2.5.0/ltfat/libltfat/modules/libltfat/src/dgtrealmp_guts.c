#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtrealmp_private.h"

#define NLOOP \
    for ( ltfat_int nidx = n2start, knidx = kstart2.n; \
          knidx < k->size.width; \
          nidx = ++nidx>=p->N[w2]? nidx - p->N[w2]: nidx, knidx+=k->astep )

#define NLOOPUNBOUNDED \
    for ( ltfat_int nidx = n2start, nidx2 = pos.n2-kmid2.wmid, knidx = kstart2.n; \
            knidx < k->size.width; \
            nidx = ++nidx>=p->N[w2]? nidx-p->N[w2]: nidx, nidx2++, knidx+=k->astep)

#define  NLOOPBOTH(body){\
for ( ltfat_int nidx = 0, knidx = kstart2.n + (kdim2.width-nover)*k->astep; \
    nidx < nover; nidx++, knidx+=k->astep ) { body}\
for ( ltfat_int nidx = n2start, knidx = kstart2.n; \
    nidx < n2end; nidx++, knidx+=k->astep ) { body}}

#define MLOOP \
    for ( ltfat_int midx = m2start, kmidx = kstart2.m;\
          kmidx < k->size.height;\
          midx = ++midx>=p->M[w2]? midx - p->M[w2]: midx, kmidx += k->Mstep)


#define  MLOOPBOTH(body){\
ltfat_int movertmp = ltfat_imin(mover - k->srange[knidx].end, p->M2[w2]);\
for ( ltfat_int midx = 0, mmidx = (kdim2.height-moverM2), kmidx = kstart2.m + mmidx*k->Mstep; \
    midx < movertmp; midx++, mmidx++, kmidx+=k->Mstep ) {body}\
\
ltfat_int m2endtmp = ltfat_imin(m2end - k->srange[knidx].end, p->M2[w2]);\
for ( ltfat_int mmidx = k->srange[knidx].start, midx = m2start + mmidx, kmidx = kstart2.m + mmidx*k->Mstep; \
    midx < m2endtmp; midx++, mmidx++, kmidx+=k->Mstep ) {body}}\

#define LTFAT_DGTREALMP_APPLYKERNEL(ctmp){\
LTFAT_COMPLEX cvaltmp = ctmp;\
if (do_substract){ LTFAT_DGTREALMP_APPLYKERNEL_SIGN(cvaltmp, -) }\
else{              LTFAT_DGTREALMP_APPLYKERNEL_SIGN(cvaltmp, +) }}

#define LTFAT_DGTREALMP_APPLYKERNEL_SIGN(ctmp, SIGN){\
if (p->params->ptype == LTFAT_TIMEINV){\
NLOOPBOTH(\
    LTFAT_COMPLEX* currcCol = s->c[w2] + nidx * p->M2[w2];\
    LTFAT_COMPLEX* kcurrCol = k->kval + knidx * k->size.height;\
    LTFAT_COMPLEX  cvaltmp2 = ctmp * kexp[knidx];\
MLOOPBOTH(\
    currcCol[midx] = currcCol[midx] SIGN (cvaltmp2) * kcurrCol[kmidx]; ))}\
else if (p->params->ptype == LTFAT_FREQINV){\
    for(ltfat_int kmidx = kstart2.m, mmidx = 0; kmidx < k->size.height;\
        kmidx += k->Mstep, mmidx++){\
        s->cvalModBuf[kIdx][mmidx] = ctmp * kexp[kmidx];}\
NLOOPBOTH(\
    LTFAT_COMPLEX* currcCol = s->c[w2] + nidx * p->M2[w2];\
    LTFAT_COMPLEX* kcurrCol = k->kval + knidx * k->size.height;\
MLOOPBOTH(\
    currcCol[midx] = currcCol[midx] SIGN s->cvalModBuf[kIdx][mmidx] * kcurrCol[kmidx]; \
    ))}}

#define LTFAT_DGTREALMP_MARKMODIFIED \
NLOOPBOTH(\
    LTFAT_NAME(maxtree_setdirty)(s->fmaxtree[w2][nidx],\
                                 m2start + k->srange[knidx].start,\
                                 m2start + kdim2.height - k->srange[knidx].end);)\
    LTFAT_NAME(maxtree_setdirty)(s->tmaxtree[w2],       n2start, n2start + kdim2.width);

int
LTFAT_NAME(dgtrealmp_execute_locomp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout)
{
    /* int status = LTFAT_DGTREALMP_STATUS_CANCONTINUE; */

    /* int uniquenyquest = p->M[origpos.w] % 2 == 0; */
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;

    int count = s->suppind[PTOI(origpos)];
    DEBUG("\n*****************\n Count %d \n ****************", count);
    if (count > 10)
    {
        /* status = LTFAT_DGTREALMP_STATUS_LOCOMP_ORTHFAILED; break; */
    }

    // STEP 1: Find all active atoms around the current one
    ltfat_int cvalNo = 0;

    /* LTFAT_NAME(kerns)* k1 = p->gramkerns[origpos.w + s->P * origpos.w]; */
    /* int do_conjat = 0; */
    /* if (  (k1->mid.hmid + 2 * origpos.m) < k1->size.height ) */
    /*     do_conjat = 1; */

    s->cvalBuf[cvalNo] = s->c[PTOI(origpos)];
    s->cvalBufPos[cvalNo] = origpos;
    cvalNo++;

    for (ltfat_int w2 = 0; w2 < s->P; w2++)
    {
        kpoint pos = kpoint_init(0, 0, w2);
        ltfat_int m2start, n2start;
        ksize   kdim2; kanchor kmid2; kpoint  kstart2;

        LTFAT_NAME(dgtrealmp_execute_indices)(
            p, origpos, &pos, &m2start, &n2start,
            &kdim2, &kmid2, &kstart2);

        LTFAT_NAME(kerns)* k = p->gramkerns[origpos.w + s->P * w2];

        NLOOPUNBOUNDED
        {
            unsigned int* suppCol = s->suppind[w2] + nidx * p->M2[w2];

            MLOOP
            {
                if ( midx == origpos.m && nidx == origpos.n && w2 == origpos.w) continue;
                if ( midx >= k->size.height && midx < p->M2[w2] - k->size.height && suppCol[midx])
                {
                    kpoint cvalPos = kpoint_init2(midx, nidx, nidx2, w2);
                    s->cvalBuf[cvalNo] = s->c[PTOI(cvalPos)];
                    s->cvalBufPos[cvalNo] = cvalPos;
                    cvalNo++;

                    /* if ( midx > 0 && do_conjat ) */
                    /* { */
                    /*     cvalPos.m =  -midx; */
                    /*     s->cvalBuf[cvalNo] = conj(s->cvalBuf[cvalNo - 1]); */
                    /*     s->cvalBufPos[cvalNo] = cvalPos; */
                    /*     cvalNo++; */
                    /*     DEBUGNOTE("PRD***********************************"); */
                    /* } */
                }
            }
        }
    }

#ifndef NDEBUG
    for (ltfat_int cidx = 0; cidx < cvalNo; cidx++)
    {
        kpoint cvalPos = s->cvalBufPos[cidx];
        LTFAT_COMPLEX cval =  s->cvalBuf[cidx];
        DEBUG("m=%td,n=%td,w=%td, r=% 5.3e,i=% 5.3e",
              cvalPos.m, cvalPos.n, cvalPos.w, ltfat_real(cval), ltfat_imag(cval));
    }
    DEBUGNOTE("--------------------");
#endif

    memcpy(s->cvalinvBuf, s->cvalBuf, cvalNo * sizeof * s->cvalinvBuf);

    if (cvalNo > 1)
    {

        /* cvalNo = 1; */
        /* kpoint cvalPos; cvalPos.m = m; cvalPos.n = n; cvalPos.w = w; */
        /* s->cvalBuf[0] = s->c[PTOI(cvalPos)]; */
        /* s->cvalBufPos[0] = cvalPos; */

        LTFAT_NAME_COMPLEX(clear_array)( s->gramBuf, cvalNo * cvalNo);
        /* memset(s->gramBuf, 0, cvalNo * cvalNo * sizeof * s->gramBuf); */
        // STEP 2: Construct the Gram matrix
        for (ltfat_int cidx1 = 0; cidx1 < cvalNo; cidx1++)
        {
            kpoint cvalPos            = s->cvalBufPos[cidx1];
            LTFAT_COMPLEX* gramBufCol = s->gramBuf + cidx1 * cvalNo;

            gramBufCol[cidx1] = 1;

            for (ltfat_int cidx2 = cidx1 + 1; cidx2 < cvalNo; cidx2++)
            {
                kpoint cvalPos2      = s->cvalBufPos[cidx2];
                kpoint pos           = cvalPos2;
                LTFAT_NAME(kerns)* k =
                    p->gramkerns[cvalPos.w + s->P * cvalPos2.w];

                /* LTFAT_COMPLEX* kvals = */
                /*     LTFAT_NAME(dgtrealmp_execute_pickkernel)( */
                /*         k, cvalPos.m, cvalPos.n, p->params->ptype); */

                ltfat_int m2start, n2start;
                ksize   kdim2; kanchor kmid2; kpoint kstart2;

                LTFAT_NAME(dgtrealmp_execute_indices)(
                    p, cvalPos, &pos, &m2start, &n2start, &kdim2,
                    &kmid2, &kstart2);

                ltfat_int muse = cvalPos2.m  - pos.m  + kmid2.hmid;
                ltfat_int nuse = cvalPos2.n2 - pos.n2 + kmid2.wmid;

                if ( muse >= 0 && muse < kdim2.height &&
                     nuse >= 0 && nuse < kdim2.width )
                    gramBufCol[cidx2] =
                        (k->kval[k->size.height * (kstart2.n + k->astep * nuse) +
                                 k->Mstep * muse + kstart2.m]);
                else
                    gramBufCol[cidx2] = 0;
            }
        }

        /* #ifndef NDEBUG */
        /*             printf("\n"); */
        /*             for (ltfat_int m = 0; m < cvalNo; m++ ) */
        /*             { */
        /*                 for (ltfat_int n = 0; n < cvalNo; n++ ) */
        /*                 { */
        /*                     printf("r=% 2.3e,i=% 2.3e ", ltfat_real(s->gramBuf[n * cvalNo + m]), */
        /*                            ltfat_imag(s->gramBuf[n * cvalNo + m])); */
        /*                 } */
        /*                 printf("\n"); */
        /*             } */
        /* #endif */


        // STEP 3: Invert that S**T
        if ( LTFAT_NAME_COMPLEX(hermsystemsolver_execute)(
                 s->hplan, s->gramBuf, cvalNo, s->cvalinvBuf) )
        {
            /* status = LTFATERR_NOTPOSDEFMATRIX; */
            return LTFAT_DGTREALMP_STATUS_LOCOMP_NOTHERM;
        }
    }
#ifndef NDEBUG
    for (ltfat_int cidx = 0; cidx < cvalNo; cidx++)
    {
        kpoint cvalPos = s->cvalBufPos[cidx];
        LTFAT_COMPLEX cval =  s->cvalinvBuf[cidx];
        DEBUG("m=%td,n=%td,n2=%td, r=% 2.3e,i=% 2.3e",
              cvalPos.m, cvalPos.n, cvalPos.n2, ltfat_real(cval), ltfat_imag(cval));
    }
    DEBUGNOTE("------------+-------");
#endif

    // STEP 4: Update result and the residuum
    for (ltfat_int cidx = 0; cidx < cvalNo; cidx++)
    {
        LTFAT_COMPLEX cvalinv = s->cvalinvBuf[cidx];
        /* LTFAT_COMPLEX cval = s->cvalBuf[cidx]; */
        kpoint cvalPos     = s->cvalBufPos[cidx];
        if (cvalPos.m < 0) continue;

        s->err -= LTFAT_NAME(dgtrealmp_execute_mp)( p, cvalinv, cvalPos, cout);

        /* int do_conj = !( cvalPos.m == 0 || (cvalPos.m == p->M2[cvalPos.w] - 1 */
        /*                                     && uniquenyquest)); */
        /*  */
        /* LTFAT_COMPLEX atprod = */
        /*     LTFAT_NAME(dgtrealmp_execute_conjatpairprod)( p, cvalPos); */
        /*  */
        /* cvalinv = (cvalinv - (atprod) * conj(cvalinv)) / (1.0 - ltfat_norm(atprod)); */
        /*  */
        /* LTFAT_REAL atenergy = */
        /*     LTFAT_NAME(dgtrealmp_execute_atenergy)( atprod, cvalinv); */
        /*  */
        /* #<{(| cvalinv *= atenergy; |)}># */
        /*  */
        /* cout[PTOI(cvalPos)] += cvalinv; */
        /*  */
        /* LTFAT_REAL cvalabs = ltfat_norm(cvalinv) * atenergy; */
        /*  */
        /* s->err -= cvalabs ; */
        /* if (do_conj) s->err -= cvalabs ; */
        /*  */
        /* LTFAT_NAME(dgtrealmp_execute_updateresiduum)( p, */
        /*         cvalPos, cvalinv,  1); */

    }

    return LTFAT_DGTREALMP_STATUS_CANCONTINUE;
}

int
LTFAT_NAME(dgtrealmp_execute_selfprojmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;

    s->err -= LTFAT_NAME(dgtrealmp_execute_mp)(
                  p, s->c[PTOI(origpos)], origpos, cout);

    LTFAT_NAME(dgtrealmp_execute_findneighbors)(p, origpos, s->pBuf, &s->pBufNo);

    if ( s->pBufNo == 1 )
        return LTFAT_DGTREALMP_STATUS_CANCONTINUE;

    for (size_t cycl = 0; cycl < p->params->cycles; cycl++ )
    {
        for (int pIdx2 = s->pBufNo -1; pIdx2 >= 0 ; pIdx2--)
        {
            kpoint spmax = s->pBuf[0];
            LTFAT_REAL projenergymax;

            LTFAT_COMPLEX dummy_cvaldual;
            LTFAT_NAME(dgtrealmp_execute_dualprodandprojenergy)(
                p, spmax, s->c[PTOI(spmax)], &dummy_cvaldual, &projenergymax);

            for (int pIdx = s->pBufNo -1; pIdx > 0 ; pIdx--)
            {
                kpoint pp = s->pBuf[pIdx];

                LTFAT_REAL projenergy;
                LTFAT_NAME(dgtrealmp_execute_dualprodandprojenergy)(
                    p, pp, s->c[PTOI(pp)], &dummy_cvaldual, &projenergy);

                if(projenergy > projenergymax)
                {
                    projenergymax = projenergy;
                    spmax = pp;
                }
            }

            if(projenergymax < 1e-8) break;

            s->err -= LTFAT_NAME(dgtrealmp_execute_mp)(
                        p, s->c[PTOI(spmax)], spmax, cout);
        }


    }
    return LTFAT_DGTREALMP_STATUS_CANCONTINUE;
}

int
LTFAT_NAME(dgtrealmp_execute_cyclicmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;

    // Normal MP step
    s->err -= LTFAT_NAME(dgtrealmp_execute_mp)(
                  p, s->c[PTOI(origpos)], origpos, cout);

    LTFAT_NAME(dgtrealmp_execute_findneighbors)(p, origpos, s->pBuf, &s->pBufNo);

    // There are no neighbors
    if ( s->pBufNo == 1 )
        return LTFAT_DGTREALMP_STATUS_CANCONTINUE;

    for (size_t cycl = 0; cycl < p->params->cycles; cycl++ )
    {
        for (int pIdx = s->pBufNo -1; pIdx >= 0 ; pIdx--)
        {
            kpoint dummypos;
            LTFAT_NAME(dgtrealmp_execute_findmaxatom)( p, &dummypos);
            long double erratomstart = s->err;

            kpoint* pos = &s->pBuf[pIdx];

            long double inverr =
                LTFAT_NAME(dgtrealmp_execute_invmp)( p, *pos, cout);

            s->err += inverr;

            s->suppind[PTOI((*pos))] = 0;
            s->curratoms--;
            LTFAT_NAME(dgtrealmp_execute_findmaxatom)(p, pos);
            if ( !s->suppind[PTOI((*pos))] ) s->curratoms++;

            long double fwderr =
                LTFAT_NAME(dgtrealmp_execute_mp)( p, s->c[PTOI((*pos))] , *pos, cout);

            s->err -= fwderr;

            long double erratomend = s->err;
            if( (erratomstart - erratomend) < (long double) (-1e-6))
            {
                // The selected atom is worse! 
                // printf("itno:%td, errdif=%.8Lf\n", s->currit , erratomstart - erratomend);
                return LTFAT_DGTREALMP_STATUS_STALLED;
            }
        }
    }
    return LTFAT_DGTREALMP_STATUS_CANCONTINUE;
}

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_mp)(
    LTFAT_NAME(dgtrealmp_state)* p, LTFAT_COMPLEX cval,
    kpoint pos, LTFAT_COMPLEX** cout)
{
    LTFAT_COMPLEX cvaldual;
    LTFAT_REAL projenergy;
    LTFAT_NAME(dgtrealmp_execute_dualprodandprojenergy)(
               p, pos, cval, &cvaldual, &projenergy);

    LTFAT_NAME(dgtrealmp_execute_updateresiduum)( p, pos, cvaldual, 1);

    p->iterstate->suppind[PTOI(pos)]++;
    cout[PTOI(pos)] += cvaldual;
    return projenergy;
}

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_invmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint pos, LTFAT_COMPLEX** cout)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;

    int uniquenyquest = p->M[pos.w] % 2 == 0;
    int do_conj = !( pos.m == 0 || (pos.m == p->M2[pos.w] - 1
                                    && uniquenyquest));
    LTFAT_COMPLEX coutval = cout[PTOI(pos)];
    cout[PTOI(pos)] = LTFAT_COMPLEX(0.0, 0.0);
    LTFAT_COMPLEX cresval = s->c[PTOI(pos)];

    LTFAT_COMPLEX atinprod;
    LTFAT_REAL oneover1minatprodnorm;
    LTFAT_NAME(dgtrealmp_execute_conjatpairprod)( 
            p, pos, &atinprod, &oneover1minatprodnorm);

    LTFAT_REAL plusatenergy =
        LTFAT_NAME(dgtrealmp_execute_projenergy)( atinprod, coutval)
        + (LTFAT_REAL)(4.0) * ltfat_real( cresval  * conj(coutval));

    if (!do_conj) plusatenergy /= 2.0;

    LTFAT_NAME(dgtrealmp_execute_updateresiduum)(
        p, pos, coutval, 0);

    return plusatenergy;
}

void
LTFAT_NAME(dgtrealmp_execute_dualprodandprojenergy)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos, LTFAT_COMPLEX cval,
    LTFAT_COMPLEX* cvaldual, LTFAT_REAL* projenergy)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;
    int uniquenyquest = p->M[pos.w] % 2 == 0;
    int do_conj = !( pos.m == 0 || (pos.m == p->M2[pos.w] - 1 && uniquenyquest));

    LTFAT_NAME(kerns)* k = p->gramkerns[pos.w + s->P * pos.w];

    *cvaldual = cval;
    *projenergy = ltfat_norm(cval);

    if (do_conj)
    {
        if ( pos.m < k->atprodsNo )
        {
            LTFAT_COMPLEX atinprod = (k->atprods[pos.m]);
            if (p->params->ptype == LTFAT_FREQINV)
                atinprod *= k->mods[ltfat_positiverem(pos.n, k->kNo)][-2*pos.m  + k->mid.hmid];

            *cvaldual = (cval - conj(cval)*conj(atinprod))*k->oneover1minatprodnorms[pos.m];
            *projenergy = LTFAT_NAME(dgtrealmp_execute_projenergy)( atinprod, *cvaldual);
            return;
        }

        ltfat_int posinkern = p->M2[pos.w] - pos.m - uniquenyquest;
        if ( posinkern < k->atprodsNo )
        {
            LTFAT_COMPLEX atinprod = (k->atprods[posinkern]);

            if (p->params->ptype == LTFAT_FREQINV)
                atinprod *= k->mods[ltfat_positiverem(pos.n, k->kNo)][2*posinkern + k->mid.hmid];

            *cvaldual = (cval - conj(cval)*conj(atinprod))*k->oneover1minatprodnorms[posinkern];
            *projenergy = LTFAT_NAME(dgtrealmp_execute_projenergy)( atinprod, *cvaldual);
            return;
        }
        *projenergy *= 2.0;
    }
}

void
LTFAT_NAME(dgtrealmp_execute_conjatpairprod)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos, LTFAT_COMPLEX* atinprod, LTFAT_REAL* oneover1minatprodnorm)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;
    int uniquenyquest = p->M[pos.w] % 2 == 0;
    int do_conj = !( pos.m == 0 || (pos.m == p->M2[pos.w] - 1 && uniquenyquest));

    LTFAT_NAME(kerns)* k = p->gramkerns[pos.w + s->P * pos.w];

    *atinprod = LTFAT_COMPLEX(0.0, 0.0);
    *oneover1minatprodnorm = 1.0;

    if (do_conj)
    {
        if ( pos.m < k->atprodsNo )
        {
            *atinprod = k->atprods[pos.m];
            if (p->params->ptype == LTFAT_FREQINV)
                *atinprod *= k->mods[ltfat_positiverem(pos.n, k->kNo)][-2*pos.m  + k->mid.hmid];

            *oneover1minatprodnorm = k->oneover1minatprodnorms[pos.m];
        }

        ltfat_int posinkern = p->M2[pos.w] - pos.m - uniquenyquest;
        if ( posinkern < k->atprodsNo )
        {
            *atinprod = conj(k->atprods[posinkern]);

            if (p->params->ptype == LTFAT_FREQINV)
                *atinprod *= k->mods[ltfat_positiverem(pos.n, k->kNo)][2*posinkern + k->mid.hmid];

            *oneover1minatprodnorm = k->oneover1minatprodnorms[posinkern];
        }
    }
}


int
LTFAT_NAME(dgtrealmp_execute_updateresiduum)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint origpos, LTFAT_COMPLEX cval,
    int do_substract)
{


    int uniquenyquest = p->M[origpos.w] % 2 == 0;
    int do_conj = !( origpos.m == 0 ||
                     (origpos.m == p->M2[origpos.w] - 1 && uniquenyquest));

    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;
    LTFAT_COMPLEX cval2 = conj(cval);
    kpoint origposconj = origpos;
    origposconj.m = p->M[origpos.w] - origpos.m;

    /* This loop is trivially pararelizable */
    for (ltfat_int w2 = 0; w2 < s->P; w2++)
    {
        ltfat_int  m2start, n2start, m2end, mover, n2end, nover, moverM2;
        kpoint pos;
        ksize   kdim2; kanchor kmid2; kpoint  kstart2;

        ltfat_int kIdx = origpos.w + s->P * w2;
        LTFAT_NAME(kerns)* k     = p->gramkerns[kIdx];
        LTFAT_COMPLEX* kexp = LTFAT_NAME(dgtrealmp_execute_pickmod)(
                                  k, origpos.m, origpos.n, p->params->ptype);

        pos.w = w2;
        LTFAT_NAME(dgtrealmp_execute_indices)(
            p, origpos, &pos, &m2start, &n2start, &kdim2, &kmid2, &kstart2);

        m2end = m2start + kdim2.height;
        mover = ltfat_imax(0, m2end - p->M[w2]);
        moverM2 = mover;
        if (kdim2.height > p->M2[w2])
            moverM2 = kdim2.height - ltfat_imax(0, p->M[w2] - m2start);
        /* m2start = ltfat_imin(m2start, p->M2[w2]); */

        n2end = n2start + kdim2.width;
        nover = ltfat_imax(0, n2end - p->N[w2]);
        if (nover > 0)
            n2end = p->N[w2];

        LTFAT_DGTREALMP_APPLYKERNEL(cval)

        LTFAT_DGTREALMP_MARKMODIFIED

        ltfat_int posinkern  = kmid2.hmid - 2 * pos.m;
        ltfat_int posinkern2 = kmid2.hmid + 2 * (p->M2[w2] - 1 - pos.m) + 1 -
                               uniquenyquest ;
        if (do_conj)
        {
            if (posinkern >= 0 || posinkern2 < kdim2.height)
            {
                kexp = LTFAT_NAME(dgtrealmp_execute_pickmod)(
                           k, origposconj.m, origpos.n, p->params->ptype);

                LTFAT_NAME(dgtrealmp_execute_indices)(
                    p, origposconj, &pos, &m2start, &n2start, &kdim2, &kmid2, &kstart2);

                m2end = m2start + kdim2.height;
                mover = ltfat_imax(0, m2end - p->M[w2]);
                moverM2 = mover;
                if (kdim2.height > p->M2[w2])
                    moverM2 = kdim2.height - ltfat_imax(0, p->M[w2] - m2start);
                /* m2end = ltfat_imin(m2end, p->M2[w2]); */

                LTFAT_DGTREALMP_APPLYKERNEL(cval2)
            }
        }

    }
    return 0;
}

inline LTFAT_COMPLEX*
LTFAT_NAME(dgtrealmp_execute_pickmod)(
    LTFAT_NAME(kerns)* k, ltfat_int m, ltfat_int n,
    ltfat_phaseconvention pconv)
{
    if (pconv == LTFAT_FREQINV)
        return k->mods[ltfat_positiverem( n*k->kSkip, k->kNo)];
    else if (pconv == LTFAT_TIMEINV)
        return k->mods[ltfat_positiverem( m*k->kSkip, k->kNo)];
    else
        return NULL;
}

inline int
LTFAT_NAME(dgtrealmp_execute_indices)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint origpos, kpoint* pos,
    ltfat_int* m2start, ltfat_int* n2start,
    ksize* kdim2, kanchor* kmid2, kpoint* kstart2)
{
    LTFAT_NAME(kerns)* k     = p->gramkerns[origpos.w + p->P * pos->w];

    pos->n    = (ltfat_int) ltfat_round( origpos.n / k->arat);
    pos->m    = (ltfat_int) ltfat_round( origpos.m / k->Mrat);

    ltfat_int n2off = origpos.n - (ltfat_int)(pos->n * k->arat);
    ltfat_int m2off = origpos.m - (ltfat_int)(pos->m * k->Mrat);

    *kdim2 = k->size;
    *kmid2 = k->mid;
    kmid2->hmid = (k->mid.hmid - m2off) / k->Mstep;
    kmid2->wmid = (k->mid.wmid - n2off) / k->astep;

    *m2start = pos->m - kmid2->hmid;
    *m2start = *m2start < 0 ? *m2start + p->M[pos->w] : *m2start;
    *n2start = pos->n - kmid2->wmid;
    *n2start = *n2start < 0 ? *n2start + p->N[pos->w] : *n2start;

    kstart2->m = k->mid.hmid - m2off - kmid2->hmid * k->Mstep;
    kstart2->n = k->mid.wmid - n2off - kmid2->wmid * k->astep;

    kdim2->height = ltfat_idivceil(kdim2->height - kstart2->m, k->Mstep);
    kdim2->width  = ltfat_idivceil(kdim2->width  - kstart2->n, k->astep);

    return 0;
}

int
LTFAT_NAME(dgtrealmp_execute_findmaxatom)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint* pos)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;
    LTFAT_REAL val = 0.0;
    int retval = LTFATERR_CANNOTHAPPEN;

    for (ltfat_int k = 0; k < s->P; k++)
    {
        LTFAT_REAL valTmp; ltfat_int nTmp;
        ltfat_int dirtystart, dirtyend;
        LTFAT_NAME(maxtree_getdirty)(s->tmaxtree[k], &dirtystart, &dirtyend);

        ltfat_int N = p->N[k];

        dirtystart = ltfat_positiverem(dirtystart, N);
        dirtyend =   ltfat_positiverem(dirtyend,   N);

        ltfat_int over = 0;
        if (dirtyend < dirtystart)
        {
            over = dirtyend;
            dirtyend = N;
        }

        for (ltfat_int nidx = 0; nidx < over; nidx++)
            LTFAT_NAME(maxtree_findmax)( s->fmaxtree[k][nidx],
                                         &s->maxcols[k][nidx],
                                         &s->maxcolspos[k][nidx]);

        for (ltfat_int nidx = dirtystart; nidx < dirtyend; nidx++)
            LTFAT_NAME(maxtree_findmax)( s->fmaxtree[k][nidx],
                                         &s->maxcols[k][nidx],
                                         &s->maxcolspos[k][nidx]);

        LTFAT_NAME(maxtree_findmax)(s->tmaxtree[k], &valTmp, &nTmp);

        if ( valTmp > val )
        {
            val = valTmp; pos->m = s->maxcolspos[k][nTmp]; pos->n = nTmp; pos->w = k;
            retval = LTFATERR_SUCCESS;
        }
    }
    return retval;
}

int
LTFAT_NAME(dgtrealmp_execute_findneighbors)(
        LTFAT_NAME(dgtrealmp_state)* p, kpoint origpos,
        kpoint* nBuf, size_t* nCount)
{
    LTFAT_NAME(dgtrealmpiter_state)* s = p->iterstate;
    *nCount = 0;
    nBuf[(*nCount)++] = origpos;

    for (ltfat_int w2 = 0; w2 < s->P; w2++)
    {
        ltfat_int m2start, n2start;
        ksize   kdim2; kanchor kmid2; kpoint  kstart2;
        kpoint pos; pos.w = w2;

        LTFAT_NAME(dgtrealmp_execute_indices)(
            p, origpos, &pos, &m2start, &n2start,
            &kdim2, &kmid2, &kstart2);

        LTFAT_NAME(kerns)* k = p->gramkerns[origpos.w + s->P * w2];

        NLOOP
        {
            unsigned int* suppCol = s->suppind[w2] + nidx * p->M2[w2];
            MLOOP
            {
                if ( (midx >= 0 && midx < p->M2[w2] ) && suppCol[midx])
                {
                    pos = kpoint_init(midx, nidx, w2);

                    int alreadyhave = 0;
                    for (size_t pIdx = 0; pIdx < *nCount; pIdx++ )
                        if ((alreadyhave = kpoint_isequal(nBuf[pIdx], pos))) break;

                    if (!alreadyhave) nBuf[(*nCount)++] = pos;
                }
            }
        }
    }

    return 0;
}

#ifdef NOBLASLAPACK

LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_init)(ltfat_int UNUSED(M),
        LTFAT_NAME_COMPLEX(hermsystemsolver_plan)** UNUSED(p)) {return 0;}


LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_execute)(
    LTFAT_NAME_COMPLEX(hermsystemsolver_plan)* UNUSED(p),
    const LTFAT_COMPLEX* UNUSED(A), ltfat_int UNUSED(M),
    LTFAT_COMPLEX* UNUSED(b)) {return 0;}

LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_done)(
    LTFAT_NAME_COMPLEX(hermsystemsolver_plan)** UNUSED(p)) {return 0;}
#endif
