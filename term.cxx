/* term.cxx -- operations on terms */

#include "xs.hxx"
#include "term.hxx"

extern Term* mkterm(const char* str, Closure* closure) {
	Term* term = gcnew(Term);
	term->str = str;
	term->closure = closure;
	return term;
}

extern Term* mkstr(const char* str) {
	Term* term = gcnew(Term);
        term->str = str;
	term->closure = NULL;
        return term;
}

extern Closure *getclosure(Term* term) {
	if (term->closure == NULL) {
		const char* s = term->str;
		assert(s);
		if (
			((*s == '{' || *s == '@') && s[strlen(s) - 1] == '}')
			|| (*s == '$' && s[1] == '&')
			|| hasprefix(s, "%closure")
		) {
			Tree* np = parsestring(s);
			if (np == NULL) return NULL;
			term->closure = extractbindings(np);
			term->str = NULL;
		}
	}
	return term->closure;
}

extern const char *getstr(Term* term) {
	assert (term != NULL);
	const char* s = term->str;
	Closure* closure = term->closure;
	assert((s == NULL) != (closure == NULL));
	if (s != NULL)
		return s;

#if 0	/* TODO: decide whether getstr() leaves term in closure or string form */
	s = str("%C", closure);
	term->str = s;
	term->closure = NULL;
	return s;
#else
	return str("%C", closure);
#endif
}

extern Term* termcat(Term* t1, Term* t2){
	if (t1 == NULL)
		return t2;
	if (t2 == NULL)
		return t1;
	return mkstr(
		str("%s%s", getstr(t1), getstr(t2)));
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
