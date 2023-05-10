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
 */

/*
 * There are two different sets of functions in this file - the first are
 * 'helper' functions used to perform operations that are not directly called
 * by MATLAB, and the second are the functions referred to in _funcLookup and
 * map to commands in MATLAB. The latter begin 'do' to easily identify them.
 */

#ifdef HAVE_PORTAUDIO

#include "mex.h"
#include "portaudio.h"
#include "mex_dll_core.h"
#include "pa_dll_playrec.h"
#include "ltfatresample.h"
#include <stdio.h>
#include <string.h>

/*
 * States are used to ensure code is only run when it will not cause problems
 * Multiple states can be set at one time by using single bits for each state
 * If required more states can be used by adding an additional #define and
 * an additional element in _stateOpts[] for each state required.

 *
 * BASIC_INIT = The exit function has been registered with mexAtExit.
 *              PortAudio has been succesfully initialised
 *              The state to return to on reset.
 *              There should be no method of clearing from this state
 *              If not in this state, only execute code to achieve this state
 * FULL_INIT  = The global streamInfoStruct has been created
 *              The PortAudio stream has been created and is running
 */

#define BASIC_INIT (1<<0)
#define FULL_INIT (1<<1)

/* macros to manipulate the _currentState variable
 * OR together (|) states to complete a combined state test
 * ie ISSTATE would only return true if all OR'd states are set.
 */

/* Set all the states OR'd together in setState */
#define SETSTATE(setState) ((_currentState) |= (setState))

/* Clear all the states OR'd together in clearState */
#define CLEARSTATE(clearState) ((_currentState) &= ~(clearState))

/* return true only if all states OR'd together in isState are set. */
#define ISSTATE(isState) (((_currentState) & (isState))==(isState))

/* Variable used to store the current system state */
int _currentState = 0;

/* Structure used to store human readable information on each state, used to
 * give feedback when a state has the wrong value.
 */
const StateOptsStruct _stateOpts[] =
{
   {
      BASIC_INIT,
      "Basic initialisation",
      "This should have started automatically - something must be wrong.",
      "This state connot be stopped without clearing the utility from memory."
   },
   {
      FULL_INIT,
      "Full initialisation",
      "Call \"init\" command to run initialisation.",
      "Call \"reset\" command."
   }
};

/* The number of elements in the above structure */
const int _stateOptsSize = sizeof(_stateOpts) / sizeof(StateOptsStruct);

/* Structure used to provide a lookup between all commands accessible from
 * MATLAB and their associated functions here.  All functions have been given
 * the same name as the MATLAB command, prefixed with 'do'.  The structure also
 * contains help information for the function, descriptions of each input and
 * output value, and upper and lower limits on the number of acceptable
 * arguments.  This structure is used by mex_dll_core.c, and all fields are
 * described in mex_dll_core.h.  The order of commands in this array is the
 * order they will be shown when listed in MATLAB.
 */
const FuncLookupStruct _funcLookup[] =
{
   HELP_FUNC_LOOKUP,   /* Add the help function provided in mex_dll_core */
   {
      "about",
      doAbout,
      0, 0, 0, 1,
      "Displays information about the playrec utility",

      "Displays information about the playrec utility",
      {
         {NULL}
      },
      {
         {
            "aboutInfo", "String containing information about this build of "
            "playrec. If no output argument is specified then the information "
            "is printed in the command window."
         }
      }
   },
   {
      "overview",
      doOverview,
      0, 0, 0, 1,
      "Displays an overview on using this playrec utility",

      "Displays an overview on using this playrec utility",
      {
         {NULL}
      },
      {
         {
            "overviewInfo", "String containing information about how to use playrec. "
            "If no output argument is specified then the information is printed "
            "in the command window."
         }
      }
   },
   {
      "getDevices",
      doGetDevices,
      0, 0, 0, 1,
      "Returns a list of available audio devices",

      "Returns information on the available devices within the system, including "
      "ID, name, host API and number of channels supported.",
      {
         {NULL}
      },
      {
         {
            "deviceList", "Structure array containing the following fields for "
            "each device:\n"
            "\t'deviceID' - ID used to refer to the device,\n"
            "\t'name' - textual name of the device,\n"
            "\t'hostAPI' - the host API used to access the device,\n"
            "\t'defaultLowInputLatency' - device default input latency used "
            "for interactive performance.  This is the value suggested to "
            "the soundcard when the device is used for input.\n"
            "\t'defaultLowOutputLatency' - device default output latency used "
            "for interactive performance.  This is the value suggested to "
            "the soundcard when the device is used for output.\n"
            "\t'defaultHighInputLatency' - device default input latency for "
            "robust non-interactive applications (eg. playing sound files),\n"
            "\t'defaultHighOutputLatency' - device default output latency for "
            "robust non-interactive applications (eg. playing sound files),\n"
            "\t'defaultSampleRate' - device default sample rate,\n"
            "\t'inputChans' - maximum number of input channels supported by the device\n"
            "\t'outputChans' - maximum number of output channels supported by the device"
         }
      }
   },
   {
      "init",
      doInit,
      3, 8, 0, 0,
      "Initialises the utility",

      "Configures the utility for audio input and/or output based on the specified "
      "configuration.  If successful the chosen device(s) will be running in "
      "the background waiting for the first pages to be received.  If unsuccessful "
      "an error will be generated containing an error number and description.\n\n"
      "All channel numbers are assumed to start at 1.  The maximum number of "
      "channels support by the device will be used if the maximum channel number "
      "is not specified.  Specifying a maximum number of channels verifies that the "
      "device will support them and slightly reduces the utility's processor usage."
      "\n\nIf an optional value is specified, all previous optional values must also "
      "be specified.",
      {
         {"sampleRate", "the sample rate at which both devices will operate"},
         {
            "playDevice", "the ID of the device to be used for sample output (as "
            "returned by 'getDevices'), or -1 for no device (ie output not required)"
         },
         {
            "recDevice", "the ID of the device to be used for sample input (as "
            "returned by 'getDevices'), or -1 for no device (ie input not required)"
         },
         {
            "playMaxChannel", "a number greater than or equal to the maximum channel "
            "that will be used for output.  This must be less than or equal to the "
            "maximum number of output channels that the device supports.  The value "
            "is ignored if playDevice is -1.",
            true
         },
         {
            "recMaxChannel", "a number greater than or equal to the maximum channel "
            "that will be used for input.  This must be less than or equal to the "
            "maximum number of input channels that the device supports.  The value "
            "is ignored if recDevice is -1.",
            true
         },
         {
            "framesPerBuffer", "the number of samples to be processed in each callback "
            "within the utility (ie the length of each block of samples transferred "
            "between the utility and the soundcard).  The lower the value specified "
            "the shorter the latency but also the greater the likelihood of glitches "
            "within the audio.  This has no influence on the size of pages that can "
            "be used.  The default is 0 which lets the utility use an optimal, and "
            "potentially different, value in each callback.  A value other than the "
            "default may introduce a second layer of buffering, increasing latency, "
            "and so should only be used in exceptional circumstances.",
            true
         },
         {
            "playSuggestedLatency", "the play latency, in seconds, the device should try "
            "to use where possible.  Defaults to the default low output latency for the "
            "device.",
            true
         },
         {
            "recSuggestedLatency", "the record latency, in seconds, the device should try "
            "to use where possible.  Defaults to the default low input latency for the "
            "device.",
            true
         }
      },
      {
         {NULL}
      }
   },
   {
      "reset",
      doReset,
      0, 0, 0, 0,
      "Resets the system to allow re-initialisation",

      "Resets the system to its state prior to initialisation through the 'init' "
      "command.  This includes deleting all pages and stopping the connection "
      "to the previously selected audio device(s).  Generates an error if the "
      "utility is not already initialised - use 'isInitialised' to determine "
      "if the utility is initialised.\n\n"
      "Use with care as there is no way to recover previously recorded data "
      "once this has been called.",
      {
         {NULL}
      },
      {
         {NULL}
      }
   },
   {
      "isInitialised",
      doIsInitialised,
      0, 0, 0, 1,
      "Indicates if the system is initialised",

      "Indicates if the system is currently initialised, and hence if 'reset' or 'init' "
      "can be called without generating an error.",
      {
         {NULL}
      },
      {
         {"currentState", "1 if the utility is currently initialised, otherwise 0."}
      }
   },

   {
      "playrec",
      doPlayrec,
      4, 4, 0, 1,
      "Adds a new page with simultaneous input and output",

      "Adds a new page containing both sample input (recording) and output (playing).  "
      "Generates an error if the required memory cannot be allocated or if any "
      "other problems are encountered.\n\n"
      "The length of the page is equal to whichever is longer: the number of "
      "samples to play or the number of samples to record.",
      {
         {
            "playBuffer", "a MxN matrix containing the samples to be output.  M is "
            "the number of samples and N is the number of channels of data."
         },
         {
            "playChanList", "a 1xN vector containing the channels on which the "
            "playBuffer samples should be output.  N is the number of channels "
            "of data, and should be the same as playBuffer (a warning is generated "
            "if they are different, but the utility will still try and create the "
            "page).  Can only contain each channel number once, but the channel "
            "order is not important and does not need to include all the channels "
            "the device supports. All output channels no specified will automatically "
            "output zeros.  The maximum channel number cannot be greater than that "
            "specified during initialisation."
         },
         {
            "recDuration", "the number of samples that should be recorded in this "
            "page, or -1 to record the same number of samples as in playBuffer."
         },
         {
            "recChanList", "a row vector containing the channel numbers of all channels "
            "to be recorded.  Can only contain each channel number once, but the "
            "channel order is not important and does not need to include all the "
            "channels the device supports.  This order of channels is used when "
            "recorded samples are returned by 'getRec'.  The maximum channel number "
            "cannot be greater than that specified during initialisation."
         }
      },
      {
         {
            "pageNumber", "a unique integer number identifying the page that has been "
            "added - use this with all other functions that query specific pages, "
            "such as 'isFinished'."
         }
      }
   },
   {
      "play",
      doPlay,
      2, 2, 0, 1,
      "Adds a new output only page",

      "Adds a new page containing only sample output (playing).  Generates an error if "
      "the required memory cannot be allocated or if any other problems are "
      "encountered.\n\nThe page is the same length as that of playBuffer.",
      {
         {
            "playBuffer", "a MxN matrix containing the samples to be output.  M is "
            "the number of samples and N is the number of channels of data."
         },
         {
            "playChanList", "a 1xN vector containing the channels on which the "
            "playBuffer samples should be output.  N is the number of channels "
            "of data, and should be the same as playBuffer (a warning is generated "
            "if they are different, but the utility will still try and create the "
            "page).  Can only contain each channel number once, but the channel "
            "order is not important and does not need to include all the channels "
            "the device supports. All output channels no specified will automatically "
            "output zeros.  The maximum channel number cannot be greater than that "
            "specified during initialisation."
         },
      },
      {
         {
            "pageNumber", "a unique integer number identifying the page that has been "
            "added - use this with all other functions that query specific pages, "
            "such as 'isFinished'."
         }
      }
   },
   {
      "rec",
      doRec,
      2, 2, 0, 1,
      "Adds a new input only page",

      "Adds a new page containing only sample input (recording).  Generates an error if "
      "the required memory cannot be allocated or if any other problems are "
      "encountered.\n\nThe page is recDuration samples long.",
      {
         {
            "recDuration", "the number of samples that should be recorded on each channel "
            "specified in recChanList."
         },
         {
            "recChanList", "a row vector containing the channel numbers of all channels "
            "to be recorded.  Can only contain each channel number once, but the "
            "channel order is not important and does not need to include all the "
            "channels the device supports.  This order of channels is used when "
            "recorded samples are returned by 'getRec'.  The maximum channel number "
            "cannot be greater than that specified during initialisation."
         }
      },
      {
         {
            "pageNumber", "a unique integer number identifying the page that has been "
            "added - use this with all other functions that query specific pages, "
            "such as 'isFinished'."
         }
      }
   },
   {
      "pause",
      doPause,
      0, 1, 0, 1,
      "Sets or queries the current pause state",

      "Queries or updates the current pause state of the utility.  If no argument is "
      "supplied then just returns the current pause status, otherwise returns the "
      "status after applying the change to newPause.",
      {
         {
            "newPause", "the new state of the utility: 1 to pause or 0 to resume the "
            "stream.  This can be either a scalar or logical value.  If newState is "
            "the same as the current state of the utility, no change occurs.",
            true
         }
      },
      {
         {
            "currentState", "the state of the utility (including the update to newPause "
            "if newPause is specified): 1 if the utility is paused or otherwise 0."
         }
      }
   },
   {
      "block",
      doBlock,
      0, 1, 0, 1,
      "Waits for the specified page to finish before returning",

      "Waits for the specified page to finish or, if no pageNumber is supplied, waits "
      "until all pages have finish.  Note that the command returns immediately if "
      "the utility is paused to avoid the system locking up.\n\n"
      "This uses very little processing power whilst waiting for the page to finish, "
      "although as a result will not necessarily return as soon as the page "
      "specified finishes.  For a faster response to pages finishing use the "
      "'isFinished' command in a tight while loop within MATLAB, such as\n\n"
      "\twhile(playrec('isFinished', pageNumber) == 0);end;\n\n"
      "This will run the processor at full power and will be very wasteful, "
      "but it does reduce the delay between a page finishing and the MATLAB "
      "code continuing, which is essential when trying to achieve very low latency.",
      {
         {"pageNumber", "the number of the page to wait until finished", true}
      },
      {
         {
            "completionState", "1 if either pageNumber is a valid page and has finished "
            "being processed or pageNumber was not specified and all pages have "
            "finished being processed.  Note that page validity refers to when the "
            "function was called and so now the page has finished it may no longer "
            "be a valid page due to automatic page condensing.\n\n"
            "-1 if the specified page is invalid or no longer exists.  This includes "
            "pages that have automatically been condensed, and hence have finished.\n\n"
            "0 if the stream is currently paused and neither return values of 1 or -1 apply."
         }
      }
   },
   {
      "isFinished",
      doIsFinished,
      0, 1, 0, 1,
      "Indicates if the specified page has finished",

      "Indicates if the specified page is finished or, if no pageNumber is supplied, "
      "indicates if all pages have finished.",
      {
         {"pageNumber", "the number of the page being tested", true}
      },
      {
         {
            "completionState", "1 if either pageNumber is a valid page that has finished "
            "being processed or pageNumber was not specified and all pages have "
            "finished being processed.\n\n"
            "-1 if the specified page is invalid or no longer exists.  This includes "
            "pages that have automatically been condensed, and hence have finished.\n\n"
            "0 if either pageNumber is a valid page that has not finished being processed "
            "or pageNumber was not specified and not all pages have finished being processed."
         }
      }
   },
   {
      "getRec",
      doGetRec,
      1, 1, 0, 2,
      "Returns the samples recorded in a page",

      "Returns all the recorded data available for the page identified by pageNumber.  "
      "If the page specified does not exist, was not specified to record any data, "
      "or has not yet started to record any data then empty array(s) are returned.  "
      "If the page is currently being processed, only the recorded data currently "
      "available is returned.",
      {
         {"pageNumber", "used to identifying the page containing the required recorded data"}
      },
      {
         {
            "recBuffer", "a MxN matrix where M is the number of samples that have been "
            "recorded and N is the number of channels of data"
         },
         {
            "recChanList", "a 1xN vector containing the channel numbers associated with "
            "each channel in recBuffer.  These channels are in the same order as that "
            "specified when the page was added."
         }
      }
   },
   {
      "getPlayrec",
      doGetPlayrec,
      1, 2, 0, 3,
      "Returns the samples played and recorded in a page",

      "Returns all the recorded data available for the page identified by pageNumber.  "
      "If the page specified does not exist, was not specified to record any data, "
      "or has not yet started to record any data then empty array(s) are returned.  "
      "If the page is currently being processed, only the recorded data currently "
      "available is returned.",
      {
         {"pageNumber", "used to identifying the page containing the required recorded data"}
      },
      {
         {
            "playrecBuffer", "a Mx(N+K) matrix where M is the number of samples that have been "
            "recorded, N is the number of channels of recorded data, K is the number of channels "
            "of played data."
         },
         {
            "recChanList", "a 1xN vector containing the channel numbers associated with "
            "each channel in recBuffer.  These channels are in the same order as that "
            "specified when the page was added."
         }
      }
   },
   {
      "delPage",
      doDelPage,
      0, 1, 0, 1,
      "Deletes the specified page or all pages",

      "Deletes either the specified page or, if no pageNumber is supplied, deletes all "
      "pages.  Pages can be in any state when they are deleted - the do not have "
      "to be finished and they can even be deleted part way through being processed "
      "without any problems (in this case the utility will automatically continue "
      "with the next page in the page list).",
      {
         {"pageNumber", "the number of the page to be deleted.", true}
      },
      {
         {
            "completionState", "0 if nothing is deleted (either there are no pages in "
            "the page list or, if pageNumber was specified, no page with the "
            "specified number exists), otherwise 1 is returned."
         }
      }
   },
   {
      "getCurrentPosition",
      doGetCurrentPosition,
      0, 0, 0, 2,
      "Returns the currently active page and sample number",

      "Returns the sample and page number for the last sample transferred to the "
      "soundcard.  Due to sample buffering this will always be slightly further "
      "through a page than the actual sample being output by the soundcard at that "
      "point in time.  For pages that record input, the sample number shows how "
      "many samples have been recorded by the page, up to the recording length limit "
      "of the page.",
      {
         {NULL}
      },
      {
         {
            "currentPage", "the current page number, or -1 if either the utility is not "
            "initialised or no page is currently being processed (there are no pages "
            "in the list or all pages are finished)."
         },
         {
            "currentSample", "the current sample number within currentPage, or -1 if "
            "currentPage is also -1.  This is only accurate to maxFramesPerBuffer samples, "
            "as returned by 'getFramesPerBuffer'."
         }
      }
   },
   {
      "getLastFinishedPage",
      doGetLastFinishedPage,
      0, 0, 0, 1,
      "Returns the page number of the last completed page",

      "Returns the page number of the last finished page still resident in memory.  Due "
      "to automatic condensing/removal of pages that are no longer required, such "
      "as finished pages with only output data, this may not be the most recent page "
      "to have finished.  Put another way, this returns the page number of the last "
      "finished page in the pageList returned by 'getPageList'.",
      {
         {NULL}
      },
      {
         {"lastPage", "pageNumber of the most recently finished page still resident in memory."}
      }
   },
   {
      "getPageList",
      doGetPageList,
      0, 0, 0, 1,
      "Returns an ordered list of all page numbers",

      "Returns a list of all the pages that are resident in memory.  The list is ordered "
      "chronologically from the earliest to latest addition.\n\n"
      "Due to automatic condensing/removal of pages that are no longer required, such "
      "as finished pages with only output data, this will not be a complete list of "
      "all pages that have ever been used with the utility.",
      {
         {NULL}
      },
      {
         {
            "pageList", "a 1xN vector containing the chronological list of pages, where N "
            "is the number of pages resident in memory."
         }
      }
   },
   {
      "getFramesPerBuffer",
      doGetFramesPerBuffer,
      0, 0, 0, 3,
      "Returns internal number of frames per buffer",

      "Returns the number of frames (samples) that are processed by the callback "
      "internally within the utility (ie the length of each block of samples "
      "sent by the utility to the soundcard).  This is either the value specified "
      "when using 'init', or the default value if the optional argument was not "
      "specified. A value of 0 means the utility is using an optimal, but potentially "
      "varying, value.",
      {
         {NULL}
      },
      {
         {
            "suggestedFramesPerBuffer", "the number of frames returned by the utility internally "
            "during each callback as specified during initialisation, or -1 if the "
            "utility is not initialised."
         },
         {
            "minFramesPerBuffer", "the minimum number of frames actually processed by the "
            "utility internally during a callback, or -1 if the utility is not initialised."
         },
         {
            "maxFramesPerBuffer", "the maximum number of frames actually proccessed by the "
            "utility internally during a callback, or -1 if the utility is not initialised."
         }
      }
   },
   {
      "getSampleRate",
      doGetSampleRate,
      0, 0, 0, 2,
      "Returns the current sample rate",

      "Returns the sample rate that was specified when using 'init'.",
      {
         {NULL}
      },
      {
         {
            "suggestedSampleRate", "the sample rate used during initialisation or -1 if the utility "
            "is not initialised."
         },
         {
            "sampleRate", "the current sample rate (obtained from the hardware if possible) "
            "or -1 if the utility is not initialised."
         }
      }
   },
   {
      "getStreamStartTime",
      doGetStreamStartTime,
      0, 0, 0, 1,
      "Returns the time at which the stream was started",

      "Returns the unix time when the stream was started (number of seconds since the "
      "standard epoch of 01/01/1970).\n\n"
      "This is included so that when using the utility to run experiments it is "
      "possible to determine which tests are conducted as part of the same stream, "
      "and so identify if restarting the stream (and hence the soundcard in some "
      "scenarios) may have caused variations in results.",
      {
         {NULL}
      },
      {
         {
            "streamStartTime", "time at which the stream was started (in seconds since "
            "the Epoch), or -1 if the utility is not initialised."
         }
      }
   },
   {
      "getPlayDevice",
      doGetPlayDevice,
      0, 0, 0, 1,
      "Returns the current output (play) device",

      "Returns the deviceID (as returned by 'getDevices') for the currently selected "
      "output device.",
      {
         {NULL}
      },
      {
         {
            "playDevice", "the deviceID for the output (play) device or -1 if no device "
            "was specified during initialisation or the utility is not initialised."
         }
      }
   },
   {
      "getPlayMaxChannel",
      doGetPlayMaxChannel,
      0, 0, 0, 1,
      "Returns the current maximum output (play) channel",

      "Returns the number of the maximum output (play) channel that can currently be "
      "used.  This might be less than the number of channels that the device can "
      "support if a lower limit was specified during initialisation.",
      {
         {NULL}
      },
      {
         {
            "playMaxChannel", "the maximum output (play) channel number that can "
            "currently be used, or -1 if either no play device was specified during "
            "initialisation or the utility is not initialised."
         }
      }
   },
   {
      "getPlayLatency",
      doGetPlayLatency,
      0, 0, 0, 2,
      "Returns the current output (play) device latency",

      "Returns the output latency for the currently selected output device as well as "
      "the suggested output latency used during initialisation",
      {
         {NULL}
      },
      {
         {
            "playSuggestedLatency", "the suggested latency for the output (play) device "
            "used during initialisation, or -1 if no device was specified during "
            "initialisation or the utility is not initialised."
         },
         {
            "playLatency", "the actual latency for the output (play) device or -1 if no device "
            "was specified during initialisation or the utility is not initialised."
         }
      }
   },
   {
      "getRecDevice",
      doGetRecDevice,
      0, 0, 0, 1,
      "Returns the current input (record) device",

      "Returns the deviceID (as returned by 'getDevices') for the currently selected "
      "input device.",
      {
         {NULL}
      },
      {
         {
            "recDevice", "the deviceID for the input (record) device or -1 if no device "
            "was specified during initialisation or the utility is not initialised."
         }
      }
   },
   {
      "getRecMaxChannel",
      doGetRecMaxChannel,
      0, 0, 0, 1,
      "Returns the current maximum input (record) channel",

      "Returns the number of the maximum input (record) channel that can currently be "
      "used.  This might be less than the number of channels that the device can "
      "support if a lower limit was specified during initialisation.",
      {
         {NULL}
      },
      {
         {
            "recMaxChannel", "the maximum input (record) channel number that can "
            "currently be used, or -1 if either no record device was specified during "
            "initialisation or the utility is not initialised."
         }
      }
   },
   {
      "getRecLatency",
      doGetRecLatency,
      0, 0, 0, 2,
      "Returns the current input (record) device latency",

      "Returns the input latency for the currently selected input device as well as "
      "the suggested input latency used during initialisation",
      {
         {NULL}
      },
      {
         {
            "recSuggestedLatency", "the suggested latency for the input (record) device "
            "used during initialisation, or -1 if no device was specified during "
            "initialisation or the utility is not initialised."
         },
         {
            "recLatency", "the actual latency for the input (record) device or -1 if no device "
            "was specified during initialisation or the utility is not initialised."
         }
      }
   },
   {
      "resetSkippedSampleCount",
      doResetSkippedSampleCount,
      0, 0, 0, 0,
      "Resets the skipped samples counter",

      "Resets the counter containing the number of samples that have been 'missed' due to "
      "no new pages existing in the page list.  See the help on 'getSkippedSampleCount' "
      "for more information.",
      {
         {NULL}
      },
      {
         {NULL}
      }
   },
   {
      "getSkippedSampleCount",
      doGetSkippedSampleCount,
      0, 0, 0, 1,
      "Returns the number of skipped samples",

      "Returns the counter containing the number of samples that have been 'missed' due "
      "to no new pages existing in the page list when the soundcard requires samples "
      "to be transferred.  The term 'missed' is specifically referring to the case "
      "where multiple consecutive pages are used to record a continuous audio stream "
      "(and so input samples are missed), but is the same also for output samples "
      "because the input and output samples within a page are always processed "
      "simultaneously.\n\n"
      "This value is incremented by one for every frame (ie one sample on every "
      "input/output channel) of data communicated between the utility and soundcard "
      "that occurred whilst there were no new pages in the page list.  Using this it "
      "is possible to determine, from within MATLAB, if any glitches in the audio have "
      "occurred through not adding a new page to the page list before all other pages "
      "have finished, such as in the case where the code within MATLAB is trying to "
      "play/record a continuous stream.\n\n"
      "The counter can be reset using 'resetSkippedSampleCount' so to check for any "
      "breaks in a continuous stream of pages: add the first page of the stream; reset "
      "the counter; continue to add pages as required; if getSkippedSampleCount ever "
      "returns a value greater than zero then there has been a break in the stream.",
      {
         {NULL}
      },
      {
         {
            "skippedSampleCount", "the number of frames (samples per channel) transferred "
            "with the soundcard that have occurred when there are no unfinished pages in "
            "the pageList, or -1 if the utility is not initialised"
         }
      }
   }
};

