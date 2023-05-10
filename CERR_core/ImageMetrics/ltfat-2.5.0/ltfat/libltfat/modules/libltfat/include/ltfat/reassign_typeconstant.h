#ifndef _LTFAT_REASSIGN_TYPECONSTANT_H
#define _LTFAT_REASSIGN_TYPECONSTANT_H

#define fbreassOptOut_EXPANDRAT 2

typedef enum
{
    REASS_DEFAULT          = 0,
    REASS_NOTIMEWRAPAROUND = 1
} fbreassHints;

typedef struct {
   ltfat_int** repos;
   ltfat_int*  reposl;
   ltfat_int*  reposlmax;
   ltfat_int   l;
} fbreassOptOut;

LTFAT_API fbreassOptOut*
fbreassOptOut_init(ltfat_int l,ltfat_int inital);

LTFAT_API void
fbreassOptOut_expand(fbreassOptOut* oo,ltfat_int ii);

LTFAT_API void
fbreassOptOut_destroy(fbreassOptOut* oo);


#endif /* end of include guard: _REASSIGN_H */
