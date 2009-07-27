/* except.c -- exception mechanism ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "print.hxx"

/* globals */
Handler *tophandler = NULL;
Handler *roothandler = NULL;
List *exception = NULL;
Push *pushlist = NULL;

/* pophandler -- remove a handler */
extern void pophandler(Handler *handler) {
	assert(tophandler == handler);
	assert(handler->rootlist == rootlist);
	tophandler = handler->up;
}

/* throwE -- raise an exception */
extern void throwE(List *e) {
	Handler *handler = tophandler;

	assert(!gcisblocked());
	assert(e != NULL);
	assert(handler != NULL);
	tophandler = handler->up;
	
	while (pushlist != handler->pushlist) {
		rootlist = &pushlist->defnroot;
		pushlist->already_popped = true;
		varpop(pushlist);
	}
	evaldepth = handler->evaldepth;

#if ASSERTIONS
	for (; rootlist != handler->rootlist; rootlist = rootlist->next)
		assert(rootlist != NULL);
#else
	rootlist = handler->rootlist;
#endif
	exception = e;
	longjmp(handler->label, 1);
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

/* newchildcatcher -- remove the current handler chain for a new child */
extern void newchildcatcher(void) {
	tophandler = roothandler;
}

#if DEBUG_EXCEPTIONS
/* raised -- print exceptions as we climb the exception stack */
extern List *raised(List *e) {
	eprint("raised (sp @ %x) %L\n", &e, e, " ");
	return e;
}
#endif
