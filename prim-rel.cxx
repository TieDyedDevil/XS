/* prim-rel.c -- relational primitives */

#include "xs.hxx"
#include "prim.hxx"
#include <string.h>

PRIM(cmp) {
	if (list == NULL || list->next == NULL)
		fail("$&cmp", "usage: $&cmp a b");
	const char *a = getstr(list->term);
	const char *b = getstr(list->next->term);
	int r = strcoll(a, b);

	list = mklist(mkstr(str("%d", r > 0 ? 1 : r < 0 ? -1 : 0)), NULL);
	return list;
}

extern void initprims_rel(Prim_dict& primdict) {
	X(cmp);
}

