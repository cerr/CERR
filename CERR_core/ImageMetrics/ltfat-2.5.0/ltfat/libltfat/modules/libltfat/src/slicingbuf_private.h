struct LTFAT_NAME(slicing_processor_state)
{
    LTFAT_NAME(slicing_processor_callback)*
    processorCallback; //!< Custom processor callback
    void* userdata; //!< Callback data
    LTFAT_NAME(block_processor_state)* block_processor;
    LTFAT_REAL* bufIn;
    LTFAT_REAL* bufOut;
    LTFAT_REAL* bufIn_start;
    LTFAT_REAL* bufOut_start;
    ltfat_int  winLen;
    ltfat_int taperLen;
    ltfat_int zpadLen;
    LTFAT_REAL* ga;
    LTFAT_REAL* gs;

};

