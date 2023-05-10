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

#ifndef PA_DLL_PLAYREC_H
#define PA_DLL_PLAYREC_H

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

#include <time.h>
#include "mex.h"
#include "portaudio.h"
#include "config.h"
#include "ltfatresample.h"

#define VERSION "2.1.0"
#define DATE "15 April 2008"
#define AUTHOR "Robert Humphrey"

/* The mx class equivalent to unsigned int */
#define mxUNSIGNED_INT mxUINT32_CLASS

/* The mx class equivalent to SAMPLE */
#define mxSAMPLE    mxSINGLE_CLASS

/* Format to be used for samples with PortAudio = 32bit */
// typedef float SAMPLE; // Already done in config.h

/* Structure to contain 'human readable' advice for each state */
typedef struct {
    int num;            /* State numerical representation (single bit set) */
    char *name;         /* Name used to textually refer to the state */
    char *startString;  /* String providing advice on how to start the state */
                        /* if it is not currently active but is required */
    char *stopString;   /* String providing advice on how to clear the state */
                        /* if it is currently active and shouldn't be */
} StateOptsStruct;

/* Structure to contain all the per-channel data for one 'page' */
typedef struct ChanBufStruct_tag {
    SAMPLE *pbuffer;                    /* The channel audio data */
    unsigned int bufLen;                /* Length of the audio buffer */
    unsigned int channel;               /* Channel number on the audio device */
                                        /* that this buffer is associated with */
                                        /* (first channel = 0) */
    struct ChanBufStruct_tag *pnextChanBuf; /* Pointer to the next channel */
                                        /* buffer in the linked list.  The */
                                        /* order of buffers in the linked list */
                                        /* is the order of 'channel' data */
                                        /* received from and returned to MATLAB */
} ChanBufStruct;

/* Structure to organise 'pages' */
typedef struct StreamPageStruct_tag {
    ChanBufStruct *pfirstRecChan;   /* First record channel within this page */
    ChanBufStruct *pfirstPlayChan;  /* First play channel within the page */

    unsigned int pageLength;        /* The maximum length of a channel in this page */
    unsigned int pageLengthRec;    /* The max. length of a chan. before resampling */
    volatile unsigned int pagePos;  /* The current position within the page */
    unsigned int pageNum;           /* A unique id to identify the page */

    unsigned int playChanCount;     /* The number of channels used to communicate */
                                    /* with PortAudio.  Must be greater than */
                                    /* the maximum channel number used. */
    bool *pplayChansInUse;          /* Pointer to array type bool, size playChanCount. */
                                    /* Each element can be: */
                                    /* true - the channel is in the play linked list */
                                    /* false - the channel is not in linked list */
                                    /* Setting false means that the channel is set */
                                    /* to all zeros within the callback.  Any channels */
                                    /* not included in this list (or set true) must */
                                    /* be included in the play channel linked list. */

    volatile bool pageUsed;         /* Set true in if the page has been used in the */
                                    /* PortAudio callback function */
    volatile bool pageFinished;     /* True if the page has been finished (all record */
                                    /* buffers full and all playout buffers 'empty') */
                                    /* Once set, this and pnextStreamPage are the */
                                    /* only variables the PortAudio callback will check */
                                    /* (none are written) */
    struct StreamPageStruct_tag *pnextStreamPage;
                                    /* The next page in the linked list */
} StreamPageStruct;


