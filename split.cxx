/* split.c -- split strings based on separators ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

static bool coalesce;
static bool splitchars;
static Buffer *buffer;
static List *value;

static bool ifsvalid = false;
static char ifs[10], isifs[256];

extern void startsplit(const char *sep, bool coalescef) {
	static bool initialized = false;
	if (!initialized) {
		initialized = true;
		globalroot(&value);
	}

	value = NULL;
	buffer = NULL;
	coalesce = coalescef;
	splitchars = !coalesce && *sep == '\0';

	if (!ifsvalid || !streq(sep, ifs)) {
		int c;
		if (strlen(sep) + 1 < sizeof ifs) {
			strcpy(ifs, sep);
			ifsvalid = true;
		} else
			ifsvalid = false;
		memzero(isifs, sizeof isifs);
		for (isifs['\0'] = true; (c = (*(unsigned const char *)sep)) != '\0'; sep++)
			isifs[c] = true;
	}
}

extern void splitstring(const char *in, size_t len, bool endword) {
	gcdisable(); /* char *s can't be made gc-safe */
	Buffer *buf = buffer;
	unsigned char *s = (unsigned char *) in, *inend = s + len;

	if (splitchars) {
		assert(buf == NULL);
		while (s < inend) {
			Term *term = mkstr(gcndup((char *) s++, 1));
			value = mklist(term, value);
		}
		gcenable();
		return;
	}

	if (!coalesce && buf == NULL)
		buf = openbuffer(0);

	while (s < inend) {
		int c = *s++;
		if (buf != NULL)
			if (isifs[c]) {
				Term *term = mkstr(sealcountedbuffer(buf));
				value = mklist(term, value);
				buf = coalesce ? NULL : openbuffer(0);
			} else
				buf = bufputc(buf, c);
		else if (!isifs[c])
			buf = bufputc(openbuffer(0), c);
	}

	if (endword && buf != NULL) {
		Term *term = mkstr(sealcountedbuffer(buf));
		value = mklist(term, value);
		buf = NULL;
	}
	buffer = buf;
	gcenable();
}

extern List *endsplit(void) {
	List *result;

	if (buffer != NULL) {
		Term *term = mkstr(sealcountedbuffer(buffer));
		value = mklist(term, value);
		buffer = NULL;
	}
	result = reverse(value);
	value = NULL;
	return result;
}

extern List *fsplit(const char *sep, List *list, bool coalesce) {
	Ref(List *, lp, list);
	startsplit(sep, coalesce);
	for (; lp != NULL; lp = lp->next) {
		/* No need for Ref because gc cannot run
		 * between these two statements         */
		const char *s = getstr(lp->term);
		splitstring(s, strlen(s), true);
	}
	RefEnd(lp);
	return endsplit();
}
