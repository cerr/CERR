#!/bin/bash

echo "Running unit tests:"

for i in $(find . -name "test_*" -not -name "*.c")
do
    if test -f $i
    then
        if $VALGRIND ./$i 2>> tests.log
        then
            echo $i PASS
         else
            echo "ERROR in test $i: here's tests.log"
            echo "------"
            tail tests.log
            exit 1
        fi
    fi
done

echo ""
