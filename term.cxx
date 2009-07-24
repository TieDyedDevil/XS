/* term.c -- operations on terms ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include "term.hxx"

DefineTag(Term, static);

extern SRef<Term> mkterm(SRef<const char> str, SRef<Closure> closure) {
	SRef<Term> term = reinterpret_cast<Term*>(gcnew(Term));
	term->str = str.release();
	term->closure = closure.release();
	return term;
}

extern SRef<Term> mkstr(SRef<const char> str) {
	SRef<Term> term = gcnew(Term);
        term->str = str.release();
	term->closure = NULL;
        return term;
}

extern Closure *getclosure(SRef<Term> term) {
	if (term->closure == NULL) {
		SRef<const char> s = term->str;
		assert(s);
		if (
			((*s == '{' || *s == '@') && s[strlen(s.uget()) - 1] == '}')
			|| (*s == '$' && s[1] == '&')
			|| hasprefix(s.uget(), "%closure")
		) {
			SRef<Tree> np = parsestring(s.uget());
			if (np == NULL) return NULL;
			term->closure = extractbindings(np.uget());
			term->str = NULL;
		}
	}
	return term->closure;
}

extern const char *getstr(SRef<Term> term) {
	SRef<const char> s = term->str;
	SRef<Closure> closure = term->closure;
	assert((s == NULL) != (closure == NULL));
	if (s != NULL)
		return s.release();

#if 0	/* TODO: decide whether getstr() leaves term in closure or string form */
	Ref(Term *, tp, term);
	s = str("%C", closure);
	tp->str = s;
	tp->closure = NULL;
	RefEnd(tp);
	return s;
#else
	return str("%C", closure.uget());
#endif
}

extern SRef<Term> termcat(SRef<Term> t1, SRef<Term> t2) {
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
