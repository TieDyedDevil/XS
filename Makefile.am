# Makefile for xs

AM_YFLAGS = -d
AUTOMAKE_OPTIONS = dejagnu
RUNTESTDEFAULTFLAGS = --tool xs XS=`pwd`/xs --srcdir $$srcdir/testsuite 

dist_man_MANS = xs.1

bin_PROGRAMS = xs
noinst_PROGRAMS = xsdump
check_PROGRAMS = ctest 
TESTS = ctest 

VPATH = $(srcdir) 
HFILES	= config.h es.h gc.h input.h prim.h print.h sigmsgs.h \
	  stdenv.h syntax.h term.h var.h
COMMON_FILES	= access.c closure.c conv.c dict.c eval.c except.c fd.c gc.c glob.c \
	  glom.c input.c heredoc.c list.c match.c opt.c \
	  prim-ctl.c prim-etc.c prim-io.c prim-sys.c prim.c print.c proc.c \
	  sigmsgs.c signal.c split.c syntax.c status.c str.c term.c \
	  token.c tree.c util.c var.c vec.c version.c parse.y
OTHER	= Makefile parse.y mksignal
GEN	= parse.h parse.c parse.output sigmsgs.c initial.c

BUILT_SOURCES = parse.h
xs_SOURCES = $(COMMON_FILES) initial.c main.c
ctest_SOURCES = tests/test_print.c tests/test_util.c tests/test_glob.c tests/all_tests.c $(COMMON_FILES)
ctest_LDADD = -lcgreen -lm

xsdump_SOURCES = $(COMMON_FILES) dump.c main.c


MANIFEST:
	find . -type f | sed s/..// > MANIFEST

ctags	:
	etags --declarations /usr/include/stdlib.h /usr/include/stdio.h /usr/include/unistd.h /usr/include/signal.h  /usr/include/errno.h /usr/include/dirent.h /usr/include/sys/wait.h /usr/include/sys/stat.h *.c *.h

mostlyclean-local: 
	rm -f $(GEN)
test	: check trip
trip	: xs $(srcdir)/trip.xs
	./xs < $(srcdir)/trip.xs

src	:
	@echo ${OTHER} ${CFILES} ${HFILES}

initial.c : xsdump $(srcdir)/initial.xs
	./xsdump < $(srcdir)/initial.xs > initial.c || (rm initial.c; false)

sigmsgs.c : mksignal $(SIGFILES)
	sh $(srcdir)/mksignal $(SIGFILES) > sigmsgs.c
