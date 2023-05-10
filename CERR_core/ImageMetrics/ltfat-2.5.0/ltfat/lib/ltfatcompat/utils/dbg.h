/*
 *   This file is from http://c.learncodethehardway.org/book/ex20.html
 *   
 *   Zed's Awesome debug macros and therir modified version for MEX files
 *   The MEX version does not have goto error and errno as the memory mnagement in
 *   mex files is automatic.
 *
 *
 */

#ifndef __dbg_h__
#define __dbg_h__
#include <stdio.h>
#include <string.h>

/* Choose the macro set depending on whether mex.h was already included*/
#if defined(mex_h) || defined(MEX_H)
   /*
    * As it is not possible to use mexErrMsgIdAndTxt and continue in MEX, we need to store
    * the error message first, clean everything and call mexErrMsgIdAndTxt after that.
    * The following macros relies on having a global variables defined:
    * static char MEXERRSTRING[500];
    * static int MEXERROCCURED = 0;
    * and 
    * error:
    *    // Tear down logic
    *    print_mexerror();
    * */
   #ifdef NDEBUG
   #define debug(M, ...)
   #else
   #define debug(M, ...) mexPrintf("DEBUG %s:%d: " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   #endif
   
   #define log_err(M, ...)  sprintf(MEXERRSTRING,"[ERROR] (%s:%d:) " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   
   #define log_warn(M, ...) mexWarnMsgIdAndTxt("LTFAT:MEX", "[WARN] (%s:%d:) " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   #define log_info(M, ...) mexPrintf("[INFO] (%s:%d) " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   
   #define check(A, M, ...) if(!(A)) { log_err(M, ##__VA_ARGS__); MEXERROCCURED = 1; goto error; }
   
   #define check_keepmessage(A) if(!(A)) { MEXERROCCURED = 1; goto error; }
   
   #define sentinel(M, ...)  { log_err(M, ##__VA_ARGS__); MEXERROCCURED = 1; goto error; }
   
   #define check_mem(A) check((A), "Out of memory.")
   
   #define check_debug(A, M, ...) if(!(A)) { debug(M, ##__VA_ARGS__); MEXERROCCURED = 1; goto error; }

   #define print_mexerror if(MEXERROCCURED) { mexErrMsgIdAndTxt("LTFAT:MEX", "%s", MEXERRSTRING); }
#else
   #include <errno.h>
   #ifdef NDEBUG

   #define debug(M, ...)
   #else
   #define debug(M, ...) fprintf(stderr, "DEBUG %s:%d: " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   #endif
   
   #define clean_errno() (errno == 0 ? "None" : strerror(errno))
   
   #define log_err(M, ...) fprintf(stderr, "[ERROR] (%s:%d: errno: %s) " M "\n", __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)
   
   #define log_warn(M, ...) fprintf(stderr, "[WARN] (%s:%d: errno: %s) " M "\n", __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)
   
   #define log_info(M, ...) fprintf(stderr, "[INFO] (%s:%d) " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)
   
   #define check(A, M, ...) if(!(A)) { log_err(M, ##__VA_ARGS__); errno=0; goto error; }
   
   #define sentinel(M, ...)  { log_err(M, ##__VA_ARGS__); errno=0; goto error; }
   
   #define check_mem(A) check((A), "Out of memory.")
   
   #define check_debug(A, M, ...) if(!(A)) { debug(M, ##__VA_ARGS__); errno=0; goto error; }

#endif
#endif
