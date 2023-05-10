#include <octave/oct.h>
#include "ltfat.h"

DEFUN_DLD (comp_pchirp, args, ,
           "This function calls the C-library\n\
            c=pchirp(L,n);\n")
{

    const octave_idx_type L = args(0).int_value();
    const octave_idx_type n = args(1).int_value();

    ComplexMatrix g(L, 1);

    ltfat_pchirp_d(L, n, reinterpret_cast<ltfat_complex_d *>(g.fortran_vec()));

    return octave_value (g);

}

