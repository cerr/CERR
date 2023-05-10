//   LTFATARGHELPER MEX file
//
//   This MEX file does the same thing as ltfatarghelper.m
//   from LTFAT but faster.
//
//
//
//   mxArrayToString has to be freed manually !!!

//#define DISABLEMEXFNC
#include "ltfatarghelper.h"

// As we cannot print error message using mexErrMsg... AND continute (e.g. to free
// resources) we must store the error message to be printed and set MEXERROCURRED
// and check it at the end of the function
char MEXERRSTRING[500];
int  MEXERROCCURED;

// For holding defaults, it is feed only together with the MEX function
static mxArray* TF_CONF = NULL;

// Special interface commands and function pointers
static scomm carr[] =
{
   {"get", getCommand},
   {"set", setCommand},
   {"all", allCommand},
   {"clearall", clearallCommand}
};

// Array length
static int scommLen = sizeof(carr) / sizeof(*carr);

/*
 * Calling conventions:
 * [flags,keyvals,posarg1,posarg2,...] =
 * ltfatarghelper(posdepnames,definput,arglist,callfun[optional])
 *
 * Special command interface:
 * ltfatarghelper('set',...)
 * ltfatarghelper('get',...)
 * ltfatarghelper('all')
 * ltfatarghelper('clearall',)
 *
 * */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   // Flag indicating whether the atexit function was already registered
   static int atExitRegistered = 0;
   MEXERROCCURED = 0;

   // These three will be pointers to input, so the cannot change
   const mxArray* posdepnames; // prhs[0]
   mxArray* definput = NULL;   // prhs[1], we might replace this with a copy
   const mxArray* arglist;     // prhs[3]
   // 4th optional arg.
   mxArray* callfun = NULL;
   // The same but as a string copy
   char* callfunStr = NULL;
   // Returned args (third and following args are copied from keyvals)
   mxArray* flags = NULL;            // plhs[0]
   mxArray* keyvals = NULL;          // plhs[1]

   // General temp. vars
   char* atosRetVal = NULL;
   char* atosRetVal2 = NULL;
   mxArray* retVal = NULL;

   // Linked list of args
   List* restlist = NULL;
   List* trashlist = NULL;
   // Temporary variables
   mxArray* defflags = NULL;
   mxArray* flagsreverse = NULL;
   mxArray* defkeyvals = NULL;
   mxArray* groups = NULL;

   // Register the atexit function if not done already
   if (!atExitRegistered)
   {
      atExitRegistered = 1;
#ifndef DISABLEMEXFNC
      mexAtExit(clearall);
#endif
   }

   // Initialize TF_CONF.funnames
   if (!TF_CONF)
   {
      const char* fieldnames = "fundefs";
      TF_CONF = mxCreateStructMatrix(1, 1, 1, &fieldnames);
      mxSetField(TF_CONF, 0, fieldnames, mxCreateStructMatrix(1, 1, 0, NULL));

#ifndef DISABLEMEXFNC
      mexMakeArrayPersistent(TF_CONF);
#endif
   }

   check( nrhs >= 1, "LTFATARGHELPER: Not enough input arguments.");

   // Safely read the first arg
   posdepnames = prhs[0];

   check( mxIsChar(posdepnames) || mxIsCell(posdepnames),
          "LTFATARGHELPER: posdepnames should be either string or a cell array.");

   // Special mode for input commands
   if (mxIsChar(posdepnames))
   {
      handleCommandMode(nlhs, plhs, nrhs, prhs);
      return; /* End here, nothing to free yet */
   }

   // Now we are in the normal mode
   check( nrhs > 2, "LTFATARGHELPER: Not enough input arguments.");
   check( nrhs < 5, "LTFATARGHELPER: Too many input arguments.");
   // only 3-4 input args are allowed

   // Second arg
   // We do duplicate here as we might want to change definput
   definput = mxDuplicateArray(prhs[1]);
   // Third arg
   arglist = prhs[2];

   // Fourth optional arg callfun
   if (nrhs < 4)
   {
      // Calling Matlab if callfun is not provided
#ifndef DISABLEMEXFNC
      check(!mexCallMATLAB(1, &retVal, 0, NULL, "dbstack"), "Calling dbstack from Matlab failed");

      check(NULL != retVal, "retVal vas not assigned in Matlab");
      check(!mxIsEmpty(retVal) && mxIsStruct(retVal) && mxGetFieldNumber(retVal, "name") != -1,
            "dbstack output is empty, it is not a struct or it does not have a name field.");
      // FIRST!! element in the recurned struct array is the calling function
      check(mxGetNumberOfElements(retVal) > 0, "Zero length output from dbstack");
      // Do duplicate as we will remove retVal afterwards
      callfun = mxDuplicateArray(mxGetField(retVal, 0, "name"));
      // And we can get rid of retVal
      mxDestroyArray(retVal);
      // ... and we will reuse that so set it to NULL
      retVal = NULL;
#else
      callfun = mxCreateString("TESTING:");
#endif
   }
   else
   {
      // Copy even if callfun was provided explicitly
      callfun = mxDuplicateArray(prhs[3]);
   }

   // Check correct format of input arguments
   check( mxIsCell(posdepnames), "LTFATARGHELPER: posdepnames should be cell.");
   check( mxIsStruct(definput), "LTFATARGHELPER: definput should be struct.");
   check( mxIsCell(arglist), "LTFATARGHELPER: arglist should be struct.");
   check( mxIsChar(callfun), "LTFATARGHELPER: callfun should be string.");

   // This has to be mxFreed at the end
   callfunStr = mxArrayToString(callfun);
   // And we can get rid of callfun
   mxDestroyArray(callfun);
   callfun = NULL;
   // Number of positional-dependent args
   mwSize nposdep = mxGetNumberOfElements(posdepnames);
   // Total number of args
   mwSize total_args = mxGetNumberOfElements(arglist);

   // Import any definition first.
   // This means calling arg_... function
   if (mxGetFieldNumber(definput, "import") != -1)
   {
      // Do duplicate of definput.import because we will overwrite definput shortly
      retVal = mxDuplicateArray(mxGetField(definput, 0, "import"));
      check(mxIsCell(retVal) && !mxIsEmpty(retVal), "LTFATARGHELPER: definput.import must be cell");
      // Temp. for holding output of mexCallMatlab
      mxArray* definputout;
      for (mwSize ii = 0; ii < mxGetNumberOfElements(retVal); ii++)
      {
         mxArray* tmp = mxGetCell(retVal, ii);
         check(mxIsChar(tmp), "LTFATARGHELPER: definput.import{ii} must be string");
         char s[100];
         strcpy(s, "arg_");
         char* tmpStr = mxArrayToString(tmp);
         strcat(s, tmpStr);
         mxFree(tmpStr);
         check( !mexCallMATLAB(1, &definputout, 1, &definput, s), "LTFATARGHELPER: error calling %s ", s);
         // Replace definput with definput just obtained
         mxDestroyArray(definput);
         definput = definputout;
         // Do a minimal check
         check( mxIsStruct(definput) &&
                ( mxGetFieldNumber(definput, "flags") != -1 || mxGetFieldNumber(definput, "keyvals") != -1  ||
                  mxGetFieldNumber(definput, "groups") != -1)
                , "LTFATARGHELPER: Function %s does not return definput in a correct format", s);
      }

      mxDestroyArray(retVal);
      retVal = NULL;
   }


   if (mxGetFieldNumber(definput, "flags") != -1)
   {
      // This is equivalent to a pointer copy
      // Done like this, defflags can be read only
      defflags = mxGetField(definput, 0, "flags");
      check(mxIsStruct(defflags), "LTFATARGHELPER: definput.flags shoud be struct");
   }

   if (mxGetFieldNumber(definput, "keyvals") != -1)
   {
      // The same here.
      defkeyvals = mxGetField(definput, 0, "keyvals");
      check(mxIsStruct(defkeyvals), "LTFATARGHELPER: definput.keyvals shoud be struct");
   }

   if (mxGetFieldNumber(definput, "groups") != -1)
   {
      // And also here
      groups = mxGetField(definput, 0, "groups");
      check(mxIsStruct(groups), "LTFATARGHELPER: definput.groups shoud be struct");
   }


   // Position of the first string arg
   mwSize first_str_pos = 0;
   while (first_str_pos < total_args && ! mxIsChar(mxGetCell(arglist, first_str_pos)))
   {
      first_str_pos++;
   }

   // If the string is found in the posistion dependent args, throw a *callfun* error
   check(first_str_pos <= nposdep, "%s: Too many input arguments", callfunStr);

   // min(nposdep,first_str_pos)
   // where to start with the regular args
   mwSize n_first_args = nposdep < first_str_pos ? nposdep : first_str_pos;

   if (NULL != defkeyvals)
   {
       // We need a copy here as we need the state of keyvals at this point
       keyvals = mxDuplicateArray(defkeyvals);
   }
   else
   {
       // We might need keyvals to be a struct
       keyvals =  mxCreateStructMatrix(1, 1, 0, NULL);
   }

   // Copy positional args as key-value parameters to keyvals
   for (mwSize ii = 0; ii < n_first_args; ii++)
   {
      atosRetVal = mxArrayToString(mxGetCell(posdepnames, ii));
      check( keyvals == NULL || mxGetFieldNumber(keyvals, atosRetVal) != -1,
             "LTFATARGHELPER: Position-dependent param. %s was not specified in definput", atosRetVal);
      mxSetField(keyvals, 0, atosRetVal, mxDuplicateArray(mxGetCell(arglist, ii)));
      ltfatClean(&atosRetVal);
   }

   if (NULL != defflags)
   {
      flags = mxCreateStructMatrix(1, 1, 0, NULL);
      flagsreverse = mxCreateStructMatrix(1, 1, 0, NULL);
      for (int ii = 0; ii < mxGetNumberOfFields(defflags); ii++)
      {
         const char *keyname = mxGetFieldNameByNumber(defflags, ii);
         mxArray* flaggroup = mxGetField(defflags, 0, keyname);

         // Assert the keyname is not yet in flags
         check(mxGetFieldNumber(flags, keyname) == -1,
               "LTFATARGHELPER: Duplicate definition of %s", keyname);
         check(mxIsCell(flaggroup) && !mxIsEmpty(flaggroup),
               "LTFATARGHELPER: Flag group [%s] must be a nonempty cell array", keyname);

         check_keepmessage(
            ltfatSetStructField(flags, "", keyname, mxDuplicateArray(mxGetCell(flaggroup, 0))) == 0);
         for (mwSize jj = 0; jj < mxGetNumberOfElements(flaggroup); jj++)
         {
            mxArray* flagopt = mxGetCell(flaggroup, jj);
            check(mxIsChar(flagopt), "Element of flag group %s in not a string.", keyname);
            atosRetVal = mxArrayToString(flagopt);
            check_keepmessage(
               ltfatSetStructField(flagsreverse, "x_", atosRetVal, mxCreateString(keyname)) == 0);
            check_keepmessage(
               ltfatSetStructField(flags, "do_", atosRetVal, mxCreateDoubleScalar(0.0)) == 0);
            ltfatClean(&atosRetVal);
         }
         atosRetVal = mxArrayToString(mxGetCell(flaggroup, 0));
         check_keepmessage(
            ltfatSetStructField(flags, "do_", atosRetVal, mxCreateDoubleScalar(1.0)) == 0);
         ltfatClean(&atosRetVal);

      }
   }

   // Fill a linked list with arguments located after the posdep. ones
   // We only add coplies to the list
   restlist = List_create();
   // Copy all args after
   if (first_str_pos < mxGetNumberOfElements(arglist))
   {
      for (mwSize ii = first_str_pos; ii < mxGetNumberOfElements(arglist); ii++)
      {
         List_push(restlist, mxDuplicateArray(mxGetCell(arglist, ii)));
      }
   }

   // Add defaults for callfun if they are contained in TF_CONF.fundefs.callfun
   // (if they exist)
   if (mxGetFieldNumber(mxGetField(TF_CONF, 0, "fundefs"), callfunStr) != -1)
   {
      mxArray *s = mxGetField(mxGetField(TF_CONF, 0, "fundefs"), 0, callfunStr);
      check(mxIsCell(s), "TF_CONF.fundefs.%s is not cell.", callfunStr);
      // prepend to restlist
      for (int ii = mxGetNumberOfElements(s) - 1; ii >= 0; ii--)
      {
         List_unshift(restlist, mxDuplicateArray(mxGetCell(s, ii)));
      }
   }

   // Add surrogate default
   // (this is used when importing flags and a different default is required )
   if (mxGetFieldNumber(definput, "importdefaults") != -1)
   {
      mxArray *s = mxGetField(definput, 0, "importdefaults");
      check(mxIsCell(s), "definput.importdefaults is not cell.");
      // prepend to restlist
      for (int ii = mxGetNumberOfElements(s) - 1; ii >= 0; ii--)
      {
         List_unshift(restlist, mxDuplicateArray(mxGetCell(s, ii)));
      }

   }

   char buf[100];
   while ( List_count(restlist) > 0 )
   {
      // This is set to 1 when given arg is known
      int found = 0;
      // Pop the first item from the list
      mxArray* argname = List_shift(restlist);
      check(argname && mxIsChar(argname), "argname is not a string");
      // String value
      atosRetVal = mxArrayToString(argname);

      memset(buf, 0, sizeof(buf));
      strcpy(buf, "x_");
      strcat(buf, atosRetVal);

      // If argname is a flag
      if (defflags && flagsreverse && (mxGetFieldNumber(flagsreverse, buf) != -1))
      {
         // Unset all other flags in that group
         atosRetVal2 =  mxArrayToString(mxGetField(flagsreverse, 0, buf));
         mxArray* flaggroup = mxGetField(defflags, 0, atosRetVal2);
         ltfatClean(&atosRetVal2);
         check(mxIsCell(flaggroup), "flaggroup must be cell")
         for (mwSize ii = 0; ii < mxGetNumberOfElements(flaggroup); ii++)
         {
            mxArray * flaggroupopt = mxGetCell(flaggroup, ii);
            check(mxIsChar(flaggroupopt), "flaggroupopt is not char");
            atosRetVal2 = mxArrayToString(flaggroupopt);
            check_keepmessage(
               ltfatSetStructField(flags, "do_", atosRetVal2 , mxCreateDoubleScalar(0.0)) == 0);
            ltfatClean(&atosRetVal2);

         }
         memset(buf, 0, sizeof(buf));
         strcpy(buf, "x_");
         strcat(buf, atosRetVal);
         atosRetVal2 = mxArrayToString(mxGetField(flagsreverse, 0, buf));
         // Set the flag
         mxSetField(flags, 0, atosRetVal2, mxDuplicateArray(argname));
         ltfatClean(&atosRetVal2);
         // Set the flag to 1
         check_keepmessage(
            ltfatSetStructField(flags, "do_", atosRetVal, mxCreateDoubleScalar(1.0)) == 0);

         found = 1;
      }
      //
      if (defkeyvals && ( mxGetFieldNumber(defkeyvals, atosRetVal) != -1))
      {
         // Sanity check
         // check(found == 0, "%s was already a flag", atosRetVal);
         check(List_count(restlist), "%s: Key-value parameter is missing a value", callfunStr)
         // In case there is a flag with the same name
         // And pop the next as it is value for the key
         // The next item is MOVED from restlist to keyvals
         check_keepmessage( ltfatSetStructField(keyvals, "", atosRetVal, List_shift(restlist)) == 0 );
         found = 1;
      }

      if (groups && mxGetFieldNumber(groups, atosRetVal) != -1)
      {
         //check(found == 0, "%s was already a flag or a keyval", atosRetVal);
         // Again, to avoid flags or keyvals having the same name
         mxArray* s = mxGetField(groups, 0, atosRetVal);
         check(mxIsCell(s), "Group definition is not a cell");
         // prepend to restlist
         for (mwSignedIndex ii = mxGetNumberOfElements(s) - 1; ii >= 0; ii--)
         {
            List_unshift(restlist, mxDuplicateArray( mxGetCell(s, ii)));
         }
         found = 1;
      }

      if (strcmp(atosRetVal, "argimport") == 0)
      {
         check(List_count(restlist) > 1, "restlist too small for argimport");
         // these two are not cleared in case of error
         mxArray* first = List_shift(restlist);
         mxArray* second = List_shift(restlist);

         for (int ii = 0; ii < mxGetNumberOfFields(first); ii++)
         {
            const char * importname =  mxGetFieldNameByNumber(first, ii);
            check_keepmessage(
               ltfatSetStructField(flags, "", importname, mxDuplicateArray(mxGetField(first, 0, importname))) == 0);
         }
         mxDestroyArray(first);

         for (int ii = 0; ii < mxGetNumberOfFields(second); ii++)
         {
            const char * importname =  mxGetFieldNameByNumber(second, ii);
            check_keepmessage(
               ltfatSetStructField(keyvals, "", importname, mxDuplicateArray(mxGetField(second, 0, importname))) == 0);
         }
         mxDestroyArray(second);

         found = 1;
      }

      check(!(!found && argname != NULL),"%s: Unknown parameter: %s", upper(callfunStr), atosRetVal);

      ltfatClean(&atosRetVal);
      mxDestroyArray(argname);
   }

   // Filling output arguments
   if (nlhs >= 1) plhs[0] = flags != NULL ? flags : mxCreateStructMatrix(1, 1, 0, NULL);
   if (nlhs >= 2) plhs[1] = keyvals != NULL ? keyvals : mxCreateStructMatrix(1, 1, 0, NULL);
   for (mwSize ii = 0; ii < nposdep; ii++)
   {
      atosRetVal =  mxArrayToString(mxGetCell(posdepnames, ii));
      plhs[2 + ii] = mxDuplicateArray(mxGetField(keyvals, 0, atosRetVal));
      ltfatClean(&atosRetVal);
   }