/* The number of elements in the above structure array */
const int _funcLookupSize = sizeof(_funcLookup) / sizeof(FuncLookupStruct);

/* Pointer to the only StreamInfoStruct */
StreamInfoStruct *_pstreamInfo;

/* The last PortAudio error */
PaError lastPaError;

/* Resampling plans */

static int playResChanCount = 0;
static resample_plan* play_resplan = NULL;

static int recResChanCount = 0;
static resample_plan* rec_resplan = NULL;
static resample_plan dummy_recplan = NULL;

void clearResPlans()
{
   int ii;

   if (dummy_recplan)
      resample_done(&dummy_recplan);

   if (rec_resplan)
   {
      if (recResChanCount > 0)
      {
         for (ii = 0; ii < recResChanCount; ii++)
            resample_done(&rec_resplan[ii]);
         recResChanCount = 0;
      }
      free(rec_resplan);
      rec_resplan = NULL;
   }
   if (play_resplan)
   {
      if (playResChanCount > 0)
      {
         for (ii = 0; ii < playResChanCount; ii++)
            resample_done(&play_resplan[ii]);

         playResChanCount = 0;
      }
      free(play_resplan);
      play_resplan = NULL;
   }
}



/*
 * FUNCTION:    convDouble(double *oldBuf, int buflen)
 *
 * Inputs:      *oldBuf pointer to an array of type double
 *              buflen  length of oldBuf
 *
 * Returns:     pointer to an array of type SAMPLE containing a copy of the
 *              data in oldBuf, or NULL if memory for the new array could not
 *              be allocated.
 *
 * Description: Makes a complete copy of oldBuf, converting all values to type
 *              SAMPLE from type double.  The returned array must be freed
 *              using mxFree once it is no longer required.
 *
 * TODO:        change to use memcpy if SAMPLE is of type double
 */
SAMPLE *convDouble(double *oldBuf, int buflen)
{
   SAMPLE *newBuf = mxCalloc(buflen, sizeof(SAMPLE));
   SAMPLE *pnew = newBuf;
   double *pold = oldBuf;

   if (newBuf)
      while (pnew < &newBuf[buflen])
         *pnew++ = (SAMPLE) * pold++;

   return newBuf;
}

/*
 * FUNCTION:    convFloat(float *oldBuf, int buflen)
 *
 * Inputs:      *oldBuf pointer to an array of type float
 *              buflen  length of oldBuf
 *
 * Returns:     pointer to an array of type SAMPLE containing a copy of the
 *              data in oldBuf, or NULL if memory for the new array could not
 *              be allocated.
 *
 * Description: Makes a complete copy of oldBuf, converting all values to type
 *              SAMPLE from type float.  The returned array must be freed
 *              using mxFree once it is no longer required.
 *
 * TODO:        change to use memcpy if SAMPLE is of type float
 */
SAMPLE *convFloat(float *oldBuf, int buflen)
{
   SAMPLE *newBuf = mxCalloc(buflen, sizeof(SAMPLE));
   SAMPLE *pnew = newBuf;
   float *pold = oldBuf;

   if (newBuf)
      while (pnew < &newBuf[buflen])
         *pnew++ = (SAMPLE) * pold++;

   return newBuf;
}

/*
 * FUNCTION:    validateState(int wantedStates, int rejectStates)
 *
 * Inputs:      wantedStates    all states that must be set, OR'd (|) together
 *              rejectStates    all states that must NOT be set, OR'd (|) together
 *
 * Returns:     void
 *
 * Description: Tests _currentState to ensure that all wantedStates are set and
 *              all rejectStates are not set.  If any wanted state is unset or
 *              any unwanted state is set, an error is generated including
 *              instructions on how to obtain the required state (based on the
 *              strings in _stateOpts).
 *
 * TODO:
 */
void validateState(int wantedStates, int rejectStates)
{
   int i;
   char *buffer;

   for (i = 0; i < _stateOptsSize; i++)
   {
      if (((wantedStates & _stateOpts[i].num) != 0) && !ISSTATE(_stateOpts[i].num))
      {
         /* This is a wanted state which doesn't exist in _currentState */
         buffer = mxCalloc( strlen( _stateOpts[i].name) +
                            + strlen( _stateOpts[i].startString ) + 60, sizeof( char ));

         if ( buffer )
         {
            sprintf( buffer, "This command can only be called if in state \"%s\".\n%s",
                     _stateOpts[i].name, _stateOpts[i].startString);

            mexErrMsgTxt( buffer );
            /* No need to free memory here as execution will always stop at the error */
         }
         else
         {
            mexErrMsgTxt( "Error allocating memory in validateState" );
         }
      }
      if (((rejectStates & _stateOpts[i].num) != 0) && ISSTATE(_stateOpts[i].num))
      {
         /* This is a reject state which does exist in _currentState */
         buffer = mxCalloc( strlen( _stateOpts[i].name) +
                            + strlen( _stateOpts[i].stopString ) + 60, sizeof( char ));

         if ( buffer )
         {
            sprintf( buffer, "This command cannot be called in state \"%s\".\n%s",
                     _stateOpts[i].name, _stateOpts[i].stopString);

            mexErrMsgTxt( buffer );
            /* No need to free memory here as execution will always stop at the error */
         }
         else
         {
            mexErrMsgTxt( "Error allocating memory in validateState" );
         }
      }
   }
}

/*
 * FUNCTION:    freeChanBufStructs(ChanBufStruct **ppcbs)
 *
 * Inputs:      **ppcbs pointer to pointer to first ChanBufStruct to be freed
 *
 * Returns:     void
 *
 * Description: Progresses along the ChanBufStruct linked list starting at
 *              the supplied location, freeing each ChanBufStruct and its
 *              contained pbuffer (if it exists).  The pointer pointing
 *              to the start of the linked list (*ppcbs) is set to NULL prior
 *              to any memory being freed.
 *
 * TODO:
 */
void freeChanBufStructs(ChanBufStruct **ppcbs)
{
   ChanBufStruct *pcurrentStruct, *pnextStruct;

   if (ppcbs)
   {
      pcurrentStruct = *ppcbs;

      *ppcbs = NULL;  /* Clear pointer to first structure before freeing it! */

      while (pcurrentStruct)
      {
         if (pcurrentStruct->pbuffer)
            mxFree(pcurrentStruct->pbuffer);

         pnextStruct = pcurrentStruct->pnextChanBuf;
         mxFree(pcurrentStruct);
         pcurrentStruct = pnextStruct;
      }
   }
}

/*
 * FUNCTION:    freeStreamPageStruct(StreamPageStruct **ppsps)
 *
 * Inputs:      **ppsps pointer to pointer to StreamPageStruct to be freed
 *
 * Returns:     void
 *
 * Description: Removes the StreamPageStruct, pointed to by the supplied
 *              pointer, from the linked list.  The order of the linked list
 *              is changed by altering the destination of the supplied pointer
 *              to skip the StreamPageStruct being freed.  To ensure no
 *              problems are encountered with the callback accessing the freed
 *              structure, after the change to the link list order is made the
 *              function waits for the callback not to be active before freeing
 *              the memory.  Although by the time the structure is freed the
 *              callback may be active again, it must have been through a 'not
 *              active' state after the change to the linked list, and
 *              therefore can not have any pointers left referring to the
 *              structure being freed.
 *
 * TODO:        Add a timeout on the loop waiting to not be in the callback, or
 *              change how this operates so there is a way to determine if the
 *              callback has ended and restarted (which is sufficient to avoid
 *              any memory sharing problems).
 *
 *              Determine the timing advantages of using a loop without 'pause'
 *              when waiting for a time not in the callback.  This will be more
 *              processor intensive, but may well enable pages to be deleted
 *              faster because the point at which the callback ends will be
 *              detected sooner.
 */

void freeStreamPageStruct(StreamPageStruct **ppsps)
{
   StreamPageStruct *pcurrentStruct;
   if (ppsps && *ppsps)
   {
      /* Bypass the structure to be freed so it is not in the linked list */
      pcurrentStruct = *ppsps;
      *ppsps = pcurrentStruct->pnextStreamPage;

      /* Having completed the pointer switch, ensure not in callback before continuing */
      while (_pstreamInfo->inCallback)
         Pa_Sleep(1);

      /* Although the callback may have resumed again by now,
       * there is no way it can have a pointer to this struct
       * because since the pointer switch there has been an
       * occasion when the callback was not active.
       */
      freeChanBufStructs(&pcurrentStruct->pfirstPlayChan);
      freeChanBufStructs(&pcurrentStruct->pfirstRecChan);

      if (pcurrentStruct->pplayChansInUse)
         mxFree(pcurrentStruct->pplayChansInUse);

      mxFree(pcurrentStruct);
   }
}

