#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

/*
Each API function takes an opaque pointer. Do not free this.
*/
typedef struct servlet servlet;

/*
Return the value associated with the given key of the query part of the URI, or NULL if 
no such key is found.

The returned string is NULL terminated. The application must not free the value.

// Example:
// For a given URI of /?key1=value1&key2=value2
const char *val = get_arg(s, "key1");
assert(strcmp(val, "value1") == 0);
*/
const char* get_arg(servlet *s, const char *name);

/*
Return the HTTP method of the request.

The returned string is NULL terminated. The application must not free the value.

// Example:
const char *method = get_method(s);
assert(strcmp(method, "GET") == 0);
*/
const char* get_method(servlet *s);

/*
Return the value associated with the given key of the HTTP header.

HTTP headers are case-insensitive and so is the key argument.

The returned string is NULL terminated. The application must not free the value.

// Example:
const char *val0 = get_header(s, "User-Agent");
const char *val1 = get_header(s, "user-agent");
assert(strcmp(val0, val1) == 0);
*/
const char* get_header(servlet *s, const char *key);

/*
Set the HTTP status code of the response.

The reason phrase is automatically set based on the integer status code.

The default status code of 200 is automatically set by the server and does not have to be 
set by the application.

// Example:
// 404 Not Found
set_status(s, 404);
*/
void set_status(servlet *s, int status);

/*
Set an HTTP header.

HTTP headers are case-insensitive. Setting the same header again replaces the previous 
header.

Internal copies are made of the key and value.

// Example:
set_header(s, "Set-Cookie", "key=value");

set_header(s, "Content-Type", "text/plain; charset=UTF-8");

unsigned length = 42;
char str_length[128];
snprintf(str_length, sizeof(str_length), "%u", length);
set_header(s, "Content-Length", str_length);
*/
void set_header(servlet *s, const char *key, const char *value);

/*
Write the given buffer to the output stream.

The first write to the output stream generates the HTTP status line and headers. Further 
changes to the status or headers is not possible once the headers are sent. Chunked 
transfer encoding is used by default when the Content-Length header is not set.

The output stream is fully buffered and is automatically flushed when it grows too large. 
One may use rflush() to manually flush the output stream to the user.

// Example:
const char reply[] = "hello world";
rwrite(s, reply, sizeof(reply) - 1);
*/
void rwrite(servlet *s, const char *buffer, size_t length);

/*
Write to the output stream according to the given printf format string and arguments.

See the documentation of rwrite() for the behavior of rprintf() with regard to the output 
stream.

// Example:
rprintf(s, "The number is <b>%i</b>\n", 42);

const char reply[] = "hello world";
rprintf(s, "%.*s", (int)sizeof(reply) - 1, reply);
// Equivalent to 
// rwrite(s, buf, sizeof(buf) - 1);
*/
int rprintf(servlet *s, const char *format, ...);

/*
Write all the buffered data in the output stream to the user.

rflush() is automatically called when the application returns.

// Example:
for (int count = 0; count < 5; ++count)
{
  rprintf(s, "count: %i\n", count);
  // Without the rflush() the user would have to wait 5 seconds to see any output.
  rflush(s);
  sleep(1);
}
rprintf(s, "done\n");
*/
void rflush(servlet *s);

#ifdef __cplusplus
}
#endif
