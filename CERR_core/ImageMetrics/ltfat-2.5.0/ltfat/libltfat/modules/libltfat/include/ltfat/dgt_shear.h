typedef struct
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int s0;
    ltfat_int s1;
    ltfat_int br;

    LTFAT_COMPLEX *p0;
    LTFAT_COMPLEX *p1;

    LTFAT_COMPLEX *fwork;
    LTFAT_COMPLEX *gwork;
    LTFAT_COMPLEX *c_rect;

    LTFAT_COMPLEX *finalmod;

    // LTFAT_FFTW(plan) f_plan;
    // LTFAT_FFTW(plan) g_plan;
    LTFAT_NAME_REAL(fft_plan)* f_plan;
    LTFAT_NAME_REAL(fft_plan)* g_plan;


    LTFAT_NAME_COMPLEX(dgt_long_plan)* rect_plan;

    const LTFAT_COMPLEX *f;
    LTFAT_COMPLEX *cout;

} LTFAT_NAME(dgt_shear_plan);


LTFAT_API LTFAT_NAME(dgt_shear_plan)
LTFAT_NAME(dgt_shear_init)(
    const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
    ltfat_int L, ltfat_int W, ltfat_int a,
    ltfat_int M, ltfat_int s0, ltfat_int s1, ltfat_int br,
    LTFAT_COMPLEX *cout,
    unsigned flags);

LTFAT_API void
LTFAT_NAME(dgt_shear_execute)(const LTFAT_NAME(dgt_shear_plan) plan);

LTFAT_API void
LTFAT_NAME(dgt_shear_done)(LTFAT_NAME(dgt_shear_plan) plan);

LTFAT_API void
LTFAT_NAME(dgt_shear)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                      ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                      ltfat_int s0, ltfat_int s1, ltfat_int br,
                      LTFAT_COMPLEX *c);

LTFAT_API void
LTFAT_NAME(pchirp)(const long long L, const long long n, LTFAT_COMPLEX *g);
