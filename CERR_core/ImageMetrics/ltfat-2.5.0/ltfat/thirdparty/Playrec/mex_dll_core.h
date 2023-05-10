/*
 * Playrec
 * Copyright (c) 2006-2008 Robert Humphrey
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Header for mex_dll_core.c which contains 'core' functions to be used when
 * creating dll files for use with MATLAB.  This allows multiple functions to
 * be called from within MATLAB through the single entry point function by
 * specifying the name of the required command/function as the first input
 * argument.
 */

#ifndef MEX_DLL_CORE_H
#define MEX_DLL_CORE_H

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

/** Adds symbol exporting function decorator to mexFunction.
    On windows, def file is no longer needed. For MinGW, it
    suppresses the default "export-all-symbols" behavior. **/
#if defined(_WIN32) || defined(__WIN32__)
#  define DLL_EXPORT_SYM __declspec(dllexport)
#else
#  define EXPORT_SYM __attribute__((visibility("default")))
#endif

#include "mex.h"

/* Macro defintions to avoid crashes under Mac OS X */
#ifndef max
#define max(a,b) ((a)>(b)? (a):(b))
#endif

#ifndef min
#define min(a,b) ((a)<(b)? (a):(b))
#endif

/* Macro defintions to avoid problems when not compiling with Matlab's mex.h */
#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif

/* Include this in _funcLookup[] to include the help command */
#define HELP_FUNC_LOOKUP {"help",                                           \
        showHelp,                                                           \
        1, 1, 0, 0,                                                         \
        "Provides usage information for each command",                      \
        "Displays command specific usage instructions.",                    \
        {                                                                   \
            {"commandName", "name of the command for which information is required"}    \
        },                                                                  \
        {                                                                   \
            {NULL}                                                          \
        },                                                                  \
    }

/* The maximum number of arguments that can be listed for lhs and rhs in funcLookupStruct_t */
#define MAX_ARG_COUNT 10

/* Width of the screen in characters when displaying help */
#define SCREEN_CHAR_WIDTH 80

/* Position of tab stops - must be 0 or power of 2 (eg 0, 1, 2, 4, 8, 16 etc); */
#define SCREEN_TAB_STOP 4

/* Including this #define makes command names case insensitive */
/* #define CASE_INSENSITIVE_COMMAND_NAME */

/* Structure to contain information about a single input or output argument. */
typedef struct {
    char *name;         /* the argument name                                            */
    char *desc;         /* description of the argument - can be multilined
                         * and will be line wrapped if longer than one line
                         */
    bool isOptional;    /* true if the argument is optional                             */
} ParamDescStruct;

/* Sturcture containing information associated for each command that can
 * be called from within MATLAB.
 */
typedef struct {
    char *name;             /* Textual string used to identify command in MATLAB        */
    bool (*func)(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
                            /* Pointer to the actual function to call.
                             * The arguments are those received by the entry point
                             * function, apart from the function name is NOT supplied
                             * and so prhs starts with the second argument and
                             * nrhs is one less. ie the arguments are as if the
                             * function was called directly from within MATLAB
                             */

    int  minInputArgs;      /* The minimum and maximum values of nlhs and nrhs that     */
    int  maxInputArgs;      /* *func should be called with. Use -1 to not check the     */
    int  minOutputArgs;     /* particular value.  This can be used to reduce the        */
    int  maxOutputArgs;     /* amount of input/output count checks in the function.     */

    char *desc;             /* Short (1 line) command description - not line wrapped    */
    char *help;             /* Complete help for the command.  Can be any length and
                             * can contain new line characters.  Will be line wrapped
                             * to fit the width of the screen as defined as
                             * SCREEN_CHAR_WIDTH with tab stops every
                             * SCREEN_TAB_STOP characters.
                             */

        /* descriptions of all input arguments in the order they are required */
    ParamDescStruct inputArgs[MAX_ARG_COUNT];
        /* descriptions of all output arguments in the order they are returned */
    ParamDescStruct outputArgs[MAX_ARG_COUNT];
} FuncLookupStruct;

/* Function prototypes */
bool showHelp(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
unsigned int linewrapString( const char *pdisplayStr, unsigned int maxLineLength,
                             unsigned int blockIndent, int firstLineIndent,
                             unsigned int tabSize );

/* Function which must have its definition supplied elsewhere.
 * Returning false makes the call to mexFunction return immediately.
 * Returning true means the first argument is analysed and the
 * appropriate function called.
 */
extern bool mexFunctionCalled(int nlhs, mxArray *plhs[],
                              int nrhs, const mxArray *prhs[]);

/* These two variables must be defined elsewhere, containing a list of all the
 * commands which the MEX-file should recognise.  See above and mex_dll_core.c
 * for more information on the fields that must be included within _funcLookup.
 * The order of the commands in _funcLookup is the order they will be displayed
 * when the available command list is generated (produced when no arguments are
 * supplied when calling the MEX-file from MATLAB).
 */
extern const FuncLookupStruct _funcLookup[];
extern const int _funcLookupSize;

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* MEX_DLL_CORE_H */
