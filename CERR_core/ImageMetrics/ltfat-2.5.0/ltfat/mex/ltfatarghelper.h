#ifndef _LTFATARGHELPER_H
#define _LTFATARGHELPER_H

#include <ctype.h>  // Because of upper
#include "mex.h"
#include "../lib/ltfatcompat/utils/dbg.h"
#include "../lib/ltfatcompat/utils/lcthw_List.h"

// To help muting the unused variable compiler warning
// Only works for GCC and Clang
#ifdef __GNUC__
#  define UNUSED(x) UNUSED_ ## x __attribute__((__unused__))
#else
#  define UNUSED(x) UNUSED_ ## x
#endif

typedef struct
{
   char command[10];
   int (*callfun)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
} scomm;


/* Functions implementing special command interace for setting up function defaults  */

void handleCommandMode(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
int getCommand(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
int setCommand(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
int allCommand(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
int clearallCommand(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/* At exit function */
void clearall();

// This is a bit tricky
// Adding mxArray to a struct means that it will be freed together with the struct. If it
// is in another struct or cell at the same time, it will be freed twice
// The same goes with mxDestroxArray here as the already existing field might be
// also referenced from another cell or struct 
// The safest thing is probably to always do mxDuplicateArray on added, unless you are
// really certain it is not referenced from elsewhere 
int ltfatSetStructField(mxArray* struc, const char* prefix, const char* fieldname, const mxArray* added);
// This will call mxFree on **array and set *array to NULL
void ltfatClean(char** array);
// Inplace string uppercase 
char* upper(char* a);


#endif /* _LTFATARGHELPER_H */

