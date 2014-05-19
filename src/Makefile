VALAC=valac
CC=cc
AR=ar
CFLAGS=`${COMMAND_PREFIX}pkg-config --cflags gobject-2.0 gio-2.0` -g

testlib:
	${VALAC} -v -X -I. -X -L. -C -H testlib.h --thread --pkg gio-2.0 --pkg posix -X -O3 -g --save-temps --library testlib testlib.vala
	${COMMAND_PREFIX}${CC} -o libtestlib.o ${CFLAGS} -I. -c testlib.c
	${COMMAND_PREFIX}${AR} rcs libtestlib.${STATIC_LIB_EXT} libtestlib.o
	${COMMAND_PREFIX}${CC} --shared -fPIC -o libtestlib.${LIB_EXT} testlib.c ${CFLAGS} -I.


	cp *.${STATIC_LIB_EXT} ../lib
	cp *.${LIB_EXT} ../lib
	cp *.h ../include
	cp *.vapi ../include
