/* str.c -- es string operations ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include "print.hxx"

struct Str_format : public Format {
	void grow(size_t more) {
		Buffer *newbuf = expandbuffer(reinterpret_cast<Buffer*>(u.p), more);
		u.p		= newbuf;
		buf		= newbuf->str + (buf - bufbegin);
		bufbegin	= newbuf->str;
		bufend		= newbuf->str + newbuf->len;
	}
};

/* strv -- print a formatted string into gc space */
extern char *strv(const char *fmt, va_list args) {
	Str_format format;

	Buffer *buf = openbuffer(0);
	format.u.p	= buf;
#if NO_VA_LIST_ASSIGN
	memcpy(format.args, args, sizeof(va_list));
#else
	format.args	= args;
#endif
	format.buf	= buf->str;
	format.bufbegin	= buf->str;
	format.bufend	= buf->str + buf->len;
	format.flushed	= 0;

	printfmt(&format, fmt);
	fmtputc(&format, '\0');
	

	return sealbuffer(reinterpret_cast<Buffer*>(format.u.p));
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
