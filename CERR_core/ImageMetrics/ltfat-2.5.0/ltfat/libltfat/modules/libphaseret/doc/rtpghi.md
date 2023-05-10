\defgroup rtpghi Real-Time Phase Gradient Heap Integration
\addtogroup rtpghi

Algorithm Description
---------------------

The implementation follows paper \cite ltfatnote043

The \a gamma parameter for a window \f$ g\f$ can be computed as
\f[
\gamma = C_g (\mathit{gl})^2
\f]
where \a gl is a window length.

FIR window                                   |   \f$ C_g \f$
---------------------------------------------|--------------
LTFAT_HANN, LTFAT_HANNING, NUTTALL10         | 0.25645
LTFAT_SQRTHANN, LTFAT_COSINE, LTFAT_SINE     | 0.41532
LTFAT_HAMMING                                | 0.29794
LTFAT_NUTTALL01                              | 0.29610
LTFAT_TRIA, LTFAT_TRIANGULAR, LTFAT_BARTLETT | 0.27561
LTFAT_SQRTTRIA                               | 0.48068
LTFAT_BLACKMAN                               | 0.17954
LTFAT_BLACKMAN2                              | 0.18465
LTFAT_NUTTALL, LTFAT_NUTTALL12               | 0.12807
LTFAT_OGG, LTFAT_ITERSINE                    | 0.35744
LTFAT_NUTTALL20                              | 0.14315
LTFAT_NUTTALL11                              | 0.17001
LTFAT_NUTTALL02                              | 0.18284
LTFAT_NUTTALL30                              | 0.09895
LTFAT_NUTTALL21                              | 0.11636
LTFAT_NUTTALL03                              | 0.13369

For \gamma for a Gaussian window please see \cite ltfatnote043

The Gaussian window will give the best result. 
LTFAT_BLACKMAN is also a good choice.





