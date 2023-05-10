/*
 *   minunit.h -- A minimal unit test framework for C
 *
 *   Originally from Jara design http://www.jera.com/techinfo/jtns/jtn002.html
 *   Modified by Zed Shaw in http://c.learncodethehardway.org
 *
 *
 *   NOTE: The UNUSED(x) macro is used to mute the unused parameter warning.
 *
 */


#undef NDEBUG
#ifndef _minunit_h
#define _minunit_h

#include <stdio.h>
#include "dbg.h"
#include <stdlib.h>
#include <time.h>

#define UNUSED(x) (void)(x)

#define mu_suite_start() char *message = NULL

#define mu_assert(test, message) if (!(test)) { log_err(message); return message; }
#define mu_run_test(test) debug("\n-----%s", " " #test); \
    message = test(); tests_run++; if (message) return message;

#define RUN_TESTS(name) int main(int argc, char *argv[]) {\
    UNUSED(argc);\
    debug("----- RUNNING: %s", argv[0]);\
        printf("----\nRUNNING: %s\n", argv[0]);\
        char *result = name();\
        if (result != 0) {\
            printf("FAILED: %s\n", result);\
        }\
        else {\
            printf("ALL TESTS PASSED\n");\
        }\
    printf("Tests run: %d\n", tests_run);\
        exit(result != 0);\
}


int tests_run;



#endif
