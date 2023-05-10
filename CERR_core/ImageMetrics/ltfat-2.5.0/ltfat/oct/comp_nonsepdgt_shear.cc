#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS
#define OCTFILENAME comp_nonsepdgt_shear // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     c=comp_nonsepdgt_shear(f,g,a,M,s0,s1,br);\n"


#include "ltfat_oct_template_helper.h"
// octave_idx_type is 32 or 64 bit signed integer

static inline void
fwd_dgt_shear(const Complex *f, const Complex *g,
              const octave_idx_type L, const octave_idx_type W,
              const octave_idx_type a, const octave_idx_type M,
              const octave_idx_type s0, const octave_idx_type s1,
              const octave_idx_type br, Complex *cout)
{
    ltfat_dgt_shear_d(reinterpret_cast<const ltfat_complex_d *>(f),
                reinterpret_cast<const ltfat_complex_d *>(g),
                L, W, a, M, s0, s1, br,
                reinterpret_cast<ltfat_complex_d *>(cout));
}

static inline void
fwd_dgt_shear(const FloatComplex *f, const FloatComplex *g,
              const octave_idx_type L, const octave_idx_type W,
              const octave_idx_type a, const octave_idx_type M,
              const octave_idx_type s0, const octave_idx_type s1,
              const octave_idx_type br, FloatComplex *cout)
{
    ltfat_dgt_shear_s(reinterpret_cast<const ltfat_complex_s *>(f),
                reinterpret_cast<const ltfat_complex_s *>(g),
                L, W, a, M, s0, s1, br,
                reinterpret_cast<ltfat_complex_s *>(cout));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    const octave_idx_type a = args(2).int_value();
    const octave_idx_type M = args(3).int_value();
    const octave_idx_type s0 = args(4).int_value();
    const octave_idx_type s1 = args(5).int_value();
    const octave_idx_type br = args(6).int_value();

    const octave_idx_type L = f.rows();
    const octave_idx_type W = f.cols();
    const octave_idx_type N = L / a;

    dim_vector dims_out(M, N, W);
    dims_out.chop_trailing_singletons();

    MArray<LTFAT_COMPLEX> cout(dims_out);

    fwd_dgt_shear(f.data(), g.data(), L, W, a, M, s0, s1, br,
                  cout.fortran_vec());

    return octave_value(cout);
}
