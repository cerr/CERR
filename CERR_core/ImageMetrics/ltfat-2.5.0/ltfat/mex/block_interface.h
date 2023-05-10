#include "ltfat_mex_template_helper.h"
#include "mex.h"
#include <string.h>

#define COMMAND_LENGTH 20

#define ARRAYLEN(x) ((sizeof(x))/(sizeof(*x)))

/*
 * Structure for holding attributes
 * */
typedef struct biEntry biEntry;
struct biEntry 
{
   char name[COMMAND_LENGTH];
   mxArray* var;
   void (*setter)(biEntry* obj,const mxArray* in);
   mxArray* (*getter)(biEntry* obj);
};


/*
 * Default setter and getter functions
 * */
void defaultSetter(biEntry* obj,const mxArray* in);
mxArray* defaultGetter(biEntry* obj);

/*
 * General functions
 * */
biEntry* lookupEntry(const char* name, biEntry* dict, size_t dictLen);
void resetAll(biEntry* dict, size_t dictLen);
void clearAll(biEntry* dict, size_t dictLen);
void clearAllWrapper();

/*
 * Custom functions
 * */
mxArray* getSource(biEntry* obj);
mxArray* getEnqBufCount();
mxArray* getToPlay(biEntry* obj);
void incPageNo();
void pushPage(const mxArray* in);
mxArray* popPage();
