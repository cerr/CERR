#include "ltfat.h"

LTFAT_API ltfatExtType
ltfatExtStringToEnum(const char* extType)
{
    if (strcmp(extType, "per") == 0)
    {
        return PER;
    }
    else if (strcmp(extType, "perdec") == 0)
    {
        return PERDEC;
    }
    else if (strcmp(extType, "ppd") == 0)
    {
        return PPD;
    }
    else if (strcmp(extType, "sym") == 0)
    {
        return SYM;
    }
    else if (strcmp(extType, "even") == 0)
    {
        return EVEN;
    }
    else if (strcmp(extType, "symw") == 0)
    {
        return SYMW;
    }
    else if (strcmp(extType, "odd") == 0)
    {
        return ODD;
    }
    else if (strcmp(extType, "asymw") == 0)
    {
        return ASYMW;
    }
    else if (strcmp(extType, "sp0") == 0)
    {
        return SP0;
    }
    else if (strcmp(extType, "zpd") == 0)
    {
        return ZPD;
    }
    else if (strcmp(extType, "zero") == 0)
    {
        return ZERO;
    }
    else if (strcmp(extType, "valid") == 0)
    {
        return VALID;
    }
    else
    {
        return BAD_TYPE;
    }
}
