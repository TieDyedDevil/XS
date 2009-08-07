/* list.c -- operations on lists ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

/*
 * allocation and garbage collector support
 */

DefineTag(List, static);

extern List *mklist(Ref<Term> term, Ref<List> next) {
	assert(term != NULL);
	Ref<List> list = gcnew(List);
	list->term = term.release();
	list->next = next.release();
	return list.release();
}

static void *ListCopy(void *op) {
	void *np = gcnew(List);
	memcpy(np, op, sizeof (List));
	return np;
}

static size_t ListScan(void *p) {
	List *list = reinterpret_cast<List*>(p);
	list->term = reinterpret_cast<Term*>(forward(list->term));
	list->next = reinterpret_cast<List*>(forward(list->next));
	return sizeof (List);
}


/*
 * basic list manipulations
 */

/* reverse -- destructively reverse a list */
extern List *reverse(List *list) {
	List *prev, *next;
	if (list == NULL)
		return NULL;
	prev = NULL;
	do {
		next = list->next;
		list->next = prev;
		prev = list;
	} while ((list = next) != NULL);
	return prev;
}

/* append -- merge two lists, non-destructively */
extern List *append(Ref<List> head, Ref<List> tail) {
	List *lp, **prevp;
	gcreserve(40 * sizeof (List));
	gcdisable();

	for (prevp = &lp; head; head = head->next) {
		List *np = mklist(head->term, NULL);
		*prevp = np;
		prevp = &np->next;
	}
	*prevp = tail.release();

	Ref<List> result = lp;
	gcenable();
	return result.release();
}

/* listcopy -- make a copy of a list */
extern List *listcopy(List *list) {
	return append(list, NULL);
}

/* length -- lenth of a list */
extern int length(Ref<List> list) {
	int len = 0;
	for (; list != NULL; list = list->next)
		++len;
	return len;
}

/* listify -- turn an argc/argv vector into a list */
extern List *listify(int argc, char **argv) {
	gcdisable();
	List *list = NULL;
	while (argc > 0) {
		Term *term = mkstr(argv[--argc]).release();
		list = mklist(term, list);
	}
	gcenable();
	return list;
}

/* nth -- return nth element of a list, indexed from 1 */
extern Term *nth(List *list, int n) {
	assert(n > 0);
	for (; list != NULL; list = list->next) {
		assert(list->term != NULL);
		if (--n == 0)
			return list->term;
	}
	return NULL;
}

static List *listify(Ref<Vector> v) {
	Ref<List> list;
	while (v->count > 0) {
		Ref<Term> term = mkstr(v->vector[--v->count]);
		list = mklist(term, list);
	}
	return list.release();
}

/* sortlist */
extern Ref<List> sortlist(Ref<List> list) {
	Ref<Vector> v = vectorize(list);
	sortvector(v);
	return listify(v);
}
