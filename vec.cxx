/* vec.c -- argv[] and envp[] vectors ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include <algorithm>

DefineTag(Vector, static);

extern SRef<Vector> mkvector(int n) {
	int i;
	SRef<Vector> v = reinterpret_cast<Vector*>(
	  gcalloc(offsetof(Vector, vector[0]) +
		  (n + 1) * sizeof(char*),
		  &VectorTag));
	v->alloclen = n;
	v->count = 0;
	for (i = 0; i <= n; i++)
		v->vector[i] = NULL;
	return v;
}

static void *VectorCopy(void *ov) {
	size_t n = offsetof(Vector, vector[0]) + sizeof(char*) *
	  (reinterpret_cast<Vector *>(ov)->alloclen + 1);
	void *nv = gcalloc(n, &VectorTag);
	memcpy(nv, ov, n);
	return nv;
}

static size_t VectorScan(void *p) {
	Vector *v = reinterpret_cast<Vector*>(p);
	int i, n = v->count;
	for (i = 0; i <= n; i++)
		v->vector[i] = reinterpret_cast<char*>(forward(v->vector[i]));
	return offsetof(Vector, vector[0]) + sizeof(char*) * (v->alloclen + 1);
}


extern SRef<Vector> vectorize(SRef<List> list) {
	int i, n = length(list.uget());

	SRef<Vector> v = NULL;
	v = mkvector(n);
	v->count = n;

	for (i = 0; list != NULL; list = list->next, i++) {
	        /* must evaluate before v->vector[i] */
		SRef<const char> s = getstr(list->term); 
		v->vector[i] = gcdup(s.uget());
	}

	return v.release();
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
