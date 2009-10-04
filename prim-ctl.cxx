/* prim-ctl.c -- control flow primitives ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "prim.hxx"

PRIM(seq) {
	List* result = ltrue;
	for (; list; list = list->next)
		result = eval1(list->term, evalflags &~ (list->next == NULL ? 0 : eval_inchild));
	return result;
}

PRIM(if) {
	for (; list != NULL; list = list->next) {
		List *cond = eval1(list->term, evalflags & (list->next == NULL ? eval_inchild : 0));
		list = list->next;
		if (list == NULL) {
			return cond;
		}
		if (istrue(cond)) {
			List *result = eval1(list->term, evalflags);
			return result;
		}
	}
	return ltrue;
}

PRIM(forever) {
	List* body = list;
	for (;;) list = eval(body, NULL, evalflags & eval_exitonfalse);
	return list;
}

PRIM(throw) {
	if (list == NULL)
		fail("$&throw", "usage: throw exception [args ...]");
	throw list;
	NOTREACHED;
}

PRIM(catch) {
	Atomic retry;

	if (list == NULL)
		fail("$&catch", "usage: catch catcher body");

	List* result = NULL;

	do {
		retry = false;

		try {

			result = eval(list->next, NULL, evalflags);

		} catch (List *frombody) {

			blocksignals();
			try {
				result
				  = eval(mklist(list->term, frombody),
					 NULL,
					 evalflags);
				unblocksignals();
			} catch (List *fromcatcher) {

				if (termeq(fromcatcher->term, "retry")) {
					retry = true;
					unblocksignals();
				} else
					throw fromcatcher;
			}

		}
	} while (retry);
	return result;
}

extern void initprims_controlflow(Prim_dict& primdict) {
	X(seq);
	X(if);
	X(throw);
	X(forever);
	X(catch);
}
