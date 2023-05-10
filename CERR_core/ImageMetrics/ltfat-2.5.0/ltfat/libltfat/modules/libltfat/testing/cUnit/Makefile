CFILES = $(shell ls test_*.c)

run_all: test_all_libltfat
	LD_LIBRARY_PATH=../../build ./test_all_libltfat

test_all_libltfat: Makefile ../../build/libltfat.so $(CFILES)
	$(CC) -Wall -Wextra -pedantic -std=gnu99 -O0 -g -I../../include -I../../thirdparty test_all_libltfat.c -o test_all_libltfat -L../../build -lltfat -lfftw3 -lfftw3f -lm

mem: test_all_libltfat
	LD_LIBRARY_PATH=../../build valgrind --leak-check=yes  ./test_all_libltfat 

clean:
	-rm -f *.o
	find . -type f -executable -exec sh -c "file -i '{}' | grep -q 'x-executable; charset=binary'" \; -print | xargs rm -f

test_%: test_%.c  Makefile
	$(shell truncate -s 0 runner_test_typecomplexindependent.c)
	$(shell truncate -s 0 runner_test_typeindependent.c)
	$(shell echo 'int TEST_NAME($@)(){' >> runner_test_typeindependent.c)
	$(shell	echo '#include "$<"' >> runner_test_typeindependent.c)
	$(shell echo 'return 0;}' >> runner_test_typeindependent.c)
	$(shell sed 's/%FUNCTIONNAME%/$@/g' runner_template.c > runner.c)
	$(CC) -Wall -Wextra -pedantic -std=c99 -O0 -g -I../../include -I../../thirdparty runner.c -o $@ -L../../build -lltfat -lfftw3 -lfftw3f -lm
	LD_LIBRARY_PATH=../../build ./$@
	-rm -f ./$@

.PHONY: run_all

