#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_dwilt // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     coef=comp_dwilt(f,g,M);\n\
                     Yeah."


#include "ltfat_oct_template_helper.h"
// octave_idx_type is 32 or 64 bit signed integer
/*
  dgtreal_ola forwarders
*/

static inline void
fwd_dwilt_fb(const Complex *f, const Complex *g,
             const octave_idx_type L, const octave_idx_type gl,
             const octave_idx_type W, const octave_idx_type M,
             Complex *cout)
{
    ltfat_dwilt_fb_dc(reinterpret_cast<const ltfat_complex_d*>(f),
                reinterpret_cast<const ltfat_complex_d*>(g),
                L, gl, W, M, reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dwilt_fb(const FloatComplex *f, const FloatComplex *g,
             const octave_idx_type L,  const octave_idx_type gl,
             const octave_idx_type W, const octave_idx_type M,
             FloatComplex *cout)
{
    ltfat_dwilt_fb_sc(reinterpret_cast<const ltfat_complex_s*>(f),
                reinterpret_cast<const ltfat_complex_s*>(g),
                L, gl, W, M,
                reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dwilt_fb(const double *f, const double *g,
             const octave_idx_type L,  const octave_idx_type gl,
             const octave_idx_type W, const octave_idx_type M,
             double *cout)
{
    ltfat_dwilt_fb_d(f, g, L, gl, W, M, cout);
}

static inline void
fwd_dwilt_fb(const float *f, const float *g,
             const octave_idx_type L,  const octave_idx_type gl,
             const octave_idx_type W, const octave_idx_type M,
             float *cout)
{
    ltfat_dwilt_fb_s(f, g, L, gl, W, M, cout);
}

static inline void
fwd_dwilt_long(const Complex *f, const Complex *g,
               const octave_idx_type L, const octave_idx_type W,
               const octave_idx_type M, Complex *cout)
{
    ltfat_dwilt_long_dc(reinterpret_cast<const ltfat_complex_d*>(f),
                  reinterpret_cast<const ltfat_complex_d*>(g),
                  L, W, M, reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dwilt_long(const FloatComplex *f, const FloatComplex *g,
               const octave_idx_type L, const octave_idx_type W,
               const octave_idx_type M, FloatComplex *cout)
{
    ltfat_dwilt_long_sc(reinterpret_cast<const ltfat_complex_s*>(f),
                  reinterpret_cast<const ltfat_complex_s*>(g),
                  L, W, M, reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dwilt_long(const double *f, const double *g,
               const octave_idx_type L, const octave_idx_type W,
               const octave_idx_type M, double *cout)
{
    ltfat_dwilt_long_d(f, g, L, W, M, cout);
}

static inline void
fwd_dwilt_long(const float *f, const float *g,
               const octave_idx_type L, const octave_idx_type W,
               const octave_idx_type M, float *cout)
{
    ltfat_dwilt_long_s(f, g, L, W, M, cout);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    const octave_idx_type M = args(2).int_value();

    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    const octave_idx_type gl = g.numel();
    const octave_idx_type W = f.columns();
    const octave_idx_type L = f.rows();
    const octave_idx_type N = L / M;


    dim_vector dims_out(2 * M, N / 2, W);
    dims_out.chop_trailing_singletons();

    MArray<LTFAT_TYPE> cout(dims_out);

    if (gl < L)
    {
        fwd_dwilt_fb(f.data(), g.data(), L, gl, W, M, cout.fortran_vec());
    }
    else
    {
        fwd_dwilt_long(f.data(), g.data(), L, W, M, cout.fortran_vec());
    }

    return octave_value(cout);
}

