/* term.c -- operations on terms ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include "term.hxx"

DefineTag(Term, static);

extern Ref<Term> mkterm(Ref<const char> str, Ref<Closure> closure) {
	Ref<Term> term = gcnew(Term);
	term->str = str.release();
	term->closure = closure.release();
	return term;
}

extern Ref<Term> mkstr(Ref<const char> str) {
	Ref<Term> term = gcnew(Term);
        term->str = str.release();
	term->closure = NULL;
        return term;
}

extern Closure *getclosure(Ref<Term> term) {
	if (term->closure == NULL) {
		Ref<const char> s = term->str;
		assert(s);
		if (
			((*s == '{' || *s == '@') && s[strlen(s.uget()) - 1] == '}')
			|| (*s == '$' && s[1] == '&')
			|| hasprefix(s.uget(), "%closure")
		) {
			Ref<Tree> np = parsestring(s.uget());
			if (np == NULL) return NULL;
			term->closure = extractbindings(np.uget());
			term->str = NULL;
		}
	}
	return term->closure;
}

extern const char *getstr(Ref<Term> term) {
	Ref<const char> s = term->str;
	Ref<Closure> closure = term->closure;
	assert((s == NULL) != (closure == NULL));
	if (s != NULL)
		return s.release();

#if 0	/* TODO: decide whether getstr() leaves term in closure or string form */
	s = str("%C", closure);
	term->str = s;
	term->closure = NULL;
	return s;
#else
	return str("%C", closure.uget());
#endif
}

extern Ref<Term> termcat(Ref<Term> t1, Ref<Term> t2) {
	if (t1 == NULL)
		return t2.release();
	if (t2 == NULL)
		return t1.release();
	return mkstr(
		str("%s%s", getstr(t1.uget()), getstr(t2.uget())));
}


static void *TermCopy(void *op) {
	void *np = gcnew(Term);
	memcpy(np, op, sizeof (Term));
	return np;
}

static size_t TermScan(void *p) {
	Term *term = reinterpret_cast<Term*>(p);
	term->closure = reinterpret_cast<Closure*>(forward(term->closure));
	term->str = reinterpret_cast<const char*>(forward(const_cast<char*>(term->str)));
	return sizeof (Term);
}

extern bool termeq(Term *term, const char *s) {
	assert(term != NULL);
	if (term->str == NULL)
		return false;
	return streq(term->str, s);
}

extern bool isclosure(Term *term) {
	assert(term != NULL);
	return term->closure != NULL;
}
