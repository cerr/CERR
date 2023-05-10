#define TYPEDEPARGS 0
#define MATCHEDARGS 1, 2
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_gabreassign // change to filename
#define OCTFILEHELP "Computes spreading permutation.\n\
                     Usage: sr=comp_gabreassign(s,itime,ifreq,a);\n\
                     Yeah."


#include "ltfat_oct_template_helper.h"
/*
  gabreassign forwarders
*/

static inline void
fwd_gabreassign(const double *s, const double *tgrad, const double *fgrad,
                const octave_idx_type L, const octave_idx_type W,
                const octave_idx_type a, const octave_idx_type M,
                double *sr)
{
    ltfat_gabreassign_d(s, tgrad, fgrad, L, W, a, M, sr);
}

static inline void
fwd_gabreassign(const float *s, const float *tgrad, const float *fgrad,
                const octave_idx_type L, const octave_idx_type W,
                const octave_idx_type a, const octave_idx_type M,
                float *sr)
{
    ltfat_gabreassign_s(s, tgrad, fgrad, L, W, a, M, sr);
}

static inline void
fwd_gabreassign(const Complex *s, const double *tgrad, const double *fgrad,
                const octave_idx_type L, const octave_idx_type W,
                const octave_idx_type a, const octave_idx_type M,
                Complex *sr)
{
    ltfat_gabreassign_dc(reinterpret_cast<const ltfat_complex_d*>(s),
                   tgrad, fgrad, L, W, a, M,
                   reinterpret_cast<ltfat_complex_d*>(sr));
}

static inline void
fwd_gabreassign(const FloatComplex *s, const float *tgrad, const float *fgrad,
                const octave_idx_type L, const octave_idx_type W,
                const octave_idx_type a, const octave_idx_type M,
                FloatComplex *sr)
{
    ltfat_gabreassign_sc(reinterpret_cast<const ltfat_complex_s*>(s),
                   tgrad, fgrad, L, W, a, M,
                   reinterpret_cast<ltfat_complex_s*>(sr));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list
octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;

    MArray<LTFAT_TYPE> s = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_REAL> tgrad = ltfatOctArray<LTFAT_REAL>(args(1));
    MArray<LTFAT_REAL> fgrad = ltfatOctArray<LTFAT_REAL>(args(2));
    const octave_idx_type a  = args(3).int_value();
    const octave_idx_type M  = s.rows();
    const octave_idx_type N  = s.columns();
    const octave_idx_type L  = N * a;

    MArray<LTFAT_TYPE> sr(dim_vector(M, N));

    fwd_gabreassign(s.data(), tgrad.data(), fgrad.data(), L, 1, a, M,
                    sr.fortran_vec());

    return octave_value(sr);
}