/*
 * FUNCTION:    freeStreamInfoStruct(StreamInfoStruct **psis)
 *
 * Inputs:      **ppsis pointer to pointer to StreamInfoStruct to be freed
 *
 * Returns:     void
 *
 * Description: Frees the StreamInfoStruct pointed to indirectly by the
 *              supplied pointer.  If the stream is active, it is stopped
 *              by setting stopStream within the structure and then polling
 *              the stream until it has stopped, which occurs after the next
 *              time the callback is executed.  This method is used instead
 :*              of calling Pa_StopStream because this was found to not always
 *              work correctly (the callback would sometimes be called after
 *              Pa_StreamActive reports the stream to not be active, and so
 *              would try to use the structure after it had been freed).
 *              After stopping the stream, it is closed and then all pages
 *              are freed before finally the StreamInfoStruct is freed and
 *              the pointer to this structure (*ppsis) is set to NULL.
 *
 * TODO:
 */
void freeStreamInfoStruct(StreamInfoStruct **ppsis)
{
   unsigned int stopTime = 0;  /* elapsed time waited in msec */

   if (ppsis && *ppsis)
   {
      /* Stop and close the stream as necessary */
      if ((*ppsis)->pstream)
      {
         /* Try to stop stream nicely so we are certain it has stopped
          * before freeing memory.  However, if this takes longer than 10s
          * change to do so using Pa_StopStream.  This may generate problems
          * with the PortAudio callback trying to access memory that has been
          * freed, but this is the best option to avoid the function hanging
          * forever.
          */
         if (Pa_IsStreamActive((*ppsis)->pstream) == 1)
         {
#ifdef DEBUG
            mexPrintf("...Stopping PortAudio Stream...");
#endif
            while ((Pa_IsStreamActive((*ppsis)->pstream) == 1)
                   && (stopTime < 10000))
            {

               (*ppsis)->stopStream = true;
               Pa_Sleep(2);
               stopTime += 2;
            }

            if (stopTime >= 10000)
            {
#ifdef DEBUG
               mexPrintf("Not stopped after %dms - forcing stop!\n", stopTime);
#endif
               checkPAErr(Pa_StopStream((*ppsis)->pstream));
               Pa_Sleep(2000); /* Wait for this to ideally have an effect */
            }
            else
            {
#ifdef DEBUG
               mexPrintf("Stopped after %dms\n", stopTime);
#endif
            }
         }
#ifdef DEBUG
         mexPrintf("...Closing PortAudio Stream.\n");
#endif
         checkPAErr(Pa_CloseStream((*ppsis)->pstream));
         (*ppsis)->pstream = NULL;

         abortIfPAErr("freeStreamInfoStruct failed to close stream");
      }

      /* Remove each page structure one at a time. freeStreamPageStruct
       * automatically makes (*ppsis)->pfirstStreamPage point at the
       * next page so this doesn't need to do so
       */
      while ((*ppsis)->pfirstStreamPage)
         freeStreamPageStruct(&(*ppsis)->pfirstStreamPage);

      /* Free the structure and clear the pointer */
      mxFree(*ppsis);
      *ppsis = NULL;

      CLEARSTATE(FULL_INIT);
   }
}

/*
 * FUNCTION:    newStreamInfoStruct(bool makeMemoryPersistent)
 *
 * Inputs:      makeMemoryPersistent    true to make all allocated memory persistent
 *
 * Returns:     StreamInfoStruct *  pointer to the new structure, or NULL
 *                                      if the memory could not be allocated
 *
 * Description: Creates a new StreamInfoStruct and sets all contained values
 *              to their default values.
 *
 * TODO:
 */
StreamInfoStruct *newStreamInfoStruct(bool makeMemoryPersistent)
{
   StreamInfoStruct *psis = mxCalloc(1, sizeof(StreamInfoStruct));

   if (!psis)
   {
      mexWarnMsgTxt("Unable to allocate memory for streamInfoStruct.");
      return NULL;
   }

   if (makeMemoryPersistent)
      mexMakeMemoryPersistent(psis);

   psis->pfirstStreamPage = NULL;

   psis->pstream = NULL;

   psis->streamStartTime = -1;

   psis->suggestedFramesPerBuffer = paFramesPerBufferUnspecified;
   psis->minFramesPerBuffer = paFramesPerBufferUnspecified;
   psis->maxFramesPerBuffer = paFramesPerBufferUnspecified;

   psis->recSuggestedLatency = 0;
   psis->playSuggestedLatency = 0;

   psis->suggestedSampleRate = 44100;
   psis->streamFlags = paNoFlag;

   psis->isPaused = false;

   psis->stopStream = false;

   psis->inCallback = false;

   psis->skippedSampleCount = 0;
   psis->resetSkippedSampleCount = false;

   psis->playChanCount = 0;
   psis->playDeviceID = paNoDevice;

   psis->recChanCount = 0;
   psis->recDeviceID = paNoDevice;

   return psis;
}

/*
 * FUNCTION:    newStreamPageStruct(unsigned int portAudioPlayChanCount,
 *                      bool makeMemoryPersistent)
 *
 * Inputs:      portAudioPlayChanCount  The number of play channels that the
 *                                      PortAudio stream will be configured
 *                                      to use (should be same as the
 *                                      playChanCount in the StreamInfoStruct
 *                                      to which the page will be added)
 *              makeMemoryPersistent    true to make all allocated memory persistent
 *
 * Returns:     StreamPageStruct *  pointer to the new structure, or NULL
 *                                      if the memory could not be allocated
 *
 * Description: Creates a new StreamPageStruct and sets all contained values
 *              to their default values, including allocating memory for
 *              the pplayChansInUse array (and setting all entires to false)
 *              and giving the page a unique page number.
 *
 * TODO:
 */
StreamPageStruct *newStreamPageStruct(unsigned int portAudioPlayChanCount, bool makeMemoryPersistent)
{
   static unsigned int nextPageNum = 0;    /* Unique page number genearator */
   unsigned int i;

   StreamPageStruct *pnewPage = mxCalloc(1, sizeof(StreamPageStruct));

   if (!pnewPage)
   {
      mexWarnMsgTxt("Unable to allocate memory for streamPageStruct.");
      return NULL;
   }

   if (makeMemoryPersistent)
      mexMakeMemoryPersistent(pnewPage);

   pnewPage->pageFinished = false;
   pnewPage->pageUsed = false;

   pnewPage->pagePos = 0;
   pnewPage->pageLength = 0;
   pnewPage->pageLengthRec = 0;
   pnewPage->pageNum = nextPageNum++;

   pnewPage->playChanCount = portAudioPlayChanCount;
   pnewPage->pplayChansInUse = mxCalloc(pnewPage->playChanCount, sizeof(bool));

   if (!pnewPage->pplayChansInUse && (pnewPage->playChanCount > 0))
   {
      mexWarnMsgTxt("Unable to allocate memory for chansInUse buffer.");
      mxFree(pnewPage);
      return NULL;
   }

   if (makeMemoryPersistent)
      mexMakeMemoryPersistent(pnewPage->pplayChansInUse);

   for (i = 0; i < pnewPage->playChanCount; i++)
      pnewPage->pplayChansInUse[i] = false;

   pnewPage->pfirstPlayChan = NULL;
   pnewPage->pfirstRecChan = NULL;
   pnewPage->pnextStreamPage = NULL;

   return pnewPage;
}

/*
 * FUNCTION:    addStreamPageStruct(StreamInfoStruct *psis,
 *                      StreamPageStruct *psps)
 *
 * Inputs:      *psis   StreamInfoStruct to which the page should be added
 *              *psps   StreamPageStruct to be added to the linked list
 *
 * Returns:     StreamPageStruct *  pointer to the stream page if
 *                                      successful, or NULL if unsuccesful
 *
 * Description: adds the supplied StreamPageStruct to the end of the page
 *              link list in StreamInfoStruct.  Verifies that the
 *              playChanCount in both the page and stream are the same before
 *              the page is added.
 *
 * TODO:
 */
StreamPageStruct *addStreamPageStruct(StreamInfoStruct *psis, StreamPageStruct *psps)
{
   StreamPageStruct **ppcurrentPage;

   if (!psis || !psps)
   {
      return NULL;
   }

   if (psis->playChanCount != psps->playChanCount)
   {
      mexWarnMsgTxt("playChanCounts in stream page is not equal to that of the stream");
      return NULL;
   }

   /* Both pointers not NULL */
   ppcurrentPage = &psis->pfirstStreamPage;

   /* Get a pointer to the stream page pointer which points to NULL
    * (ie a pointer to the pointer at the end of the linked list)
    */
   while (*ppcurrentPage)
      ppcurrentPage = &(*ppcurrentPage)->pnextStreamPage;

   /* Add the stream page */
   *ppcurrentPage = psps;

   return psps;
}

/*
 * FUNCTION:    playrecCallback(const void *inputBuffer,
 *                              void *outputBuffer,
 *                              unsigned long frameCount,
 *                              const PaStreamCallbackTimeInfo *timeInfo,
 *                              PaStreamCallbackFlags statusFlags,
 *                              void *userData )
 *
 * Inputs:      inputBuffer     array of interleaved input samples
 *              outputBuffer    array of interleaved output samples
 *              frameCount      number of sample frames to be processed
 *              timeInfo        struct with time in seconds
 *              statusFlags     flags indicating whether input and/or output
 *                              buffers have been inserted or will be dropped
 *                              to overcome underflow or overflow conditions
 *              userData        pointer to the StreamInfoStruct for this
 *                              stream, as passed to Pa_OpenStream()
 *
 * Returns:     paComplete or paAbort to stop the stream if either userData is NULL
 *              or stopStream has been set, or paContinue (0) for the stream to
 *              continue running
 *
 * Description: Implementation of PortAudioCallback called by PortAudio to
 *              process recorded data and supply more output samples.  See
 *              portaudio.h for more information on the supplied parameters.
 *
 *              Iterates through the page linked list to find the first
 *              unfinished page. If no unfinished pages exist, all input
 *              samples are ignored and all output samples are set to zero.
 *              Otherwise, the output samples are set according to the data
 *              contained in the page, or set to zero if either the channel is
 *              not in use, or there are no more samples remaining for the
 *              channel.  Recorded data is stored as required by the page.
 *              The page linked list is descended until all samples within both
 *              buffers have been used as required, even if the data is spread
 *              throughout multiple consecutive pages.
 *
 *              NOTE: None of the PortAudio functions may be called from
 *              within this callback function except for Pa_GetCPULoad().
 *
 * TODO:
 */
static int playrecCallback(const void *inputBuffer, void *outputBuffer,
                           unsigned long frameCount,
                           const PaStreamCallbackTimeInfo *timeInfo,
                           PaStreamCallbackFlags statusFlags, void *userData )
{
   /* Cast to stream info structure */
   StreamInfoStruct *psis = (StreamInfoStruct*)userData;

   /* The current page within which we are working */
   StreamPageStruct *pcurrentsps = NULL;

   unsigned int samplesProcessed = 0;
   unsigned int samplesFromPage = 0;

   SAMPLE *pout = (SAMPLE *)outputBuffer;
   SAMPLE *pin = (SAMPLE *)inputBuffer;

   SAMPLE *ps;     /* A generic SAMPLE pointer used for pointer
                     * arithmetic in multiple occasions
                     */

   bool isPaused;  /* Used to get value of psis->isPaused so this is only tested
                     * once at the start of the callback, avoiding problems with
                     * it changing during the callback!
                     */

   unsigned int chan;  /* Channel number being processed */

   unsigned int tmpBufPos; /* used as a buffer location index, because
                             * there is no longer one per buffer
                             */
   ChanBufStruct *pcbs;

   /* Check valid pointer has been supplied, otherwise stop the stream */
   if (!psis)
   {
      return paAbort;
   }

   /* Signal we're in callback - this does not have to be the first
    * statement within the callback provided it is set prior to any
    * manipulation of the stream pages.
    */
   psis->inCallback = true;

   /* Find the first unfinished page */
   pcurrentsps = psis->pfirstStreamPage;
   while (pcurrentsps && pcurrentsps->pageFinished)
      pcurrentsps = pcurrentsps->pnextStreamPage;

   /* Only process samples from a page if not paused.
    * Copy pause to avoid problems with it changing during the callback!
    */
   isPaused = psis->isPaused;

   if (!isPaused)
   {

      /* Loop through as many pages as required to process frameCount samples
       * break is used to exit the loop once enough samples have been processed
       */
      while (pcurrentsps)
      {

         /* None of the pages looked at by this code should have pageFinished
          * set, although check it just to be on the safe side!
          */
         if (!pcurrentsps->pageFinished)
         {

            pcurrentsps->pageUsed = true;

            /* Determine how many samples to use from this page */
            samplesFromPage = min(frameCount - samplesProcessed, pcurrentsps->pageLength - pcurrentsps->pagePos);

            /* Blank all channels that are not in use by this page (that are valid channels!)
             * This might turn out to be quicker just blanking all of the buffer
             */
            if (pout && pcurrentsps->pplayChansInUse)
            {
               for (chan = 0; (chan < pcurrentsps->playChanCount) && (chan < psis->playChanCount); chan++)
               {
                  if (!pcurrentsps->pplayChansInUse[chan])
                  {

                     /* psis->playChanCount must be greater than 0 to have
                      * reached this point, so no need to worry about this
                      * for loop never ending
                      */
                     for (ps = (pout + samplesProcessed * psis->playChanCount + chan);
                           ps < (pout + (samplesProcessed + samplesFromPage) * psis->playChanCount);
                           ps += psis->playChanCount)
                     {

                        *ps = 0;
                     }
                  }
               }
            }

            /* Step through all channels that may contain data */
            if (pout && (psis->playChanCount > 0))
            {
               for (pcbs = pcurrentsps->pfirstPlayChan; pcbs; pcbs = pcbs->pnextChanBuf)
               {
                  tmpBufPos = pcurrentsps->pagePos;

                  if (pcbs->pbuffer
                        && (tmpBufPos < pcbs->bufLen)
                        // && (pcbs->channel >= 0) //always true
                        && (pcbs->channel < psis->playChanCount))
                  {

                     /* This chanBuf contains a valid buffer and has data left to use!
                      * Step through the frame copying data.
                      */

                     /* psis->playChanCount must be greater than 0 to have
                      * reached this point, so no need to worry about this
                      * for loop never ending
                      */

                     for (ps = (pout + samplesProcessed * psis->playChanCount + pcbs->channel);
                           ps < (pout + (samplesProcessed + samplesFromPage) * psis->playChanCount);
                           ps += psis->playChanCount)
                     {

                        if (tmpBufPos < pcbs->bufLen)
                        {
                           *ps = *(pcbs->pbuffer + tmpBufPos);
                           tmpBufPos++;
                        }
                        else
                        {
                           *ps = 0;
                        }
                     }
                  }
                  else
                  {
                     /* There is nothing in this channels buffer to be used,
                      * so zero the output channel
                      */

                     /* psis->playChanCount must be greater than 0 to have
                      * reached this point, so no need to worry about this
                      * for loop never ending
                      */
                     for (ps = (pout + samplesProcessed * psis->playChanCount + pcbs->channel);
                           ps < (pout + (samplesProcessed + samplesFromPage) * psis->playChanCount);
                           ps += psis->playChanCount)
                     {

                        *ps = 0;
                     }
                  }
               }
            }

            /* Record all channels as required */
            if (pin)
            {
               for (pcbs = pcurrentsps->pfirstRecChan; pcbs; pcbs = pcbs->pnextChanBuf)
               {
                  tmpBufPos = pcurrentsps->pagePos;

                  if (pcbs->pbuffer
                        && (tmpBufPos < pcbs->bufLen)
                        // && (pcbs->channel >= 0)// always true
                        && (pcbs->channel < psis->recChanCount))
                  {

                     /* This chanBuf contains a valid buffer and has space left to use!
                      * Channels without a valid buffer, or that have reached the end of
                      * their buffer, should not need anything doing to them
                      */

                     /* Step through each frame copying data */

                     for (ps = (pin + samplesProcessed * psis->recChanCount + pcbs->channel);
                           (ps < (pin + (samplesProcessed + samplesFromPage) * psis->recChanCount)) && (tmpBufPos < pcbs->bufLen);
                           ps += psis->recChanCount)
                     {

                        *(pcbs->pbuffer + tmpBufPos) = *ps;
                        tmpBufPos++;
                     }
                  }
               }
            }

            /* Either the end of the page, or the end of the frame should have been reached
             * Both might also have occurred simultaneously!
             */
            samplesProcessed += samplesFromPage;
            pcurrentsps->pagePos += samplesFromPage;

            if (pcurrentsps->pagePos >= pcurrentsps->pageLength)
            {
               /* Page is finished */
               pcurrentsps->pageFinished = true;
            }

            if (samplesProcessed >= frameCount)
            {
               /* buffer is finished */
               break;
            }

         } /* if(!pcurrentsps->pageFinished) */

         /* buffer not finished - go to the next page */
         pcurrentsps = pcurrentsps->pnextStreamPage;

      } /* while(pcurrentsps) */

   } /* if(!isPaused) */


   /* Either the buffer is finished, or we've run out of pages, or we're paused */
   if (pout && (samplesProcessed < frameCount))
   {
      /* Run out of pages, or paused (doesn't matter which) */

      /* Zero all remaining output samples */
      for (chan = 0; chan < psis->playChanCount; chan++)
      {
         /* psis->playChanCount must be greater than 0 to have
          * reached this point, so no need to worry about this
          * for loop never ending
          */

         for (ps = (pout + samplesProcessed * psis->playChanCount + chan);
               ps < (pout + frameCount * psis->playChanCount);
               ps += psis->playChanCount)
         {

            *ps = 0;
         }
      }
   }

   if (psis->resetSkippedSampleCount)
   {
      /* Clear the value of skippedSampleCount BEFORE
       * clearing resetSkippedSampleCount to ensure there is no
       * chance of reading an incorrect value.
       */
      psis->skippedSampleCount = 0;
      psis->resetSkippedSampleCount = false;
   }

   if (!isPaused && (samplesProcessed < frameCount))
   {
      /* Not paused, so increment skippedSampleCount */
      psis->skippedSampleCount += frameCount - samplesProcessed;
   }

   if (!isPaused && (statusFlags & (paOutputUnderflow | paOutputOverflow
                                    | paInputUnderflow | paInputOverflow)))
   {
      /* Not paused, and we've not processed/provided data fast
       * enough, or the input and output buffers became out of sync.
       * Either way, increment skippedSampleCount so Matlab can tell
       * that something's gone wrong.
       */
      psis->skippedSampleCount++;
   }

   if ((psis->minFramesPerBuffer == paFramesPerBufferUnspecified)
         || (frameCount < psis->minFramesPerBuffer))
   {

      psis->minFramesPerBuffer = frameCount;
   }

   if ((psis->maxFramesPerBuffer == paFramesPerBufferUnspecified)
         || (frameCount > psis->maxFramesPerBuffer))
   {

      psis->maxFramesPerBuffer = frameCount;
   }

   /* Signal we're leaving the callback - this does not have to be the last
    * statement within the callback provided no manipulation of the stream
    * pages occurs after it is cleared.
    */
   psis->inCallback = false;

   return psis->stopStream ? paComplete : paContinue;
}

