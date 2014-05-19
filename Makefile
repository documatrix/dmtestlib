
all: build
	cp -u -r -p cmake build/
	cp -u -r -p doc build/
	cp -u -r -p src build/
	cp -u -r -p CMakeLists.txt build/
	find build/ -name CMakeCache.txt -delete
	cd build && cmake . && make

install: build
	cd build && make install

clean: build
	rm -rf build

build:
	mkdir build
	mkdir build/log

