# Makefile for xs

AM_YFLAGS = -d
AM_CXXFLAGS = $(GUILE_CFLAGS)
#AUTOMAKE_OPTIONS = dejagnu
RUNTESTDEFAULTFLAGS = --tool xs XS=`pwd`/xs --srcdir $$srcdir/testsuite --debug

dist_man_MANS = xs.1

bin_PROGRAMS = xs
noinst_PROGRAMS = xsdump
#check_PROGRAMS = ctest 
#TESTS = ctest 

VPATH = $(srcdir) 
HFILES	= config.hxx es.hxx gc.hxx input.hxx prim.hxx print.hxx sigmsgs.hxx \
	  stdenv.hxx syntax.hxx term.hxx var.hxx
COMMON_FILES	= access.cxx closure.cxx conv.cxx eval.cxx fd.cxx glob.cxx \
	  glom.cxx input.cxx heredoc.cxx list.cxx match.cxx opt.cxx \
	  prim-ctl.cxx prim-etc.cxx prim-io.cxx prim-sys.cxx prim.cxx print.cxx proc.cxx \
	  sigmsgs.cxx signal.cxx split.cxx syntax.cxx status.cxx str.cxx term.cxx \
	  token.cxx tree.cxx util.cxx var.cxx version.cxx parse.yxx
OTHER	= Makefile parse.yxx mksignal
GEN	= parse.h parse.cxx parse.output sigmsgs.cxx initial.cxx

BUILT_SOURCES = parse.h
xs_SOURCES = $(COMMON_FILES) initial.cxx main.cxx
xs_LDADD = $(GUILE_LIBS)
#ctest_SOURCES = tests/test_print.cxx tests/test_util.cxx tests/all_tests.cxx $(COMMON_FILES)
#ctest_LDADD = -lcgreen -lm

xsdump_SOURCES = $(COMMON_FILES) dump.cxx main.cxx
xsdump_LDADD = $(xs_LDADD)


MANIFEST:
	find . -type f | sed s/..// > MANIFEST

ctags	:
	etags --declarations /usr/include/stdlib.h /usr/include/stdio.h /usr/include/unistd.h /usr/include/signal.h  /usr/include/errno.h /usr/include/dirent.h /usr/include/sys/wait.h /usr/include/sys/stat.h *.cxx *.hxx

mostlyclean-local: 
	rm -f $(GEN)
test	: check trip testxs
trip	: xs $(srcdir)/trip.xs
	./xs < $(srcdir)/trip.xs

# No point in including all the actual tests as deps
testxs  : xs $(srcdir)/test.xs
	$(srcdir)/test.xs

src	:
	@echo ${OTHER} ${CFILES} ${HFILES}

initial.cxx : xsdump $(srcdir)/initial.xs
	./xsdump < $(srcdir)/initial.xs > initial.cxx || (rm initial.cxx; false)

sigmsgs.cxx : mksignal $(SIGFILES) es.hxx 
	sh $(srcdir)/mksignal $(SIGFILES) > sigmsgs.cxx
