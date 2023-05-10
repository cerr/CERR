#ifndef _ltfat_dgtrealmp_private_h
#define _ltfat_dgtrealmp_private_h
#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

struct LTFAT_NAME(dgtrealmp_parbuf)
{
    LTFAT_REAL**        g;
    ltfat_int*          gl;
    ltfat_int*          a;
    ltfat_int*          M;
    int*         chanmask;
    ltfat_int           P;
    ltfat_dgtmp_params* params;
    LTFAT_NAME(dgtrealmp_iterstep_callback)* iterstepcallback;
    void*                        iterstepcallbackdata;
//    LTFAT_REAL          chirprate;
//    LTFAT_REAL          shiftby;
};

struct ltfat_dgtmp_params
{
    // ltfat_dgtrealmp_hint  hint;
    ltfat_dgtmp_alg       alg;
    double                atprodreltoldb;
    double                atprodreltoladj;
    long double           errtoldb;
    long double           errtoladj;
    double                kernrelthr;
    size_t                maxit;
    size_t                maxatoms;
    size_t                iterstep;
    int                   verbose;
    int                   initwasrun;
    int                   treelevels;
    size_t                cycles;
    ltfat_phaseconvention ptype;
    int                   do_pedantic;
};

typedef struct
{
    ltfat_int height;
    ltfat_int width;
} ksize;

typedef struct
{
    ltfat_int hmid;
    ltfat_int wmid;
} kanchor;

typedef struct
{
    ltfat_int start;
    ltfat_int end;
} krange;

typedef struct
{
    ltfat_int m;
    ltfat_int n;
    ltfat_int w;
    ltfat_int n2;
} kpoint;
#define PTOI(k) k.w][k.m + p->M2[k.w] * k.n
#define kpoint_init(m,n,w) LTFAT_STRUCTINIT(kpoint,m,n,w,n)
#define kpoint_init2(m,n,n2,w) LTFAT_STRUCTINIT(kpoint,m,n,w,n2)
#define kpoint_isequal(k1,k2) (k1.m == k2.m && k1.n == k2.n && k1.w == k2.w)


typedef struct
{
    ksize              size;
    kanchor             mid;
    ltfat_int           kNo;
    ltfat_int         kSkip;
    LTFAT_COMPLEX**    mods;
    LTFAT_COMPLEX*     kval;
    krange*           range;
    krange*          srange;
    LTFAT_REAL       absthr;
    double             Mrat;
    double             arat;
    ltfat_int         Mstep;
    ltfat_int         astep;
    LTFAT_COMPLEX*     atprods;
    LTFAT_REAL* oneover1minatprodnorms;
    ltfat_int   atprodsNo;
    int cloned;
     ltfat_phaseconvention ptype;
} LTFAT_NAME(kerns);


typedef struct
{
    LTFAT_COMPLEX**        c;
    LTFAT_REAL**           maxcols;
    ltfat_int**            maxcolspos;
    LTFAT_NAME(maxtree)**  tmaxtree;
    LTFAT_NAME(maxtree)*** fmaxtree;
    unsigned int**         suppind;
    long double            err;
    long double            fnorm2;
    size_t                 currit;
    size_t                 curratoms;
    ltfat_int              P;
    ltfat_int*             N;
    LTFAT_COMPLEX**        cvalModBuf;
    // LocOMP related
    LTFAT_COMPLEX*         gramBuf;
    LTFAT_COMPLEX*         cvalBuf;
    LTFAT_COMPLEX*         cvalinvBuf;
    kpoint*                cvalBufPos;
    LTFAT_NAME_COMPLEX(hermsystemsolver_plan)* hplan;
    // CyclicMP related
    kpoint*                pBuf;
    size_t                 pBufSize;
    size_t                 pBufNo;
} LTFAT_NAME(dgtrealmpiter_state);


typedef struct
{
    ltfat_int n;
    ltfat_int w;
    LTFAT_NAME(dgtrealmp_state)* state;
} LTFAT_NAME(dgtrealmp_state_closure);

struct LTFAT_NAME(dgtrealmp_state)
{
    LTFAT_NAME(dgtrealmpiter_state)* iterstate;
    LTFAT_NAME(kerns)**             gramkerns; // PxP plans
    LTFAT_NAME(dgtreal_plan)**       dgtplans;  // P plans
    ltfat_int*        a;
    ltfat_int*        M;
    ltfat_int*       M2;
    ltfat_int*        N;
    int*       chanmask;
    ltfat_int         P;
    ltfat_int         L;
    ltfat_dgtmp_params* params;
    LTFAT_COMPLEX**     couttmp;
    LTFAT_NAME(dgtrealmp_state_closure)** closures;
    LTFAT_NAME(dgtrealmp_iterstep_callback)* callback;
    void* userdata;
};

static inline LTFAT_REAL
ltfat_norm(LTFAT_COMPLEX c)
{
    return ltfat_real(c) * ltfat_real(c) + ltfat_imag(c) * ltfat_imag(c);
}

static inline LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_projenergy)(
    LTFAT_COMPLEX atinprod, LTFAT_COMPLEX cval)
{
    LTFAT_REAL cr = ltfat_real(cval);
    LTFAT_REAL ci = ltfat_imag(cval);
    LTFAT_REAL cr2 = cr*cr;
    LTFAT_REAL ci2 = ci*ci;
	LTFAT_REAL two = (LTFAT_REAL) 2.0;
    return two*(cr2 + ci2 + ltfat_real(atinprod)*(cr2 - ci2) - two*ltfat_imag(atinprod)*cr*ci);
}