/*
 * FUNCTION:    mexFunctionCalled(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 * Returns:     true, or aborts with an error if initialisation of PortAudio
 *              failed.
 *
 * Description: initialises PortAudio, if not already initialised, and
 *              registers exitFunc as the mex exit function if this has not
 *              already been done.  Calls condensePages() to minimise memory
 *              usage as frequently as possible.  See mex_dll_core.c for
 *              information on when this function is called, including the
 *              possible return values.
 *
 * TODO:        Add seperate function accessible from MATLAB to disable
 *              automatic page condensing if optimum speed is more important
 *              than minimizing memory usage
 */
bool mexFunctionCalled(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   /* Reset error on each function call */
   lastPaError = paNoError;

   if (_currentState == 0)
   {
      /* initialise PortAudio and register exit function */
#ifdef DEBUG
      mexPrintf("First call to function...\n");
      mexPrintf("...initialising PortAudio.\n");
#endif
      /* In this case a little more than checkPAErr is required,
       * becase the terminate must occur before displaying the
       * error message
       */
      if (checkPAErr(Pa_Initialize()) != paNoError)
      {
         checkPAErr(Pa_Terminate());
         abortIfPAErr("Failed to initialise PortAudio...Terminating");
      }

#ifdef DEBUG
      mexPrintf("...Registering exit function.\n");
#endif
      mexAtExit(exitFunc);
      SETSTATE(BASIC_INIT);
   }

   condensePages();

   /* Always continue processing if we get this far */
   return true;
}

/*
 * FUNCTION:    condensePages(void)
 *
 * Inputs:      void
 *
 * Returns:     void
 *
 * Description: Iterates through all finished pages freeing as much memory
 *              as possible without deleting any recorded data.  For pages
 *              only containing output data the page is completely removed
 *              whereas pages also containing recorded data have their output
 *              data and pplayChansInUse freed leaving the minimum amount of
 *              memory in use.
 *
 * TODO:        Change to take a pointer to the StreamInfoStruct to be
 *              condensed, thus making the function compatible if the utility
 *              is adapted to use more than one stream simultaneously.
 */
void condensePages(void)
{
   StreamPageStruct **ppsps;

   if (_pstreamInfo)
   {
      ppsps = &_pstreamInfo->pfirstStreamPage;

      while (*ppsps)
      {
         /* Move through all stream pages, clearing the play buffers
          * if the stream is finished, to conserve space
          */
         if ((*ppsps)->pageFinished)
         {

            /* if there are no record buffers, completely remove the page */
            if (!(*ppsps)->pfirstRecChan)
            {
               freeStreamPageStruct(ppsps);
               /* Do not select the next page, as this has happened
                * automatically by supplying ppsps to
                * freeStreamPageStruct
                */
            }
            else
            {
               /* This conditional if is not required, as it is also
                * checked within freeChanBufStructs.  However, this
                * will reduce the number of function calls that just
                * return immediately!
                */
              
               // if ((*ppsps)->pfirstPlayChan)
              // freeChanBufStructs(&(*ppsps)->pfirstPlayChan);

               if ((*ppsps)->pplayChansInUse)
               {
                  mxFree((*ppsps)->pplayChansInUse);
                  (*ppsps)->pplayChansInUse = NULL;
                  (*ppsps)->playChanCount = 0;
               }
               ppsps = &(*ppsps)->pnextStreamPage;
            }
         }
         else
         {
            break;  /* Once the first unFinished page has been reached
                         * all the subsequent pages will also be unFinished.
                         */
         }
      }
   }
}

/*
 * FUNCTION:    exitFunc(void)
 *
 * Inputs:      void
 *
 * Returns:     void
 *
 * Description: Function registered using mexAtExit and called whenever the
 *              MEX-function is cleared or MATLAB is terminated.  Frees all
 *              allocated memory and terminates PortAudio if required.
 *
 * TODO:
 */
void exitFunc(void)
{
   clearResPlans();

#ifdef DEBUG
   mexPrintf("Running playrec exitFunc...\n");
#endif

   /* Let freeStreamInfoStruct handle the closing of PortAudio */
   freeStreamInfoStruct(&_pstreamInfo);

   if (ISSTATE(BASIC_INIT))
   {
#ifdef DEBUG
      mexPrintf("...Terminating PortAudio.\n");
#endif
      checkPAErr(Pa_Terminate());
   }

   CLEARSTATE(BASIC_INIT);

   abortIfPAErr("PortAudio error during exitFunc");
}

/*
 * FUNCTION:    checkPAErr(PaError err)
 *
 * Inputs:      err             the PaError returned by any PortAudio function
 *
 * Returns:     paError         the err value supplied
 *
 * Description: Verifies if err is equal to paNoError.  If not, the PortAudio
 *              error number is stored in lastPaError so it can be recalled
 *              later.
 *
 * TODO:
 */
PaError checkPAErr(PaError err)
{
   if ( err != paNoError )
   {
      lastPaError = err;
   }

   return err;
}

/*
 * FUNCTION:    abortIfPAErr(const char* msg)
 *
 * Inputs:      msg             the message to add to the start of the error
 *
 * Returns:     void
 *
 * Description: Verifies if lastPaError is equal to paNoError.  If not, then
 *              an error message is displayed and the mex function aborts.
 *
 * TODO:
 */
void abortIfPAErr(const char* msg)
{
   char *buffer;

   if ( lastPaError != paNoError )
   {
      buffer = mxCalloc( strlen( Pa_GetErrorText( lastPaError ))
                         + strlen( msg ) + 40, sizeof( char ));

      if ( buffer )
      {
         sprintf( buffer, "%s \n{PortAudio Error [%d]: %s}",
                  msg, lastPaError, Pa_GetErrorText( lastPaError ));

         mexErrMsgTxt( buffer );
         /* No need to free memory here as execution will always stop at the error */
      }
      else
      {
         mexErrMsgTxt( "Error allocating memory in abortPAErr" );
      }
   }
}

/*
 * FUNCTION:    channelListToChanBufStructs(const mxArray *pmxChanArray,
 *                      ChanBufStruct **ppfirstcbs, unsigned int minChanNum,
 *                      unsigned int maxChanNum, bool makeMemoryPersistent)
 *
 * Inputs:      pmxChanArray    pointer to mxArray containing channel list
 *                              as a row vector (chan numbers are base 1)
 *                              The order of channel numbers is preserved in
 *                              the linked list, and no channel number can be
 *                              duplicated (this is checked).
 *              ppfirstcbs      pointer to the pointer which should be set
 *                              to point at the first ChanBufStruct
 *              minChanNum      the minimum channel number to be accepted
 *                              (base 0, NOT base 1)
 *              maxChanNum      the maximum channel number to be accepted
 *                              (base 0, NOT base 1)
 *              makeMemoryPersistent    true to make all allocated memory persistent
 *
 * Returns:     true if the channel list is valid and all memory has been
 *              allocated successfully, otherwise a description of the error
 *              is printed to the MATLAB command window and false is returned.
 *
 * Description: Allocates and arranges all of the memory required for a
 *              ChanBufStruct linked list based on the list of channels
 *              provided in the mxArray pointed to by pmxChanArray.
 *              Note that this array specifies channels starting at number 1
 *              whilst the minChanNum and maxChanNum are based on the channel
 *              numbers starting at zero.  This is also how the channel numbers
 *              are stored within the ChanBufStruct, and the pmxChanArray
 *              only uses values starting at 1 to make it the utility user friendly
 *
 *              Rather than returning a pointer to the start of the linked list,
 *              this directly updates the pointer which will be used to point at
 *              the start of the list.
 *
 *              Note that if ppfirstcbs points to the start of a linked list before
 *              calling this function, the linked list is not freed and instead
 *              this pointer to the start of it is just overwritten!
 *
 * TODO:        Change implementation to return the pointer to the start of the
 *              linked list, or NULL if there was an error.  Therefore removing
 *              the need for ppfirstcbs to be supplied, which can be confusing.
 */

bool channelListToChanBufStructs(const mxArray *pmxChanArray, ChanBufStruct **ppfirstcbs,
                                 unsigned int minChanNum, unsigned int maxChanNum,
                                 bool makeMemoryPersistent)
{
   unsigned int chanUseCount = 0;
   double *pchani, *pchanj, *pchanList;
   ChanBufStruct **ppcbs;

   if (!pmxChanArray || !ppfirstcbs)
   {
      mexWarnMsgTxt("Invalid pointer in channelListToChanBufStructs.");
      return false;
   }

   if (!mxIsNumeric(pmxChanArray))
   {
      mexWarnMsgTxt("Channel array must be numeric.");
      return false;
   }
   if (mxIsComplex(pmxChanArray))
   {
      mexWarnMsgTxt("Channel array must not be complex.");
      return false;
   }
   if (mxGetM(pmxChanArray) != 1)
   {
      mexWarnMsgTxt("Channel array must have 1 row.");
      return false;
   }

   chanUseCount = mxGetN(pmxChanArray);
   pchanList = mxGetPr(pmxChanArray);

   /* Check all channel values are unique */

   for (pchani = pchanList; pchani < &pchanList[chanUseCount]; pchani++)
   {
      if (*pchani != (int)*pchani)
      {
         mexWarnMsgTxt("Channel values must all be integers.");
         return false;
      }

      if (*pchani <= minChanNum || *pchani > (maxChanNum + 1))
      {
         /* mexPrintf("Channel numbers must all be between %d and %d.\n", minChanNum + 1, maxChanNum + 1); */
         mexWarnMsgTxt("Channel numbers out of range.");
         return false;
      }

      for (pchanj = pchanList; pchanj < &pchanList[chanUseCount]; pchanj++)
      {
         if ((pchani != pchanj) && (*pchani == *pchanj))
         {
            /* Pointers are different, but point to the same value */
            /* mexPrintf("Each channel may only be specified once in a list: value %d duplicated.\n", (int)*pchani); */
            mexWarnMsgTxt("Channel number duplicated within channel list.");
            return false;
         }
      }
   }

   /* Generate the linked list, iterating through the list of channels */
   ppcbs = ppfirstcbs;

   for (pchani = pchanList; pchani < &pchanList[chanUseCount]; pchani++)
   {
      *ppcbs = mxCalloc(1, sizeof(ChanBufStruct));
      if (!*ppcbs)
      {
         mexWarnMsgTxt("Unable to allocate memory for channel buffer structure.");
         freeChanBufStructs(ppfirstcbs);
         return false;
      }

      if (makeMemoryPersistent)
         mexMakeMemoryPersistent(*ppcbs);

      (*ppcbs)->pbuffer = NULL;
      (*ppcbs)->bufLen = 0;
      (*ppcbs)->channel = (int) * pchani - 1; /* Storing channel numbers base 0, whereas they are supplied by the user base 1; */
      (*ppcbs)->pnextChanBuf = NULL;

      ppcbs = &(*ppcbs)->pnextChanBuf;
   }

   return true;
}

/*
 * FUNCTION:    addPlayrecPage(mxArray **ppmxPageNum, const mxArray *pplayData,
 *                  const mxArray *pplayChans, const mxArray *precDataLength,
 *                  const mxArray *precChans)
 *
 * Inputs:      **ppmxPageNum   pointer to a pointer which will be changed to
 *                              point at an mxArray containing the page number
 *                              of the page added.
 *              *pplayData      pointer to an MxN mxArray containing the play
 *                              data for the page, or NULL for no output. M is
 *                              the number of samples and N is the number of
 *                              channels of data.
 *              pplayChans      pointer to a 1xN mxArray containing the order
 *                              of channels in pplayData or NULL for no output
 *              *precDataLength pointer to a scalar mxArray containing the
 *                              number of samples to record, or -1 to use the
 *                              same length as pplayData (only valid if
 *                              pplayData is not NULL).
 *              *precChans      pointer to a 1xP mxArray containing the order
 *                              of channels to record where P is the total
 *                              number of channels to record (this is the order
 *                              the channels are retured).
 *
 * Returns:     true if page added successfully, false if an error occurred
 *              (returned after displaying an error message), or aborts with
 *              an error if not in full initialisation state.
 *              ppmsPageNum is only valid if true is returned.
 *
 * Description: Adds a new page at the end of the current page list.  The new
 *              page contains the play data (if specified) and is configured
 *              to record the specified channels.  Completes all validation
 *              checks and completely creates the page before adding it to the
 *              page linked list.  In doing so, the output and recording will
 *              always remain synchronised nomatter if there are or aren't
 *              other pages in the list.
 *
 *              All memory allocated and referenced from within the created
 *              page is made persistent.  If false is returned then all this
 *              memory is freed up before returning and all references to
 *              the page are removed.  However, if true is returned (page
 *              created successfully) then appropriate measures to free
 *              the page must be made once the page is nolonger required.
 *
 * TODO:
 */
