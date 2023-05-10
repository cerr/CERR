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
 * 'Core' functions to be used when creating dll files for use with MATLAB.
 * The main function, mexFunction, allows multiple functions to be called from
 * within MATLAB through the single entry point function by specifying the name
 * of the required function/'command' as the first argument.  The available
 * functions must be included in an array _funcLookup[] defined in an alternate
 * file with the number of available functions defined as _funcLookupSize.
 *
 * One such command might be a 'help' function such as that supplied below,
 * which must be specified in _funcLookup[] if required.  To just have this
 * command, _funcLookup[] and _funcLookupSize can be specified as:

const FuncLookupStruct _funcLookup[] = {
    {"help",
        showHelp,
        0, 0, 1, 1,
        "Provides usage information for each command",
        "Displays command specific usage instructions.",
        {
            {"commandName", "name of the command for which information is required"}
        },
        {
            {NULL}
        },
    }
}

const int _funcLookupSize = sizeof(_funcLookup)/sizeof(funcLookupStruct);

 * (note that HELP_FUNC_LOOKUP is defined in mex_dll_core.h to ease the inclusion
 * of the help command)
 *
 * For a description of all the fields to be included, see the definition of
 * FuncLookupStruct in mex_dll_core.h
 *
 * Every time the entry-point function is called the function

bool mexFunctionCalled(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])

 * is called with the same arguments as supplied to the entry-point function. This
 * function must have a definition supplied, which returns true to continue
 * distributing the function call to the appropriate function, or false for the
 * entry-point function to return immediately.
 *
 * If a command 'name' in _funcLookup[] matches the first argument supplied
 * then the number of arguments supplied (nrhs) and expected (nlhs) are
 * checked against those required.  If these are valid the function is called,
 * or otherwise an error is generated including help on the command concerned.
 * Additionally, if the function returns false it indicates the arguments were
 * invalid and an error is generated.  NOTE: The first argument to the entry-
 * point function (the name of the command) is NOT supplied to the
 * function called.  That is, the function is called with arguments as though
 * it had been called directly from MATLAB.  The min and max tests on nrhs
 * occur AFTER the removal of this argument.
 *
 * The function linewrapString can be used whenever text needs to be displayed
 * in the MATLAB command window.  As its name suggests, this takes a string
 * and linewraps it to fit the width of display specified when calling the
 * function.  This supports strings containing new line characters ('\n') and
 * tab characters ('\t'), as well as being able to indent the text relative to
 * the left hand side of the command window.
 */

#include "mex.h"
#include "mex_dll_core.h"
#include <string.h>

