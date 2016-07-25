default: modserver

# $@ is the target name
# $+ are the names of all dependencies

# Different platforms require different build flags.
UNAME = $(shell sh -c 'uname -s 2>/dev/null || echo none')
ifeq ($(UNAME),SunOS)
	LDLIBS += -ldl -lsocket -lnsl
else
ifeq ($(UNAME),Darwin)
	LDFLAGS += -Wl,-undefined -Wl,dynamic_lookup
	LDLIBS += -ldl
else
ifeq ($(UNAME),Linux)
	LDLIBS += -ldl
endif
endif
endif

LUASRC = dep/lua-5.2.4/src

all: \
	$(LUASRC)/liblua.a \
	$(LUASRC)/lua \
	dep/posix.a \
	api/c/modserver.o \
	cutil.a \
	module \
	example
	
modserver: all
	@./$(LUASRC)/lua dep/luastatic.lua modserver.lua api/lua/modserver.lua config.lua \
	 http.lua module/*.lua util.lua \
		api/c/modserver.o dep/posix.a cutil.a \
		$(LUASRC)/liblua.a -I$(LUASRC) $(LDFLAGS) $(LDLIBS)

# Build dependencies

$(LUASRC)/liblua.a:
	cd $(LUASRC) && \
		$(MAKE) liblua.a CFLAGS="-O2 -Wall -DLUA_COMPAT_ALL -DLUA_USE_POSIX -DLUA_USE_DLOPEN"
$(LUASRC)/lua:
	cd $(LUASRC) && \
		$(MAKE) lua CFLAGS="-O2 -Wall -DLUA_COMPAT_ALL -DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
			LIBS="-lm $(LDLIBS)"
dep/posix.a: dep/luaposix/posix.c
	cc -std=c99 -O2 -c -DLPOSIX_2001_COMPLIANT=1 $+ -Idep/luaposix -I$(LUASRC) \
		-o dep/posix.o && ar rcs $@ dep/posix.o
api/c/modserver.o: api/c/modserver.c
	cc -c -O2 -std=c99 $+ -Iapi/c -I$(LUASRC) -o $@
cutil.a: util.c
	cc -c -std=c99 -O2 -I$(LUASRC) $+ -o cutil.o
	ar rcs $@ cutil.o

# Modules

module: \
	module/python.so \
	module/ruby.so

module/python.so: PYTHON := $(shell pkg-config --cflags --libs python3)
module/python.so: module/python.c
	cc -std=c99 -fPIC -shared $(LDFLAGS) $+ $(LDLIBS) -Iapi/c -I$(LUASRC) \
		$(PYTHON) -o $@ || true
module/ruby.so: RUBY := $(shell pkg-config --cflags --libs ruby)
module/ruby.so: module/ruby.c
	cc -std=c99 -fPIC -shared $(LDFLAGS) $+ $(LDLIBS) -Iapi/c -I$(LUASRC) \
		$(RUBY) -o $@ || true

# Application Examples

example: CFLAGS = -std=c99 -fPIC -shared -Wall -Wextra -Iapi/c -Wno-unused-parameter
example: CPPFLAGS = -fPIC -shared -Wall -Wextra -Iapi/c -Wno-unused-parameter
example: example/c/hello.c.so \
	example/c/sleep.c.so \
	example/c/arg.c.so \
	example/c/file.c.so \
	example/c/segfault.c.so \
	example/c/content-length.c.so \
	example/c++/hello.cpp.so \
	example/crystal/hello.cr.so \
	example/crystal/test.cr.so \
	example/d/hello.d.so \
	example/go/hello.go.so \
	example/go/test.go.so \
	example/haskell/hello.hs.so \
	example/nim/hello.nim.so \
	example/nim/test.nim.so \
	example/rust/hello.rs.so \
	example/rust/test.rs.so

example/c/hello.c.so: example/c/hello.c
	cc $(CFLAGS) $(LDFLAGS) $+ -o $@
example/c/sleep.c.so: example/c/sleep.c
	cc $(CFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/c/arg.c.so: example/c/arg.c
	cc $(CFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/c/file.c.so: example/c/file.c
	cc $(CFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/c/segfault.c.so: example/c/segfault.c
	cc $(CFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/c/content-length.c.so: example/c/content-length.c
	cc $(CFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/c++/hello.cpp.so: example/c++/hello.cpp
	c++ $(CPPFLAGS) $(LDFLAGS) $(LDFLAGS) $+ -o $@
example/crystal/hello.cr.so: example/crystal/hello.cr
	crystal build --single-module --link-flags="-shared" $+ -o $@ || true
example/crystal/test.cr.so: example/crystal/test.cr
	crystal build --single-module --link-flags="-shared" $+ -o $@ || true
example/d/hello.d.so: example/d/hello.d
	ldc2 -shared $+ -Iapi/d -od=example/d/ -of $@ || true
PWD = $(shell pwd)
GOPATH = $(PWD)/api/go
example/go/hello.go.so: example/go/hello.go
	GOPATH=$(GOPATH) go build -buildmode=c-shared -o $@ $+ || true
example/go/test.go.so: example/go/test.go
	GOPATH=$(GOPATH) go build -buildmode=c-shared -o $@ $+ || true
example/haskell/hello.hs.so: HASKELL := -L$(shell ghc --print-libdir)/rts \
	-lHSrts-ghc$(shell ghc --numeric-version)
example/haskell/hello.hs.so: example/haskell/hello.hs example/haskell/hello_stub.c
	ghc --make -dynamic -shared -fPIC -Iapi/c -I/usr/lib/ghc/include \
		$(HASKELL) $+ -o $@ || true
example/nim/hello.nim.so: example/nim/hello.nim
	nim compile --app:lib -p=api/nim --out=$@ $+ || true
example/nim/test.nim.so: example/nim/test.nim
	nim compile --app:lib -p=api/nim --out=$@ $+ || true
example/rust/hello.rs.so: example/rust/hello.rs
	rustc -C prefer-dynamic $+ -o $@ || true
example/rust/test.rs.so: example/rust/test.rs
	rustc -C prefer-dynamic $+ -o $@ || true

# Commands

run: modserver
	./modserver config.conf
INSTALL_TOP = /tmp/opt/modserver
install: modserver
	mkdir -p $(INSTALL_TOP) $(INSTALL_TOP)/module
	cp modserver config.conf $(INSTALL_TOP)
	cp module/*.so $(INSTALL_TOP)/module
clean:
	cd dep/lua-5.2.4 && $(MAKE) clean
	rm -f modserver *.o *.so *.a module/*.so modserver.lua.c *.zip \
		dep/*.o dep/*.a dep/*.so
	find ./api/ ./example/ -name \*.so -o -name \*.o | xargs rm -f
luacheck:
	luacheck modserver.lua api/lua/modserver.lua config.lua http.lua util.lua
slowloris:
	./test/slowloris.pl -dns 127.0.0.1:8080
cloc:
	cloc --quiet modserver.lua api/lua/modserver.lua config.lua http.lua util.lua \
		api/c/modserver.c api/c/modserver.h util.c \
		module/cgi.lua module/lua.lua module/so.lua module/py.c
wrk:
	wrk -c 10 -t 1 -d 10 "http://127.0.0.1:8080/example/lua/hello.lua"
