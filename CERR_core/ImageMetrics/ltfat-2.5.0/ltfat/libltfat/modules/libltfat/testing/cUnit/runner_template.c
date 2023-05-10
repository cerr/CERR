#include "ltfat.h"
#include "ltfat/errno.h"
#include "ltfat/macros.h"
#include "minunit.h"
#include "runner_multiinclude.h"

void all_tests()
{
    mu_suite_start();

    mu_run_test_singledouble(%FUNCTIONNAME%);

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