/*
 * FUNCTION:    mexFunction(int nlhs, mxArray *plhs[],
 *                                  int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 * Returns:     void
 *
 * Description: The entry point function for the MEX-file.  Called whenever
 *              the utility is used within MATLAB.  Initially calls
 *              mexFunctionCalled and, depending on the return value of this,
 *              will continue to process the first argument supplied.
 *              If no arguments are supplied, a list of all available commands
 *              (as defined in _funcLookup) is displayed.  Otherwise the
 *              supplied command name is compared to each one in _funcLookup
 *              until a match is found.  If a match is found, the number of
 *              arguments is compared to that expected (given in _funcLookup)
 *              and if they are valid, the associated function is called.
 *              If this function returns false, or no match is found for the
 *              command name, or the incorrect number of arguments are supplied
 *              then an error is generated.
 *
 *              If CASE_INSENSITIVE_COMMAND_NAME is defined, the command name
 *              matching is case insensitive, although a message is displayed
 *              if the incorrect case has been used.
 * TODO:
 *
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

#ifndef HAVE_PORTAUDIO
#ifdef IS_OCTAVE
  const char id[] = "Octave:disabled_feature";
#else
  const char id[] = "Matlab:disabled_feature";
#endif
  mexErrMsgIdAndTxt (id, "PLAYREC: Support for the block processing framework was disabled when LTFAT was built.");
#else

    int i;
    bool validFuncName = false;
    bool validArgNumber;
    unsigned int charCount, maxFuncNameLen = 0;
    char *namebuf;

    if(!mexFunctionCalled(nlhs, plhs, nrhs, prhs))
        return;

    if(nrhs < 1) {
        if(nlhs < 1) {
            mexPrintf("\nFirst argument must be one of following strings:\n");

            /* Determine the maximum length of any function name */
            for(i=0; i<_funcLookupSize; i++) {
                if((_funcLookup[i].func!=NULL) && _funcLookup[i].name)
                    maxFuncNameLen = max(maxFuncNameLen, strlen(_funcLookup[i].name));
            }

            /* Display all function names and descriptions */
            for(i=0; i<_funcLookupSize; i++) {
                if((_funcLookup[i].func!=NULL) && _funcLookup[i].name) {
                    mexPrintf("%s", _funcLookup[i].name);

                    /* Space out correctly, independant of function name length */
                    charCount = strlen(_funcLookup[i].name);
                    while(charCount++ < maxFuncNameLen)
                        mexPrintf(" ");

                    if(_funcLookup[i].desc)
                        mexPrintf(" - %s\n", _funcLookup[i].desc);
                    else
                        mexPrintf(" -\n");
                }
            }
        }
        else {
            /* Return argument expected so return info on all available functions */
            const char *fieldNames[] = {"name", "description",
                                         "minInputArgs", "maxInputArgs",
                                         "minOutputArgs", "maxOutputArgs",
                                         "help",
                                         "inputArgs", "outputArgs"};
            const char *paramFieldNames[] = {"name", "description", "isOptional"};

            int argCount, argNum;
            mxArray *pParamFields;

            plhs[0] = mxCreateStructMatrix(1, _funcLookupSize,
                    sizeof(fieldNames)/sizeof(char*), fieldNames);

            for(i=0; i<_funcLookupSize; i++) {
                mxSetField(plhs[0],i,"name", mxCreateString(_funcLookup[i].name));
                mxSetField(plhs[0],i,"description", mxCreateString(_funcLookup[i].desc));
                mxSetField(plhs[0],i,"minInputArgs",
                    mxCreateDoubleScalar(_funcLookup[i].minInputArgs));
                mxSetField(plhs[0],i,"maxInputArgs",
                    mxCreateDoubleScalar(_funcLookup[i].maxInputArgs));
                mxSetField(plhs[0],i,"minOutputArgs",
                    mxCreateDoubleScalar(_funcLookup[i].minOutputArgs));
                mxSetField(plhs[0],i,"maxOutputArgs",
                    mxCreateDoubleScalar(_funcLookup[i].maxOutputArgs));
                mxSetField(plhs[0],i,"help", mxCreateString(_funcLookup[i].help));

                argCount = 0;

                for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                    if((_funcLookup[i].inputArgs[argNum].name)
                        && (_funcLookup[i].inputArgs[argNum].desc)) {

                        argCount++;
                    }
                }

                pParamFields = mxCreateStructMatrix(1, argCount,
                        sizeof(paramFieldNames)/sizeof(char*), paramFieldNames);

                mxSetField(plhs[0],i,"inputArgs", pParamFields);

                argCount = 0;
                for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                    if((_funcLookup[i].inputArgs[argNum].name)
                        && (_funcLookup[i].inputArgs[argNum].desc)) {

                        mxSetField(pParamFields,argCount,"name",
                            mxCreateString(_funcLookup[i].inputArgs[argNum].name));
                        mxSetField(pParamFields,argCount,"description",
                            mxCreateString(_funcLookup[i].inputArgs[argNum].desc));
                        mxSetField(pParamFields,argCount,"isOptional",
                            mxCreateDoubleScalar(_funcLookup[i].inputArgs[argNum].isOptional ? 1 : 0));
                        argCount++;
                    }
                }

                argCount = 0;

                for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                    if((_funcLookup[i].outputArgs[argNum].name)
                        && (_funcLookup[i].outputArgs[argNum].desc)) {

                        argCount++;
                    }
                }

                pParamFields = mxCreateStructMatrix(1, argCount,
                        sizeof(paramFieldNames)/sizeof(char*), paramFieldNames);

                mxSetField(plhs[0],i,"outputArgs", pParamFields);

                argCount = 0;
                for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                    if((_funcLookup[i].outputArgs[argNum].name)
                        && (_funcLookup[i].outputArgs[argNum].desc)) {

                        mxSetField(pParamFields,argCount,"name",
                            mxCreateString(_funcLookup[i].outputArgs[argNum].name));
                        mxSetField(pParamFields,argCount,"description",
                            mxCreateString(_funcLookup[i].outputArgs[argNum].desc));
                        mxSetField(pParamFields,argCount,"isOptional",
                            mxCreateDoubleScalar(_funcLookup[i].outputArgs[argNum].isOptional ? 1 : 0));
                        argCount++;
                    }
                }
            }
        }
        return;
    }

    if(!mxIsChar(prhs[0])) {
        mexErrMsgTxt("First argument must be a string.\nSupply no arguments to list all valid command names.");
    }

    /* Provided we can get the string out of the first argument, try and find a match! */
    if((namebuf=mxArrayToString(prhs[0]))!=NULL) {
        for(i=0; i<_funcLookupSize; i++) {
#ifdef CASE_INSENSITIVE_COMMAND_NAME
            if((_funcLookup[i].name) && (_strcmpi(_funcLookup[i].name, namebuf)==0) && (_funcLookup[i].func!=NULL)) {
                if(strcmp(_funcLookup[i].name, namebuf)!=0) {
                    mexPrintf("Using '%s' instead of '%s'\n", _funcLookup[i].name, namebuf);
                }
#else
            if((_funcLookup[i].name) && (strcmp(_funcLookup[i].name, namebuf)==0) && (_funcLookup[i].func!=NULL)) {
#endif
                validFuncName = true;
                validArgNumber = true;

                /* Call function 'removing' the first element of prhs, */
                if((_funcLookup[i].minInputArgs >= 0) && (_funcLookup[i].minInputArgs > (nrhs-1))) {
                    mexPrintf("Not enough input arguments specified\n");
                    validArgNumber = false;
                }
                if((_funcLookup[i].maxInputArgs >= 0) && (_funcLookup[i].maxInputArgs < (nrhs-1))) {
                    mexPrintf("Too many input arguments specified\n");
                    validArgNumber = false;
                }
                if((_funcLookup[i].minOutputArgs >= 0) && (_funcLookup[i].minOutputArgs > nlhs)) {
                    mexPrintf("Not enough output arguments specified\n");
                    validArgNumber = false;
                }
                if((_funcLookup[i].maxOutputArgs >= 0) && (_funcLookup[i].maxOutputArgs < nlhs)) {
                    mexPrintf("Too many output arguments specified\n");
                    validArgNumber = false;
                }
                /* This will only call the function if there are valid numbers of arguments */
                if(!validArgNumber || !(*_funcLookup[i].func)(nlhs, plhs, nrhs - 1, &prhs[1])) {
                    /* Input arguments were not valid - display command help */
                    mexPrintf("\n%s - %s\n\n", _funcLookup[i].name, _funcLookup[i].desc);
                    mexPrintf("Use the arguments \"'help', '%s'\" to see usage instructions\n\n", _funcLookup[i].name);
                    mexErrMsgTxt("Invalid argument combination for command");
                }
                break;
            }
        }

        if(!validFuncName) {
            mexErrMsgTxt("First argument is not a valid command call name.\nSupply no arguments to list all valid command names.");
        }

        mxFree(namebuf);

    }
    else {
        mexErrMsgTxt("Error obtaining string from first argument");
    }
#endif
}

