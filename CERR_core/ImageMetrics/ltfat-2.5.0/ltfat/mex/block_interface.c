#include "block_interface.h"


void defaultSetter(biEntry* obj, const mxArray* in)
{
   if (obj->var != NULL)
      mxDestroyArray(obj->var);

   obj->var = mxDuplicateArray(in);
   mexMakeArrayPersistent(obj->var);
}

mxArray* defaultGetter(biEntry* obj)
{
   if (obj->var != NULL)
      return mxDuplicateArray(obj->var);
   else
      return mxCreateDoubleMatrix(0, 0, mxREAL);
}

/*
 * Filling the attributes dictionary
 * */
static biEntry vars[] =
{
   // Default setters and getters
   {.name = "Ls", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "Fs", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "OutFile", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "Offline", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "Pos", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "Datapos", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "BufCount", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "PlayChanList", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "RecChanList", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "PageList", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "PageNo", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "Skipped", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "BufLen", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "ClassId", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "AnaOverlap", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "SynOverlap", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "DispLoad", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   {.name = "IsLoop", .var = NULL, .setter = defaultSetter, .getter = defaultGetter},
   // Default setters and custom getters
   {.name = "Source", .var = NULL, .setter = defaultSetter, .getter = getSource},
   {.name = "EnqBufCount", .var = NULL, .setter = NULL, .getter = getEnqBufCount},
   {.name = "ToPlay", .var = NULL, .setter = defaultSetter, .getter = getToPlay},
};




biEntry* lookupEntry(const char* name, biEntry* dict, size_t dictLen)
{
   size_t ii;
   for (ii = 0; ii < dictLen; ii++)
   {
      if (!strncmp(name, dict[ii].name, strlen(dict[ii].name)))
      {
         return &dict[ii];
      }
   }
   return NULL;
}

void resetAll(biEntry* dict, size_t dictLen)
{
   size_t ii;
   clearAll(dict, dictLen);
   for (ii = 0; ii < dictLen; ii++)
   {
      if (!strcmp(dict[ii].name, "Ls"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(-1.0));
      }
      else if (!strcmp(dict[ii].name, "Pos"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "Datapos"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "Offline"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "BufCount"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(3.0));
      }
      else if (!strcmp(dict[ii].name, "PageNo"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "Skipped"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "DispLoad"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(1.0));
      }
      else if (!strcmp(dict[ii].name, "IsLoop"))
      {
         dict[ii].setter(&dict[ii], mxCreateDoubleScalar(0.0));
      }
      else if (!strcmp(dict[ii].name, "ClassId"))
      {
         dict[ii].setter(&dict[ii], mxCreateString("double"));
      }
   }
}

void clearAllWrapper()
{
   clearAll(vars, ARRAYLEN(vars));
}

void clearAll(biEntry* dict, size_t dictLen)
{
   size_t ii;
   for (ii = 0; ii < dictLen; ii++)
   {
      if (dict[ii].var != NULL)
      {
         mxDestroyArray(dict[ii].var);
         dict[ii].var = NULL;
      }
   }
}
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   (void) nlhs; // To avoid the unused parameter warning
   static int atExitRegistered = 0;
   if (!atExitRegistered)
   {
      atExitRegistered = 1;
      mexAtExit(clearAllWrapper);
   }
   if (nrhs < 1)
   {
      mexErrMsgTxt("BLOCK_INTERFACE: Not enough input arguments.");
   }

   const mxArray* mxCmd = prhs[0];
   char command[COMMAND_LENGTH];
   size_t comStrLen = mxGetNumberOfElements(mxCmd);
   mxGetString(mxCmd, command, comStrLen + 1);

   if (!strncmp(command, "set", 3))
   {
      if (nrhs < 2)
      {
         mexErrMsgTxt("BLOCK_INTERFACE: Not enough arguments for the set method.");
      }
      biEntry* cmdStruct = lookupEntry(command + 3, vars, ARRAYLEN(vars));

      if (cmdStruct == NULL)
      {
         mexErrMsgTxt("BLOCK_INTERFACE: Unrecognized set command.");
      }
      cmdStruct->setter(cmdStruct, prhs[1]);
      return;
   }
   else if (!strncmp(command, "get", 3))
   {
      if (nrhs > 1)
      {
         mexErrMsgTxt("BLOCK_INTERFACE: Too many input arguments for get method.");
      }
      biEntry* cmdStruct = lookupEntry(command + 3, vars, ARRAYLEN(vars));
      if (cmdStruct == NULL)
      {
         mexErrMsgTxt("BLOCK_INTERFACE: Unrecognized get command.");
      }
      plhs[0] = cmdStruct->getter(cmdStruct);
      return;
   }
   else if (!strcmp(command, "reset"))
   {
      resetAll(vars, ARRAYLEN(vars));
      return;

   }
   else if (!strcmp(command, "incPageNo"))
   {
      incPageNo();
      return;
   }
   else if (!strcmp(command, "popPage"))
   {
      plhs[0] = popPage();
      return;
   }
   else if (!strcmp(command, "pushPage"))
   {
      pushPage(prhs[1]);
      return;
   }
   else if (!strcmp(command, "clearAll"))
   {
      clearAllWrapper();
      return;
   }
   else if (!strcmp(command, "flushBuffers"))
   {
      biEntry* be1 = lookupEntry("AnaOverlap", vars, ARRAYLEN(vars));

      if (be1->var != NULL)
      {
         mxDestroyArray(be1->var);
         be1->var = NULL;
      }
      biEntry* be2 = lookupEntry("SynOverlap", vars, ARRAYLEN(vars));

      if (be2->var != NULL)
      {
         mxDestroyArray(be2->var);
         be2->var = NULL;
      }
      return;
   }

   mexErrMsgTxt("BLOCK_INTERFACE: Unrecognized command.");

}

