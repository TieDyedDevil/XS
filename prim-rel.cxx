/* prim-rel.cxx -- relational primitives */

#include "xs.hxx"
#include "prim.hxx"
#include <string.h>
#include <stdlib.h>

static int isnumber(const char *s) {
	return strspn(s, "0123456789.") == strlen(s);
}

static int isfloat(const char *s) {
	return strchr(s, '.') != NULL;
}

PRIM(cmp) {
	if (list == NULL || list->next == NULL)
		fail("$&cmp", "usage: $&cmp a b");
	const char *a = getstr(list->term);
	const char *b = getstr(list->next->term);
	long r;
	if (isnumber(a) && isnumber(b)) {
		if (isfloat(a) || isfloat(b)) {
			float va = strtod(a, NULL);
			float vb = strtod(b, NULL);
			r = va > vb ? 1 : va < vb ? -1 : 0;
		} else r = strtol(a, NULL, 10) - strtol(b, NULL, 10);
	} else r = strcoll(a, b);

	list = mklist(mkstr(str("%d", r > 0 ? 1 : r < 0 ? -1 : 0)), NULL);
	return list;
}

extern void initprims_rel(Prim_dict& primdict) {
	X(cmp);
}

