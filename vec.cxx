/* vec.c -- argv[] and envp[] vectors ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include <iostream>
#include <algorithm>

size_t vector_size(const Vector *v) {
	/* TODO: +1 is probably just an artifact of an earlier time, no? */
	return reinterpret_cast<const char*>(v->vector + v->alloclen + 1) - reinterpret_cast<const char*>(v);
}

extern Vector* mkvector(int n) {
	int i;
	Vector* v = reinterpret_cast<Vector*>(GC_MALLOC(offsetof(Vector, vector[0]) + (n + 1) * sizeof(char*)));
	v->alloclen = n;
	v->count = 0;
	for (i = 0; i <= n; i++)
		v->vector[i] = NULL;
	return v;
}

extern Vector* vectorize(List* list) {
	int n = length(list);
	Vector* v = mkvector(n);
	v->count = n; /* GC may forward extra NULL pointers, no matter */
	for (int i = 0; list != NULL; list = list->next, i++)
		v->vector[i] = gcdup(getstr(list->term));

	return v;
}

/* qstrcmp -- a strcmp wrapper for sort */
extern int qstrcmp(const char *s1, const char *s2) {
	return strcmp(s1, s2) < 0;
}

/* sortvector */
extern void sortvector(Vector* v) {
	assert(v->vector[v->count] == NULL);
	std::sort(v->vector, v->vector + v->count, qstrcmp);
}