#ifdef HAVE_PORTAUDIO

/*
 * FUNCTION:    showHelp(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of prhs is used, and should contain the name
 *              of the command on which help is required
 *
 * Returns:     false if more than one input argument is supplied in prhs or if the
 *              first argument is not a string.  Otherwise returns true.
 *
 * Description: Displays help information on the specified command using the
 *              text stored in _funcLookup.  Provided the first element of
 *              prhs is a valid string, searches through _funcLookup until
 *              a match is found.  Then displays the help information on the
 *              command including a list of arguments and their descriptions.
 *
 *              If CASE_INSENSITIVE_COMMAND_NAME is defined, the command name
 *              matching is case insensitive.
 *
 * TODO:
 *
 */
bool showHelp(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int i, argNum;
    bool validFuncName, firstParam;
    char *namebuf;

    validFuncName = false;

    if((nrhs==1) && mxIsChar(prhs[0])) {
        if((namebuf=mxArrayToString(prhs[0]))!=NULL) {
            for(i=0; i<_funcLookupSize; i++) {

#ifdef CASE_INSENSITIVE_COMMAND_NAME
                if((_funcLookup[i].name) && (_strcmpi(_funcLookup[i].name, namebuf)==0)
                    && (_funcLookup[i].func!=NULL)) {

                    if(strcmp(_funcLookup[i].name, namebuf)!=0) {
                        mexPrintf("Found case insensitive match to supplied argument '%s'\n", namebuf);
                    }
#else
                if((_funcLookup[i].name) && (strcmp(_funcLookup[i].name, namebuf)==0)
                    && (_funcLookup[i].func!=NULL)) {
#endif
                    validFuncName = true;

                    /* Display the command usage on one line, nomatter how long it is */
                    mexPrintf("[");
                    firstParam = true;
                    /* Display left hand arguments */
                    for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                        if((_funcLookup[i].outputArgs[argNum].name)
                            && (_funcLookup[i].outputArgs[argNum].desc)) {

                            if(!firstParam) {
                                mexPrintf(", ");
                            }
                            firstParam = false;
                            if(_funcLookup[i].outputArgs[argNum].isOptional)
                                mexPrintf("{%s}", _funcLookup[i].outputArgs[argNum].name);
                            else
                                mexPrintf("%s", _funcLookup[i].outputArgs[argNum].name);
                        }
                    }

                    mexPrintf("] = %s(", _funcLookup[i].name);

                    /* Display right hand arguments */
                    firstParam = true;
                    for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                        if((_funcLookup[i].inputArgs[argNum].name)
                            && (_funcLookup[i].inputArgs[argNum].desc)) {

                            if(!firstParam) {
                                mexPrintf(", ");
                            }
                            firstParam = false;
                            if(_funcLookup[i].inputArgs[argNum].isOptional)
                                mexPrintf("{%s}", _funcLookup[i].inputArgs[argNum].name);
                            else
                                mexPrintf("%s", _funcLookup[i].inputArgs[argNum].name);
                        }
                    }

                    mexPrintf(")\n\n");

                    /* Display the body of the help for the command */
                    linewrapString(_funcLookup[i].help, SCREEN_CHAR_WIDTH, 0, 0, SCREEN_TAB_STOP);
                    mexPrintf("\n");

                    /* Display information on input arguments if they exist */
                    firstParam = true;
                    for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                        if((_funcLookup[i].inputArgs[argNum].name)
                            && (_funcLookup[i].inputArgs[argNum].desc)) {

                            if(firstParam) {
                                firstParam = false;
                                mexPrintf("Input Arguments:\n");
                            }
                            mexPrintf("    %s %s\n", _funcLookup[i].inputArgs[argNum].name,
                                _funcLookup[i].inputArgs[argNum].isOptional ? "{optional}" : "");

                            linewrapString(_funcLookup[i].inputArgs[argNum].desc,
                                    SCREEN_CHAR_WIDTH, 8, 0, SCREEN_TAB_STOP);
                        }
                    }

                    /* Add an extra line if there's at least one paramter */
                    if(!firstParam)
                        mexPrintf("\n");

                    /* Display information on output arguments if they exist */
                    firstParam = true;
                    for(argNum = 0; argNum < MAX_ARG_COUNT; argNum++) {
                        if((_funcLookup[i].outputArgs[argNum].name)
                            && (_funcLookup[i].outputArgs[argNum].desc)) {

                            if(firstParam) {
                                firstParam = false;
                                mexPrintf("Output Arguments:\n");
                            }
                            mexPrintf("    %s %s\n", _funcLookup[i].outputArgs[argNum].name,
                                _funcLookup[i].outputArgs[argNum].isOptional ? "{optional}" : "");

                            linewrapString(_funcLookup[i].outputArgs[argNum].desc,
                                    SCREEN_CHAR_WIDTH, 8, 0, SCREEN_TAB_STOP);
                        }
                    }

                    /* Add an extra line if there's at least one paramter */
                    if(!firstParam)
                        mexPrintf("\n");

                }
            }
            mxFree(namebuf);
        }

        if(!validFuncName) {
            mexErrMsgTxt("No help available for specified command.\n"
                         "Supply no arguments to list all valid command names.");
        }
    }
    else {
        mexPrintf("Help command requires a single string argument");
        return false;
    }

    return true;
}

