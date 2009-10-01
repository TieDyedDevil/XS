/* split.c -- split strings based on separators ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include <sstream>
using std::stringstream;

static bool coalesce;
static bool splitchars;
static stringstream buf;
static List *value;

static bool ifsvalid = false;
static char ifs[10], isifs[256];

extern void startsplit(const char *sep, bool coalescef) {
	value = NULL;
	buf.str("");
	coalesce = coalescef;
	splitchars = !coalesce && *sep == '\0';

	if (!ifsvalid || !streq(sep, ifs)) {
		if (strlen(sep) + 1 < sizeof ifs) {
			strcpy(ifs, sep);
			ifsvalid = true;
		} else ifsvalid = false;

		memzero(isifs, sizeof isifs);

		isifs['\0'] = true;
		for (int c; (c = (*(unsigned const char *)sep)) != '\0'; sep++)
			isifs[c] = true;
	}
}

static void skipifs(unsigned char*& s, unsigned char * inend) {
	assert(coalesce);
	while (s < inend) {
		int c = *s++;
		if (!isifs[c]) {
			buf.put(c);
			return;
		}
	}
	buf.str(""); /* Tell endsplit not to touch buf */
}

template <bool coalesce>
static inline void newbuf(unsigned char*& s, unsigned char *inend) {
	buf.str("");
	if (coalesce) skipifs(s, inend);
}

template <bool coalesce>
static inline void handleifs(unsigned char*& s, unsigned char *inend) {
	Term *term = mkstr(gcdup(buf.str().c_str()));
	value = mklist(term, value);
	newbuf<coalesce>(s, inend);
}

/* Doesn't handle splitchars case, only coalesce + normal */
template <bool coalesce>
static void runsplit(unsigned char*& s, unsigned char * inend) {
	if (coalesce) skipifs(s, inend);
	while (s < inend) {
		int c = *s++;
		if (isifs[c]) handleifs<coalesce>(s, inend);
		else buf.put(c);
	}
}

extern void splitstring(const char *in, size_t len, bool endword) {
	unsigned char *s = (unsigned char *) in, *const inend = s + len;

	if (splitchars) {
		while (s < inend) {
			Term *term = mkstr(gcndup((char *) s++, 1));
			value = mklist(term, value);
		}
		
		return;
	} 
	else if (coalesce) runsplit<true>(s, inend);
	else runsplit<false>(s, inend);

	if (endword && buf.tellp() > 0) {
		Term *term = mkstr(gcdup(buf.str().c_str()));
		value = mklist(term, value);
		buf.str("");
	}
}

extern List* endsplit(void) {
	if (buf.tellp() > 0) {
		Term* term = mkstr(gcdup(buf.str().c_str()));
		value = mklist(term, value);
		buf.str("");
	}
	List* result = reverse(value);
	value = NULL;
	return result;
}

extern List* fsplit(const char *sep, List* list, bool coalesce) {
	startsplit(sep, coalesce);
	for (; list; list = list->next) {
		const char* s = getstr(list->term);
		splitstring(s, strlen(s), true);
	}
	return endsplit();
}
