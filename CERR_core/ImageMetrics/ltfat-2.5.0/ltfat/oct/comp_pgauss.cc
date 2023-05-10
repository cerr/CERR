#include <octave/oct.h>
#include "ltfat.h"

DEFUN_DLD (comp_pgauss, args, ,
           "This function calls the C-library\n\
            c=comp_pgauss(L,w,c_t,c_f);\n")
{

    const int    L      = args(0).int_value();
    const double w      = args(1).double_value();
    const double c_t    = args(2).double_value();
    const double c_f    = args(3).double_value();

    if (c_f == 0.0)
    {
        Matrix g(L, 1);
        ltfat_pgauss_d(L, w, c_t, g.fortran_vec());

        return octave_value (g);
    }
    else
    {
        ComplexMatrix g(L, 1);
        ltfat_pgauss_dc(L, w, c_t, c_f,
                       reinterpret_cast<ltfat_complex_d*>(g.fortran_vec()));

        return octave_value (g);
    }
}