error:
   if (NULL != restlist)
   {
      // The list should be empty already, but clear it anyway
      LIST_FOREACH(restlist, first, next, cur)
      {
         mxDestroyArray(cur->value);
      }
      // And destroy the list itself (WARNING_ List_clear calls free on elements)
      List_destroy(restlist);
   }

   if (NULL != trashlist)
   {
      LIST_FOREACH(trashlist, first, next, cur)
      {
         mxDestroyArray(cur->value);
      }
      List_destroy(restlist);
   }
   //return;
   // Conditionally clear everything
   if (NULL != atosRetVal)    mxFree(atosRetVal);
   if (NULL != atosRetVal2)   mxFree(atosRetVal2);
   if (NULL != callfunStr)    mxFree(callfunStr);

   if (NULL != callfun)       mxDestroyArray(callfun);
   if (NULL != definput)      mxDestroyArray(definput);
   if (NULL != retVal)        mxDestroyArray(retVal);
   if (NULL != flagsreverse)  mxDestroyArray(flagsreverse);

   debug("Before global error message.");
   print_mexerror;
   debug("There was no error.");

}


int ltfatSetStructField(mxArray* struc, const char* prefix, const char* fieldname, const mxArray* added)
{
   check(NULL != struc, "struc is NULL");
   check(NULL != added, "added is NULL");
   check(mxIsStruct(struc), "struc is not a struct");
   char buf[100];
   strcpy(buf, prefix);
   strcat(buf, fieldname);

   if (mxGetFieldNumber(struc, buf) != -1)
   {
      // Beware!! This might be referenced from a diffetent struct!
      mxDestroyArray(mxGetField(struc, 0, buf));
   }
   else
   {
      check(mxAddField(struc, buf) != -1, "Couldn't add %s field to a struct.", buf);
   }
   // We moved the const to the function header
   mxSetField(struc, 0, buf, (mxArray*) added);
   return 0;
error:
   return -1;
}

