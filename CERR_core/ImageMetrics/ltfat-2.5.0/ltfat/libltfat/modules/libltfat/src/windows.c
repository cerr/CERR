#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

LTFAT_API int
LTFAT_NAME(pgauss)(ltfat_int L, const double w, const double c_t,
                   LTFAT_REAL* g)
{
    ltfat_int lr, k, nk;
    double tmp, sqrtL, safe, gnorm, gtmp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(g);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive (passed %td).", L);
    CHECK(LTFATERR_NOTPOSARG, w > 0, "w must be positive (passed %f).", w);


    sqrtL = sqrt((double)L);
    safe = 4;
    gnorm = 0;

    /* Outside the interval [-safe,safe] then exp(-pi*x.^2) is numerically zero. */
    nk = (ltfat_int)ceil(safe / sqrt((double)L / sqrt(w)));

    for ( lr = 0; lr < L; lr++)
    {
        gtmp = 0.0;
        for (k = -nk; k <= nk; k++)
        {
            /* Use a tmp variable to calculate squaring */
            tmp = ((double)lr + c_t) / sqrtL - (double)k * sqrtL;
            gtmp += exp(-M_PI * tmp * tmp / w);
        }
        gnorm += gtmp * gtmp;
        g[lr] = (LTFAT_REAL) gtmp;
    }

    /* Normalize it exactly. */
    gnorm = sqrt(gnorm);

    for ( lr = 0; lr < L; lr++)
        g[lr] /= ( (LTFAT_REAL) gnorm);

error:
    return status;
}


/* does not work correctly. This code does:
%for k=-nk:nk
%  tmp=exp(-pi*((lr+c_t)/sqrtL-k*sqrtL).^2/w)
%  g=g+tmp.*cos(2*pi*c_f*(lr/L-k))+i*tmp.*sin(2*pi*c_f*(lr/L-k));
%end;
*/

LTFAT_API int
LTFAT_NAME_COMPLEX(pgauss)(ltfat_int L, const double w, const double c_t,
                           const double c_f, LTFAT_COMPLEX* g)
{
    int status = LTFATERR_SUCCESS;
    ltfat_int lr, k, nk;
    double tmp, sqrtL, safe, gnorm;
    LTFAT_COMPLEX gtmp;

    CHECKNULL(g);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive (passed %td).", L);
    CHECK(LTFATERR_NOTPOSARG, w > 0, "w must be positive (passed %f).", w);

    sqrtL = sqrt((double)L);
    safe = 4;
    gnorm = 0;

    /* Outside the interval [-safe,safe] then exp(-pi*x.^2) is numerically zero. */
    nk = (ltfat_int)ceil(safe / sqrt((double)L / sqrt(w)));

    for ( lr = 0; lr < L; lr++)
    {
        gtmp = (LTFAT_COMPLEX) 0.0;
        for (k = -nk; k <= nk; k++)
        {
            /* Use a tmp variable to calculate squaring */
            tmp = ((double)lr + c_t) / sqrtL - (double)k * sqrtL;
            tmp = exp( -M_PI * tmp * tmp / w );
            gtmp += (LTFAT_REAL)(tmp) *
                    exp(I * (LTFAT_REAL)( 2.0 * M_PI * c_f * ((( double)lr) / ((double)L) - ((
                                              double)k))));

            g[lr] = gtmp;
        }
        double gReal = ltfat_real(gtmp);
        double gImag = ltfat_imag(gtmp);
        gnorm += (gReal * gReal + gImag * gImag);
    }

    /* Normalize it exactly. */
    gnorm = sqrt(gnorm);

    for ( lr = 0; lr < L; lr++)
        g[lr] /= ( (LTFAT_REAL) gnorm );

error:
    return status;
}
