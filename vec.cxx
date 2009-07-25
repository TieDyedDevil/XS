/* vec.c -- argv[] and envp[] vectors ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include <iostream>
#include <algorithm>

DefineTag(Vector, static);

size_t vector_size(const Vector *v) {
	/* TODO: +1 is probably just an artifact of an earlier time, no? */
	return reinterpret_cast<const char*>(v->vector + (v->alloclen + 1)) - reinterpret_cast<const char*>(v);
}

extern SRef<Vector> mkvector(int n) {
	int i;
	SRef<Vector> v = reinterpret_cast<Vector*>(gcalloc(offsetof(Vector, vector[0]), &VectorTag));
	v->alloclen = n;
	v->count = 0;
	for (i = 0; i <= n; i++)
		v->vector[i] = NULL;
	return v;
}

static void *VectorCopy(void *ov_void) {
	Vector *ov = reinterpret_cast<Vector*>(ov_void);
	size_t n = vector_size(ov);;
	void *nv = gcalloc(n, &VectorTag);
	memcpy(nv, ov, n);
	return nv;
}

static size_t VectorScan(void *p) {
	Vector *v = reinterpret_cast<Vector*>(p);
	for (int i = 0; i <= v->count; i++)
		v->vector[i] = reinterpret_cast<char*>(forward(v->vector[i]));
	return vector_size(v);;
}

extern SRef<Vector> vectorize(SRef<List> list) {
	int n = length(list.uget());
	SRef<Vector> v = mkvector(n);
	v->count = n; /* GC may forward extra NULL pointers, no matter */
	for (int i = 0; list != NULL; list = list->next, i++) {
		/* gcdup() must occur _before_ v->vector[i] because
		 * otherwise v may be forwarded
		 */
		char *t = gcdup(getstr(list->term));
		v->vector[i] = t;
	}

	return v;
}

/* qstrcmp -- a strcmp wrapper for sort */
extern int qstrcmp(const char *s1, const char *s2) {
	return strcmp(s1, s2) < 0;
}

/* sortvector */
extern void sortvector(SRef<Vector> v) {
	assert(v->vector[v->count] == NULL);
	std::sort(v->vector, v->vector + v->count, qstrcmp);
}