void handleCommandMode(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   char * c = NULL;
   check( nrhs < 4, "LTFATARGHELPER: Too many input arguments.");
   check( mxIsStruct(TF_CONF), "TF_CONF was nit initialized")

   c = mxArrayToString(prhs[0]);
   int cfound = 0;
   for (int ii = 0; ii < scommLen; ii++)
   {
      if (!strcmp(carr[ii].command, c))
      {
         // Command found, call the associated function and check the return code
         // The error message from the function is still stored in a global var
         check_keepmessage(carr[ii].callfun(nlhs, plhs, nrhs, prhs) == 0);
         cfound = 1;
         break;
      }
   }
   ltfatClean(&c);
   check(cfound, "LTFATARGHELPER: Unrecognized command.");
   return;
error:
   if (NULL != c) mxFree(c);
   print_mexerror;
}


int getCommand(int UNUSED(nlhs), mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   char* definputStr = NULL;
   check(nrhs == 2, "Number of arguments must be 2 for the get command")
   const mxArray* definput = prhs[1];
   definputStr =  mxArrayToString(definput);
   check(TF_CONF, "TF_CONF is null");
   check(mxIsChar(definput), "definput must be a string")
   check(mxGetFieldNumber(TF_CONF, "fundefs") != -1, "TF_CONF.fundefs does not exist");
   if (mxGetFieldNumber(mxGetField(TF_CONF, 0, "fundefs"), definputStr) != -1)
   {
      plhs[0] = mxDuplicateArray(mxGetField(mxGetField(TF_CONF, 0, "fundefs"), 0, definputStr));
   }
   else
   {
      plhs[0] = mxCreateCellMatrix(0, 0);
   }

   mxFree(definputStr);
   return 0;
error:
   if (NULL != definputStr) mxFree(definputStr);
   return -1;
}


