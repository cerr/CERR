#define LTFAT_DOUBLE
#include "ltfat/types.h"
#define TEST_NAME(name) name##_d
#define TEST_NAME_COMPLEX(name) name##_dc

#include "test_typecomplexindependent.c"
#include "test_typeindependent.c"

#undef TEST_NAME
#undef TEST_NAME_COMPLEX
#undef LTFAT_DOUBLE

#define LTFAT_SINGLE
#include "ltfat/types.h"
#define TEST_NAME(name) name##_s
#define TEST_NAME_COMPLEX(name) name##_sc

#include "test_typecomplexindependent.c"
#include "test_typeindependent.c"


#undef TEST_NAME
#undef TEST_NAME_COMPLEX
#undef LTFAT_SINGLE

#define LTFAT_COMPLEXTYPE

#define LTFAT_DOUBLE
#include "ltfat/types.h"
#define TEST_NAME(name) name##_dc
#define TEST_NAME_COMPLEX(name) name##_dc

#include "test_typecomplexindependent.c"

#undef TEST_NAME
#undef TEST_NAME_COMPLEX
#undef LTFAT_DOUBLE

#define LTFAT_SINGLE
#include "ltfat/types.h"
#define TEST_NAME(name) name##_sc
#define TEST_NAME_COMPLEX(name) name##_sc


#include "test_typecomplexindependent.c"

#undef TEST_NAME
#undef TEST_NAME_COMPLEX
#undef LTFAT_SINGLE
#undef LTFAT_COMPLEXTYPE

// Unsets all the macros 
#include "ltfat/types.h"
