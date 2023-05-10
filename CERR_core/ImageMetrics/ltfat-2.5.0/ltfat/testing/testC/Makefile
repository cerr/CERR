#   
#   Makefile 
#   
#   A common makefile for managing compilation of all tests.
#   By default, the makefile supplies only the basic flags,
#   test-specific flags, files and libraries are read directly
#   from a comment in test.
#
#   Usage:
#
#

CFLAGS=-g -Wall -Wextra -DNDEBUG
LIBS=

TEST_SRC=$(wildcard test_*.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))

all: $(TESTS)

$(TESTS): % : %.c
	$(CC) $(CFLAGS) $^ $(shell sed '2q;d' $^) -o $@ $(LIBS)


debug: CFLAGS=-g -Wall -Wextra
debug: LIBS=-lprofiler
debug: all


clean:
	rm -rf $(TESTS)

.PHONY: tests
tests: $(TESTS)
	sh ./runtests.sh

valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)


