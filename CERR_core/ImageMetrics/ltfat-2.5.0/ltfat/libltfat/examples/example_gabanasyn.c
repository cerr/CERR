#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include "ltfat.h"

int main()
{
    // Number of frequency channels
    ltfatInt M = 2048;
    // Hop factor
    ltfatInt a = 256;
    // Length of the signal. Must be an integer multiple of both a and M
    ltfatInt L = 100*2048;
    // Length of the window, I use a Gauss window here which is possibly 
    // fully supported
    ltfatInt gl = L;
    // Number of channels
    ltfatInt W = 1;

    // Number of unique channels when the input is a real signal
    ltfatInt M2 = M / 2 + 1;
    // Number of time hops
    ltfatInt N = L / a;

    // Allocate space for a window
    double* g = ltfat_malloc(gl * sizeof * g);
    // Alocate space for the dual window
    double* gd = ltfat_malloc(gl * sizeof * gd);
    // Space for input signal
    double* f = ltfat_malloc(W * L * sizeof * f);
    // Space for reconstructed signal
    double* frec = ltfat_malloc(W * L * sizeof * f);
    // Space for coefficients 
    double _Complex* c = ltfat_malloc(W * M2 * N * sizeof * c);

    // Generate some input
    srand(time(NULL));
    for (ltfatInt l = 0; l < W * L; ++l)
    {
        f[l] = ((double)rand()) / RAND_MAX;
    }

    // Compute window. Using a*M/L for w makes the time-frequency support of the
    // Gaussion window to best fit the time-frequency sampling grid
    pgauss_d(L, a * M / L, 0, g);

    // Compute the dual window
    gabdual_long_d(g,L,1,a,M,gd);

    // Do the transform
    dgtreal_long_d(f, g, L, W, a, M, TIMEINV, c);

    // Do inverse transform
    idgtreal_long_d(c, gd, L, W, a, M, TIMEINV, frec);


    // Comute error of the reconstruction
    double err = 0.0;

    for (ltfatInt l = 0; l < L * W; ++l)
    {
        double dif = fabs( f[l] - frec[l] );
        err += dif * dif;
    }

    printf("Error of the reconstruction is %e\n", err);

    LTFAT_SAFEFREEALL(g, gd, f, frec, c);
    return 0;
}