/* The top level structure used to organise the stream and all data associated */
/* with it.  If more than one stream is required simultaneously use multiple */
/* StreamInfoStruct's with one per stream.  Provided some way to indicate */
/* which stream to use is added to the commands, each stream should be able to */
/* run completely independantly with only very little work. */
/* For example, have a linked list containing all StreamInfoStruct's and then */
/* a global variable pointing to the one in use.  An additional command would */
/* be required to select which stream all other commands refer to, and doInit, */
/* doReset and mexFunctionCalled would need to be modified slightly, but apart */
/* from that everything else should be able to remain the same. */
typedef struct {
    StreamPageStruct *pfirstStreamPage;
                                    /* First page in the linked list */

    PaStream *pstream;              /* Pointer to the stream, or NULL for no stream */

    time_t streamStartTime;         /* The start time of the stream, can be used to */
                                    /* detemine if a new stream has been started. */

    /* Configuration settings used when opening the stream - see Pa_OpenStream */
    /* in portaudio.h for descriptions of these parameters: */
    double suggestedSampleRate;

    unsigned long suggestedFramesPerBuffer;
    unsigned long minFramesPerBuffer;
    unsigned long maxFramesPerBuffer;

    PaTime        recSuggestedLatency;
    PaTime        playSuggestedLatency;

    PaStreamFlags streamFlags;

    volatile bool stopStream;       /* Set true to trigger the callback to stop the */
                                    /* stream. */

    volatile bool inCallback;       /* Set true whilst in the callback. */

    volatile unsigned long skippedSampleCount;
                                    /* The number of samples that have been zeroed */
                                    /* whilst there are no unfinished pages in the */
                                    /* linked list.  Should only be modified in */
                                    /* the callback.  Use resetSkippedSampleCount */
                                    /* to reset the counter. */
                                    /* If resetSkippedSampleCount is true the value */
                                    /* of skippedSampleCount should be ignored and */
                                    /* instead assumed to be 0. */
    volatile bool resetSkippedSampleCount;
                                    /* Set true to reset skippedSampleCount.  The reset */
                                    /* takes place within the callback, at which point */
                                    /* this is cleared.  This is to ensure it does always */
                                    /* get cleared. */

    volatile bool isPaused;         /* set true to 'pause' playback and recording */
                                    /* Never stops the PortAudio stream, just alters */
                                    /* the data transferred. */

    PaDeviceIndex playDeviceID;     /* Device ID for the device being used, or */
                                    /* PaNoDevice for no device */
    PaDeviceIndex recDeviceID;      /* Device ID for the device being used, or */
                                    /* PaNoDevice for no device */
    unsigned int playChanCount;     /* The number of channels used to communicate */
                                    /* with PortAudio.  Must be greater than */
                                    /* the maximum channel number used. */
    unsigned int recChanCount;      /* The number of channels used to communicate */
                                    /* with PortAudio.  Must be greater than */
                                    /* the maximum channel number used. */
} StreamInfoStruct;

/* Function prototypes */

SAMPLE *convDouble(double *oldBuf, int buflen);
SAMPLE *convFloat(float *oldBuf, int buflen);

void validateState(int wantedStates, int rejectStates);

void freeChanBufStructs(ChanBufStruct **ppcbs);
void freeStreamPageStruct(StreamPageStruct **ppsps);
void freeStreamInfoStruct(StreamInfoStruct **psis);

StreamInfoStruct *newStreamInfoStruct(bool makeMemoryPersistent);

StreamPageStruct *addStreamPageStruct(StreamInfoStruct *psis, StreamPageStruct *psps);
StreamPageStruct *newStreamPageStruct(unsigned int portAudioPlayChanCount, bool makeMemoryPersistent);

static int playrecCallback(const void *inputBuffer, void *outputBuffer,
                           unsigned long frameCount,
                           const PaStreamCallbackTimeInfo *timeInfo,
                           PaStreamCallbackFlags statusFlags, void *userData );

bool mexFunctionCalled(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void condensePages(void);

void exitFunc(void);
PaError checkPAErr(PaError err);
void abortIfPAErr(const char* msg);

bool channelListToChanBufStructs(const mxArray *pmxChanArray, ChanBufStruct **ppfirstcbs, unsigned int minChanNum, unsigned int maxChanNum, bool makeMemoryPersistent);

bool addPlayrecPage(mxArray **ppmxPageNum, const mxArray *pplayData, const mxArray *pplayChans, const mxArray *precDataLength, const mxArray *precChans);

/* all 'do' functions return true if all input arguments are valid, otherwise */
/* false (triggering display of the list of valid arguments) */
bool doAbout(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doOverview(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doInit(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doPlayrec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doPlay(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doRec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetRec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetPlayrec(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetSampleRate(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetFramesPerBuffer(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetStreamStartTime(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetPlayDevice(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetRecDevice(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetPlayMaxChannel(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetRecMaxChannel(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetPlayLatency(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetRecLatency(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetPageList(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetCurrentPosition(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetLastFinishedPage(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doPause(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doBlock(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doIsFinished(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doIsInitialised(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doDelPage(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doReset(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetDevices(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doGetSkippedSampleCount(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
bool doResetSkippedSampleCount(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* PA_DLL_PLAYREC_H */
