#define TYPEDEPARGS 0
#define SINGLEARGS
#define MATCHEDARGS 1
#define COMPLEXARGS
#define OCTFILENAME comp_isepdgtreal // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                    c=comp_isepdgtreal(c,g,L,a,M,phasetype);\n\
                    Yeah.\n"


#include "ltfat_oct_template_helper.h"
// octave_idx_type is 32 or 64 bit signed integer

static inline void
fwd_idgtreal_fb(const Complex *coef, const double *gf,
                const octave_idx_type L, const octave_idx_type gl,
                const octave_idx_type W, const octave_idx_type a,
                const octave_idx_type M, const octave_idx_type ptype,
                double *f)
{
    ltfat_idgtreal_fb_d(reinterpret_cast<const ltfat_complex_d*>(coef),
                  gf, L, gl, W, a, M,
                  static_cast<const ltfat_phaseconvention>(ptype),
                  f);
}

static inline void
fwd_idgtreal_fb(const FloatComplex *coef, const float *gf,
                const octave_idx_type L, const octave_idx_type gl,
                const octave_idx_type W, const octave_idx_type a,
                const octave_idx_type M, const octave_idx_type ptype,
                float *f)
{
    ltfat_idgtreal_fb_s(reinterpret_cast<const ltfat_complex_s*>(coef),
                  gf, L, gl, W, a, M,
                  static_cast<const ltfat_phaseconvention>(ptype),
                  f);
}

static inline void
fwd_idgtreal_long(const Complex *coef, const double *gf,
                  const octave_idx_type L, const octave_idx_type W,
                  const octave_idx_type a, const octave_idx_type M,
                  const octave_idx_type ptype, double *f)
{
    ltfat_idgtreal_long_d(reinterpret_cast<const ltfat_complex_d*>(coef),
                    gf, L, W, a, M,
                    static_cast<const ltfat_phaseconvention>(ptype),
                    f);
}

static inline void
fwd_idgtreal_long(const FloatComplex *coef, const float *gf,
                  const octave_idx_type L, const octave_idx_type W,
                  const octave_idx_type a, const octave_idx_type M,
                  const octave_idx_type ptype, float *f)
{
    ltfat_idgtreal_long_s(reinterpret_cast<const ltfat_complex_s*>(coef),
                    gf, L, W, a, M,
                    static_cast<const ltfat_phaseconvention>(ptype),
                    f);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;

    MArray<LTFAT_TYPE> coef = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_REAL> gf = ltfatOctArray<LTFAT_REAL>(args(1));
    const octave_idx_type L = args(2).int_value();
    const octave_idx_type a = args(3).int_value();
    const octave_idx_type M = args(4).int_value();
    const octave_idx_type ptype = args(5).int_value() == 1? LTFAT_TIMEINV: LTFAT_FREQINV;
    const octave_idx_type N = L / a;
    const octave_idx_type M2 = M / 2 + 1;
    const octave_idx_type W = coef.numel() / (N * M2);
    const octave_idx_type gl = gf.rows();

    MArray<LTFAT_REAL> f(dim_vector(L, W));

    if (gl < L)
    {
        fwd_idgtreal_fb(coef.data(), gf.data(), L, gl, W, a, M, ptype,
                        f.fortran_vec());
    }
    else
    {
        fwd_idgtreal_long(coef.data(), gf.data(), L, W, a, M, ptype,
                          f.fortran_vec());
    }
    return octave_value(f);
}
