#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

struct LTFAT_NAME(maxtree)
{
    ltfat_int dirtystart;
    ltfat_int dirtyend;
    LTFAT_REAL*  pointedarray;
    LTFAT_REAL*  treeVals;
    LTFAT_REAL** treePtrs;
    ltfat_int*   treePos;
    ltfat_int**  treePosPtrs;
    ltfat_int    depth;
    ltfat_int    L;
    ltfat_int    Lstep;
    ltfat_int    nextL;
    ltfat_int*   levelL;
    ltfat_int    W;
    int is_complexinput;
    LTFAT_NAME(maxtree_complexinput_callback)* callback;
    void* userdata;
};

LTFAT_API int
LTFAT_NAME(maxtree_setcallback)(LTFAT_NAME(maxtree)* p,
        LTFAT_NAME(maxtree_complexinput_callback)* callback,
        void* userdata)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(callback);
    p->callback = callback;
    p->userdata = userdata;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(maxtree_init)(
    ltfat_int L, ltfat_int Lstep, ltfat_int depth,
    LTFAT_NAME(maxtree)** pout)
{
    LTFAT_NAME(maxtree)* p = NULL;
    ltfat_int nextL, granL, cumL;
    int status = LTFATERR_SUCCESS;

    CHECK(LTFATERR_NOTPOSARG, L > 0,
          "L must be positive (passed %td)" , L);
    CHECK(LTFATERR_BADARG, depth >= 0,
          "depth must be zero or greater (passed %td)", depth);

    granL = 1 << (depth);

    while ( granL > 2 * L )
        granL = 1 << (--depth);

    nextL = granL * ((L + granL - 1 ) / granL);

    CHECKMEM( p = LTFAT_NEW( LTFAT_NAME(maxtree)) );
    CHECKMEM( p->levelL = LTFAT_NEWARRAY(ltfat_int, depth + 1) );
    CHECKMEM( p->treePtrs = LTFAT_NEWARRAY(LTFAT_REAL*, depth + 1) );

    p->levelL[depth] = L;
    for (ltfat_int d = 1; d < depth + 1; d++)
    {
        ltfat_int Llevel = ltfat_idivceil(L, 1 << (d));
        p->levelL[depth - d] = Llevel + Llevel%2;
    }

    if (depth > 0)
    {

        CHECKMEM( p->treeVals = LTFAT_NAME_REAL(calloc)( nextL ));
        CHECKMEM( p->treePos = LTFAT_NEWARRAY(ltfat_int, nextL ) );
        CHECKMEM( p->treePosPtrs = LTFAT_NEWARRAY(ltfat_int*, depth ) );

        cumL = 0;
        for (ltfat_int d = 0; d < depth; d++)
        {
            p->treePosPtrs[d] = p->treePos + cumL;
            p->treePtrs[d] = p->treeVals + cumL;
            cumL += p->levelL[d];
        }
    }

    p->depth = depth; p->L = L; p->nextL = nextL; p->Lstep = Lstep;

    p->dirtystart = p->Lstep;
    p->dirtyend   = 0;

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(maxtree_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(maxtree_done)(LTFAT_NAME(maxtree)** p)
{
    LTFAT_NAME(maxtree)* pp = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    ltfat_safefree(pp->treeVals);
    ltfat_safefree(pp->treePos);
    ltfat_safefree(pp->levelL);
    ltfat_safefree(pp->treePtrs);
    ltfat_safefree(pp->treePosPtrs);

    ltfat_free(pp);
    *p = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(maxtree_initwitharray)(
    ltfat_int L, ltfat_int depth, const LTFAT_REAL inarray[],
    LTFAT_NAME(maxtree)** pout)
{
    LTFAT_NAME(maxtree)* p = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS( LTFAT_NAME(maxtree_init)( L, L, depth, &p));
    CHECKSTATUS( LTFAT_NAME(maxtree_reset)( p, inarray));

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(maxtree_done)(&p);
    return status;
}


LTFAT_API int
LTFAT_NAME(maxtree_reset_complex)(
    LTFAT_NAME(maxtree)* p, const LTFAT_COMPLEX inarray[])
{
    p->treePtrs[p->depth] = (LTFAT_REAL*) inarray;
    p->is_complexinput = 1;

    return LTFAT_NAME(maxtree_updaterange)(p, 0, p->L);
}

LTFAT_API int
LTFAT_NAME(maxtree_reset)(
    LTFAT_NAME(maxtree)* p, const LTFAT_REAL inarray[])
{
    p->treePtrs[p->depth] = (LTFAT_REAL*) inarray;
    p->is_complexinput = 0;

    return LTFAT_NAME(maxtree_updaterange)(p, 0, p->L);
}


LTFAT_API int
LTFAT_NAME(maxtree_setdirty)(LTFAT_NAME(maxtree)* p, ltfat_int start,
                             ltfat_int end)
{
    if (start < p->dirtystart) p->dirtystart = start;
    if (end   > p->dirtyend)  p->dirtyend  = end;
    return 0;
}

LTFAT_API int
LTFAT_NAME(maxtree_getdirty)(LTFAT_NAME(maxtree)* p, ltfat_int* start,
                             ltfat_int* end)
{
    *start = p->dirtystart;
    *end   = p->dirtyend;
    return 0;
}

int
LTFAT_NAME(maxtree_updatedirty)(LTFAT_NAME(maxtree)* p)
{
    if ( p->dirtyend <= p->dirtystart )
        return 1;

    int ret = LTFAT_NAME(maxtree_updaterange)(p, p->dirtystart, p->dirtyend);
    p->dirtystart = p->Lstep;
    p->dirtyend   = 0;
    return ret;
}

int
LTFAT_NAME(maxtree_updaterange)(LTFAT_NAME(maxtree)* p, ltfat_int start,
                                ltfat_int end)
{
    if (p->depth == 0) return 0;

    if (end > p->Lstep)
    {
        ltfat_int over = end - p->Lstep;
        LTFAT_NAME(maxtree_updaterange)( p, 0, over);
    }

    if (end > p->L) end = p->L;
    if (start >= end) return 0;

    ltfat_int parity = 0;
    parity =  end == p->L ? end % 2 : 0;
    start = start - start % 2;
    end   = end   + end % 2;
    start = start >> 1; end = end >> 1;

    LTFAT_REAL* treeVal = p->treePtrs[p->depth];
    LTFAT_REAL* treeValnext = p->treePtrs[p->depth - 1];
    ltfat_int* treePosnext = p->treePosPtrs[p->depth - 1];

    ltfat_int endmpar = end - parity - start;
    ltfat_int newl = start - 1;

    for (ltfat_int l = 0; l < endmpar; l++)
    {
        newl++;
        ltfat_int twol = newl << 1;
        ltfat_int twolp1 = twol + 1;
        LTFAT_REAL tv1, tv2;
        if (p->is_complexinput)
        {
            if(p->callback)
            {
                tv1 = p->callback(p->userdata, *((LTFAT_COMPLEX*)&treeVal[2 * twol]), twol);
                tv2 = p->callback(p->userdata, *((LTFAT_COMPLEX*)&treeVal[2 * twolp1]), twolp1);
            }
            else
            {
                tv1 = treeVal[2 * twol] * treeVal[2 * twol] +
                      treeVal[2 * twol + 1] * treeVal[2 * twol + 1];
                tv2 = treeVal[2 * twolp1] * treeVal[2 * twolp1] +
                      treeVal[2 * twolp1 + 1] * treeVal[2 * twolp1 + 1];
            }
        }
        else
        {
            tv1 = treeVal[twol];
            tv2 = treeVal[twolp1];
        }

        if ( tv1 > tv2)
        {
            treeValnext[newl] = tv1;
            treePosnext[newl] = twol;
        }
        else
        {
            treeValnext[newl] = tv2;
            treePosnext[newl] = twolp1;
        }
    }

    if ( parity )
    {
        ltfat_int lastl = 2 * (end - 1);
        if (p->is_complexinput)
        {
            if(p->callback)
                treeValnext[end - 1] =
                    p->callback(p->userdata, *((LTFAT_COMPLEX*)&treeVal[2 * lastl]), lastl);
            else
                treeValnext[end - 1] =
                    treeVal[2 * lastl] * treeVal[2 * lastl] +
                    treeVal[2 * lastl + 1] * treeVal[2 * lastl + 1];
        }
        else
            treeValnext[end - 1] = treeVal[lastl];

        treePosnext[end - 1] = 2 * (end - 1);
    }

    for (ltfat_int d = p->depth - 1; d > 0; d--)
    {
        start = start - start % 2;
        end   = end   + end % 2;
        start = start >> 1; end = end >> 1;

        treeVal     = p->treePtrs[d];
        treeValnext = p->treePtrs[d - 1];
        ltfat_int* treePos      = p->treePosPtrs[d];
        treePosnext  = p->treePosPtrs[d - 1];

        endmpar = end - start;
        newl = start - 1;

        for (ltfat_int l = 0; l < endmpar; l++)
        {
            newl++;
            ltfat_int twol = newl << 1;
            ltfat_int twolp1 = twol + 1;
            LTFAT_REAL tv1 = treeVal[twol];
            LTFAT_REAL tv2 = treeVal[twolp1];
            if ( tv1 > tv2)
            {
                treeValnext[newl] = tv1;
                treePosnext[newl] = treePos[twol];
            }
            else
            {
                treeValnext[newl] = tv2;
                treePosnext[newl] = treePos[twolp1];
            }
        }
    }

    return 0;
}

LTFAT_API int
LTFAT_NAME(maxtree_findmax)(LTFAT_NAME(maxtree)* p, LTFAT_REAL* max,
                            ltfat_int* maxPos)
{
    LTFAT_NAME(maxtree_updatedirty)(p);

    if(  p->is_complexinput && p->depth == 0 )
    {
        LTFAT_COMPLEX* toplevel = (LTFAT_COMPLEX*)p->treePtrs[0];
        *maxPos = 0;
        if(p->callback)
        {
            *max =  p->callback(p->userdata, toplevel[0], 0);
            for(ltfat_int l = 1; l< p->levelL[0]; l++)
            {
                LTFAT_REAL tmpenergy = p->callback(p->userdata, toplevel[l], l);
                if( tmpenergy > *max )
                {
                    *max = tmpenergy;
                    *maxPos = l;
                }
            }
        }
        else
        {
            LTFAT_COMPLEX maxc;
            LTFAT_NAME_COMPLEX(findmaxinarray)(toplevel, p->levelL[0], &maxc, maxPos);
            *max = ltfat_energy(maxc);
        }
    }
    else
    {
        LTFAT_NAME_REAL(findmaxinarray)(p->treePtrs[0], p->levelL[0],
                                        max, maxPos);
    }

    if (p->depth > 0)
        *maxPos = p->treePos[*maxPos];
    return 0;
}
