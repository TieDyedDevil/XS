# Makefile for es ($Revision: 1.4 $)

# Some of the advice here is rather old and out of date.  The
# configuration of es will be improved by 0.9beta, but I didn't
# want to hunt out machines from now til eternity.

# comment out the CFLAGS -Wall if you're not using gcc,
# but i'd encourage you to compile with full warnings on.
# let us know what warnings you get, though we don't promise
# to shut them all up.  if you're using sun's SPARCcompiler
# we recommend -Xa mode.  if you're using the native alpha
# compile, we recommend -g3 -O -Olimit 1000.  on recent
# SGI Irix releases using the native compiler, you will
# probably need -xansi.

# see config.h for command-line -D flags you may want to use.
# if you're using SunOS 5 (Solaris 2), be sure to include
# -DSOLARIS in the CFLAGS, since sun made it difficult to
# detect which system you're running.  also, since sun really
# seems to have screwed up and removed both getrusage() and
# wait3() in Solaris 2, you should probably add -DBUILTIN_TIME=0
# to the cflags.  if you're running an OSF1 derivative, try -DOSF1.
# if you're using HP/UX do a -DHPUX.

# also, please use whatever -D flags you need to in order
# to get definitions of all signals from <sys/signal.h>.
# _POSIX_SOURCE, _XOPEN_SOURCE are the obvious ones.

AM_YFLAGS = -d

bin_PROGRAMS = es esdump
check_PROGRAMS = ctest 
TESTS = ctest 

VPATH = $(srcdir) 
HFILES	= config.h es.h gc.h input.h prim.h print.h sigmsgs.h \
	  stdenv.h syntax.h term.h var.h
COMMON_FILES	= access.c closure.c conv.c dict.c eval.c except.c fd.c gc.c glob.c \
	  glom.c input.c heredoc.c list.c match.c open.c opt.c \
	  prim-ctl.c prim-etc.c prim-io.c prim-sys.c prim.c print.c proc.c \
	  sigmsgs.c signal.c split.c syntax.c status.c str.c term.c \
	  token.c tree.c util.c var.c vec.c version.c parse.y
OTHER	= Makefile parse.y mksignal
GEN	= parse.h parse.c parse.output sigmsgs.c initial.c

BUILT_SOURCES = parse.h
es_SOURCES = $(COMMON_FILES) initial.c main.c
ctest_SOURCES = tests/test_print.c tests/test_util.c tests/all_tests.c $(COMMON_FILES)
ctest_LDADD = -lcgreen -lm

esdump_SOURCES = $(COMMON_FILES) dump.c main.c


MANIFEST:
	find . -type f | sed s/..// > MANIFEST

ctags	:
	etags --declarations /usr/include/stdlib.h /usr/include/stdio.h /usr/include/unistd.h /usr/include/signal.h  /usr/include/errno.h /usr/include/dirent.h /usr/include/sys/wait.h /usr/include/sys/stat.h *.c *.h

mostlyclean-local: 
	rm -f $(GEN)
test	: check trip
trip	: es $(srcdir)/trip.es
	./es < $(srcdir)/trip.es

src	:
	@echo ${OTHER} ${CFILES} ${HFILES}

initial.c : esdump $(srcdir)/initial.es
	./esdump < $(srcdir)/initial.es > initial.c || (rm initial.c; false)

sigmsgs.c : mksignal $(SIGFILES)
	sh $(srcdir)/mksignal $(SIGFILES) > sigmsgs.c