/*
 * FUNCTION:    linewrapString( const char *pdisplayStr,
 *                              unsigned int maxLineLength,
 *                              unsigned int blockIndent,
 *                              int firstLineIndent,
 *                              unsigned int tabSize )
 *
 * Inputs:      *pdisplayStr    pointer to the string to be displayed
 *              maxLineLength   the maximum line length (including any indent that may be required)
 *              blockindent     indentation to be applied to all lines
 *              firstlineindent indent to be applied to first line in addition to blockindent
 *                              note that this is the first line of the text,
 *                              and not the first line of every paragraph.
 *              tabSize         size of tab stops (must be 0 or power of 2 eg 0, 1, 2, 4, 8, ...)
 *                              if not, will default to 4.
 *
 * Returns:     number of lines required to display the text
 *
 * Description: Word wraps a line to fit the dimensions specified by breaking
 *              at spaces where required.  If a word is too long for one line
 *              it is split at the end of the line.  Tabs can be included and
 *              will align to the next integer multiple of tabSize along the
 *              line.  When a line is wrapped, any white space between the last
 *              character of one line and the first character of the next line
 *              is removed.  However, any white space following a forced line
 *              break is not removed, although will only take up at most one
 *              line.
 *
 * TODO:        Do not add extra line if last line in string just contains spaces
 */

