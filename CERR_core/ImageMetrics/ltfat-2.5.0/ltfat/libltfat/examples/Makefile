CFLAGS+=-g -Wall -Wextra -std=c++11

SRC=$(wildcard *.c)
PROGS = $(patsubst %.c,%,$(SRC))

all: $(PROGS)

%: %.c
	$(CXX) $(CFLAGS) -g -Ofast -I.. $< -o $@ ../build/libltfat.a -lblas -llapack -lfftw3 -lc -lm -lsndfile

clean:
	-rm $(PROGS)
