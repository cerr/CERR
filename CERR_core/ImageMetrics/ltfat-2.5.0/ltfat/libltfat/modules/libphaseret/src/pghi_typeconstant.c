#include "phaseret/rtpghi.h"

PHASERET_API double
phaseret_firwin2gamma(LTFAT_FIRWIN win, ltfat_int gl)
{
    double gamma;
    if ( gl <= 0) return NAN;

    switch (win)
    {
    case LTFAT_HANN:
    /* case LTFAT_HANNING: */
    /* case LTFAT_NUTTALL10: */
        gamma = 0.25645; break;
    case LTFAT_SQRTHANN:
    /* case LTFAT_COSINE: */
    /* case LTFAT_SINE: */
        gamma = 0.41532; break;
    case LTFAT_HAMMING:
        gamma = 0.29794; break;
    case LTFAT_NUTTALL01:
        gamma = 0.29610; break;
    case LTFAT_SQUARE:
    /* case LTFAT_RECT: */
        gamma = 0.85732; break;
    case LTFAT_TRIA:
    /* case LTFAT_TRIANGULAR: */
    /* case LTFAT_BARTLETT: */
        gamma = 0.27561; break;
    case LTFAT_SQRTTRIA:
        gamma = 0.48068; break;
    case LTFAT_BLACKMAN:
        gamma = 0.17954; break;
    case LTFAT_BLACKMAN2:
        gamma = 0.18465; break;
    case LTFAT_NUTTALL:
    /* case LTFAT_NUTTALL12: */
        gamma = 0.12807; break;
    case LTFAT_OGG:
    /* case LTFAT_ITERSINE: */
        gamma = 0.35744; break;
    case LTFAT_NUTTALL20:
        gamma = 0.14315; break;
    case LTFAT_NUTTALL11:
        gamma = 0.17001; break;
    case LTFAT_NUTTALL02:
        gamma = 0.18284; break;
    case LTFAT_NUTTALL30:
        gamma = 0.09895; break;
    case LTFAT_NUTTALL21:
        gamma = 0.11636; break;
    case LTFAT_NUTTALL03:
        gamma = 0.13369; break;
    case LTFAT_TRUNCGAUSS01:
        gamma = 0.17054704423023; break;
    default:
        return NAN;
    };

    gamma *= gl * gl;

    return gamma;
}
