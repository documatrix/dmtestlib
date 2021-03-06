CP=cp -u -r -p
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  CP=rsync -au
endif

CMAKE_PREFIX=
ifeq "${MAKECMDGOALS}" "windows"
  CMAKE_PREFIX=-DCMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32/sys-root/mingw
endif

ifeq "${MAKECMDGOALS}" "windows64"
  CMAKE_PREFIX=-DCMAKE_INSTALL_PREFIX=/usr/x86_64-w64-mingw32/sys-root/mingw
endif

ifneq "${PREFIX}" ""
  CMAKE_PREFIX=-DCMAKE_INSTALL_PREFIX=${PREFIX}
endif

ifeq "${TARGET_GLIB}" ""
  TARGET_GLIB=2.32
endif
CMAKE_VALA_OPTS=--target-glib=${TARGET_GLIB}

CMAKE_OPTS=${CMAKE_PREFIX} -DCMAKE_VALA_OPTS=${CMAKE_VALA_OPTS} -DVAPIDIRS=${VAPIDIRS} -DTARGET_GLIB=${TARGET_GLIB} -DCMAKE_INSTALL_RPATH=\$$ORIGIN/../lib

all: linux

copy_files:
	${CP} cmake build/
	${CP} doc build/
	${CP} src build/
	${CP} CMakeLists.txt build/
	find build/ -name CMakeCache.txt -delete

linux: build copy_files
	cd build && cmake . ${CMAKE_OPTS} && make

windows: build copy_files
	cd build && cmake . -DCMAKE_TOOLCHAIN_FILE=../cmake/Toolchain-mingw32.cmake ${CMAKE_OPTS} && make

windows64: build copy_files
	cd build && cmake . -DCMAKE_TOOLCHAIN_FILE=../cmake/Toolchain-mingw64.cmake ${CMAKE_OPTS} && make

webassembly: build copy_files
	cd build && emcmake cmake . ${CMAKE_OPTS} && make

install: build
	cd build && make install

clean: build
	rm -rf build

build:
	mkdir build
	mkdir build/log