bool addPlayrecPage(mxArray **ppmxPageNum, const mxArray *pplayData,
                    const mxArray *pplayChans, const mxArray *precDataLength,
                    const mxArray *precChans)
{
   StreamPageStruct *psps;
   ChanBufStruct *pcbs;
   resample_error rerr = RESAMPLE_OK;
   unsigned int dataChanCount, playSamplePerChan = 0, recSamplePerChan;
   unsigned int i, chansCopied, playResPlanId = 0, bufTmpLen;

   validateState(BASIC_INIT | FULL_INIT, 0);

   /* Should not get here if _pstreamInfo is null */
   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet _pstreamInfo is NULL.");
   }

   if ((pplayData && !pplayChans) || (!pplayData && pplayChans))
   {
      mexWarnMsgTxt("Either both or neither of playData and playChans should be NULL.");
      return false;
   }

   if ((precDataLength && !precChans) || (!precDataLength && precChans))
   {
      mexWarnMsgTxt("Either both or neither of recDataLength and recChans should be NULL.");
      return false;
   }

   if (pplayData && (_pstreamInfo->playDeviceID == paNoDevice))
   {
      mexWarnMsgTxt("Unable to play when no play device has been selected.");
      return false;
   }

   if (precDataLength && (_pstreamInfo->recDeviceID == paNoDevice))
   {
      mexWarnMsgTxt("Unable to record when no record device has been selected.");
      return false;
   }

   psps = newStreamPageStruct(_pstreamInfo->playChanCount, true);

   if (!psps)
   {
      mexWarnMsgTxt("Unable to create new page.");
      return false;
   }

   if (pplayData && pplayChans)
   {
      if (!mxIsNumeric(pplayData) || mxIsComplex(pplayData)
            || (!mxIsSingle(pplayData) && !mxIsDouble(pplayData)))
      {

         mexWarnMsgTxt("Audio buffer must be non-complex numbers of type single or double.");
         freeStreamPageStruct(&psps);
         return false;
      }

      /* Create a linked list of all the channels required, checking they're all
       * within the valid range of channel numbers
       */
      if (!channelListToChanBufStructs(pplayChans, &psps->pfirstPlayChan, 0,
                                       _pstreamInfo->playChanCount - 1, true))
      {
         freeStreamPageStruct(&psps);
         return false;
      }

      /* Clear chansInUse array */
      if (psps->pplayChansInUse)
      {
         for (i = 0; i < psps->playChanCount; i++)
            psps->pplayChansInUse[i] = false;
      }
      else
      {
         mexWarnMsgTxt("chansInUse buffer has not be created successfully.");
         freeStreamPageStruct(&psps);
         return false;
      }

      /* Copy across all data */
      dataChanCount = mxGetN(pplayData);
      playSamplePerChan = mxGetM(pplayData);



      pcbs = psps->pfirstPlayChan;
      chansCopied = 0;

      if (playSamplePerChan > 0)
      {
         while (pcbs && (chansCopied < dataChanCount))
         {
            /* Float32 input data */
            if (mxIsSingle(pplayData))
               pcbs->pbuffer = convFloat((float *)mxGetData(pplayData) +
                                         chansCopied * playSamplePerChan,
                                         playSamplePerChan);
            else if (mxIsDouble(pplayData)) /* Double */
               pcbs->pbuffer = convDouble((double *)mxGetData(pplayData) +
                                          chansCopied * playSamplePerChan,
                                          playSamplePerChan);
            else
            {
               /* This should never be called as the if statement above should
                * catch this condition
                */
               mexWarnMsgTxt("Audio buffer of incorrect data type.");
               freeStreamPageStruct(&psps);
               return false;
            }

            /* Do resampling if play resampler is present*/
            if (play_resplan)
            {
               bufTmpLen = resample_nextoutlen(
                              play_resplan[playResPlanId], playSamplePerChan);
               SAMPLE* buf = mxCalloc(bufTmpLen, sizeof * buf);
               mexMakeMemoryPersistent(buf);
               rerr = resample_execute(play_resplan[playResPlanId],
                                       pcbs->pbuffer, playSamplePerChan, buf, bufTmpLen);
               mxFree(pcbs->pbuffer);
               pcbs->pbuffer = buf;
               pcbs->bufLen = bufTmpLen;
               playResPlanId++;
            }
            else
            {
               pcbs->bufLen = playSamplePerChan;
            }

            if (rerr != RESAMPLE_OK)
            {
               mexWarnMsgTxt("Resampling returned an error. This should not happened.");
            }


            if (!pcbs->pbuffer)
            {
               mexWarnMsgTxt("Audio buffer conversion returned NULL.");
               freeStreamPageStruct(&psps);
               return false;
            }

            /* This if statement should not be required (included for safety) */
            if (
                  //  (pcbs->channel >= 0) && // always true
                    (pcbs->channel < psps->playChanCount))
               psps->pplayChansInUse[pcbs->channel] = true;

            chansCopied++;

            mexMakeMemoryPersistent(pcbs->pbuffer);
            pcbs = pcbs->pnextChanBuf;
         }
      }

      psps->pageLength = max(psps->pageLength, psps->pfirstPlayChan->bufLen);
      /* This is only used if recording is also performed */
      psps->pageLengthRec = max(psps->pageLengthRec, playSamplePerChan);


      /* Check to see if either there are more channels than required, or too few channels */
      if ((chansCopied < dataChanCount) && (playSamplePerChan > 0))
         mexWarnMsgTxt("More channels of data supplied than channels in channel list; ignoring remaining channels.");
      else if (pcbs)
         mexWarnMsgTxt("Fewer channels of data supplied than channels in channel list; \"Zeroing\" all other channels.");
   }

   if (precDataLength && precChans)
   {
      if (!mxIsNumeric(precDataLength) || mxIsComplex(precDataLength)
            || (mxGetN(precDataLength) != 1) || (mxGetM(precDataLength) != 1)
            || (mxGetScalar(precDataLength) != (int)mxGetScalar(precDataLength)))
      {

         mexWarnMsgTxt("Number of record samples must be a non-complex integer.");
         return false;
      }
      else if (mxGetScalar(precDataLength) < 0)
      {
         if (_pstreamInfo->playDeviceID == paNoDevice || !pplayData)
         {
            mexWarnMsgTxt("Cannot use play sample count for record sample count when no play buffer in page.");
            freeStreamPageStruct(&psps);
            return false;
         }
         /* Use the same length of buffer for recording in the same page */
         recSamplePerChan = psps->pfirstPlayChan->bufLen;
      }
      else
      {
         /* Number of recorded samples specified directly. */
         recSamplePerChan = (int)mxGetScalar(precDataLength);

         psps->pageLengthRec = recSamplePerChan;


         if (rec_resplan)
         {
            recSamplePerChan = resample_nextinlen(dummy_recplan, recSamplePerChan);
            resample_advanceby(dummy_recplan, recSamplePerChan, (int)mxGetScalar(precDataLength));
         }
      }

      if (recSamplePerChan > 0)
      {
         /* Only process recording if there are going ot be some samples recorded!
          * Create a linked list of all the channels required, checking they're all
          * within the valid range of channel numbers
          */
         if (!channelListToChanBufStructs(precChans, &psps->pfirstRecChan, 0, _pstreamInfo->recChanCount - 1, true))
         {
            freeStreamPageStruct(&psps);
            return false;
         }

         pcbs = psps->pfirstRecChan;
         psps->pageLength = max(psps->pageLength, recSamplePerChan);


         while (pcbs)
         {
            pcbs->pbuffer = mxCalloc(recSamplePerChan, sizeof(SAMPLE));

            if (!pcbs->pbuffer)
            {
               mexWarnMsgTxt("Unable to create audio record buffer.");
               freeStreamPageStruct(&psps);
               return false;
            }

            mexMakeMemoryPersistent(pcbs->pbuffer);
            pcbs->bufLen = recSamplePerChan;
            pcbs = pcbs->pnextChanBuf;
         }
      }
   }

   /* This should be used here to avoid problems with clearing the
    * zero length page and then accessing this!
    */
   *ppmxPageNum = mxCreateDoubleScalar(psps->pageNum);

   /* Reaching here means the page has been created successfully, so add
    * to end of page list provided it is worth adding!
    */
   if (psps->pageLength == 0)
   {
      mexWarnMsgTxt("Page added has zero length.");
      freeStreamPageStruct(&psps);
      /* Still return the pageNumber without an error as this is not fatal */
   }
   else if (!addStreamPageStruct(_pstreamInfo, psps))
   {
      mexWarnMsgTxt("Unable to add page to stream");
      freeStreamPageStruct(&psps);
      mxDestroyArray(*ppmxPageNum);
      *ppmxPageNum = NULL;
      return false;
   }

   return true;
}

/*
 * FUNCTION:    doInit(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *          Requires between 3 and 8 right-hand side arguments (ie nrhs
 *          between 3 and 8, and prhs with at least this many elements).
 *          These elements store, in order, sampleRate, playDevice,
 *          recDevice, playMaxChannel, recMaxChannel, framesPerBuffer,
 *          playSuggestedLatency, recSuggestedLatency.
 *          Where:
 *  sampleRate
 *      the sample rate at which both devices will operate
 *  playDevice
 *      the ID of the device to be used for output (as returned by
 *      'getDevices'), or -1 for no device (ie output not required)
 *  recDevice
 *      the ID of the device to be used for recording (as returned by
 *      'getDevices'), or -1 for no device (ie recording not required)
 *  playMaxChannel {optional}
 *      a number greater than or equal to the maximum channel that will be used
 *      for output.  This must be less than or equal to the maximum number of
 *      output channels that the device supports.  Value ignored if playDevice
 *      is -1.
 *  recMaxChannel {optional}
 *      a number greater than or equal to the maximum channel that will be used
 *      for recording.  This must be less than or equal to the maximum number
 *      of input channels that the device supports.  Value ignored if recDevice
 *      is -1.
 * framesPerBuffer {optional}
 *      the number of samples to be processed in each callback within the
 *      utility (ie the length of each block of samples sent by the utility to
 *      the soundcard).  The lower the value specified the shorter the latency
 *      but also the greater the likelihood of glitches within the audio.
 *      A value of 0 lets the utility use an optimal, and potentially different,
 *      value in each callback.
 * playSuggestedLatency {optional}
 *      the play latency, in seconds, the device should try to use where possible.
 *      Defaults to the default low output latency for the device if not specified.
 * recSuggestedLatency {optional}
 *      the record latency, in seconds, the device should try to use where possible.
 *      Defaults to the default low input latency for the device if not specified.
 *
 * Returns:     true if stream opened succesfully or there is no stream to open
 *              (ie both playDevice and recDevice are -1).  Otherwise false after
 *              an appropriate error message has been displayed in the MATLAB
 *              command window.
 *
 * Description: Initialises the PortAudio stream based on the arguments supplied.
 *              If the maxChannel values are not specified, the maximum channel
 *              number supported by the relevant device is determined and used.  If
 *              the framesPerBuffer value is not specified, the default, as set in
 *              newStreamInfoStruct() is used.  All other initialisation values used
 *              are also set in this other function.
 *
 *              Note that this also starts the PortAudio stream, so by the end, or
 *              shortly afterwars, the playrecCallback() function will start being
 *              called.
 *
 * TODO:
 */
