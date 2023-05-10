#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXARGS
#define OCTFILENAME comp_iwfac // change to filename
#define OCTFILEHELP "Computes inverse window factorization.\n\
                    Usage: c=comp_iwfac(gf,L,a,M);\n\
                    Yeah."


#include "ltfat_oct_template_helper.h"

static inline void fwd_iwfac(const Complex *gf,
                             const octave_idx_type L, const octave_idx_type R,
                             const octave_idx_type a, const octave_idx_type M,
                             Complex *g)
{
    ltfat_iwfac_dc(reinterpret_cast<const ltfat_complex_d*>(gf),
             L, R, a, M,
             reinterpret_cast<ltfat_complex_d*>(g));
}

static inline void fwd_iwfac(const FloatComplex *gf,
                             const octave_idx_type L, const octave_idx_type R,
                             const octave_idx_type a, const octave_idx_type M,
                             FloatComplex *g)
{
    ltfat_iwfac_sc(reinterpret_cast<const ltfat_complex_s*>(gf),
             L, R, a, M,
             reinterpret_cast<ltfat_complex_s*>(g));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;

    MArray<LTFAT_TYPE> gf = ltfatOctArray<LTFAT_TYPE>(args(0));
    const octave_idx_type L = args(1).int_value();
    const octave_idx_type R = gf.numel() / L;
    const octave_idx_type a = args(2).int_value();
    const octave_idx_type M = args(3).int_value();

    MArray<LTFAT_COMPLEX> g(dim_vector(L, 1));

    fwd_iwfac(gf.data(), L, R, a, M, g.fortran_vec());

    return octave_value(g);
}
