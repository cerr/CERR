#include "ltfat.h"
#include "ltfat/errno.h"
#include "ltfat/macros.h"
#include "minunit.h"


void all_tests()
{
    mu_suite_start();

    mu_run_test_singledoublecomplex(test_circshift);
    mu_run_test_singledoublecomplex(test_fftshift);
    mu_run_test_singledoublecomplex(test_ifftshift);
    mu_run_test_singledoublecomplex(test_fir2long);
    mu_run_test_singledoublecomplex(test_long2fir);
    mu_run_test_singledoublecomplex(test_normalize);
    mu_run_test_singledoublecomplex(test_firwin);
    mu_run_test_singledoublecomplex(test_gabdual_painless);
    mu_run_test_singledoublecomplex(test_gabdual_long);
    mu_run_test_singledoublecomplex(test_dgt_fb);
    mu_run_test_singledoublecomplex(test_idgt_fb);
    mu_run_test_singledoublecomplex(test_dgt_long);
    mu_run_test_singledoublecomplex(test_idgt_long);
    mu_run_test_singledouble(test_dgtreal_fb);
    mu_run_test_singledouble(test_idgtreal_fb);
    mu_run_test_singledouble(test_dgtreal_long);
    mu_run_test_singledouble(test_idgtreal_long);
    mu_run_test_singledouble(test_pgauss);
    mu_run_test_singledouble(test_fftcircshift);
    mu_run_test_singledouble(test_fftfftshift);
    mu_run_test_singledouble(test_fftifftshift);
    mu_run_test_singledouble(test_fftrealcircshift);
    mu_run_test_singledouble(test_fftrealfftshift);
    mu_run_test_singledouble(test_fftrealifftshift);

    mu_suite_stop();
}


int main()
{
    all_tests();

    
    if (ft.noOfFailedTests > 0)
    {
        printf("\n----------------\nFAILED TESTS %d: \n\n", ft.noOfFailedTests);
        for (int ii = 0; ii < ft.noOfFailedTests; ii++) { printf("    %s\n", ft.failedTests[ii]); }
        ltfat_free(ft.failedTests);
    }
    else
    {
        printf("\n----------------\nALL TESTS PASSED\n");
    }
}
