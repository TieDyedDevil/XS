/* term.h -- definition of term structure */

struct Term {
	const char *str;
	Closure *closure;
};
