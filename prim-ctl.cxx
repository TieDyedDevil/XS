/* prim-ctl.c -- control flow primitives ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "prim.hxx"

PRIM(seq) {
	const List* result = ltrue;
	iterate(list)
		result = eval1(list->term, evalflags &~ 
			(list->next == NULL 
			? 0 
			: eval_inchild));
	return result;
}

PRIM(if) {
	iterate(list) {
		const List *cond = eval1(list->term, 
                        evalflags & (list->next == NULL ? eval_inchild : 0));
		list = list->next;
		if (list == NULL)
			return cond;
                else if (istrue(cond))
			return eval1(list->term, evalflags);
	}
	return ltrue;
}

PRIM(forever) {
	List* body = list;
        const List *result = list;
	for (;;) result = eval(body, NULL, evalflags & eval_exitonfalse);
	return result;
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

	const List* result = NULL;

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
