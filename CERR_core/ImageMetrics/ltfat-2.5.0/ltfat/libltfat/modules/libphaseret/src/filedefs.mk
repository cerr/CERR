files += gla.c legla.c gsrtisila.c gsrtisilapghi.c pghi.c rtisila.c rtpghi.c spsi.c utils.c
files_notypechange += pghi_typeconstant.c legla_typeconstant.c

DSLFLAGS = -lltfat
DLFLAGS = -lltfatd
SLFLAGS = -lltfatf
CFLAGS+=-Imodules/libltfat/include
extradepincludes:=\#include \"ltfat.h\"\n

