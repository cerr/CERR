#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_iatrousfilterbank_td // change to filename
#define OCTFILEHELP "This function calls the C-library \n\
                     f=comp_iatrousfilterbank_td(c,g,a,offset) \n\
                     Yeah."

#include "ltfat_oct_template_helper.h"


static inline void
fwd_iatrousfilterbank_td(const Complex *c, const Complex *g[],
                         const ltfat_int L, ltfat_int gl[],
                         const ltfat_int W, ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                         Complex *f, ltfatExtType ext)
{
    ltfat_iatrousfilterbank_td_dc(reinterpret_cast<const ltfat_complex_d *>(c),
                            reinterpret_cast<const ltfat_complex_d **>(g),
                            L, gl, W, a, offset, M,
                            reinterpret_cast<ltfat_complex_d *>(f),
                            ext);
}

static inline void
fwd_iatrousfilterbank_td(const FloatComplex *c, const FloatComplex *g[],
                         const ltfat_int L, ltfat_int gl[],
                         const ltfat_int W, ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                         FloatComplex *f, ltfatExtType ext)
{
    ltfat_iatrousfilterbank_td_sc(reinterpret_cast<const ltfat_complex_s *>(c),
                            reinterpret_cast<const ltfat_complex_s **>(g),
                            L, gl, W, a, offset, M,
                            reinterpret_cast<ltfat_complex_s *>(f),
                            ext);
}

static inline void
fwd_iatrousfilterbank_td(const double *c, const double *g[],
                         const ltfat_int L, ltfat_int gl[],
                         const ltfat_int W, ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                         double *f, ltfatExtType ext)
{
    ltfat_iatrousfilterbank_td_d(c, g, L, gl, W, a, offset, M, f, ext);
}

static inline void
fwd_iatrousfilterbank_td(const float *c, const float *g[],
                         const ltfat_int L, ltfat_int gl[],
                         const ltfat_int W, ltfat_int a[],
                         ltfat_int offset[], const ltfat_int M,
                         float *f, ltfatExtType ext)
{
    ltfat_iatrousfilterbank_td_s(c, g, L, gl, W, a, offset, M, f, ext);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_TYPE> c = ltfatOctArray<LTFAT_TYPE>(args(0));
    // Cell aray containing impulse responses
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    // Subsampling factors
    Matrix aDouble = args(2).matrix_value();
    Matrix offsetDouble = args(3).matrix_value();

    const octave_idx_type L = c.dim1();
    const octave_idx_type M = c.dim2();
    octave_idx_type W = 1;
    if (c.ndims() > 2)
    {
        W = c.dim3();
    }

    const octave_idx_type filtLen = g.rows();

    OCTAVE_LOCAL_BUFFER (const LTFAT_TYPE*, gPtrs, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, filtLens, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, a, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, offset, M);


    for (octave_idx_type m = 0; m < M; m++)
    {
        filtLens[m] = (ltfat_int) filtLen;
        a[m] = (ltfat_int) aDouble(0);
        offset[m] = (ltfat_int) offsetDouble(m);
        gPtrs[m] = g.data() +  m * filtLen;
    }

    MArray<LTFAT_TYPE> f(dim_vector(L, W));

    fwd_iatrousfilterbank_td(c.data(), gPtrs, L, filtLens, W, a, offset, M,
                             f.fortran_vec(), PER);

    return octave_value(f);
}
