/* str.c -- xs string operations ($Revision: 1.1.1.1 $) */

#include "xs.hxx"
#include "print.hxx"
#include <sstream>
#include <limits>
using std::stringstream;

class Str_format : public Format {
public:
	void put(char c) {
		sstream.put(c);
	}
	void append(const char *s, size_t len) {
		sstream.write(s, len);
	}
	char *gcstr() {
		return gcdup(sstream.str().c_str());
	}

	// Growth, size already handled
	int size() const {
		return std::numeric_limits<int>::max();
	}
private:
	stringstream sstream;
};

/* strv -- print a formatted string into gc space */
extern char *strv(const char *fmt, va_list args) {
	Str_format format;

	va_copy(format.args, args);
	format.flushed	= 0;

	printfmt(&format, fmt);
	format.put('\0');

	return format.gcstr();
}

/* str -- create a string (in garbage collection space) by printing to it */
extern char *str (const char * fmt, ...) {
	char *s;
	va_list args;
	va_start(args, fmt);
	s = strv(fmt, args);
	va_end(args);
	return s;
}

/*
 * StrList -- lists of strings
 *	to even include these is probably a premature optimization
 */

extern StrList* mkstrlist(const char* str, StrList* next) {
	assert(str != NULL);
	StrList* list = gcnew(StrList);
	list->str = str;
	list->next = next;
	return list;
}
