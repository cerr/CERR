#ifndef _circularbuf_private_h
#define _circularbuf_private_h

struct LTFAT_NAME(analysis_fifo_state)
{
    ltfat_int winLen; //!< Window length
    ltfat_int readchanstride; //!< Window length
    ltfat_int hop; //!< Hop size
    LTFAT_REAL* buf; //!< Ring buffer array
    ltfat_int bufLen; //!< Length of the previous
    ltfat_int readIdx; //!< Read pos.
    ltfat_int writeIdx; //!< Write pos.
    ltfat_int numChans;
};

struct LTFAT_NAME(synthesis_fifo_state)
{
    ltfat_int winLen; //!< Window length
    ltfat_int writechanstride; //!< Window length
    ltfat_int hop; //!< Hop size
    LTFAT_REAL* buf; //!< Ring buffer array
    ltfat_int bufLen; //!< Length of the previous
    ltfat_int readIdx; //!< Read pos.
    ltfat_int writeIdx; //!< Write pos.
    ltfat_int numChans;
};

struct LTFAT_NAME(block_processor_state)
{
    LTFAT_NAME(block_processor_callback)*
    processorCallback; //!< Custom processor callback
    void* userdata; //!< Callback data
    LTFAT_NAME(analysis_fifo_state)* fwdfifo;
    LTFAT_NAME(synthesis_fifo_state)* backfifo;
    ltfat_int bufLenMax;
    LTFAT_REAL* prebuf;
    LTFAT_REAL* postbuf;
    LTFAT_REAL* prewin;
    LTFAT_REAL* postwin;
    int freeBuffers;
    const LTFAT_REAL** inTmp;
    LTFAT_REAL** outTmp;
    size_t in_pos;
    size_t out_pos;
    double in_in_out_offset;
    double out_in_in_offset;
    ltfat_int prehop;
    ltfat_int posthop;
};

#endif
