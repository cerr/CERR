typedef struct LTFAT_NAME(dgt_multi_plan) LTFAT_NAME(dgt_multi_plan);

// {
//     ltfat_int a;
//     ltfat_int M;
//     ltfat_int L;
//     ltfat_int Lg;
//     ltfat_int W;
//     ltfat_int lt1;
//     ltfat_int lt2;
//
//     LTFAT_COMPLEX *f;
//     LTFAT_COMPLEX *c_scratch;
//     LTFAT_COMPLEX *cout;
//
//     LTFAT_COMPLEX *mwin;
//     LTFAT_COMPLEX *c_rect;
//
//     LTFAT_COMPLEX *mod;
//
//     LTFAT_NAME(dgt_long_plan) *rect_plan_array;
//
// } LTFAT_NAME(dgt_multi_plan);

struct LTFAT_NAME(dgt_multi_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int Lg;
    ltfat_int W;
    ltfat_int lt1;
    ltfat_int lt2;

    LTFAT_COMPLEX *f;
    LTFAT_COMPLEX *c_scratch;
    LTFAT_COMPLEX *cout;

    LTFAT_COMPLEX *mwin;
    LTFAT_COMPLEX *c_rect;

    LTFAT_COMPLEX *mod;

    LTFAT_NAME_COMPLEX(dgt_long_plan)** rect_plan_array;
};

LTFAT_API LTFAT_NAME(dgt_multi_plan)
LTFAT_NAME(dgt_multi_init)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                           ltfat_int L, ltfat_int Lg, ltfat_int W, ltfat_int a, ltfat_int M,
                           ltfat_int lt1, ltfat_int lt2,
                           LTFAT_COMPLEX *c,unsigned flags);

LTFAT_API void
LTFAT_NAME(dgt_multi_execute)(const LTFAT_NAME(dgt_multi_plan) plan);

LTFAT_API void
LTFAT_NAME(dgt_multi_done)(LTFAT_NAME(dgt_multi_plan) plan);

LTFAT_API void
LTFAT_NAME(nonsepwin2multi)(const LTFAT_COMPLEX *g,
                            ltfat_int L, ltfat_int Lg, ltfat_int a, ltfat_int M,
                            ltfat_int lt1, ltfat_int lt2,
                            LTFAT_COMPLEX *mwin);

LTFAT_API void
LTFAT_NAME(dgt_multi)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                      ltfat_int L, ltfat_int Lg, ltfat_int W, ltfat_int a, ltfat_int M,
                      ltfat_int lt1, ltfat_int lt2,
                      LTFAT_COMPLEX *c);
