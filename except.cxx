/* except.c -- exception mechanism ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "print.hxx"

/* globals */
List *exception = NULL;

/* throwE -- raise an exception */
extern void throwE(List *e) {
	assert(!gcisblocked());
	assert(e != NULL);
	throw e;
	NOTREACHED;
}

/* fail -- pass a user catchable error up the exception chain */
extern void fail (const char * from,  const char * fmt, ...) {
	char *s;
	va_list args;

	va_start(args, fmt);
	s = strv(fmt, args);
	va_end(args);

	List *x;
	{
		gcdisable();
		SRef<List> e = mklist(mkstr("error"),
			      	mklist(mkstr((char *) from),
				     	mklist(mkstr(s), NULL)));
		while (gcisblocked())
			gcenable();
		x = e.release();
	}
	throwE(x);
	NOTREACHED;
}

#if DEBUG_EXCEPTIONS
/* raised -- print exceptions as we climb the exception stack */
extern List *raised(List *e) {
	eprint("raised (sp @ %x) %L\n", &e, e, " ");
	return e;
}
#endif
