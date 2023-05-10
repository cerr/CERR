#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_atrousfilterbank_td // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     c=comp_atrousfilterbank_td(f,g,a,offset) \n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_atrousfilterbank_td(const Complex *f, const Complex *g[],
                        const ltfat_int L, ltfat_int gl[],
                        const ltfat_int W,  ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                        Complex *c, ltfatExtType ext)
{
    ltfat_atrousfilterbank_td_dc(reinterpret_cast<const ltfat_complex_d *>(f),
                           reinterpret_cast<const ltfat_complex_d **>(g),
                           L, gl, W, a, offset, M,
                           reinterpret_cast<ltfat_complex_d *>(c),
                           ext);
}

static inline void
fwd_atrousfilterbank_td(const FloatComplex *f, const FloatComplex *g[],
                        const ltfat_int L,  ltfat_int gl[],
                        const ltfat_int W,  ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                        FloatComplex *c, ltfatExtType ext)
{
    ltfat_atrousfilterbank_td_sc(reinterpret_cast<const ltfat_complex_s *>(f),
                           reinterpret_cast<const ltfat_complex_s **>(g),
                           L, gl, W, a, offset, M,
                           reinterpret_cast<ltfat_complex_s *>(c),
                           ext);
}

static inline void
fwd_atrousfilterbank_td(const double *f, const double *g[],
                        const ltfat_int L,  ltfat_int gl[],
                        const ltfat_int W,  ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                        double *c, ltfatExtType ext)
{
    ltfat_atrousfilterbank_td_d(reinterpret_cast<const double *>(f),
                          reinterpret_cast<const double **>(g),
                          L, gl, W, a, offset, M,
                          reinterpret_cast<double *>(c),
                          ext);
}

static inline void
fwd_atrousfilterbank_td(const float *f, const float *g[],
                        const ltfat_int L,  ltfat_int gl[],
                        const ltfat_int W,  ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                        float *c, ltfatExtType ext)
{
    ltfat_atrousfilterbank_td_s(reinterpret_cast<const float *>(f),
                          reinterpret_cast<const float **>(g),
                          L, gl, W, a, offset, M,
                          reinterpret_cast<float *>(c),
                          ext);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list
octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    Matrix aDouble = args(2).matrix_value();
    Matrix offsetDouble = args(3).matrix_value();

    // Input length
    const octave_idx_type L  = f.rows();
    // Number of channels
    const octave_idx_type W  = f.columns();
    // Number of filters
    const octave_idx_type M = g.columns();
    const octave_idx_type filtLen = g.rows();

    // Allocating temporary arrays
    OCTAVE_LOCAL_BUFFER (const LTFAT_TYPE*, gPtrs, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, a, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, offset, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, filtLens, M);

    for (octave_idx_type m = 0; m < M; m++)
    {
        a[m] = (ltfat_int) aDouble(0);
        offset[m] = (ltfat_int) offsetDouble(m);
        filtLens[m] = (ltfat_int) filtLen;
        gPtrs[m] = g.data() +  m * filtLen;
    }

    dim_vector dims_out(L, M, W);
    dims_out.chop_trailing_singletons();
    MArray<LTFAT_TYPE> c(dims_out);

    fwd_atrousfilterbank_td(f.data(), gPtrs, L,
                            filtLens, W, a, offset, M, c.fortran_vec(), PER);

    return octave_value(c);
}
