CXXFLAGS+=-Ofast -Wall -Wextra -std=c++1z 

ifeq ($(TYPE),single)
	CXXFLAGS+=-DLTFAT_SINGLE
else
	CXXFLAGS+=-DLTFAT_DOUBLE
endif

SRC=$(wildcard *.cpp)
PROGS = $(patsubst %.cpp,%,$(SRC))
libltfat=../../build/libltfat.a

all: $(PROGS) 

$(PROGS): %: %.cpp $(libltfat)
	$(CXX) $(CXXFLAGS) -I../utils -I../../modules/libltfat/include $< -o $@ $(libltfat) -lfftw3 -lfftw3f -lc -lm 

$(libltfat):
	make -C ../.. -j12 MODULE=libltfat NOBLASLAPACK=1 COMPTARGET=fulloptim static

clean: cleanlib cleanexe

cleanlib:
	make -C ../.. clean

cleanexe:
	-rm $(PROGS)

