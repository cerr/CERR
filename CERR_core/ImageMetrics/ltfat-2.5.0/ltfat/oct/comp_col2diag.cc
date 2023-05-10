#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_col2diag // change to filename
#define OCTFILEHELP "Computes spreading permutation.\n\
                     Usage: cout=comp_col2diag(cin);\n Yeah."

#include "ltfat_oct_template_helper.h"

/*
  col2diag forwarders
*/

static inline void
fwd_col2diag(const Complex *cin, const octave_idx_type L, Complex *cout)
{
    ltfat_col2diag_dc(reinterpret_cast<const ltfat_complex_d*>(cin), L,
                reinterpret_cast<ltfat_complex_d*>(cout));
}

static inline void
fwd_col2diag(const FloatComplex *cin, const octave_idx_type L,
             FloatComplex *cout)
{
    ltfat_col2diag_sc(reinterpret_cast<const ltfat_complex_s*>(cin), L,
                reinterpret_cast<ltfat_complex_s*>(cout));
}

static inline void
fwd_col2diag(const double *cin, const octave_idx_type L, double *cout)
{
    ltfat_col2diag_d(cin, L, cout);
}

static inline void
fwd_col2diag(const float *cin, const octave_idx_type L, float *cout)
{
    ltfat_col2diag_s(cin, L, cout);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list
octFunction(const octave_value_list& args, int nargout)
{
    MArray<LTFAT_TYPE> cin = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> cout(cin.dims());
    cout.fill(0);

    const octave_idx_type L = cin.rows();

    fwd_col2diag(cin.data(), L, cout.fortran_vec());

    return octave_value(cout);
}
