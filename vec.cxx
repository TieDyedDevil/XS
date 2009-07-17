/* vec.c -- argv[] and envp[] vectors ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

DefineTag(Vector, static);

extern Vector *mkvector(int n) {
	int i;
	Vector *v = reinterpret_cast<Vector*>(
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


extern Vector *vectorize(List *list) {
	int i, n = length(list);

	Ref(Vector *, v, NULL);
	Ref(List *, lp, list);
	v = mkvector(n);
	v->count = n;

	for (i = 0; lp != NULL; lp = lp->next, i++) {
	        /* must evaluate before v->vector[i] */
		const char *s = getstr(lp->term); 
		v->vector[i] = gcdup(s);
	}

	RefEnd(lp);
	RefReturn(v);
}

/* qstrcmp -- a strcmp wrapper for qsort */
extern int qstrcmp(const void *s1, const void *s2) {
	return strcmp(*(const char **)s1, *(const char **)s2);
}

/* sortvector */
extern void sortvector(Vector *v) {
	assert(v->vector[v->count] == NULL);
	qsort(v->vector, v->count, sizeof (char *), qstrcmp);
}