int setCommand(int UNUSED(nlhs), mxArray *UNUSED(plhs[]), int nrhs, const mxArray *prhs[])
{
   char* definputStr = NULL;
   check(nrhs == 3, "Number of arguments must be 3 for the set command")
   const mxArray* definput = prhs[1];
   const mxArray* arglist = prhs[2];
   definputStr =  mxArrayToString(definput);
   check(TF_CONF, "TF_CONF is null");
   check(mxIsChar(definput), "definput must be a string")
   check(mxIsCell(arglist), "arglist must be a cell array")
   check(mxGetFieldNumber(TF_CONF, "fundefs") != -1, "TF_CONF.fundefs does not exist");
   check_keepmessage(
      ltfatSetStructField(mxGetField(TF_CONF, 0, "fundefs"), "", definputStr, mxDuplicateArray(arglist)) == 0);
   mexMakeArrayPersistent(TF_CONF);

   mxFree(definputStr);
   return 0;
error:
   if (NULL != definputStr) mxFree(definputStr);
   return -1;
}

int allCommand(int UNUSED(nlhs), mxArray *plhs[], int nrhs, const mxArray *UNUSED(prhs[]))
{
   check(nrhs == 1, "Number of arguments must be 1 for the all command")
   check(TF_CONF, "TF_CONF is null");
   check(mxGetFieldNumber(TF_CONF, "fundefs") != -1, "TF_CONF.fundefs does not exist")
   plhs[0] = mxDuplicateArray(mxGetField(TF_CONF, 0, "fundefs"));
   return 0;
error:
   return -1;
}


int clearallCommand(int UNUSED(nlhs), mxArray *UNUSED(plhs[]),
                    int nrhs, const mxArray *UNUSED(prhs[]))
{
   check(nrhs == 1, "Number of arguments must be 1 for the clearall command")
   check(TF_CONF, "TF_CONF is null");
   check(mxGetFieldNumber(TF_CONF, "fundefs") != -1, "TF_CONF.fundefs does not exist")
   mxDestroyArray(mxGetField(TF_CONF, 0, "fundefs"));
   mxSetField(TF_CONF, 0, "fundefs" , mxCreateStructMatrix(1, 1, 0, NULL));
   mexMakeArrayPersistent(TF_CONF);
   return 0;
error:
   return -1;
}

void clearall()
{
   if (NULL != TF_CONF) mxDestroyArray(TF_CONF);
}

void ltfatClean(char** array)
{
   if (NULL != *array)  mxFree(*array);
   else log_warn("Deleting empty string");
   *array = NULL;
}

char* upper(char* a)
{
   int ii = 0;
   while (a[ii])
   {
      a[ii] = toupper(a[ii]);
      ii++;
   }
   return a;
}
