#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_sepdgt // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     Usage: c=comp_sepdgt(f,g,a,M,phasetype) \n Yeah."

#include "ltfat_oct_template_helper.h"
/*
  dgt_fb forwarders
*/

static inline void
fwd_dgt_fb(const Complex *f, const Complex *g,
           const octave_idx_type L, const octave_idx_type gl,
           const octave_idx_type W, const octave_idx_type a,
           const octave_idx_type M, const octave_idx_type ptype,
           Complex *cout)
{
    ltfat_dgt_fb_dc(reinterpret_cast<const ltfat_complex_d*>(f),
              reinterpret_cast<const ltfat_complex_d*>(g),
              L, gl, W, a, M,
              static_cast<const ltfat_phaseconvention>(ptype),
              reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgt_fb(const FloatComplex *f, const FloatComplex *g,
           const octave_idx_type L, const octave_idx_type gl,
           const octave_idx_type W, const octave_idx_type a,
           const octave_idx_type M, const octave_idx_type ptype,
           FloatComplex *cout)
{
    ltfat_dgt_fb_sc(reinterpret_cast<const ltfat_complex_s*>(f),
              reinterpret_cast<const ltfat_complex_s*>(g),
              L, gl, W, a, M,
              static_cast<const ltfat_phaseconvention>(ptype),
              reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dgt_fb(const double *f, const double *g,
           const octave_idx_type L, const octave_idx_type gl,
           const octave_idx_type W, const octave_idx_type a,
           const octave_idx_type M, const octave_idx_type ptype,
           Complex *cout)
{
    ltfat_dgt_fb_d(reinterpret_cast<const double*>(f),
             reinterpret_cast<const double*>(g),
             L, gl, W, a, M,
             static_cast<const ltfat_phaseconvention>(ptype),
             reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgt_fb(const float *f, const float *g,
           const octave_idx_type L, const octave_idx_type gl,
           const octave_idx_type W, const octave_idx_type a,
           const octave_idx_type M, const octave_idx_type ptype,
           FloatComplex *cout)
{
    ltfat_dgt_fb_s(reinterpret_cast<const float*>(f),
             reinterpret_cast<const float*>(g),
             L, gl, W, a, M,
             static_cast<const ltfat_phaseconvention>(ptype),
             reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dgt_long(const Complex *f, const Complex *g,
             const octave_idx_type L, const octave_idx_type W,
             const octave_idx_type a, const octave_idx_type M,
             const octave_idx_type ptype, Complex *cout)
{
    ltfat_dgt_long_dc(reinterpret_cast<const ltfat_complex_d*>(f),
                reinterpret_cast<const ltfat_complex_d*>(g),
                L, W, a, M,
                static_cast<const ltfat_phaseconvention>(ptype),
                reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgt_long(const FloatComplex *f, const FloatComplex *g,
             const octave_idx_type L, const octave_idx_type W,
             const octave_idx_type a, const octave_idx_type M,
             const octave_idx_type ptype, FloatComplex *cout)
{
    ltfat_dgt_long_sc(reinterpret_cast<const ltfat_complex_s*>(f),
                reinterpret_cast<const ltfat_complex_s*>(g),
                L, W, a, M,
                static_cast<const ltfat_phaseconvention>(ptype),
                reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dgt_long(const double *f, const double *g,
             const octave_idx_type L, const octave_idx_type W,
             const octave_idx_type a, const octave_idx_type M,
             const octave_idx_type ptype, Complex *cout)
{
    ltfat_dgt_long_d(f, g, L, W, a, M,
               static_cast<const ltfat_phaseconvention>(ptype),
               reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgt_long(const float *f, const float *g,
             const octave_idx_type L, const octave_idx_type W,
             const octave_idx_type a, const octave_idx_type M,
             const octave_idx_type ptype, FloatComplex *cout)
{
    ltfat_dgt_long_s(f, g, L, W, a, M,
               static_cast<const ltfat_phaseconvention>(ptype),
               reinterpret_cast<ltfat_complex_s*>(cout));
}
template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    const octave_idx_type a = args(2).int_value();
    const octave_idx_type M = args(3).int_value();
    const octave_idx_type ptype = args(4).int_value() == 1? LTFAT_TIMEINV: LTFAT_FREQINV;

    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    const octave_idx_type L  = f.rows();
    const octave_idx_type W  = f.columns();
    const octave_idx_type gl = g.rows();
    const octave_idx_type N = L / a;

    dim_vector dims_out(M, N, W);
    dims_out.chop_trailing_singletons();

    MArray<LTFAT_COMPLEX> cout(dims_out);

    if (gl < L)
    {
        fwd_dgt_fb(f.data(), g.data(), L, gl, W, a, M, ptype,
                   cout.fortran_vec());
    }
    else
    {
        fwd_dgt_long(f.data(), g.data(), L, W, a, M, ptype, cout.fortran_vec());
    }

    return octave_value(cout);
}
