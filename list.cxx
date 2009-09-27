/* list.c -- operations on lists ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

/*
 * allocation and garbage collector support
 */

extern List *mklist(Term* term, List* next) {
	assert(term != NULL);
	List* list = gcnew(List);
	list->term = term;
	list->next = next;
	return list;
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
extern List *append(List* head, List* tail) {
	List *lp, **prevp;
	

	for (prevp = &lp; head; head = head->next) {
		List *np = mklist(head->term, NULL);
		*prevp = np;
		prevp = &np->next;
	}
	*prevp = tail;

	List* result = lp;
	
	return result;
}

/* listcopy -- make a copy of a list */
extern List *listcopy(List *list) {
	return append(list, NULL);
}

/* length -- lenth of a list */
extern int length(List* list) {
	int len = 0;
	for (; list != NULL; list = list->next)
		++len;
	return len;
}

/* listify -- turn an argc/argv vector into a list */
extern List *listify(int argc, char **argv) {
	
	List *list = NULL;
	while (argc > 0) {
		Term *term = mkstr(argv[--argc]);
		list = mklist(term, list);
	}
	
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

static List *listify(Vector* v) {
	List* list = NULL;
	while (v->count > 0) {
		Term* term = mkstr(v->vector[--v->count]);
		list = mklist(term, list);
	}
	return list;
}

/* sortlist */
extern List* sortlist(List* list) {
	Vector* v = vectorize(list);
	sortvector(v);
	return listify(v);
}
