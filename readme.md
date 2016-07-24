`modserver` is an HTTP/1.1 application server. Applications are loaded at runtime from a 
configuration file. The server exports an API for use by applications to interpret 
requests and generate responses. Modules provide support for loading applications written 
in a variety of programming languages.

Here is an example application that writes a message to the user using the C API:
```
#include "modserver.h"

int run(servlet *s)
{
  rprintf(s, "hello from C");
  return 0;
}
```

## Building
`modserver` builds on at least the following platforms: FreeBSD, GNU/Linux, Illumos, Mac 
OS X, NetBSD, and OpenBSD. Run `make` or `gmake` depending on the platform.

Individual modules may fail to build if their dependencies are not found. This is normal 
and does not affect the building of the server. Read the [Makefile](src/Makefile) to get 
a sense for what is required to build each module.

## Dependencies
- A C compiler supporting C99.
- An operating system supporting POSIX.1-2001.
- [Lua](https://www.lua.org/)
- [luaposix](https://github.com/luaposix/luaposix)
- [luastatic](https://github.com/ers35/luastatic)

A copy of all build dependencies are included in source form in the [dep](src/dep/) 
directory. Modules may require additional dependencies.

## Usage
`modserver config.conf`

## Configuration
See [config.conf](src/config.conf) for an example configuration file and 
[config.lua](src/config.lua) for the available configuration options.

The server listens on port 8080 by default: http://127.0.0.1:8080/

## API
The API is documented in [modserver.h](src/api/c/modserver.h).

## Languages
There are example hello world applications in a variety of programming languages:
- [C](src/example/c/hello.c)
- [C++](src/example/c++/hello.cpp)
- [Crystal](src/example/crystal/hello.cr)
- [CGI](src/example/cgi/hello.cgi)
- [D](src/example/d/hello.d)
- [Go](src/example/go/hello.go)
- [Haskell](src/example/haskell/hello.hs)
- [Lua](src/example/lua/hello.lua)
- [Nim](src/example/nim/hello.nim)
- [Python](src/example/python/hello.py)
- [Ruby](src/example/ruby/hello.rb)
- [Rust](src/example/rust/hello.rs)

See the [module](src/module/) directory to learn how to add support for another 
language.

## Design
The design is a traditional forking server. Each concurrent request is handled by a 
separate process. A new process is created when all processes are busy handling a 
request. A process handles many requests to avoid the overhead of forking on each 
request. An idle process exits after five seconds to free its resources.

Applications are free to use blocking I/O because the operating system schedules the 
processes. A crash while handling a request does not affect other requests. The server 
reports the crash and continues running. One tradeoff with this design is the memory 
usage increases with the number of concurrent requests as more processes are created.

## Status
`modserver` is in active development. Some language modules are more developed than 
others. This will improve over time.

## Feedback
Email [eric@ers35.com](mailto:eric@ers35.com) or post a GitHub issue to give feedback.

## Known Issues
- Go servlets panic on Mac OS X.
- Go servlets sometimes deadlock on runtime.futexsleep.
