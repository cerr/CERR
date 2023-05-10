#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

LTFAT_API void
LTFAT_NAME(col2diag)(const LTFAT_TYPE *cin, ltfat_int L,
                     LTFAT_TYPE *cout)
{
    ltfat_int ii;

    LTFAT_TYPE *pcout;
    const LTFAT_TYPE *pcin;

    pcout=cout;
    ltfat_int Lp1=L+1;
    for (ltfat_int jj=0; jj<L; jj++)
    {
        pcin=cin+(L-jj)*L;
        for (ii=0; ii<jj; ii++)
        {
            (*pcout) = (*pcin);
            pcout++;
            pcin+=Lp1;
        }
        pcin-=L*L;
        for (ii=jj; ii<L; ii++)
        {
            (*pcout) = (*pcin);
            pcout++;
            pcin+=Lp1;
        }
    }

}

