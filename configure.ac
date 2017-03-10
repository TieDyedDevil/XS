dnl Process this file with autoconf to produce a configure script.
AC_INIT(xs, 1.1)
AC_CONFIG_HEADER(config.h)
AM_INIT_AUTOMAKE([-Wall])

dnl AC_CMDSTDOUT_CPP(variable, command, headers)
AC_DEFUN([AC_CMDSTDOUT_CPP],
[cat > conftest.$ac_ext <<EOF
[#]line __oline__ "configure"
#include "confdefs.h"
[$3]
EOF
$1=`(eval "$ac_cpp conftest.$ac_ext") 2>&AC_FD_CC | $2`
rm -f conftest*
])


use_readline=yes
use_editline=no

AC_ARG_WITH(readline,  AS_HELP_STRING(--without-readline, use GNU Readline), 
	use_readline=no)
AC_ARG_WITH(editline, AS_HELP_STRING(--with-editline, use the Editline library),
	use_editline=yes)

AC_ARG_ENABLE(debug, AS_HELP_STRING(--enable-debug, debug mode for xs developers), debug_build=yes) 
AC_ARG_ENABLE(static, AS_HELP_STRING(--enable-static, build statically), LDFLAGS=-static) 

AC_ARG_ENABLE(assertions, AS_HELP_STRING(--enable-assertions, [Normal assertions]), 
    AC_DEFINE(ASSERTIONS,1,"Enable normal xs assertions"))

AC_ARG_ENABLE(lisptrees, AS_HELP_STRING(--enable-lisptrees, [Allow dumping parsed code in s-expression format]),
    AC_DEFINE(LISPTREES,1,"Enable lisp tree dumping"))

dnl enable debug stuff
if test "$debug_build" = yes; then
	AC_DEFINE(ASSERTIONS,1,"Enable normal assertions")
	CXXFLAGS="-Wall -Wextra -Wno-unused-parameter -O0 -ggdb3"
fi



dnl Old solaris compatibility stuff

AC_CANONICAL_HOST

case "$host" in
	*sun5* | *solaris2*)
		AC_DEFINE(SOLARIS,,Solaris compatibility)
	;;
esac


dnl Checks for programs.
AC_PROG_CXX
AC_PROG_INSTALL
AC_PROG_YACC

AC_LANG(C++)

dnl Boehm
AC_CHECK_LIB(gc, main, , [AC_MSG_ERROR([Boehm GC is not installed])])

dnl ----------------------------
dnl CHECK FOR /dev/fd FILESYSTEM
dnl ----------------------------
AC_CACHE_CHECK(for /dev/fd filesystem, es_cv_sys_dev_fd,
[test -d /dev/fd && es_cv_sys_dev_fd=yes || es_cv_sys_dev_fd=no])
if test $es_cv_sys_dev_fd = yes; then
  AC_DEFINE(HAVE_DEV_FD,,/dev/fd support for >{} <{})
fi

AC_SYS_INTERPRETER
if test $ac_cv_sys_interpreter = yes
then
	AC_DEFINE(KERNEL_POUNDBANG,,execve has shebang support)
fi


dnl Checks for libraries.

AC_CHECK_LIB(sun, getpwuid)

if test "$use_readline" = yes || test "$use_editline" = yes
then
    dnl Are these really wanted/can they even work?
	dnl AC_CHECK_LIB(terminfo, main)
	dnl AC_CHECK_LIB(termcap, main)
    AC_CHECK_LIB(ncurses, initscr)
    if test "$use_readline" = yes
    then
    	AC_CHECK_LIB(readline, readline)
    elif test "$use_editline" = yes
    then
    	AC_CHECK_LIB(edit, readline)
    fi
fi


dnl Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS(fcntl.h limits.h sys/ioctl.h sys/time.h unistd.h memory.h stdarg.h sys/cdefs.h tr1/unordered_map)


dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_UID_T
AC_TYPE_SIZE_T

dnl Checks for library functions.
AC_TYPE_GETGROUPS
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MMAP
AC_TYPE_SIGNAL

if test "$ac_cv_type_signal" = void
then
	AC_DEFINE(VOID_SIGNALS,,Signal handlers have void return type instead of int)
fi

AC_FUNC_WAIT3
AC_CHECK_FUNCS(strerror strtol lstat setrlimit sigrelse sighold sigaction sysconf setsid)

dnl check for a u_quad_t or something like that
AC_CACHE_CHECK(for rlimit type ..., es_cv_rlimit_t,
AC_CMDSTDOUT_CPP(es_cv_rlimit_t, 
grep rlim_cur | sed -e 's/rlim_cur.*//' -e 's/^ //g' -e 's/^	//g' -e q,
[#ifdef HAVE_SETRLIMIT
# include <sys/resource.h>
#endif],long))

AC_CACHE_CHECK(for files to extract signal information from,
es_cv_sigfiles,
AC_CMDSTDOUT_CPP(es_cv_sigfiles,
[changequote(,)
egrep '^#[ 	]+1[	 ]+' | sed 's/.*"\(.*\)".*/\1/' |sort -u |  
grep '^/' |tr '\012' ' ' 
changequote([,])],
[#include <signal.h>], /usr/include/signal.h))
SIGFILES=$es_cv_sigfiles
AC_SUBST(SIGFILES)

AC_DEFINE_UNQUOTED(LIMIT_T, $es_cv_rlimit_t, Type of data in structure from getrlimit)

AC_OUTPUT(Makefile)
