#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_filterbank_td // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     c=comp_filterbank_td(f,g,a,offset,ext)\n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_filterbank_td(const Complex *f, const Complex *g[],
                  const ltfat_int L,ltfat_int gl[],
                  const ltfat_int W, ltfat_int a[],
                  ltfat_int offset[], const ltfat_int M,
                  Complex *c[], ltfatExtType ext)
{
    ltfat_filterbank_td_dc(reinterpret_cast<const ltfat_complex_d *>(f),
                     reinterpret_cast<const ltfat_complex_d **>(g),
                     L, gl, W, a, offset, M,
                     reinterpret_cast<ltfat_complex_d **>(c),
                     ext);
}

static inline void
fwd_filterbank_td(const FloatComplex *f, const FloatComplex *g[],
                  const ltfat_int L, ltfat_int gl[],
                  const ltfat_int W, ltfat_int a[],
                  ltfat_int offset[], const ltfat_int M,
                  FloatComplex *c[], ltfatExtType ext)
{
    ltfat_filterbank_td_sc(reinterpret_cast<const ltfat_complex_s *>(f),
                     reinterpret_cast<const ltfat_complex_s **>(g),
                     L, gl, W, a, offset, M,
                     reinterpret_cast<ltfat_complex_s **>(c),
                     ext);
}

static inline void
fwd_filterbank_td(const double *f, const double *g[],
                  const ltfat_int L, ltfat_int gl[],
                  const ltfat_int W, ltfat_int a[],
                  ltfat_int offset[], const ltfat_int M,
                  double *c[], ltfatExtType ext)
{
    ltfat_filterbank_td_d(f, g, L, gl, W, a, offset, M, c, ext);
}

static inline void
fwd_filterbank_td(const float *f, const float *g[],
                  const ltfat_int L, ltfat_int gl[],
                  const ltfat_int W, ltfat_int a[],
                  ltfat_int offset[], const ltfat_int M,
                  float *c[], ltfatExtType ext)
{
    ltfat_filterbank_td_s(f, g, L, gl, W, a, offset, M, c, ext);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    // Cell aray containing impulse responses
    Cell g = args(1).cell_value();
    // Subsampling factors
    Matrix aDouble = args(2).matrix_value();
    // Skips
    Matrix offsetDouble = args(3).matrix_value();
    charMatrix extMat = args(4).char_matrix_value();
    ltfatExtType ext = ltfatExtStringToEnum(extMat.row_as_string(0).c_str());
    // Input length
    const octave_idx_type L  = f.rows();
    // Number of channels
    const octave_idx_type W  = f.columns();
    // Number of filters
    const octave_idx_type M = g.numel();

    // Allocating temporary arrays
    // Filter lengts
    OCTAVE_LOCAL_BUFFER (ltfat_int, filtLen, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, a, M);
    OCTAVE_LOCAL_BUFFER (ltfat_int, offset , M);
    // Impulse responses pointers
    OCTAVE_LOCAL_BUFFER (const LTFAT_TYPE*, gPtrs, M);
    // Output subbands pointers
    OCTAVE_LOCAL_BUFFER (LTFAT_TYPE*, cPtrs, M);
    // Output cell elements array,
    OCTAVE_LOCAL_BUFFER (MArray<LTFAT_TYPE>, c_elems, M);
    //
    OCTAVE_LOCAL_BUFFER (MArray<LTFAT_TYPE>, g_elems, M);

    for (octave_idx_type m = 0; m < M; m++)
    {
        a[m] = (ltfat_int) aDouble(m);
        offset[m] = (ltfat_int) offsetDouble(m);
        g_elems[m] = ltfatOctArray<LTFAT_TYPE>(g.elem(m));
        gPtrs[m] = g_elems[m].data();
        filtLen[m] = (ltfat_int) g_elems[m].numel();
        octave_idx_type outLen = (octave_idx_type)
                                 filterbank_td_size(L, a[m], filtLen[m],
                                         offset[m], ext);
        c_elems[m] = MArray<LTFAT_TYPE>(dim_vector(outLen, W));
        cPtrs[m] = c_elems[m].fortran_vec();
    }

    fwd_filterbank_td(f.data(), gPtrs, L, filtLen, W, a, offset, M, cPtrs, ext);

    Cell c(dim_vector(M, 1));
    for (octave_idx_type m = 0; m < M; ++m)
    {
        c.elem(m) = c_elems[m];
    }
    return octave_value(c);
}
