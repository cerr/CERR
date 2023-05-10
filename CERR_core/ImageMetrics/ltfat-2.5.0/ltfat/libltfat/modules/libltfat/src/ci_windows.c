#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#define FIRWIN_RESETCOUNTER do{ \
if (ii == domod.quot + domod.rem) \
                posInt = startInt; \
            }while(0)

LTFAT_API int
LTFAT_NAME(firwin)(LTFAT_FIRWIN win, ltfat_int gl, LTFAT_TYPE* g)
{
    double step, startInt, posInt;
    ltfat_div_t domod;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(g);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");

    step = 1.0 / gl;
    // for gl even
    startInt = -0.5;
    domod = ltfat_idiv(gl, 2);

    if (domod.rem)
        startInt = -0.5 + step / 2.0;

    posInt = 0;

    switch (win)
    {
    case LTFAT_HANN:
    {
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.5 + 0.5 * cos(2.0 * M_PI * posInt) );
            posInt += step;
        }
        break;
    }

    case LTFAT_SQRTHANN:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( sqrt(0.5 + 0.5 * cos(2.0 * M_PI * posInt)) );
            posInt += step;
        }
        break;

    case LTFAT_HAMMING:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.54 + 0.46 * cos(2.0 * M_PI * posInt));
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL01:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.53836 + 0.46164 * cos(2 * M_PI * posInt) );
            posInt += step;
        }
        break;

    case LTFAT_RECT:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( (fabs(posInt) < 0.5 ? 1.0 : 0.0 ));
            posInt += step;
        }
        break;

    case LTFAT_TRIANGULAR:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 1.0 - 2.0 * fabs(posInt) );
            posInt += step;
        }
        break;

    case LTFAT_SQRTTRIA:
        LTFAT_NAME(firwin)(LTFAT_TRIA, gl, g);
        for (ltfat_int ii = 0; ii < gl; ii++)
            g[ii] = ( sqrt(g[ii]) );

        break;

    case LTFAT_BLACKMAN:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.42 + 0.5 * cos(2 * M_PI * posInt)
                                   + 0.08 * cos( 4.0 * M_PI * posInt) );
            posInt += step;
        }
        break;

    case LTFAT_BLACKMAN2:
    {
        double denomfac = 1.0 / 18608.0;
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            double tmp = 7938.0 + 9240.0 * cos(2.0 * M_PI * posInt) +
                         1430.0 * cos( 4.0 * M_PI * posInt);
            g[ii] = (LTFAT_REAL) ( tmp * denomfac );
            posInt += step;
        }
        break;
    }
    case LTFAT_NUTTALL:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.355768 + 0.487396 * cos(2.0 * M_PI * posInt) +
                                   0.144232 * cos(4.0 * M_PI * posInt) +
                                   0.012604 * cos(6.0 * M_PI * posInt));
            posInt += step;
        }
        break;

    case LTFAT_OGG:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            double innercos = cos(M_PI * posInt);
            g[ii] = (LTFAT_REAL) ( sin(M_PI / 2.0 * innercos * innercos) );
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL20:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) (( 3.0 + 4.0 * cos(2.0 * M_PI * posInt)
                                    + cos(4.0 * M_PI * posInt) ) / 8.0);
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL11:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.40897 + 0.5 * cos(2.0 * M_PI * posInt) +
                                   0.09103 * cos( 4.0 * M_PI * posInt) );
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL02:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.4243801 + 0.4973406 * cos(2.0 * M_PI * posInt) +
                                   0.0782793 * cos( 4.0 * M_PI * posInt) );
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL30:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 10.0 + 15.0 * cos(2.0 * M_PI * posInt) +
                                   6.0 * cos( 4.0 * M_PI * posInt) +
                                   cos(6.0 * M_PI * posInt));
            g[ii] /= 32.0;
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL21:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.338946 + 0.481973 * cos(2.0 * M_PI * posInt) +
                                   0.161054 * cos(4.0 * M_PI * posInt) +
                                   0.018027 * cos(6.0 * M_PI * posInt));
            posInt += step;
        }
        break;

    case LTFAT_NUTTALL03:
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) ( 0.3635819 + 0.4891775 * cos(2.0 * M_PI * posInt) +
                                   0.1365995 * cos( 4.0 * M_PI * posInt) +
                                   0.0106411 * cos(6.0 * M_PI * posInt));
            posInt += step;
        }
        break;
    case LTFAT_TRUNCGAUSS01:
    {
        double gamma =  4.0 * log(0.01);
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) exp(posInt * posInt * gamma);
            posInt += step;
        }
        break;
    }
    case LTFAT_TRUNCGAUSS005:
    {
        double gamma =  4.0 * log(0.005);
        for (ltfat_int ii = 0; ii < gl; ii++)
        {
            FIRWIN_RESETCOUNTER;
            g[ii] = (LTFAT_REAL) exp(posInt * posInt * gamma);
            posInt += step;
        }
        break;
    }
    default:
        CHECKCANTHAPPEN("Unknown window");
    };

    // Fix symmetry of windows which are not zero at -0.5
    if (!domod.rem)
        g[domod.quot + domod.rem] = 0.0;

error:
    return status;
}


LTFAT_API int
LTFAT_NAME(mtgauss)(ltfat_int a, ltfat_int M, double thr, LTFAT_TYPE* g)
{
    double step, startInt, posInt, gamma;
    ltfat_div_t domod;
    int status = LTFATERR_FAILED;
    ltfat_int gl = ltfat_mtgausslength( a, M, thr);
    CHECKNULL(g);
    CHECKSTATUS(gl);

    step = 1.0 / gl;
    startInt = -0.5;
    domod = ltfat_idiv(gl, 2);

    if (domod.rem)
        startInt = -0.5 + step / 2.0;

    posInt = 0;
    gamma =  -M_PI*((double)(gl*gl))/((double)(a*M));
    for (ltfat_int ii = 0; ii < gl; ii++)
    {
        FIRWIN_RESETCOUNTER;
        g[ii] = (LTFAT_REAL) exp(posInt * posInt * gamma);
        posInt += step;
    }

    // Fix symmetry of windows which are not zero at -0.5
    if (!domod.rem)
        g[domod.quot + domod.rem] = 0.0;

    return LTFATERR_SUCCESS;
error:
    return status;
}


#undef FIRWIN_RESETCOUNTER