mxArray* getSource(biEntry* obj)
{
   if (obj->var == NULL || mxIsNumeric(obj->var))
      return mxCreateString("numeric");
   else
      return mxDuplicateArray(obj->var);
}

mxArray* getEnqBufCount()
{
   double retVal = 0.0;
   biEntry* cmdStruct = lookupEntry("PageList", vars, ARRAYLEN(vars));
   if (cmdStruct->var != NULL)
      retVal = mxGetNumberOfElements(cmdStruct->var);

   return mxCreateDoubleScalar(retVal);
}

void incPageNo()
{
   double* pageNo;
   biEntry* cmdStruct = lookupEntry("PageNo", vars, ARRAYLEN(vars));
   if (cmdStruct->var == NULL)
   {
      cmdStruct->var = mxCreateDoubleScalar(1.0);
      mexMakeArrayPersistent(cmdStruct->var);
   }
   else
   {
      pageNo = mxGetPr(cmdStruct->var);
      *pageNo = *pageNo + 1.0;
   }
}

mxArray* getToPlay(biEntry* obj)
{
   if (obj->var != NULL)
   {
      mxArray* duplicate = mxDuplicateArray(obj->var);
      mxDestroyArray(obj->var);
      obj->var = NULL;
      return duplicate;
   }
   else
   {
      return defaultGetter(obj);
   }
}

void pushPage(const mxArray* in)
{
   biEntry* cmdStruct = lookupEntry("PageList", vars, ARRAYLEN(vars));
   if (cmdStruct->var == NULL)
   {
      cmdStruct->setter(cmdStruct, in);
   }
   else
   {
      size_t M = mxGetM(cmdStruct->var);
      size_t N = mxGetN(cmdStruct->var);
      size_t maxMN = M > N ? M : N;
      mxArray* tmp = mxCreateDoubleMatrix(1, maxMN + 1, mxREAL);
      memcpy(mxGetPr(tmp), mxGetPr(cmdStruct->var), maxMN * sizeof(double));
      memcpy(mxGetPr(tmp) + maxMN, mxGetPr(in), sizeof(double));
      cmdStruct->setter(cmdStruct, tmp);
   }
}

mxArray* popPage()
{
   size_t M,N,maxMN;
   double retVal;
   mxArray* tmp;
   biEntry* cmdStruct = lookupEntry("PageList", vars, ARRAYLEN(vars));
   if (cmdStruct->var == NULL)
   {
      return cmdStruct->getter(cmdStruct);
   }
   else
   {
      retVal = mxGetScalar(cmdStruct->var);
      M = mxGetM(cmdStruct->var);
      N = mxGetN(cmdStruct->var);
      maxMN = M > N ? M : N;
      tmp = mxCreateDoubleMatrix(1, maxMN - 1, mxREAL);
      memcpy(mxGetPr(tmp), mxGetPr(cmdStruct->var) + 1, (maxMN - 1)*sizeof(double));
      cmdStruct->setter(cmdStruct, tmp);
      return mxCreateDoubleScalar(retVal);
   }
}

