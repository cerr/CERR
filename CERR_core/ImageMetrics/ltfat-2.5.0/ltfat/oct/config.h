/* This file should contain the configuration parameters
   necessary for the Oct-compilation. */

#ifndef CONFIG_H
#define CONFIG_H 1

#define FFTW_OPTITYPE FFTW_ESTIMATE

/* Define to a macro mangling the given C identifier (in lower and upper
   case), which must not contain underscores, for linking with Fortran. */
#define F77_FUNC(name,NAME) name ## _

#endif /* CONFIG_H */