unsigned int linewrapString( const char *pdisplayStr, unsigned int maxLineLength, unsigned int blockIndent,
                             int firstLineIndent, unsigned int tabSize ) {
    unsigned int lineStartChar = 0; /* index of character used at the start of the line             */
    unsigned int lineEndChar;       /* index of last character on the line (includes white space)   */
    int lastPrintChar;              /* index of the last printable character on the line            */
    int lastPrintCharTmp;           /* temporary index of the last printable character on the line  */
    bool stringEnd = false;         /* true -> the end of the string has been reached               */
    unsigned int thisLineIndent;    /* the limit of the length of this line                         */
    unsigned int lineNumber = 0;    /* Line number being displayed                                  */
    unsigned int lineCharPos;       /* Position on the line (0 is first character)                  */
    bool tooLongWord;               /* used to determine if a word is longer than a single line     */
    unsigned int tabSpaceTmp;       /* temporary counter used to add the correct number             */
                                    /* of spaces to effectively insert a tab                        */

    unsigned int i;                 /* general counting index                                       */

    unsigned int tabStopBitMask = tabSize - 1;  /* Mask used when calculating the position
                                                 * of the next tab stop
                                                 */

    if(tabSize == 0) {
        tabStopBitMask = 0;
    }
    else if(tabStopBitMask & tabSize) {
        /* tabSize is not power of 2 */
        tabSize = 4;
        tabStopBitMask = tabSize - 1;
    }

    /* Don't even attempt to display if the formatting values supplied are silly */
    if(!pdisplayStr
        || !pdisplayStr[0]
        || (maxLineLength < 1)
        // || (blockIndent + firstLineIndent < 0) // this is False all the time
        || (maxLineLength < blockIndent)
        || (maxLineLength < blockIndent + firstLineIndent)) {

            stringEnd = true;
    }

    /* step through each line, one at a time */
    while( !stringEnd ) {
        lineNumber++;

        /* Calculate available length of this line */
        thisLineIndent = blockIndent;
        if(lineNumber==1)
            thisLineIndent += firstLineIndent;

        /* Set 'defaults' for the line */
        lineEndChar = lineStartChar;
        lastPrintChar = lineStartChar - 1;
        lastPrintCharTmp = lineStartChar - 1;
        lineCharPos = thisLineIndent;

        tooLongWord = true;

        /* go though to the end of the line, keeping track of the last printing character
         * or find a new line character if that occurs before the end of the line
         */

        for( i = lineStartChar; ( lineCharPos < maxLineLength ) && pdisplayStr[ i ]; i++ ) {
            if( pdisplayStr[ i ] == ' ' ) {
                lineEndChar = i;
                lastPrintChar = lastPrintCharTmp;
                lineCharPos++;
                tooLongWord = false;
            }
            else if( pdisplayStr[ i ] == '\t' ) {
                lineEndChar = i;
                lastPrintChar = lastPrintCharTmp;
                tabSpaceTmp = tabSize - (lineCharPos & tabStopBitMask);
                lineCharPos += tabSpaceTmp;
                tooLongWord = false;
            }
            else if( pdisplayStr[ i ] == '\n' ) {
                /* Do not include new line character at end of current line */
                lineEndChar = i;
                lastPrintChar = lastPrintCharTmp;
                tooLongWord = false;
                break;
            }
            else {
                lineCharPos++;
                lastPrintCharTmp = i;
            }
        }

        if(!pdisplayStr[ i ]) {
            /* end of the string has been reached */
            lineEndChar = i;
            lastPrintChar = i - 1;
            tooLongWord = false;
            stringEnd = true;
        }

        /* Generate initial padding */
        lineCharPos = thisLineIndent;

        for( i = 0; i < thisLineIndent; i++)
            mexPrintf( " " );

        /* display the line of text going up to either the last printing character
         * or the end of the line if the word is longer than a single line
         */
        for( i = lineStartChar; (((int)i <= lastPrintChar) || tooLongWord) && ( lineCharPos < maxLineLength ); i++ ) {
            if( pdisplayStr[ i ] == '\t' ) {
                tabSpaceTmp = tabSize - (lineCharPos & tabStopBitMask);
                lineCharPos += tabSpaceTmp;
                while(tabSpaceTmp--)
                    mexPrintf( " " );
            }
            else {
                mexPrintf( "%c", pdisplayStr[ i ] );
                lineCharPos++;
            }

            /* Keep track of end of line if tooLongWord */
            if(tooLongWord) {
                lastPrintChar = i;
                lineEndChar = i;
            }
        }

        mexPrintf("\n");

        /* Now find the last non printing character of the line */
        if(pdisplayStr[ lineEndChar ] && pdisplayStr[ lineEndChar ] != '\n') {
            /* Get to the end of the white space at the end of the line */
            while((pdisplayStr[ lineEndChar + 1 ] == ' ')
                || (pdisplayStr[ lineEndChar + 1 ] == '\t')) {

                    lineEndChar++;
            }

            if(pdisplayStr[ lineEndChar + 1 ] == '\n') {
                /* If at the end of all this white space there's a new line
                 * include it in the current line
                 */
                lineEndChar++;
            }

            if(!pdisplayStr[ lineEndChar + 1 ]) {
                /* end of the string has been reached */
                lineEndChar++;
                stringEnd = true;
            }
        }

        /* make the first character of the next line the next character in the string */
        lineStartChar = lineEndChar + 1;
    }

    return lineNumber;
}
#endif
