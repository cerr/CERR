#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_sepdgtreal // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     Usage: c=comp_sepdgtreal(f,g,a,M,phasetype);\n\
                     Yeah."


#include "ltfat_oct_template_helper.h"
/*
   dgtreal_fb forwarders
*/

static inline void
fwd_dgtreal_fb(const double *f, const double *g,
               const octave_idx_type L, const octave_idx_type gl,
               const octave_idx_type W, const octave_idx_type a,
               const octave_idx_type M, const octave_idx_type phasetype,
               Complex *cout)
{
    ltfat_dgtreal_fb_d(f, g, L, gl, W, a, M,
                 static_cast<ltfat_phaseconvention>(phasetype),
                 reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgtreal_fb(const float *f, const float *g,
               const octave_idx_type L, const octave_idx_type gl,
               const octave_idx_type W, const octave_idx_type a,
               const octave_idx_type M, const octave_idx_type phasetype,
               FloatComplex *cout)
{
    ltfat_dgtreal_fb_s(f, g, L, gl, W, a, M,
                 static_cast<ltfat_phaseconvention>(phasetype),
                 reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_dgtreal_long(const double *f, const double *g, const octave_idx_type L,
                 const octave_idx_type W, const octave_idx_type a,
                 const octave_idx_type M, const octave_idx_type phasetype,
                 Complex *cout)
{
    ltfat_dgtreal_long_d(f, g, L, W, a, M,
                   static_cast<ltfat_phaseconvention>(phasetype),
                   reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_dgtreal_long(const float *f, const float *g, const octave_idx_type L,
                 const octave_idx_type W, const octave_idx_type a,
                 const octave_idx_type M, const octave_idx_type phasetype,
                 FloatComplex *cout)
{
    ltfat_dgtreal_long_s(f, g, L, W, a, M,
                   static_cast<ltfat_phaseconvention>(phasetype),
                   reinterpret_cast<ltfat_complex_s*>(cout));
}
template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    const octave_idx_type a = args(2).int_value();
    const octave_idx_type M = args(3).int_value();
    const octave_idx_type phasetype = args(4).int_value()== 1? LTFAT_TIMEINV: LTFAT_FREQINV;
    const octave_idx_type M2 = M / 2 + 1;

    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    const octave_idx_type L  = f.rows();
    const octave_idx_type W  = f.columns();
    const octave_idx_type gl = g.rows();
    const octave_idx_type N = L / a;

    dim_vector dims_out(M2, N, W);
    dims_out.chop_trailing_singletons();

    MArray<LTFAT_COMPLEX> cout(dims_out);

    if (gl < L)
    {
        fwd_dgtreal_fb(f.data(), g.data(), L, gl, W, a, M, phasetype,
                       cout.fortran_vec());
    }
    else
    {
        fwd_dgtreal_long(f.data(), g.data(), L, W, a, M, phasetype,
                         cout.fortran_vec());
    }

    return octave_value(cout);
}
