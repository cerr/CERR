LIBLTFAT -- Backend library of LTFAT
------------------------------------

This is a standalone backend library of LTFAT.

Dependencies
------------

The library depends on FFTW, BLAS and LAPACK. On Ubuntu, just run
```
sudo apt-get install libfftw3-dev libblas-dev liblapack-dev
```
followed by
```
make
sudo make install PREFIX=/usr/local
```

You might also need to run
```
sudo ldconfig
```
to make the just installed library accesible.

Building with MAKE (Linux)
--------------------------

There are three target libraries (static and shared versions)
* build/libltfat.a(.so)   Contains double and single prec. versions of the functions
* build/libltfatd.a(.so)  Just double prec. versions of the functions
* build/libltfatf.a(.so)  Just single prec. versions of the functions

The dependency on BLAS and LAPACK can be disabled by calling
```
make NOBLASLAPACK=1
```

The dependency on FFTW can be disabled by calling
```
make FFTBACKEND=KISS
```
The internal [KISS FFT](http://kissfft.sourceforge.net/) implementation will be used.

Building with CMAKE (Linux, Windows)
------------------------------------

By default, cmake is configured as if `NOBLASLAPACK=1` and `FFTBACKEND=KISS` were set such
that libltfat is standalone (except for the libm dependency).

Documentation
-------------

Doxygen generated documentation is available [here](http://ltfat.github.io/libltfat).

Contacts
--------

libltfat was written by Peter L. Søndergaard and Zdeněk Průša.