bool doInit(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   int ii;
   PaStreamParameters inputParameters;
   PaStreamParameters outputParameters;
   double resRat;
   validateState(BASIC_INIT, FULL_INIT );

   /* Completely clear out the previous stream */
   if (_pstreamInfo)
   {
      freeStreamInfoStruct(&_pstreamInfo);
   }

   /* Check stream info structure created successfully */
   if (!(_pstreamInfo = newStreamInfoStruct(true)))
   {
      return false;
   }

   /* Get sample rate */
   if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
         || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1)
         || (mxGetScalar(prhs[0]) != (int)mxGetScalar(prhs[0]))
         || (mxGetScalar(prhs[0]) <= 0))
   {

      mexWarnMsgTxt("Samplerate must be a non-complex scalar integer greater than zero.");
      freeStreamInfoStruct(&_pstreamInfo);
      return false;
   }

   _pstreamInfo->suggestedSampleRate = mxGetScalar(prhs[0]);

   /* Get play device -  <0 is no device */
   if (!mxIsNumeric(prhs[1]) || mxIsComplex(prhs[1])
         || (mxGetN(prhs[1]) != 1) || (mxGetM(prhs[1]) != 1)
         || (mxGetScalar(prhs[1]) != (int)mxGetScalar(prhs[1])))
   {

      mexWarnMsgTxt("Play DeviceID must be a non-complex integer.");
      freeStreamInfoStruct(&_pstreamInfo);
      return false;
   }
   else if (mxGetScalar(prhs[1]) >= Pa_GetDeviceCount())
   {
      mexWarnMsgTxt("Play DeviceID must be a valid device number.");
      freeStreamInfoStruct(&_pstreamInfo);
      return false;
   }
   else if (mxGetScalar(prhs[1]) < 0)
   {
      _pstreamInfo->playDeviceID = paNoDevice;
   }
   else
   {
      _pstreamInfo->playDeviceID = (PaDeviceIndex)mxGetScalar(prhs[1]);
   }

   /* Get record device - <0 is no device */
   if (!mxIsNumeric(prhs[2]) || mxIsComplex(prhs[2])
         || (mxGetN(prhs[2]) != 1) || (mxGetM(prhs[2]) != 1)
         || (mxGetScalar(prhs[2]) != (int)mxGetScalar(prhs[2])))
   {

      mexWarnMsgTxt("Record DeviceID must be a non-complex integer.");
      freeStreamInfoStruct(&_pstreamInfo);
      return false;
   }
   else if (mxGetScalar(prhs[2]) >= Pa_GetDeviceCount())
   {
      mexWarnMsgTxt("Record DeviceID must be a valid device number.");
      freeStreamInfoStruct(&_pstreamInfo);
      return false;
   }
   else if (mxGetScalar(prhs[2]) < 0)
   {
      _pstreamInfo->recDeviceID = paNoDevice;
   }
   else
   {
      _pstreamInfo->recDeviceID = (PaDeviceIndex)mxGetScalar(prhs[2]);
   }

   /* Check there is at least a play or record device */
   if ((_pstreamInfo->playDeviceID == paNoDevice)
         && (_pstreamInfo->recDeviceID == paNoDevice))
   {
      mexWarnMsgTxt("playdevice < 0 and recdevice < 0. Nothing to be done - initialisation not complete.");
      freeStreamInfoStruct(&_pstreamInfo);
      return true;
   }

   /* Check maximum play channel number */
   if (_pstreamInfo->playDeviceID != paNoDevice)
   {
      if (nrhs >= 4)
      {
         if (!mxIsNumeric(prhs[3]) || mxIsComplex(prhs[3])
               || (mxGetN(prhs[3]) != 1) || (mxGetM(prhs[3]) != 1)
               || (mxGetScalar(prhs[3]) != (int)mxGetScalar(prhs[3]))
               || (mxGetScalar(prhs[3]) <= 0))
         {

            mexWarnMsgTxt("Maximum channel number for output must be a non-complex scalar integer greater than zero.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }

         /* The supplied value is the channel number, base 1
          * This is the same as the number of channels (even though we are using base 0)
          */
         _pstreamInfo->playChanCount = (unsigned int)mxGetScalar(prhs[3]);
      }
      else
      {
         /* Determine maximum number from PortAudio and use that */
         const PaDeviceInfo *pdi = Pa_GetDeviceInfo(_pstreamInfo->playDeviceID);

         if (pdi)
         {
            _pstreamInfo->playChanCount = pdi->maxOutputChannels;
         }
         else
         {
            mexWarnMsgTxt("Unable to retrieve maximum play channel number for device.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }
      }
   }

   /* Check maxmimum record channel number */
   if (_pstreamInfo->recDeviceID != paNoDevice)
   {
      if (nrhs >= 5)
      {
         if (!mxIsNumeric(prhs[4]) || mxIsComplex(prhs[4])
               || (mxGetN(prhs[4]) != 1) || (mxGetM(prhs[4]) != 1)
               || (mxGetScalar(prhs[4]) != (int)mxGetScalar(prhs[4]))
               || (mxGetScalar(prhs[4]) <= 0))
         {

            mexWarnMsgTxt("Maximum channel number for recording must be a non-complex scalar integer greater than zero.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }

         /* The supplied value is the channel number, base 1
          * This is the same as the number of channels (even though we are using base 0)
          */
         _pstreamInfo->recChanCount = (unsigned int)mxGetScalar(prhs[4]);
      }
      else
      {
         /* Determine maximum number from PortAudio and use that */
         const PaDeviceInfo *pdi = Pa_GetDeviceInfo(_pstreamInfo->recDeviceID);

         if (pdi)
         {
            _pstreamInfo->recChanCount = pdi->maxInputChannels;
         }
         else
         {
            mexWarnMsgTxt("Unable to retrieve maximum record channel number for device.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }
      }
   }

   /* Get framesPerBuffer if valid */
   if (nrhs >= 6)
   {
      if (!mxIsNumeric(prhs[5]) || mxIsComplex(prhs[5])
            || (mxGetN(prhs[5]) != 1) || (mxGetM(prhs[5]) != 1)
            || (mxGetScalar(prhs[5]) != (int)mxGetScalar(prhs[5]))
            || (mxGetScalar(prhs[5]) < 0))
      {

         /* Zero is used for 'Unspecified' ie let PortAudio choose */
         mexWarnMsgTxt("Frame buffer size must be a non-complex scalar integer "
                       "greater than or equal to zero.");
         freeStreamInfoStruct(&_pstreamInfo);
         return false;
      }

      _pstreamInfo->suggestedFramesPerBuffer = (unsigned int)mxGetScalar(prhs[5]);
   }

   /* Get playSuggestedLatency if valid */
   if (_pstreamInfo->playDeviceID != paNoDevice)
   {
      if (nrhs >= 7)
      {
         if (!mxIsNumeric(prhs[6]) || mxIsComplex(prhs[6])
               || (mxGetN(prhs[6]) != 1) || (mxGetM(prhs[6]) != 1)
               || (mxGetScalar(prhs[6]) < 0))
         {

            mexWarnMsgTxt("Play suggested latency must be a non-complex "
                          "scalar value greater than or equal to zero.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }

         _pstreamInfo->playSuggestedLatency = (PaTime)mxGetScalar(prhs[6]);
      }
      else
      {
         _pstreamInfo->playSuggestedLatency =
            Pa_GetDeviceInfo( _pstreamInfo->playDeviceID )->defaultLowOutputLatency;
      }
   }

   /* Get recSuggestedLatency if valid */
   if (_pstreamInfo->recDeviceID != paNoDevice)
   {
      if (nrhs >= 8)
      {
         if (!mxIsNumeric(prhs[7]) || mxIsComplex(prhs[7])
               || (mxGetN(prhs[7]) != 1) || (mxGetM(prhs[7]) != 1)
               || (mxGetScalar(prhs[7]) < 0))
         {

            mexWarnMsgTxt("Record suggested latency must be a non-complex "
                          "scalar value greater than or equal to zero.");
            freeStreamInfoStruct(&_pstreamInfo);
            return false;
         }

         _pstreamInfo->recSuggestedLatency = (PaTime)mxGetScalar(prhs[7]);
      }
      else
      {
         _pstreamInfo->recSuggestedLatency =
            Pa_GetDeviceInfo( _pstreamInfo->recDeviceID )->defaultLowInputLatency;
      }
   }

   if (_pstreamInfo->recDeviceID != paNoDevice)
   {
      inputParameters.device = _pstreamInfo->recDeviceID;
      inputParameters.channelCount = _pstreamInfo->recChanCount;
      inputParameters.sampleFormat = paFloat32;
      inputParameters.suggestedLatency = _pstreamInfo->recSuggestedLatency;
      inputParameters.hostApiSpecificStreamInfo = NULL;
   }

   if (_pstreamInfo->playDeviceID != paNoDevice)
   {
      outputParameters.device = _pstreamInfo->playDeviceID;
      outputParameters.channelCount = _pstreamInfo->playChanCount;
      outputParameters.sampleFormat = paFloat32;
      outputParameters.suggestedLatency = _pstreamInfo->playSuggestedLatency;
      outputParameters.hostApiSpecificStreamInfo = NULL;
   }

   /* Open an audio I/O stream. */
   checkPAErr(Pa_OpenStream(
                 &_pstreamInfo->pstream,
                 (_pstreamInfo->recDeviceID != paNoDevice) ? &inputParameters : NULL,
                 (_pstreamInfo->playDeviceID != paNoDevice) ? &outputParameters : NULL,
                 _pstreamInfo->suggestedSampleRate,
                 _pstreamInfo->suggestedFramesPerBuffer,
                 _pstreamInfo->streamFlags,
                 playrecCallback,
                 _pstreamInfo));

   clearResPlans();

   /* If the sampling rate is not supported, try initializing with fs=44,1kHz*/
   if ( lastPaError == paInvalidSampleRate )
   {
      lastPaError = paNoError;
      mexWarnMsgTxt("PLAYREC: Device does not support selected sampling rate. Will use 44.1 kHz and resample.");
      resRat = 44100.0 / _pstreamInfo->suggestedSampleRate;
      _pstreamInfo->suggestedSampleRate = 44100.0;

      checkPAErr(Pa_OpenStream(
                    &_pstreamInfo->pstream,
                    (_pstreamInfo->recDeviceID != paNoDevice) ? &inputParameters : NULL,
                    (_pstreamInfo->playDeviceID != paNoDevice) ? &outputParameters : NULL,
                    _pstreamInfo->suggestedSampleRate,
                    _pstreamInfo->suggestedFramesPerBuffer,
                    _pstreamInfo->streamFlags,
                    playrecCallback,
                    _pstreamInfo));

      /* Initialize record resampler(s) */
      if (_pstreamInfo->recDeviceID != paNoDevice)
      {
         dummy_recplan = resample_init(RESAMPLING_TYPE, 1.0 / resRat);
         recResChanCount = _pstreamInfo->recChanCount;
         rec_resplan = malloc(recResChanCount * sizeof * rec_resplan);
         for (ii = 0; ii < recResChanCount; ii++)
            rec_resplan[ii] = resample_init( RESAMPLING_TYPE, 1.0 / resRat );
      }

      /* Initialize play resampler */
      if (_pstreamInfo->playDeviceID != paNoDevice)
      {
         playResChanCount = _pstreamInfo->playChanCount;
         play_resplan = malloc(playResChanCount * sizeof * play_resplan);
         for (ii = 0; ii < playResChanCount; ii++)
            play_resplan[ii] = resample_init( RESAMPLING_TYPE, resRat );
      }

   }

   if (lastPaError != paNoError)
   {
      /* the value of stream is invalid, so clear it before freeing the stream
      * structure */
      _pstreamInfo->pstream = NULL;
      freeStreamInfoStruct(&_pstreamInfo);
      abortIfPAErr("Init failed to open PortAudio stream");
   }


   /* Stream is open, so now store time and start stream. */
   time(&_pstreamInfo->streamStartTime);

   if (checkPAErr(Pa_StartStream( _pstreamInfo->pstream )) != paNoError)
   {
      /* Stream cannot be started */
      freeStreamInfoStruct(&_pstreamInfo);
      abortIfPAErr("Init failed to start PortAudio stream");
   }

   SETSTATE(FULL_INIT);

   return true;
}

/*
 * FUNCTION:    doPlayrec(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *          4 right-hand side arguments (stored in the first 4 elements of prhs)
 *          must be provided containing the following values (in this order):
 *  playBuffer
 *      a MxN matrix containing the samples to be played.  M is the number of
 *      samples and N is the number of channels of data.
 *  playChanList
 *      a 1xN vector containing the channels on which the playBuffer samples
 *      should be output.  N is the number of channels of data, and should be
 *      the same as playBuffer (a warning is generated if they are different
 *      but the utility will still try and create the page).  Can only contain
 *      each channel number once, but the channel order is not important and
 *      does not need to include all the channels the device supports (all
 *      unspecified channels will automatically output zeros).  The maximum
 *      channel number cannot be greater than that specified during
 *      initialisation.
 *  recDuration
 *      the number of samples that should be recorded in this page, or -1 to
 *      record the same number of samples as in playBuffer.
 *  recChanList
 *      a row vector containing the channel numbers of all channels to be
 *      recorded.  Can only contain each channel number once, but the channel
 *      order is not important and does not need to include all the channels
 *      the device supports.
 *
 * Returns:     true if page added successfully, false if an error occurred
 *              (returned after displaying an error message)
 *
 * Description: Adds a page (containging play and record) to the end of the
 *              current list of pages, returning the number of the new page
 *              in the first element of plhs.
 *
 *              See addPlayrecPage for more information.
 *
 * TODO:
 */
bool doPlayrec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   return addPlayrecPage(&plhs[0], prhs[0], prhs[1], prhs[2], prhs[3]);
}

/*
 * FUNCTION:    doPlay(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *          2 right-hand side arguments (stored in the first 2 elements of prhs)
 *          must be provided containing the following values (in this order):
 *  playBuffer
 *      a MxN matrix containing the samples to be played.  M is the number of
 *      samples and N is the number of channels of data.
 *  playChanList
 *      a 1xN vector containing the channels on which the playBuffer samples
 *      should be output.  N is the number of channels of data, and should be
 *      the same as playBuffer (a warning is generated if they are different
 *      but the utility will still try and create the page).  Can only contain
 *      each channel number once, but the channel order is not important and
 *      does not need to include all the channels the device supports (all
 *      unspecified channels will automatically output zeros).  The maximum
 *      channel number cannot be greater than that specified during
 *      initialisation.
 *
 * Returns:     true if page added successfully, false if an error occurred
 *              (returned after displaying an error message)
 *
 * Description: Adds a page (containging only play channels) to the end of the
 *              current list of pages, returning the number of the new page
 *              in the first element of plhs.
 *
 *              See addPlayrecPage for more information.
 *
 * TODO:
 */
bool doPlay(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   return addPlayrecPage(&plhs[0], prhs[0], prhs[1], NULL, NULL);
}

/*
 * FUNCTION:    doRec(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *          2 right-hand side arguments (stored in the first 2 elements of prhs)
 *          must be provided containing the following values (in this order):
 *
 *  recDuration
 *      the number of samples that should be recorded on each channel specified
 *      in recChanList.
 *  recChanList
 *      a row vector containing the channel numbers of all channels to be
 *      recorded.  Can only contain each channel number once, but the channel
 *      order is not important and does not need to include all the channels
 *      the device supports.  This is the same as the order of channels
 *      returned by 'getRec'.  The maximum channel number cannot be greater
 *      than that specified during initialisation.
 *
 * Returns:     true if page added successfully, false if an error occurred
 *              (returned after displaying an error message)
 *
 * Description: Adds a page (containging only record channels) to the end of the
 *              current list of pages, returning the number of the new page
 *              in the first element of plhs.
 *
 *              See addPlayrecPage for more information.
 *
 * TODO:
 */
bool doRec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   return addPlayrecPage(&plhs[0], NULL, NULL, prhs[0], prhs[1]);
}

/*
 * FUNCTION:    doPause(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  If (nrhs > 0) then the first element
 *              of prhs must also be valid and must point to a scalar.
 *
 * Returns:     true is successful, false if the supplied argument is invalid,
 *              or aborts with an error if not in full initialisation state.
 *              The first element in plhs is only valid when true is returned.
 *
 * Description: If (nrhs > 0) then the stream pause state is updated with that
 *              contained in the first element of prhs which should be 1 to
 *              pause the stream or 0 to unpause the stream.  If no arguments
 *              are supplied then the stream pause state is not altered.
 *
 *              Returns a double scalar in the first element of plhs containing
 *              the current pause state (1 for paused, 0 for running).  If a
 *              new pause state was supplied, the returned state is that after
 *              the update has occurred.
 *
 * TODO:
 */
bool doPause(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   " _pstreamInfo is NULL.");
   }

   if (nrhs > 0)
   {
      if (!(mxIsNumeric(prhs[0]) || mxIsLogical(prhs[0]))
            || mxIsComplex(prhs[0])
            || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1)
            || ((mxGetScalar(prhs[0]) != 0)
                && (mxGetScalar(prhs[0]) != 1)))
      {

         mexWarnMsgTxt("New pause state must be either 0 (off) or 1 (on).");
         return false;
      }

      _pstreamInfo->isPaused = (mxGetScalar(prhs[0]) == 1);
   }

   plhs[0] = mxCreateDoubleScalar(_pstreamInfo->isPaused ? 1 : 0);
   return true;
}

/*
 * FUNCTION:    doBlock(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  If (nrhs > 0) then the first element
 *              of prhs must also be valid and must point to a scalar.
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: Waits until the specified page has finished before returning.
 *
 *              If (nrhs > 0), and hence at least one argument is supplied,
 *              then the first element of prhs is assumed to contain a page
 *              number.  Otherwise the utility automatically uses the page
 *              number of the last page resident in memory.
 *
 *              Returns a double scalar in the first element of plhs containing:
 *              1 if the specified page is a valid page and has finished being
 *              processed (note that page validity refers to when the function
 *              was called and so now the page has finished it may no longer
 *              be a valid page).
 *              0 if the specified page is a valid page that has not finished
 *              being processed.  This is only returned if the stream is paused
 *              and is used to avoid the function blocking indefinitely.
 *              -1 if the specified page is invalid or no longer exists.  This
 *              includes pages that have automatically been condensed, and hence
 *              have finished.
 *
 * TODO:
 */
bool doBlock(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;

   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   if (!_pstreamInfo->pfirstStreamPage)
   {
      plhs[0] = mxCreateDoubleScalar(-1);
      return true;
   }

   psps = _pstreamInfo->pfirstStreamPage;

   if (nrhs > 0)
   {
      if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
            || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1))
      {

         plhs[0] = mxCreateDoubleScalar(-1);
         return true;
      }

      while (psps)
      {
         if (psps->pageNum == (int)mxGetScalar(prhs[0]))
            break;

         psps = psps->pnextStreamPage;
      }

      if (!psps)
      {
         /* page does not exist, so return immediately */
         plhs[0] = mxCreateDoubleScalar(-1);
         return true;
      }
   }
   else
   {
      /* Find the last page */
      while (psps)
      {
         if (!psps->pnextStreamPage)
            break;

         psps = psps->pnextStreamPage;
      }

      if (!psps)
      {
         /* page does not exist, so return immediately
          * This condition should have been caught earlier
          */
         plhs[0] = mxCreateDoubleScalar(-1);
         return true;
      }
   }

   while (!psps->pageFinished)
   {
      if (_pstreamInfo->isPaused)
      {
         plhs[0] = mxCreateDoubleScalar(0);
         return true;
      }
      Pa_Sleep(1);
   }

   plhs[0] = mxCreateDoubleScalar(1);
   return true;
}

/*
 * FUNCTION:    doIsFinished(int nlhs, mxArray *plhs[],
                        int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  If (nrhs > 0) then the first element
 *              of prhs must also be valid and must point to a scalar.
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: If (nrhs > 0), and hence at least one argument is supplied,
 *              then the first element of prhs is assumed to contain a page
 *              number.  Otherwise the utility automatically uses the page
 *              number of the last page resident in memory.
 *
 *              Returns a double scalar in the first element of plhs containing:
 *              1 if the specified page is a valid page and has finished being
 *              processed or all pages are finished,
 *              0 if the specified page is a valid page but has not finished
 *              being processed or there are unfinished pages,
 *              -1 if the specified page is invalid or no longer exists.  This
 *              includes pages that have automatically been condensed, and hence
 *              have finished.
 *
 * TODO:
 */
bool doIsFinished(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;

   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   if (!_pstreamInfo->pfirstStreamPage)
   {
      /* No pages - they must have all finished! */
      plhs[0] = mxCreateDoubleScalar(1);
      return true;
   }

   psps = _pstreamInfo->pfirstStreamPage;

   if (nrhs > 0)
   {
      /* Page has been specified */
      if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
            || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1))
      {

         plhs[0] = mxCreateDoubleScalar(-1);
         return true;
      }

      /* Find specified page */
      while (psps)
      {
         if (psps->pageNum == (int)mxGetScalar(prhs[0]))
            break;

         psps = psps->pnextStreamPage;
      }

      if (!psps)
      {
         /* page does not exist, */
         plhs[0] = mxCreateDoubleScalar(-1);
      }
      else
      {
         /* page does exist, so indicate if finished */
         plhs[0] = mxCreateDoubleScalar(psps->pageFinished ? 1 : 0);
      }
   }
   else
   {
      /* Find the last page, or any page not finished */
      while (psps)
      {
         if (!psps->pnextStreamPage || !psps->pageFinished)
            break;

         psps = psps->pnextStreamPage;
      }

      if (!psps)
      {
         /* This condition should have been caught earlier */
         plhs[0] = mxCreateDoubleScalar(1);
      }
      else
      {
         plhs[0] = mxCreateDoubleScalar(psps->pageFinished ? 1 : 0);
      }
   }

   return true;
}

/*
 * FUNCTION:    doIsInitialised(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              1 if the utility is fully initialised, otherwise 0.
 *
 * TODO:
 */
bool doIsInitialised(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   if (ISSTATE(FULL_INIT))
      plhs[0] = mxCreateDoubleScalar(1);
   else if (ISSTATE(BASIC_INIT))
      /* If required can return different values for BASIC_INIT and no init! */
      plhs[0] = mxCreateDoubleScalar(0);
   else
      plhs[0] = mxCreateDoubleScalar(0);

   return true;
}

/*
 * FUNCTION:    doDelPage(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  If (nrhs != 0) then the first element
 *              of prhs must also be valid and must point to a scalar.
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: If (nrhs==0), and hence no arguments are supplied, then all
 *              pages resident in memory are deleted.  Otherwise it is assumed
 *              that a argument is supplied in the first element of prhs,
 *              containing the page number of the page to be deleted.
 *
 *              If nothing is deleted (no pages resident in memory or there is
 *              no page with the specified page number) then 0 is returned as
 *              the first element of plhs.  Otherwise, 1 is returned as the
 *              first element of plhs.
 *
 * TODO:
 */
bool doDelPage(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct **ppsps;

   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   if (nrhs == 0)
   {
      /* Deleting all */

      if (!_pstreamInfo->pfirstStreamPage)
      {
         /* Nothing to delete */
         plhs[0] = mxCreateDoubleScalar(0);
         return true;
      }

      while (_pstreamInfo->pfirstStreamPage)
         freeStreamPageStruct(&_pstreamInfo->pfirstStreamPage);
   }
   else
   {
      /* Been supplied a argument */
      if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
            || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1))
      {

         plhs[0] = mxCreateDoubleScalar(0);
         return true;
      }

      /* Find the corresponding page */
      ppsps = &_pstreamInfo->pfirstStreamPage;

      while (*ppsps)
      {
         if ((*ppsps)->pageNum == (int)mxGetScalar(prhs[0]))
            break;

         ppsps = &(*ppsps)->pnextStreamPage;
      }

      if (!*ppsps)
      {
         /* page does not exist, so return immediately */
         plhs[0] = mxCreateDoubleScalar(0);
         return true;
      }

      freeStreamPageStruct(ppsps);
   }

   plhs[0] = mxCreateDoubleScalar(1);
   return true;
}

/*
 * FUNCTION:    doGetPlayrec(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.  The first element
 *              of prhs must also be valid and must point to an mxArray (the
 *              type of mxArray is checked).
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: Returns all recorded samples available for the page specified.
 *              The page required is identified by its page number, supplied as
 *              the first element of prhs.  An array is always returned in the
 *              first element of plhs, and if (nlhs >= 2) then an array is also
 *              returned in the second element of plhs.  The first of these
 *              contains the recorded data in an MxN array where M is the
 *              number of samples that have been recorded (if the page is
 *              currently being processed this will be the number of valid
 *              samples at the specific point in time) and N is the number
 *              of channels of data.  The second array is a 1xN array
 *              containing the channel number asssociated with each channel
 *              of data in the first array.  If the page requested does not
 *              exist, or contains no recorded data (either because there are
 *              no channels set to record, or because the page is waiting to be
 *              processed) then the array(s) returned are empty.
 *
 * TODO:
 */
