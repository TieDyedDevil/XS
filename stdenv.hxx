/* stdenv.hxx -- set up an environment we can use */

#include "xsconfig.hxx"
#include <vector>
#include <map>
using std::map;

#ifndef NO_GC
#include <gc/gc.h>
#include <gc/gc_cpp.h>
#include <gc/gc_allocator.h>
#else /* DEBUGGING ONLY! */
#define UseGC (void*) new int[1000] 
#define GC_init()
#define GC_MALLOC malloc
#define gc_allocator std::allocator
#define traceable_allocator std::allocator
#define GC_gcollect()
#define GC_disable()
class gc_cleanup {};
#endif

#include <boost/foreach.hpp>
#define foreach BOOST_FOREACH

#ifdef HAVE_SYS_CDEFS_H
# include <sys/cdefs.h>
#endif

/*
 * type qualifiers
 */

/*
 * protect the rest of xs source from the dance of the includes
 */

#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <string.h>
#include <stddef.h>

#if HAVE_MEMORY_H
#include <memory.h>
#endif

#if HAVE_STDARG_H
#include <stdarg.h>
#else
#include <varargs.h>
#endif

#include <errno.h>
#include <setjmp.h>
#include <signal.h>
#include <ctype.h>

#if REQUIRE_STAT || REQUIRE_IOCTL
#include <sys/types.h>
#endif

#if REQUIRE_IOCTL
#include <sys/ioctl.h>
#endif

#if REQUIRE_STAT
#include <sys/stat.h>
#endif

#if __GNUC__
#define NORETURN __attribute__ ((noreturn))
#else
#define NORETURN
#endif

#if REQUIRE_DIRENT
#if HAVE_DIRENT_H
#include <dirent.h>
typedef struct dirent Dirent;
#else
#include <sys/dir.h>
typedef struct direct Dirent;
#endif
#endif

#include <sys/wait.h>

/* stdlib */

#include <stdlib.h>

/*
 * things that should be defined by header files but might not have been
 */

#ifndef	offsetof
#define	offsetof(t, m)	((size_t) (((char *) &((t *) 0)->m) - (char *)0))
#endif

#ifndef	EOF
#define	EOF	(-1)
#endif

/*
 * xs_setjmp/longjmp/jmp_buf ensure proper signal handling when we throw
 * out of a handler
 */

#if HAVE_DECL_SIGSETJMP
# define xs_setjmp(buf) sigsetjmp(buf,1)
# define xs_longjmp     siglongjmp
# define xs_jmp_buf     sigjmp_buf
#else
# define xs_setjmp(buf) setjmp(buf)
# define xs_longjmp     longjmp
# define xs_jmp_buf     jmp_buf
#endif

/*
 * macros
 */

#define	streq(s, t)		(strcmp(s, t) == 0)
#define	strneq(s, t, n)		(strncmp(s, t, n) == 0)
#define	hasprefix(s, p)		strneq(s, p, (sizeof p) - 1)
#define	arraysize(a)		((int) (sizeof (a) / sizeof (*a)))
#define	memzero(dest, count)	memset(dest, 0, count)

#define	STMT(stmt)		do { stmt; } while (0)
#define	NOP			do {} while (0)

#define CONCAT(a,b)	a ## b

/* Two for macro expansion */
#define _STRING(s)	#s
#define STRING(s) _STRING(s)

/*
 * types we use throughout xs
 */

#if USE_SIG_ATOMIC_T
typedef volatile sig_atomic_t Atomic;
#else
typedef volatile int Atomic;
#endif

#ifdef VOID_SIGNALS
typedef void Sigresult;
#define	SIGRESULT
#else
typedef int Sigresult;
#define	SIGRESULT	0
#endif

typedef GETGROUPS_T gidset_t;

/*
 * assertion checking
 */

#if ASSERTIONS
#define	assert(expr) \
	STMT( \
		if (!(expr)) { \
			eprint("%s:%d: assertion failed (%s)\n", \
				__FILE__, __LINE__, STRING(expr)); \
			abort(); \
		} \
	)
#else
#define	assert(ignore)	NOP
#endif

enum { UNREACHABLE = 0 };


#define	NOTREACHED	STMT(assert(UNREACHABLE))


/*
 * hacks to present a standard system call interface
 */

#ifdef HAVE_SETSID
# define setpgrp(a, b) setsid()
#else

#ifdef linux
#include "unistd.h"
#define setpgrp(a, b)	setpgid(a, b)
#endif

#if sgi
#define	setpgrp(a, b)	BSDsetpgrp(a,b)
#endif

#if HPUX
#define	setpgrp(a, b)	setpgrp()
#endif
#endif

#if !HAVE_LSTAT
#define	lstat	stat
#endif
