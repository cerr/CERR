#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXARGS
#define OCTFILENAME comp_nonsepwin2multi // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                    c=comp_nonsepwin2multi(g,a,M,lt,L);\n"


#include "ltfat_oct_template_helper.h"
// octave_idx_type is 32 or 64 bit signed integer


static inline void
fwd_nonsepwin2multi(const Complex *g,
                    const octave_idx_type L, const octave_idx_type Lg,
                    const octave_idx_type a, const octave_idx_type M,
                    const octave_idx_type lt1, const octave_idx_type lt2,
                    Complex *mwin)
{
    ltfat_nonsepwin2multi_d(
        reinterpret_cast<const ltfat_complex_d *>(g),
        L,Lg,a,M,lt1,lt2,
        reinterpret_cast<ltfat_complex_d *>(mwin));
}

static inline void
fwd_nonsepwin2multi(const FloatComplex *g,
                    const octave_idx_type L, const octave_idx_type Lg,
                    const octave_idx_type a, const octave_idx_type M,
                    const octave_idx_type lt1, const octave_idx_type lt2,
                    FloatComplex *mwin)
{
    ltfat_nonsepwin2multi_s(
        reinterpret_cast<const ltfat_complex_s *>(g),
        L,Lg,a,M,lt1,lt2,
        reinterpret_cast<ltfat_complex_s *>(mwin));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(0));

    const int    a        = args(1).int_value();
    const int    M        = args(2).int_value();
    const Matrix lt       = args(3).matrix_value();
    const int    L        = args(4).int_value();

    const int Lg = g.rows();
    const int lt1 = ltfat_round(lt(0));
    const int lt2 = ltfat_round(lt(1));

    MArray<LTFAT_COMPLEX> mwin(dim_vector(L,lt2));

    fwd_nonsepwin2multi(g.data(),L,Lg,a,M,lt1,lt2,mwin.fortran_vec());

    return octave_value(mwin);
}
