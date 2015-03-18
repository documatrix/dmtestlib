
CMAKE_PREFIX=
ifeq "${MAKECMDGOALS}" "windows"
  CMAKE_PREFIX=-DCMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32/sys-root/mingw
endif

ifneq "${PREFIX}" ""
  CMAKE_PREFIX=-DCMAKE_INSTALL_PREFIX=${PREFIX}
endif

ifeq "${TARGET_GLIB}" ""
  TARGET_GLIB=2.32
endif
CMAKE_VALA_OPTS=--target-glib=${TARGET_GLIB}

CMAKE_OPTS=${CMAKE_PREFIX} -DCMAKE_VALA_OPTS=${CMAKE_VALA_OPTS} -DVAPIDIRS=${VAPIDIRS} -DTARGET_GLIB=${TARGET_GLIB}

all: linux

copy_files:
	cp -u -r -p cmake build/
	cp -u -r -p doc build/
	cp -u -r -p src build/
	cp -u -r -p CMakeLists.txt build/
	find build/ -name CMakeCache.txt -delete

linux: build copy_files
	cd build && cmake . ${CMAKE_OPTS} && make

windows: build copy_files
	cd build && cmake . -DCMAKE_TOOLCHAIN_FILE=../cmake/Toolchain-mingw32.cmake ${CMAKE_OPT} && make

install: build
	cd build && make install

clean: build
	rm -rf build

build:
	mkdir build
	mkdir build/log