static inline LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_dualprojenergy)(
    LTFAT_COMPLEX atinprod, LTFAT_REAL oneoveroneminatprodnorm, LTFAT_COMPLEX cval)
{
    LTFAT_COMPLEX cvaldual = (cval - (atinprod) * conj(cval)) * oneoveroneminatprodnorm;
    return LTFAT_NAME(dgtrealmp_execute_projenergy)( atinprod, cvaldual);
}

/* BEGIN_C_DECLS */
#ifdef __cplusplus
extern "C" {
#endif

int
LTFAT_NAME(dgtrealmpiter_init)(
    ltfat_int a[], ltfat_int M[], ltfat_int P, ltfat_int L,
    LTFAT_NAME(dgtrealmpiter_state)** state);

int
LTFAT_NAME(dgtrealmpiter_done)(LTFAT_NAME(dgtrealmpiter_state)** state);

int
LTFAT_NAME(dgtrealmp_kernel_cloneconj)(
    LTFAT_NAME(kerns)* kin, LTFAT_NAME(kerns)** kout);

int
LTFAT_NAME(dgtrealmp_kernel_init)(
    const LTFAT_REAL* g[], ltfat_int gl[], ltfat_int a[], ltfat_int M[],
    ltfat_int L, LTFAT_REAL reltol, ltfat_phaseconvention ptype,
    LTFAT_NAME(kerns)** pout);

int
LTFAT_NAME(dgtrealmp_kernel_done)(LTFAT_NAME(kerns)** k);

int
LTFAT_NAME(dgtrealmp_kernel_modfi)(
    const LTFAT_COMPLEX* kfirst, ksize size, kanchor mid, ltfat_int n, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod);

int
LTFAT_NAME(dgtrealmp_kernel_modti)(
    const LTFAT_COMPLEX* kfirst, ksize size, kanchor mid, ltfat_int m, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod);

int
LTFAT_NAME(dgtrealmp_kernel_modfiexp)(
    ksize size, kanchor mid, ltfat_int n, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod);

int
LTFAT_NAME(dgtrealmp_kernel_modtiexp)(
    ksize size, kanchor mid, ltfat_int m, ltfat_int a, ltfat_int M,
    LTFAT_COMPLEX* kmod);

int
LTFAT_NAME(dgtrealmp_kernel_findsmallsize)(
    const LTFAT_COMPLEX kernlarge[], ltfat_int M, ltfat_int N,
    LTFAT_REAL reltol, LTFAT_REAL* absthr, ksize* size, kanchor* anchor);

int
LTFAT_NAME(dgtrealmp_essentialsupport)(
    const LTFAT_REAL g[], ltfat_int gl, LTFAT_REAL reltol,
    ltfat_int* lefttail, ltfat_int* righttail);

int
LTFAT_NAME(dgtrealmp_execute_kpos)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos1, kpoint pos2,
    ltfat_int* m2, ltfat_int* n2, ltfat_int* Mstep, ltfat_int* astep,
    ksize* kdim2, kanchor* kmid2, kpoint* kstart2);

int
LTFAT_NAME(dgtrealmp_execute_indices)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint origpos, kpoint* pos,
    ltfat_int* m2start, ltfat_int* n2start, ksize* kdim2, kanchor* kmid2,
    kpoint* kstart2);

LTFAT_COMPLEX*
LTFAT_NAME(dgtrealmp_execute_pickkernel)(
    LTFAT_NAME(kerns)* currkern, ltfat_int m, ltfat_int n,
    ltfat_phaseconvention pconv);

LTFAT_COMPLEX*
LTFAT_NAME(dgtrealmp_execute_pickmod)(
    LTFAT_NAME(kerns)* currkern, ltfat_int m, ltfat_int n,
    ltfat_phaseconvention pconv);

int
LTFAT_NAME(dgtrealmp_execute_findmaxatom)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint* pos);
// ltfat_int* m, ltfat_int* n, ltfat_int* w);

int
LTFAT_NAME(dgtrealmp_execute_findneighbors)(
        LTFAT_NAME(dgtrealmp_state)* p, kpoint pos,
        kpoint* nBuf, size_t* nCount);

int
LTFAT_NAME(dgtrealmp_execute_updateresiduum)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos, LTFAT_COMPLEX cval,
    int do_substract);

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_atenergy)(
    LTFAT_COMPLEX ainprod, LTFAT_COMPLEX cval);

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_adjustedenergy)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos, LTFAT_COMPLEX cval);

void
LTFAT_NAME(dgtrealmp_execute_conjatpairprod)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos,
    LTFAT_COMPLEX* atinprod, LTFAT_REAL* oneover1minatprodnorm);

void
LTFAT_NAME(dgtrealmp_execute_dualprodandprojenergy)(
    LTFAT_NAME(dgtrealmp_state)* p, kpoint pos, LTFAT_COMPLEX cval,
    LTFAT_COMPLEX* cvaldual, LTFAT_REAL* projenergy);

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_mp)(
    LTFAT_NAME(dgtrealmp_state)* p, LTFAT_COMPLEX cval,
    kpoint pos, LTFAT_COMPLEX** cout);

int
LTFAT_NAME(dgtrealmp_execute_cyclicmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout);

int
LTFAT_NAME(dgtrealmp_execute_selfprojmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout);

int
LTFAT_NAME(dgtrealmp_execute_locomp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint origpos, LTFAT_COMPLEX** cout);

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_invmp)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint pos, LTFAT_COMPLEX** cout);

LTFAT_REAL
LTFAT_NAME(dgtrealmp_execute_realatenergy)(
    LTFAT_NAME(dgtrealmp_state)* p,
    kpoint pos, LTFAT_COMPLEX cval);

LTFAT_REAL
LTFAT_NAME(pedantic_callback)(void* userdata,
                              LTFAT_COMPLEX cval, ltfat_int pos);
#ifdef __cplusplus
}  // extern "C"
#endif

#endif
