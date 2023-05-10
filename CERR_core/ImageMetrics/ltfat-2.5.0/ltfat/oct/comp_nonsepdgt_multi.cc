#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define COMPLEXARGS
#define OCTFILENAME comp_nonsepdgt_multi // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     c=comp_nonsepdgt_multi(f,g,a,M,lt);\n"


#include "ltfat_oct_template_helper.h"


static inline void
fwd_dgt_multi( const Complex *f,const Complex *g,
               const octave_idx_type L, const octave_idx_type Lg,
               const octave_idx_type W, const octave_idx_type a,
               const octave_idx_type M, const octave_idx_type lt1,
               const octave_idx_type lt2, Complex *cout)
{
    ltfat_dgt_multi_d(
        reinterpret_cast<const ltfat_complex_d *>(f),
        reinterpret_cast<const ltfat_complex_d *>(g),
        L,Lg,W,a,M,lt1,lt2,
        reinterpret_cast<ltfat_complex_d *>(cout));
}

static inline void
fwd_dgt_multi( const FloatComplex *f,const FloatComplex *g,
               const octave_idx_type L, const octave_idx_type Lg,
               const octave_idx_type W, const octave_idx_type a,
               const octave_idx_type M, const octave_idx_type lt1,
               const octave_idx_type lt2, FloatComplex *cout)
{
    ltfat_dgt_multi_s(
        reinterpret_cast<const ltfat_complex_s *>(f),
        reinterpret_cast<const ltfat_complex_s *>(g),
        L,Lg,W,a,M,lt1,lt2,
        reinterpret_cast<ltfat_complex_s *>(cout));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    DEBUGINFO;
    MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> g = ltfatOctArray<LTFAT_TYPE>(args(1));
    const int    a        = args(2).int_value();
    const double M        = args(3).int_value();
    const Matrix lt       = args(4).matrix_value();

    const int L  = f.rows();
    const int W  = f.cols();
    const int Lg = g.rows();
    const int N  = L/a;

    const int lt1 = ltfat_round(lt(0));
    const int lt2 = ltfat_round(lt(1));

    dim_vector dims_out(M,N,W);
    dims_out.chop_trailing_singletons();

    MArray<LTFAT_COMPLEX> cout(dims_out);

    fwd_dgt_multi(f.data(),g.data(),L,Lg,W,a,M,lt1,lt2,cout.fortran_vec());

    return octave_value(cout);
}
