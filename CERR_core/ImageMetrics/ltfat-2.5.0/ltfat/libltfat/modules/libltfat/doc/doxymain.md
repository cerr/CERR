\mainpage libltfat - Large Time-Frequency Analysis Toolbox Library 
[Fork libltfat on Github](https://github.com/ltfat/libltfat)

This is the documentation page for the standalone back end library of
 [LTFAT](http://ltfat.github.io/) the Matlab/Octave
toolbox for working with time-frequency analysis and synthesis. It is intended
both as an educational and a computational tool. The toolbox provides a large
number of linear transforms including Gabor and wavelet transforms along with 
routines for constructing windows (filter prototypes) and routines for 
manipulating coefficients

Modules
-------

The following modules are included in the libltfat repository and can be optionally
compiled:

* Phase Retrieval Toolbox Library [libphaseret](http://ltfat.github.io/libphaseret/)

Function naming convention
--------------------------

The function names are in the following format:

\c ltfat_<function_name>[_<d|s|dc|sc>](<parameters>)

The \c ltfat_ prefix is present in all function names while the suffix
is optional and identifies the data type the function is working with:

<table>
<caption id="multi_row">Data type suffix</caption>
<tr><th>Suffix</th><th>Data type</th></tr>
<tr><td>d</td><td>\c double</td></tr>
<tr><td>s</td><td>\c float</td></tr>
<tr><td>dc</td><td>\c ltfat_complex_d</td></tr>
<tr><td>sc</td><td>\c ltfat_complex_s</td></tr>
</table>

\note In the documentation the prefix and the suffix will be omitted when
introducing a non-unique function and when referring to the function group.
Similarly, the real data type (\c float or \c double) will be referred to as
\c LTFAT_REAL and the complex data type (\c ltfat_complex_s or \c ltfat_complex_d)
 as \c LTFAT_COMPLEX.

\note Additionally, the \c LTFAT_TYPE type will be used whenever there is a version of the
function for each of the four aforementioned types.

Compatibility
-------------

The source code of the library complies with both C99 and C++11 standards.

When compiled with C99 enabled, \c ltfat_complex_d and \c ltfat_complex_s
are effectively the following typedefs:

~~~~~~~~~~~~~~~{.c}
typedef complex double ltfat_complex_d;
typedef complex float ltfat_complex_s;
~~~~~~~~~~~~~~~
Where \c complex \c double and \c complex \c float types 
are a [C99 feature](http://en.cppreference.com/w/c/numeric/complex).

When compiled with C++11 enabled, the following typedefs are used:
~~~~~~~~~~~~~~~{.cpp}
typedef std::complex<double> ltfat_complex_d;
typedef std::complex<float> ltfat_complex_s;
~~~~~~~~~~~~~~~
The description can be found here [std::complex](http://en.cppreference.com/w/cpp/numeric/complex).

Arrays of complex data types from both C99 and C++11 are binary 
compatible with simple arrays of basic types with the real and the imaginary parts interleaved in memory.

Therefore, in C99 it is legal to do the following casts
~~~~~~~~~~~~~~~{.cpp}
complex double c[] = {{1.0,2.0},{3.0,4.0},{5.0,6.0}};
double (*c2)[2] = (double(*)[2]) c;
// c2[n][0] is identical to creal(c[n]) and c2[n][1] is identical to cimag(c[n])
// Or even
double *c3 = (double*) c;
// and c3[2*n] is identical to creal(c[n]) and c3[2*n+1] is identical to cimag(c[n])
~~~~~~~~~~~~~~~

Similarly, in C++11 one can do
~~~~~~~~~~~~~~~{.cpp}
std::complex<double> c[] = {{1.0,2.0},{3.0,4.0},{5.0,6.0}};
double (*c2)[2] = reinterpret_cast<double(*)[2]>(c);
// c2[n][0] is identical to real(c[n]) and c2[n][1] is identical to imag(c[n])
// Or even
double *c3 = reinterpret_cast<double*>( c);
// and c3[2*n] is identical to real(c[n]) and c3[2*n+1] is identical to imag(c[n])
~~~~~~~~~~~~~~~

\warning The other way around i.e. casting \c double* (memory allocated as an array of \c
double) to  \c complex \c double* or
\c std::complex<double>* might not work. See this 
[stackoverflow question](http://stackoverflow.com/questions/23198943/is-it-legal-to-cast-float-to-stdcomplexfloat).

Linking
-------

The following table summarizes what type the \c ltfat_complex_d expands to depending 
on the compiler
<table>
<tr><th></th><th>Single number</th><th>Array</th><th>Pointer</th></tr>
<tr><td>C99</td><td>\c complex \c double</td><td>\c complex \c double[]</td><td>\c complex \c double*</td></tr>
<tr><td>C++11</td><td>\c std::complex<double></td><td>\c std::complex<double>[]</td><td>\c std::complex<double>*</td></tr>
<tr><td>Compatibility (C++11 and \c LTFAT_CINTERFACE defined)</td><td>\c double[2]</td><td>\c double[][2]</td><td>\c double(*)[2]</td></tr>
</table>
\c ltfat_complex_s expands the same way.

Arrays, matrices and naming conventions
---------------------------------------

The multidimensional arrays are contiguous in memory and therefore, they
are reffered to by a single pointer and the individual dimensions are
accessed trough an offset.

When an array represents a matrix, it is assumed that the columns are the
first dimension and therefore they are stored continuously in memory.

In the function headers, the data arrays are denoted with array brackets []
and a pointer is used whenever referring to a single object. This distinction
is just cosmetics as the arrays decay to pointers anyway.

Array sizes, indexes etc. are represented using \t ltfat_int , which is defined as:
~~~~~~~~~~~~~~~{.c}
#ifdef LTFAT_LARGEARRAYS
typedef ptrdiff_t ltfat_int;
#else
typedef int       ltfat_int;
#endif 
~~~~~~~~~~~~~~~
\note Size of \t ptrdiff_t is system dependent.

Use ltfat_int_is_compatible() to test whether your signed integer type size is
compatible with the one libltfat was compiled with. It is crucial the sizes
match whenever an array of integers is passed to a libltfat function.

Further, the following naming conventions are used consistently:
<table>
<caption id="multi_row">Argument naming</caption>
<tr><th>Arg. name</th><th>Definition</th></tr>
<tr><td>f</td><td>Time domain signal</td></tr>
<tr><td>g,gd,gt</td><td>Window (filter), canonical dual window, canonical tight window </td></tr>
<tr><td>c</td><td>Coefficients</td></tr>
<tr><td>a</td><td>Integer. Time hop size.</td></tr>
<tr><td>M</td><td>Integer. Number of frequency channels (FFT length).</td></tr>
<tr><td>M2</td><td>Integer. Number of unique frequency channels for real signals:
M2=M/2+1.</td></tr>
<tr><td>L</td><td>Integer. Length of the signal. </td></tr>
<tr><td>N</td><td>Integer. Number of time shifts: N=L/a.</td></tr>
<tr><td>W</td><td>Integer. Number of signal channels.</td></tr>
</table>


Error handling
--------------

Every function which returns a status code should be checked by the user.
Additionally, the error message is printed to the standard error stream.
This behavior can be turned off or a custom error handler can be registered.
For details see \ref error

Plans
-----

When repeated computations with the same settings are desired, it is
convenient to create a __plan__ using the appropriate *_init function,
call the *_execute function multiple times and destroy the plan by
calling the *_done function.
The plan usually contains some precomputed read-only data,
working arrays and other plans.
The plan is represented as a pointer to an opaque structure and here
is an example how to use it: 
~~~~~~~~~~~~~~~{.c}
ltfat_dgt_long_plan_d* plan = NULL;

ltfat_dgt_long_init_d(f, g, L, W, a, M, c, ptype, FFTW_ESTIMATE, &plan)
// Fill in c after calling init. The FFTW planning routine migh have written 
// something to it.

ltfat_dgt_long_execute_d(plan);
// Refresh data in f and call execute again  

ltfat_dgt_long_done_d(&plan);
~~~~~~~~~~~~~~~

\note Please note that due to the
<a href="https://github.com/FFTW/fftw3/issues/16">limitation of FFTW</a>
the *_init routines are not re-entrant because of the FFTW planning happening in them.
Therefore, the *_init functions cannot be called simultaneously on different threads even 
when creating completely separate plans.

\note Further, the *_execute functions are reentrant and thread-safe, but not when executed 
on a single plan concurrently on separate threads. This is a contrast with the FFTW
execute function, which is thread safe even for a single plan. 
This limitation comes from the fact that the LTFAT plan contains some working buffers.

States
------

A __state__ is a plan which additionally holds some data which persists
between the execute calls.


