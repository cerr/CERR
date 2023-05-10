#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_wfac // change to filename
#define OCTFILEHELP "Computes window factorization.\n\
                     Usage: c=comp_wfac(g,a,M);\n\
                     Yeah."

#include "ltfat_oct_template_helper.h"
/*
   dgt_fb forwarders
*/

static inline void
fwd_comp_wfac(const Complex *g,
              const octave_idx_type L, const octave_idx_type R,
              const octave_idx_type a, const octave_idx_type M,
              Complex *cout)
{
    ltfat_wfac_dc(reinterpret_cast<const ltfat_complex_d*>(g),
            L, R, a, M,
            reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_comp_wfac(const FloatComplex *g,
              const octave_idx_type L, const octave_idx_type R,
              const octave_idx_type a, const octave_idx_type M,
              FloatComplex *cout)
{
    ltfat_wfac_sc(reinterpret_cast<const ltfat_complex_s*>(g),
            L, R, a, M,
            reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_comp_wfac(const double *g,
              const octave_idx_type L, const octave_idx_type R,
              const octave_idx_type a, const octave_idx_type M,
              Complex *cout)
{
    ltfat_wfac_d(reinterpret_cast<const double*>(g),
           L, R, a, M,
           reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_comp_wfac(const float *g,
              const octave_idx_type L, const octave_idx_type R,
              const octave_idx_type a, const octave_idx_type M,
              FloatComplex *cout)
{
    ltfat_wfac_s(reinterpret_cast<const float*>(g),
           L, R, a, M,
           reinterpret_cast<ltfat_complex_s*>(cout));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(0));
    const octave_idx_type a = args(1).int_value();
    const octave_idx_type M = args(2).int_value();
    const octave_idx_type L = g.rows();
    const octave_idx_type R = g.columns();

    const octave_idx_type b = L / M;

    ltfat_int h_a, h_m;
    const octave_idx_type c = ltfat_gcd(a, M, &h_a, &h_m);
    const octave_idx_type p = a / c;
    const octave_idx_type q = M / c;
    const octave_idx_type d = b / p;

    MArray<LTFAT_COMPLEX> cout(dim_vector(p * q * R, c * d));

    fwd_comp_wfac(g.data(), L, R, a, M, cout.fortran_vec());

    return octave_value(cout);
}