bool doGetPlayrec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;
   ChanBufStruct *pcbs;
   ChanBufStruct *pcbsBoth[2];

   resample_error rerr = RESAMPLE_OK;
   SAMPLE *poutBuf;
   mxArray *mxRecChanList;
   mxArray *mxPlayChanList;
   unsigned int *pChanListBoth[2];
   unsigned int recSamples, recSamplesTmp;
   unsigned int channels[2];
   unsigned int recResPlanId = 0;
   unsigned int ii;

   /* SRC_DATA recData;*/

   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   /* Configure return values to defaults, and then change if necessary */
   plhs[0] = mxCreateNumericMatrix(0, 0, mxSAMPLE, mxREAL);
   if (nlhs > 1) plhs[1] = mxCreateNumericMatrix(0, 0, mxSAMPLE, mxREAL);
   if (nlhs > 2) plhs[2] = mxCreateNumericMatrix(0, 0, mxSAMPLE, mxREAL);

   /* No pages */
   if (!_pstreamInfo->pfirstStreamPage)
   {
      return true;
   }

   /* There must be one element on rhs before function is called */
   if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
         || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1)
         || (mxGetScalar(prhs[0]) != (int)mxGetScalar(prhs[0])))
   {

      return true;
   }

   /* Try and find requested stream. */
   psps = _pstreamInfo->pfirstStreamPage;

   while (psps)
   {
      if (psps->pageNum == (int)mxGetScalar(prhs[0]))
         break;

      psps = psps->pnextStreamPage;
   }

   if (!psps)
   {
      /* page does not exist, so return immediately */
      return true;
   }

   /* Found the required page */

   /* Determine the maximum number of samples recorded by finding the longest
    * buffer, and then limiting to how far through the page we currently are.
    * This allows for different length buffers in the future.
    */
   recSamples = 0;
   recSamplesTmp = 0;
   channels[0] = 0;
   channels[1] = 0;

   pcbsBoth[0] = psps->pfirstRecChan;
   pcbsBoth[1] = psps->pfirstPlayChan;

   pcbs = pcbsBoth[0];

   while (pcbs)
   {
      /* Check for valid buffer */
      if (pcbs->pbuffer && (pcbs->bufLen > 0))
      {
         recSamplesTmp = max(recSamples, pcbs->bufLen);
         channels[0]++;
      }
      pcbs = pcbs->pnextChanBuf;
   }

   pcbs = pcbsBoth[1];

   while (pcbs)
   {
      /* Check for valid buffer */
      if (pcbs->pbuffer && (pcbs->bufLen > 0))
      {
         channels[1]++;
      }
      pcbs = pcbs->pnextChanBuf;
   }

   if (rec_resplan)
   {
      /* We will do resampling */
      if (psps->pagePos != recSamplesTmp)
      {
         /* Page was not yet finished, do something harmless. */
         recSamples = (unsigned int) ( psps->pageLengthRec * psps->pagePos / ((double)recSamples));
      }
      else
      {
         recSamples = psps->pageLengthRec;
      }
   }
   else
   {
      recSamples = recSamplesTmp;
   }


   /* If there are no samples recorded, no need to continue */
   if ((recSamples == 0) || (channels[0] == 0) || (channels[1] == 0))
   {
      return true;
   }

   /* This initialises all elements to zero, so for shorter channels no
    * problems should arise. Although on exit MATLAB frees the arrays created
    * above, do so here for completeness
    */
   mxDestroyArray(plhs[0]);

   plhs[0] = mxCreateNumericMatrix(recSamples, channels[0] + channels[1], mxSAMPLE, mxREAL);
   poutBuf = (SAMPLE*)mxGetData(plhs[0]);

   /* Create the channel list, but only return it if its required */
   mxRecChanList = mxCreateNumericMatrix(1, channels[0], mxUNSIGNED_INT, mxREAL);
   mxPlayChanList = mxCreateNumericMatrix(1, channels[0], mxUNSIGNED_INT, mxREAL);
   pChanListBoth[0] = (unsigned int*)mxGetData(mxRecChanList);
   pChanListBoth[1] = (unsigned int*)mxGetData(mxPlayChanList);


   if (poutBuf && pChanListBoth[0] && pChanListBoth[1])
   {

      for (ii = 0; ii < 2; ii++)
      {
         pcbs = pcbsBoth[ii];

         /* Copy the data across, decrement recChannels to make sure
          * the end of the buffer isn't overwritten
          */
         while (pcbs && (channels[ii] > 0))
         {
            if (pcbs->pbuffer && (pcbs->bufLen > 0))
            {
               if (!rec_resplan)
               {
                  /* Do just a copy if no resampling should be done*/
                  memcpy(poutBuf, pcbs->pbuffer,
                         min(recSamples, pcbs->bufLen) * sizeof(SAMPLE));
               }
               else
               {
                  rerr = resample_execute(rec_resplan[recResPlanId],
                                          pcbs->pbuffer, pcbs->bufLen,
                                          poutBuf, recSamples);
                  if (rerr != RESAMPLE_OK)
                  {
                     mexWarnMsgTxt("Resampling returned an error. This should not happen.");
                  }

                  recResPlanId++;
               }

               poutBuf += recSamples;

               *pChanListBoth[ii]++ = pcbs->channel + 1;   /* Add 1 for base 1 channels */
               channels[ii]--;
            }
            pcbs = pcbs->pnextChanBuf;
         }
      }
   }

   if (nlhs > 1)
   {
      mxDestroyArray(plhs[1]);
      plhs[1] = mxPlayChanList;
   }
   if (nlhs > 2)
   {
      mxDestroyArray(plhs[22]);
      plhs[2] = mxRecChanList;
   }

   return true;
}
/*
 * FUNCTION:    doGetRec(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.  The first element
 *              of prhs must also be valid and must point to an mxArray (the
 *              type of mxArray is checked).
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: Returns all recorded samples available for the page specified.
 *              The page required is identified by its page number, supplied as
 *              the first element of prhs.  An array is always returned in the
 *              first element of plhs, and if (nlhs >= 2) then an array is also
 *              returned in the second element of plhs.  The first of these
 *              contains the recorded data in an MxN array where M is the
 *              number of samples that have been recorded (if the page is
 *              currently being processed this will be the number of valid
 *              samples at the specific point in time) and N is the number
 *              of channels of data.  The second array is a 1xN array
 *              containing the channel number asssociated with each channel
 *              of data in the first array.  If the page requested does not
 *              exist, or contains no recorded data (either because there are
 *              no channels set to record, or because the page is waiting to be
 *              processed) then the array(s) returned are empty.
 *
 * TODO:
 */
bool doGetRec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;
   ChanBufStruct *pcbs;

   resample_error rerr = RESAMPLE_OK;
   SAMPLE *poutBuf;
   mxArray *mxChanList;
   unsigned int *pRecChanList;
   unsigned int recSamples, recSamplesTmp;
   unsigned int recChannels;
   unsigned int recResPlanId = 0;

   /* SRC_DATA recData;*/

   validateState(BASIC_INIT | FULL_INIT, 0);

   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   /* Configure return values to defaults, and then change if necessary */
   plhs[0] = mxCreateNumericMatrix(0, 0, mxSAMPLE, mxREAL);
   if (nlhs >= 2)
      plhs[1] = mxCreateNumericMatrix(0, 0, mxSAMPLE, mxREAL);

   /* No pages */
   if (!_pstreamInfo->pfirstStreamPage)
   {
      return true;
   }

   /* There must be one element on rhs before function is called */
   if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])
         || (mxGetN(prhs[0]) != 1) || (mxGetM(prhs[0]) != 1)
         || (mxGetScalar(prhs[0]) != (int)mxGetScalar(prhs[0])))
   {

      return true;
   }

   /* Try and find requested stream. */
   psps = _pstreamInfo->pfirstStreamPage;

   while (psps)
   {
      if (psps->pageNum == (int)mxGetScalar(prhs[0]))
         break;

      psps = psps->pnextStreamPage;
   }

   if (!psps)
   {
      /* page does not exist, so return immediately */
      return true;
   }

   /* Found the required page */

   /* Determine the maximum number of samples recorded by finding the longest
    * buffer, and then limiting to how far through the page we currently are.
    * This allows for different length buffers in the future.
    */
   recSamples = 0;
   recSamplesTmp = 0;
   recChannels = 0;

   pcbs = psps->pfirstRecChan;

   while (pcbs)
   {
      /* Check for valid buffer */
      if (pcbs->pbuffer && (pcbs->bufLen > 0))
      {
         recSamplesTmp = max(recSamples, pcbs->bufLen);
         recChannels++;
      }
      pcbs = pcbs->pnextChanBuf;
   }


   if (rec_resplan)
   {
      /* We will do resampling */
      if (psps->pagePos != recSamplesTmp)
      {
         /* Page was not yet finished, do something harmless. */
         recSamples = (unsigned int) ( psps->pageLengthRec * psps->pagePos / ((double)recSamples));
      }
      else
      {
         recSamples = psps->pageLengthRec;
      }
   }
   else
   {
      recSamples = recSamplesTmp;
   }

   /* If there are no samples recorded, no need to continue */
   if ((recSamples == 0) || (recChannels == 0))
   {
      return true;
   }

   /* This initialises all elements to zero, so for shorter channels no
    * problems should arise. Although on exit MATLAB frees the arrays created
    * above, do so here for completeness
    */
   mxDestroyArray(plhs[0]);

   plhs[0] = mxCreateNumericMatrix(recSamples, recChannels, mxSAMPLE, mxREAL);
   poutBuf = (SAMPLE*)mxGetData(plhs[0]);

   /* Create the channel list, but only return it if its required */
   mxChanList = mxCreateNumericMatrix(1, recChannels, mxUNSIGNED_INT, mxREAL);
   pRecChanList = (unsigned int*)mxGetData(mxChanList);

   if (poutBuf && pRecChanList)
   {
      pcbs = psps->pfirstRecChan;

      /* Copy the data across, decrement recChannels to make sure
       * the end of the buffer isn't overwritten
       */
      while (pcbs && (recChannels > 0))
      {
         if (pcbs->pbuffer && (pcbs->bufLen > 0))
         {
            if (!rec_resplan)
            {
               /* Do just a copy if no resampling should be done*/
               memcpy(poutBuf, pcbs->pbuffer,
                      min(recSamples, pcbs->bufLen) * sizeof(SAMPLE));
            }
            else
            {
               rerr = resample_execute(rec_resplan[recResPlanId],
                                       pcbs->pbuffer, pcbs->bufLen,
                                       poutBuf, recSamples);
               if (rerr != RESAMPLE_OK)
               {
                  mexWarnMsgTxt("Resampling returned an error. This should not happen.");
               }

               recResPlanId++;
            }

            poutBuf += recSamples;

            *pRecChanList++ = pcbs->channel + 1;   /* Add 1 for base 1 channels */
            recChannels--;
         }
         pcbs = pcbs->pnextChanBuf;
      }
   }

   if (nlhs >= 2)
   {
      mxDestroyArray(plhs[1]);
      plhs[1] = mxChanList;
   }

   return true;
}

/*
 * FUNCTION:    doGetSampleRate(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first two elements of plhs.
 *              The first contains the suggested sample rate during initialisation
 *              and the second contains the current sample rate available from
 *              the hardware (if possible). Alternatively, -1 if the stream has
 *              not been initialised.
 *
 * TODO:
 */
bool doGetSampleRate(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   const PaStreamInfo *streamInfo;

   if (!_pstreamInfo)
   {
      plhs[0] = mxCreateDoubleScalar(-1);

      if (nlhs >= 2)
      {
         plhs[1] = mxCreateDoubleScalar(-1);
      }
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->suggestedSampleRate);

      if (nlhs >= 2)
      {
         streamInfo = Pa_GetStreamInfo(_pstreamInfo->pstream);
         if (streamInfo)
         {
            plhs[1] = mxCreateDoubleScalar(streamInfo->sampleRate);
         }
         else
         {
            plhs[1] = mxCreateDoubleScalar(-1);
         }
      }
   }
   return true;
}

/*
 * FUNCTION:    doGetFramesPerBuffer(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid and if (nlhs >= 2)
 *              then also the third element.
 *
 * Returns:     true
 *
 * Description: Returns double scalars in the first three elements of plhs
 *              containing the suggested value during initialisation and the minimum
 *              and maximum number of samples processed in any single callback.
 *              Alternatively, -1 if the stream has not been initialised.
 *
 * TODO:
 */
bool
doGetFramesPerBuffer(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo)
   {
      plhs[0] = mxCreateDoubleScalar(-1);

      if (nlhs >= 2)
      {
         plhs[1] = mxCreateDoubleScalar(-1);
      }

      if (nlhs >= 3)
      {
         plhs[2] = mxCreateDoubleScalar(-1);
      }
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->suggestedFramesPerBuffer);

      if (nlhs >= 2)
      {
         plhs[1] = mxCreateDoubleScalar(_pstreamInfo->minFramesPerBuffer);
      }

      if (nlhs >= 3)
      {
         plhs[2] = mxCreateDoubleScalar(_pstreamInfo->maxFramesPerBuffer);
      }
   }
   return true;
}

/*
 * FUNCTION:    doGetStreamStartTime((int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the unix time (number of seconds since the standard epoch of
 *              1/1/1970) for when the current stream was started, or -1 if the
 *              stream has not been initialised.  This can be used as an
 *              identifying value for the stream, to help keep track of what
 *              data was recorded using each stream (ie all recordings with the
 *              same stream start time must have been recorded at the same
 *              sample rate using the same device(s)).
 *
 * TODO:
 */
bool
doGetStreamStartTime(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo)
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar((double)_pstreamInfo->streamStartTime);
      /* mexPrintf("%s\n", asctime(localtime(&_pstreamInfo->streamStartTime))); */
   }
   return true;
}

/*
 * FUNCTION:    doGetPlayDevice(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the ID of the current play device, or -1 if either the stream
 *              has not been initialised or it was initialised with no play
 *              device.
 *
 * TODO:
 */
bool doGetPlayDevice(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo || (_pstreamInfo->playDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->playDeviceID);
   }
   return true;
}

/*
 * FUNCTION:    doGetRecDevice(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the ID of the current record device, or -1 if either the stream
 *              has not been initialised or it was initialised with no record
 *              device.
 *
 * TODO:
 */
bool doGetRecDevice(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo || (_pstreamInfo->recDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->recDeviceID);
   }
   return true;
}

/*
 * FUNCTION:    doGetPlayMaxChannel(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the maximum number of play channels, or -1 if either the stream
 *              has not been initialised or it was initialised with no play
 *              device.
 *
 * TODO:
 */
bool
doGetPlayMaxChannel(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo || (_pstreamInfo->playDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->playChanCount);
   }
   return true;
}

/*
 * FUNCTION:    doGetRecMaxChannel(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the maximum number of record channels, or -1 if either the stream
 *              has not been initialised or it was initialised with no record
 *              device.
 *
 * TODO:
 */
bool
doGetRecMaxChannel(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo || (_pstreamInfo->recDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->recChanCount);
   }
   return true;
}

/*
 * FUNCTION:    doGetPlayLatency(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.  All other inputs
 *              are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs with
 *              the latency used during initialisation. The second element
 *              contains the actual latency for the play device, or -1 if
 *              either the stream has not been initialised or it was
 *              initialised with no play device.
 *
 * TODO:
 */
bool
doGetPlayLatency(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   const PaStreamInfo *streamInfo;

   if (!_pstreamInfo || (_pstreamInfo->playDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);

      if (nlhs >= 2)
      {
         plhs[1] = mxCreateDoubleScalar(-1);
      }
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->playSuggestedLatency);

      if (nlhs >= 2)
      {
         streamInfo = Pa_GetStreamInfo(_pstreamInfo->pstream);
         if (streamInfo)
         {
            plhs[1] = mxCreateDoubleScalar(streamInfo->outputLatency);
         }
         else
         {
            plhs[1] = mxCreateDoubleScalar(-1);
         }
      }
   }

   return true;
}

/*
 * FUNCTION:    doGetRecLatency(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.  All other inputs
 *              are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs with
 *              the latency used during initialisation. The second element
 *              contains the actual latency for the record device, or -1 if
 *              either the stream has not been initialised or it was
 *              initialised with no record device.
 *
 * TODO:
 */
bool doGetRecLatency(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   const PaStreamInfo *streamInfo;

   if (!_pstreamInfo || (_pstreamInfo->recDeviceID == paNoDevice))
   {
      plhs[0] = mxCreateDoubleScalar(-1);

      if (nlhs >= 2)
      {
         plhs[1] = mxCreateDoubleScalar(-1);
      }
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->recSuggestedLatency);

      if (nlhs >= 2)
      {
         streamInfo = Pa_GetStreamInfo(_pstreamInfo->pstream);
         if (streamInfo)
         {
            plhs[1] = mxCreateDoubleScalar(streamInfo->inputLatency);
         }
         else
         {
            plhs[1] = mxCreateDoubleScalar(-1);
         }
      }
   }

   return true;
}

/*
 * FUNCTION:    doGetPageList(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a 1xN array of unsigned integers in the first element
 *              of plhs.  The array contains the page numbers of all pages
 *              resident in memory, arranged chronologically from the earliest
 *              to latest addition.  As such, the lenght of the array, N, is
 *              the number of pages currently resident in memory.
 *
 * TODO:
 */
bool doGetPageList(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;
   unsigned int *ppageList;
   unsigned int pageCount = 0;

   /* Not initialised or no pages */
   if (!_pstreamInfo || !_pstreamInfo->pfirstStreamPage)
   {
      plhs[0] = mxCreateNumericMatrix(1, 0, mxUNSIGNED_INT, mxREAL);
      return true;
   }

   psps = _pstreamInfo->pfirstStreamPage;

   while (psps)
   {
      pageCount++;
      psps = psps->pnextStreamPage;
   }

   plhs[0] = mxCreateNumericMatrix(1, pageCount, mxUNSIGNED_INT, mxREAL);

   ppageList = (unsigned int*)mxGetData(plhs[0]);

   if (ppageList)
   {
      psps = _pstreamInfo->pfirstStreamPage;

      /* Copy the data across.
       * Decrement pageCount incase another item has been added simultaneously
       */
      while (psps && (pageCount > 0))
      {
         pageCount--;
         *ppageList++ = psps->pageNum;
         psps = psps->pnextStreamPage;
      }
   }

   return true;
}

/*
 * FUNCTION:    doGetCurrentPosition(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The first element of plhs is always used and so must be valid
 *              (this is not checked).  Additionally, if (nlhs >= 2) then the
 *              second element of plhs must also be valid.  All other inputs
 *              are not used or verified.
 *
 * Returns:     true
 *
 * Description: Always returns a double scalar in the first element of plhs
 *              containing the page number of the current page being processed.
 *              If there is no page currently being processed (there are no
 *              pages, or all pages are finished) then the returned page number
 *              is -1.  If (nlhs >= 2) then a double scalar in the second
 *              element of plhs is also returned.  This represents the current
 *              sample number within the current page, or -1 if there is no
 *              current page.
 *
 * TODO:
 */
