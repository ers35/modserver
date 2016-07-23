/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Define this if your system has a crypt() function */
//#define HAVE_CRYPT 1

/* Define to 1 if you have the <crypt.h> header file. */
//#define HAVE_CRYPT_H 1

/* Define to 1 if you have the declaration of `fdatasync', and to 0 if you
   don't. */
//#define HAVE_DECL_FDATASYNC 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the `fdatasync' function. */
//#define HAVE_FDATASYNC 1

/* Define to 1 if you have the `gethostid' function. */
#define HAVE_GETHOSTID 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <lauxlib.h> header file. */
#define HAVE_LAUXLIB_H 1

/* Define to 1 if you have the `rt' library (-lrt). */
#define HAVE_LIBRT 1

/* Define to 1 if you have the <linux/netlink.h> header file. */
//#define HAVE_LINUX_NETLINK_H 1

/* Define to 1 if you have the <luaconf.h> header file. */
#define HAVE_LUACONF_H 1

/* Define to 1 if you have the <lualib.h> header file. */
#define HAVE_LUALIB_H 1

/* Define to 1 if you have the <lua.h> header file. */
#define HAVE_LUA_H 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `msgrcv' function. */
#define HAVE_MSGRCV 1

/* Define to 1 if you have the `msgsnd' function. */
#define HAVE_MSGSND 1

/* Define to 1 if you have the <net/if.h> header file. */
#define HAVE_NET_IF_H 1

/* Define to 1 if you have the `posix_fadvise' function. */
//#define HAVE_POSIX_FADVISE 1

/* Define to 1 if you have the `sched_getsheduler' function. */
/* #undef HAVE_SCHED_GETSHEDULER */

/* Define to 1 if you have the <sched.h> header file. */
//#define HAVE_SCHED_H 1

/* Define to 1 if you have the `sched_setscheduler' function. */
//#define HAVE_SCHED_SETSCHEDULER 1

/* Define to 1 if you have the `statvfs' function. */
#define HAVE_STATVFS 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strlcpy' function. */
/* #undef HAVE_STRLCPY */

/* Define if your system has SysV message APIs */
#define HAVE_SYSV_MESSAGING 1

/* Define to 1 if you have the <sys/msg.h> header file. */
#define HAVE_SYS_MSG_H 1

/* Define to 1 if you have the <sys/statvfs.h> header file. */
#define HAVE_SYS_STATVFS_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* Name of package */
#define PACKAGE "luaposix"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "http://github.com/luaposix/luaposix/issues"

/* Define to the full name of this package. */
#define PACKAGE_NAME "luaposix"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "luaposix 33.4.0"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "luaposix"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "33.4.0"

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Enable extensions on AIX 3, Interix.  */
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
/* Enable threading extensions on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif


/* Version number of package */
#define VERSION "33.4.0"

/* Define to 1 if on MINIX. */
/* #undef _MINIX */

/* Define to 2 if the system does not provide POSIX.1 features except with
   this defined. */
/* #undef _POSIX_1_SOURCE */

/* Define to 1 if you need to in order for `stat' and other things to work. */
/* #undef _POSIX_SOURCE */
