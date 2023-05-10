#if !(defined(LTFAT_DOUBLE) || defined(LTFAT_SINGLE))
#define LTFAT_DOUBLE
#endif

#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#ifdef __cplusplus
#include <chrono>
#include <iostream>
#include <vector>
#include <memory>

using Clock = std::chrono::high_resolution_clock;
using namespace std;
#else
#endif
