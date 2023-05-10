#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

/* typedef enum */
/* { */
/*     DSTI = FFTW_RODFT00, DSTIII = FFTW_RODFT01, */
/*     DSTII = FFTW_RODFT10, DSTIV = FFTW_RODFT11 */
/* } dst_kind; */

LTFAT_API LTFAT_NAME(dst_plan)*
LTFAT_NAME(dst_init)( ltfat_int L, ltfat_int W, LTFAT_TYPE *cout,
                      const dst_kind kind)
{
    LTFAT_FFTW(iodim64) dims, howmanydims;
    LTFAT_FFTW(plan) p;

#ifdef LTFAT_COMPLEXTYPE
    dims.n = L;
    dims.is = 2;
    dims.os = 2;

    howmanydims.n = W;
    howmanydims.is = 2*L;
    howmanydims.os = 2*L;

    unsigned flag = FFTW_ESTIMATE | FFTW_UNALIGNED;
#else
    dims.n = L;
    dims.is = 1;
    dims.os = 1;

    howmanydims.n = W;
    howmanydims.is = L;
    howmanydims.os = L;

    unsigned flag = FFTW_ESTIMATE;
#endif

    LTFAT_FFTW(r2r_kind) kindFftw = FFTW_RODFT00;
    
    switch (kind)
    {
        case DSTI:  kindFftw = FFTW_RODFT00; break;
        case DSTII: kindFftw = FFTW_RODFT10; break;
        case DSTIII: kindFftw = FFTW_RODFT01; break;
        case DSTIV: kindFftw = FFTW_RODFT11; break;
    };

    p = LTFAT_FFTW(plan_guru64_r2r)(1, &dims,
                                  1, &howmanydims,
                                  (LTFAT_REAL*)cout, (LTFAT_REAL*)cout,
                                  &kindFftw, flag);

    return (LTFAT_NAME(dst_plan)*)p;
}


// f and cout cannot be equal, because creating plan can tamper with the array
LTFAT_API void
LTFAT_NAME(dst)(const LTFAT_TYPE *f, ltfat_int L, ltfat_int W,
                LTFAT_TYPE *cout, const dst_kind kind)
{
    LTFAT_NAME(dst_plan)* p = LTFAT_NAME(dst_init)( L, W, cout, kind);

    LTFAT_NAME(dst_execute)(p, f,  L,  W, cout, kind);

    LTFAT_NAME(dst_done)(p);
}

LTFAT_API void
LTFAT_NAME(dst_done)( LTFAT_NAME(dst_plan)* p)
{
    LTFAT_FFTW(destroy_plan)((LTFAT_FFTW(plan)) p);
}

// f and cout can be equal, provided plan was already created
LTFAT_API void
LTFAT_NAME(dst_execute)(LTFAT_NAME(dst_plan)* p, const LTFAT_TYPE *f,
                        ltfat_int L, ltfat_int W, LTFAT_TYPE *cout,
                        const dst_kind kind)
{
    // Copy input to the output
    if(cout!=f)
        memcpy(cout,f,L*W*sizeof*f);

    if(L==1)
        return;

    ltfat_int N = 2*L;
    LTFAT_REAL sqrt2 = (LTFAT_REAL) sqrt(2.0);
    LTFAT_REAL postScale = (LTFAT_REAL) 1.0/sqrt2;
    LTFAT_REAL scale = (LTFAT_REAL) ( sqrt2*(1.0/(double)N)*sqrt((double)L) );

    if(kind==DSTIII)
    {
        for(ltfat_int ii=0; ii<W; ii++)
        {
            cout[(ii+1)*L-1] *= sqrt2;
        }
    }

    if(kind==DSTI)
    {
        N += 2;
        scale = (LTFAT_REAL) ( sqrt2*(1.0/((double)N))*sqrt((double)L+1.0) );
    }

    LTFAT_REAL* c_r = (LTFAT_REAL*)cout;

    LTFAT_FFTW(execute_r2r)((LTFAT_FFTW(plan))p,c_r,c_r);
#ifdef LTFAT_COMPLEXTYPE
    LTFAT_REAL* c_i = c_r+1;
    LTFAT_FFTW(execute_r2r)((LTFAT_FFTW(plan))p,c_i,c_i);
#endif

    // Post-scaling
    for(ltfat_int ii=0; ii<L*W; ii++)
    {
        cout[ii] *= scale;
    }

    if(kind==DSTII)
    {
        // Scale AC component
        for(ltfat_int ii=0; ii<W; ii++)
        {
            cout[(ii+1)*L-1] *= postScale;
        }
    }
}