bool
doGetCurrentPosition(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;

   if (!_pstreamInfo || !_pstreamInfo->pfirstStreamPage)
   {
      plhs[0] = mxCreateDoubleScalar(-1);
      if (nlhs >= 2)
         plhs[1] = mxCreateDoubleScalar(-1);
      return true;
   }

   psps = _pstreamInfo->pfirstStreamPage;

   while (psps->pnextStreamPage && psps->pageFinished)
      psps = psps->pnextStreamPage;

   if (!psps->pnextStreamPage && psps->pageFinished)
   {
      /* The last stream page is finished, so there is no current page */
      plhs[0] = mxCreateDoubleScalar(-1);
      if (nlhs >= 2)
         plhs[1] = mxCreateDoubleScalar(-1);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(psps->pageNum);
      if (nlhs >= 2)
         plhs[1] = mxCreateDoubleScalar(psps->pagePos);
   }
   return true;
}

/*
 * FUNCTION:    doGetLastFinishedPage(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the page number of the last finished page still resident in
 *              memory (ie pages that have not been deleted either
 *              automatically during page condensing or through a call to
 *              delPage). If there are no finished pages resident in memory
 *              then the returned page number is -1.
 *
 * TODO:
 */
bool
doGetLastFinishedPage(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   StreamPageStruct *psps;
   unsigned int finishedPage;

   /* Check there is at least one finished page */
   if (!_pstreamInfo || !_pstreamInfo->pfirstStreamPage ||
         !_pstreamInfo->pfirstStreamPage->pageFinished)
   {
      plhs[0] = mxCreateDoubleScalar(-1);
      return true;
   }

   /* To get here the first page is finished */
   finishedPage = _pstreamInfo->pfirstStreamPage->pageNum;
   psps = _pstreamInfo->pfirstStreamPage->pnextStreamPage;

   while (psps && psps->pageFinished)
   {
      finishedPage = psps->pageNum;
      psps = psps->pnextStreamPage;
   }

   plhs[0] = mxCreateDoubleScalar(finishedPage);
   return true;
}

/*
 * FUNCTION:    doReset(int nlhs, mxArray *plhs[],
 *                       int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              No inputs are used or verified.
 *
 * Returns:     true, or aborts with an error if not in full initialisation
 *              state.
 *
 * Description: Resets the utility to the basic initialisation state,
 *              including deleting all pages and stopping the PortAudio stream.
 *
 * TODO:
 */
bool doReset(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   validateState(BASIC_INIT | FULL_INIT, 0);

   /* Should not get here if _pstreamInfo is null */
   if (!_pstreamInfo)
   {
      mexErrMsgTxt("An error has occurred - in full initialisation yet "
                   "_pstreamInfo is NULL.");
   }

   /* freeing the stream info structure also closes the stream */
   freeStreamInfoStruct(&_pstreamInfo);

   CLEARSTATE(FULL_INIT);
   return true;
}

/*
 * FUNCTION:    doGetDevices(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true, or aborts with an error if not in basic initialisation
 *              state
 *
 * Description: Returns a 1xN struct array as the first element of plhs,
 *              containing the name, ID and number of input and output channels
 *              for all availables devices.
 *
 * TODO:
 */
bool doGetDevices(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   const char *fieldNames[] = {"deviceID", "name",
                               "hostAPI", "defaultLowInputLatency",
                               "defaultLowOutputLatency",
                               "defaultHighInputLatency",
                               "defaultHighOutputLatency",
                               "defaultSampleRate",
                               "supportedSampleRates",
                               "inputChans", "outputChans"
                              };

   const double samplingRates[] = { 8000.0, 11025.0, 16000.0, 22050.0,
                                    32000.0, 44100.0, 48000.0, 88200.0,
                                    96000.0, 192000.0
                                  };
   const int numSamplingRates = sizeof(samplingRates) / sizeof(samplingRates[0]);

   const PaDeviceInfo *pdi;
   PaDeviceIndex i;
   int ii;
   int numDevices;

   validateState(BASIC_INIT, 0);

   numDevices = Pa_GetDeviceCount();

   if ( numDevices < 0 )
   {
      mexPrintf( "PortAudio Error, Pa_CountDevices returned 0x%x\n",
                 numDevices );
   }

   plhs[0] = mxCreateStructMatrix(1, numDevices,
                                  sizeof(fieldNames) / sizeof(char*), fieldNames);

   for ( i = 0; i < numDevices; i++)
   {
      pdi = Pa_GetDeviceInfo(i);

      if (pdi != NULL)
      {
         mxSetField(plhs[0], i, "deviceID", mxCreateDoubleScalar(i));
         mxSetField(plhs[0], i, "name", mxCreateString(pdi->name));
         mxSetField(plhs[0], i, "hostAPI",
                    mxCreateString(Pa_GetHostApiInfo( pdi->hostApi )->name));
         mxSetField(plhs[0], i, "defaultLowInputLatency",
                    mxCreateDoubleScalar(pdi->defaultLowInputLatency));
         mxSetField(plhs[0], i, "defaultLowOutputLatency",
                    mxCreateDoubleScalar(pdi->defaultLowOutputLatency));
         mxSetField(plhs[0], i, "defaultHighInputLatency",
                    mxCreateDoubleScalar(pdi->defaultHighInputLatency));
         mxSetField(plhs[0], i, "defaultHighOutputLatency",
                    mxCreateDoubleScalar(pdi->defaultHighOutputLatency));
         mxSetField(plhs[0], i, "defaultSampleRate",
                    mxCreateDoubleScalar(pdi->defaultSampleRate));
         mxSetField(plhs[0], i, "inputChans",
                    mxCreateDoubleScalar(pdi->maxInputChannels));
         mxSetField(plhs[0], i, "outputChans",
                    mxCreateDoubleScalar(pdi->maxOutputChannels));
         /*
          * This is a workaround how to obtain list of supported sampling
          * frequencies. Only the ones in the samplingRates array are
          * tested. The device might be actually capabe of more.
          * */
         PaStreamParameters* dummyIn;
         PaStreamParameters* dummyOut;
         if (pdi->maxInputChannels > 0)
         {
            dummyIn = calloc(1, sizeof(PaStreamParameters));
            dummyIn->device = i;
            dummyIn->channelCount = pdi->maxInputChannels;
            dummyIn->sampleFormat = paFloat32;
         }
         else
         {
            dummyIn = NULL;
         }
         if (pdi->maxOutputChannels > 0)
         {
            dummyOut = calloc(1, sizeof(PaStreamParameters));
            dummyOut->device = i;
            dummyOut->channelCount = pdi->maxOutputChannels;
            dummyOut->sampleFormat = paFloat32;
         }
         else
         {
            dummyOut = NULL;
         }
         int numSupSampRates = 0;
         double supSampRates[numSamplingRates];
         for (ii = 0; ii < numSamplingRates; ii++)
         {
            if (!Pa_IsFormatSupported(dummyIn, dummyOut,
                                      samplingRates[ii]))
            {
               supSampRates[numSupSampRates++] = samplingRates[ii];
            }
         }

         if (dummyIn != NULL)
            free(dummyIn);
         if (dummyOut != NULL)
            free(dummyOut);

         mxArray* mxSubSampRates =
            mxCreateDoubleMatrix(1, numSupSampRates, mxREAL);
         memcpy(mxGetData(mxSubSampRates), supSampRates,
                numSupSampRates * sizeof(double));

         mxSetField(plhs[0], i, "supportedSampleRates", mxSubSampRates);


      }
   }

   return true;
}

/*
 * FUNCTION:    doGetSkippedSampleCount(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              The only input used is the first element of plhs, which must
 *              be a valid array with at least one element (this is not
 *              checked).  All other inputs are not used or verified.
 *
 * Returns:     true
 *
 * Description: Returns a double scalar in the first element of plhs containing
 *              the number of samples that have occurred whilst there are no new
 *              pages in the pageList, or -1 if either the stream
 *              has not been initialised.
 *
 * TODO:
 */
bool doGetSkippedSampleCount(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

   if (!_pstreamInfo)
   {
      plhs[0] = mxCreateDoubleScalar(-1);
   }
   else if (_pstreamInfo->resetSkippedSampleCount)
   {
      plhs[0] = mxCreateDoubleScalar(0);
   }
   else
   {
      plhs[0] = mxCreateDoubleScalar(_pstreamInfo->skippedSampleCount);
   }
   return true;
}

/*
 * FUNCTION:    doResetSkippedSampleCount(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              No inputs are used or verified.
 *
 * Returns:     true
 *
 * Description: Resets the skipped sample count to zero.
 *
 * TODO:
 */
bool doResetSkippedSampleCount(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   if (!_pstreamInfo)
   {
      return true;
   }

   _pstreamInfo->resetSkippedSampleCount = true;

   return true;
}

/*
 * FUNCTION:    doAbout(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              No inputs are used or verified.
 *
 * Returns:     true
 *
 * Description: Outputs as either a argument or to the command window information
 *              about the version of playrec.
 *
 * TODO:
 */
bool doAbout(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   static const char *aboutString =

      "Playrec is a Matlab utility (MEX file) that provides simple yet versatile access to \
soundcards using PortAudio, a free, open-source audio I/O library. It can be used on \
different platforms (Windows, Macintosh, Unix) and access the soundcard via different \
host API including ASIO, WMME and DirectSound under Windows.\n\n\
A list of all commands implemented by the utility can be obtained by calling playrec \
with no arguments.  A basic outline of how to use this utility is provided by typing \
'overview' as the first argument.  For more information on any command type 'help' as \
the first argument followed by the command of interest as the second argument.\n\n\
This utility was initially written as part of a Robert Humphrey's MEng project for \
The University of York, UK, in 2006. This was undertaken at TMH (Speech, Music and \
Hearing) at The Royal Institute of Technology (KTH) in Stockholm and was funded by \
The Swedish Foundation for International Cooperation in Research and Higher Education \
(STINT). The project was titled Automatic Speaker Location Detection for use in \
Ambisonic Systems.\n\n\
ASIO is a trademark and software of Steinberg Media Technologies GmbH\n\n\
Version: " VERSION "\nDate: " DATE "\nAuthor: " AUTHOR "\nCompiled on: "
      __DATE__ " at " __TIME__ "\nBuilt with defines: "

#ifdef CASE_INSENSITIVE_COMMAND_NAME
      "CASE_INSENSITIVE_COMMAND_NAME, "
#endif
#ifdef DEBUG
      "DEBUG, "
#endif

      "\nAvailable host API: ";

   PaHostApiIndex apiCount = Pa_GetHostApiCount();
   PaHostApiIndex i;
   const PaHostApiInfo *apiInfo;

   int bufLen = strlen(aboutString);

   char *buffer, *write_point;

   /* Calculate required buffer length, being over generous to avoid problems */
   for (i = 0; i < apiCount; i++)
   {
      apiInfo = Pa_GetHostApiInfo(i);
      bufLen += strlen(apiInfo->name) + 20;
   }

   buffer = mxCalloc( bufLen + 20, sizeof( char ));

   if ( buffer )
   {
      write_point = buffer;

      strcpy(write_point, aboutString);
      write_point += strlen(aboutString);

      for (i = 0; i < apiCount; i++)
      {
         apiInfo = Pa_GetHostApiInfo(i);
         write_point += sprintf(write_point, "%s (%d devices), ", apiInfo->name, apiInfo->deviceCount);
      }

      *write_point = '\0';

      if (nlhs < 1)
      {
         linewrapString(buffer, SCREEN_CHAR_WIDTH, 0, 0, SCREEN_TAB_STOP);
      }
      else
      {
         plhs[0] = mxCreateString(buffer);
      }
      /* No need to free memory here as execution will always stop at the error */
   }
   else
   {
      mexErrMsgTxt( "Error allocating memory in doAbout" );
   }

   return true;
}

/*
 * FUNCTION:    doOverview(int nlhs, mxArray *plhs[],
 *                      int nrhs, const mxArray *prhs[])
 *
 * Inputs:      nlhs - number of mexFunction output arguments
 *              plhs - pointer to array of mexFunction output arguments
 *              nrhs - number of mexFunction input arguments
 *              prhs - pointer to array of mexFunction input arguments
 *
 *              No inputs are used or verified.
 *
 * Returns:     true
 *
 * Description: Outputs as either a argument or to the command window an
 *              overview of how to use playrec.
 *
 * TODO:
 */
bool doOverview(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   /* To do this line wrapping quickly can use "^(.{1,90} )" and "\1\\\n" as
      find and replace regular expressions in Textpad */
   static const char *overviewString =
      "This page provides a basic outline of how to use the Playrec utility. More information \
on any command can be found by using \"playrec('help', 'command_name')\" or simply \
\"playrec help command_name\".\n\n"
      "To simplify operation, all functionality is accessed through one function in Matlab.  \
To achieve this the first argument in the function call is always the name of the \
command/operation required, eg \"playrec('getDevices')\" or \"playrec('isInitialised')\". \
If additional arguments are required then they are specified after this, eg \
\"playrec('init', 48000, 1, -1)\". A list of all available commands can be displayed by \
supplying no arguments.\n\n"
      "Before any audio can be played or recorded, the utility must be initialised to use the \
required sample rate and device(s).  Initialisation is achieved using the \"init\" \
command, supplying the ID of the required audio device(s) as returned by \"getDevices\". \
Once successfully initialised, the sample rate or device(s) to be used cannot be changed \
without first resetting the utility using the \"reset\" command.  This clears all \
previously recorded data so use it with care. To check if the utility is currently \
initialised, use the \"isInitialised\" command.\n\n"
      "The utility divides time up into pages with no restrictions on the duration of any one \
page, although with very short pages skipping in the audio may occur if they cannot be \
supplied fast enough. There can be as many pages as required provided the utility can \
allocate enough memory. Pages are joined together sequentially in the order they are \
added, with each page starting the sample after the previous page finishes.  A page can \
contain samples that are to be output on one or more channels and buffers to store \
recorded samples on one or more channels.  The duration of a page is determined by the \
longest channel contained within the page.  Therefore if, for example, the record channels \
are 1000 samples long whilst output channels are only 900 samples long, the page will be \
1000 samples long and the final 100 output samples of the page will automatically be set \
to 0.\n\n"
      "When each page is added, the channels that are to be used for recording and/or output are \
specified (depending on the command used to add the page).  The channels used must be \
within the range specified during initialisation and no channel can be duplicated within a \
channel list.  Within these limits, the channel list for each page can be different and \
each list can contain as many or as few channels as required in any order.  All output \
channels not provided with any data within a page will output 0 for the duration of the \
page.  Similarly, during any times when there are no further pages to process 0 will be \
output on all channels.\n\n"
      "Each page has a unique number which is returned by any of the commands used to add pages \
(\"playrec\", \"play\" or \"rec\").  When a page is added, the utility does not wait until \
the page has completed before returning.  Instead, the page is queued up and the page \
number can then be used to check if the page has finished, using \"isFinished\".  \
Alternatively a blocking command, \"block\", can be used to wait until the page has \
finished.  To reduce the amount of memory used, finished pages are automatically condensed \
whenever any command is called in the utility.  If a page contains any recorded data, this \
is left untouched although any output data within the page is removed.  If the page does \
not contain any recorded data, the whole page is deleted during this page condensing.  For \
this reason if either \"isFinished\", \"block\" or \"delPage\" indicate the page number is \
invalid this means the page either never existed or has already finished and then been \
deleted during page condensing.\n\n"
      "For pages containing recorded data, the data can be accessed using the \"getRec\" command \
once the page is finished (indicating the recording has completed).  This does not delete \
the data so it can be accessed as many times as required.  To delete the recorded data, \
the whole page must be deleted using the \"delPage\" command.  This command will delete \
pages nomatter what their current state: waiting to start, currently active or finished.  \
If no page number is supplied, all pages will be deleted, again regardless of their state \
so use with care.\n\n"
      "To ascertain which pages are still left in memory, the \"getPageList\" command can be \
used, returning a list of the pages in chronological order.  NOTE: there may have been \
gaps of silence or other pages between consecutive pages in this list due to pages either \
being automatically or explicitly deleted as detailed above.  To determine if there were \
gaps between pages due to all pages finishing processing before new ones are added, the \
commands \"getSkippedSampleCount\" and \"resetSkippedSampleCount\" can be used.\n\n"
      "The page that is currently being output is returned by \"getCurrentPosition\", along with \
an approximate sample position within the page.  Additionally, the page number of the last \
completed page still resident in memory is returned by \"getLastFinishedPage\".  NOTE: \
this might not be the most recent page to finish if that page has been deleted either \
during page condensing (ie contained no recorded data) or through the use of \"delPage\".\n\n"
      "Finally, the utility can be paused and resumed using the \"pause\" command.  This will \
manipulate all output and recording channels simultaneously to ensure synchronisation is \
always maintained.  This command can also be used to ascertain if the utility is currently \
running or paused.";

   if (nlhs < 1)
   {
      linewrapString(overviewString, SCREEN_CHAR_WIDTH, 0, 0, SCREEN_TAB_STOP);
   }
   else
   {
      plhs[0] = mxCreateString(overviewString);
   }

   return true;
}
#endif
