/* str.c -- es string operations ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include "print.hxx"

/* grow -- buffer grow function for str() */
static void str_grow(Format *f, size_t more) {
	Buffer *buf = expandbuffer(reinterpret_cast<Buffer*>(f->u.p), more);
	f->u.p		= buf;
	f->buf		= buf->str + (f->buf - f->bufbegin);
	f->bufbegin	= buf->str;
	f->bufend	= buf->str + buf->len;
}

/* strv -- print a formatted string into gc space */
extern char *strv(const char *fmt, va_list args) {
	Format format;

	
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
	format.grow	= str_grow;
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


#define	PRINT_ALLOCSIZE	64

/* mprint_grow -- buffer grow function for mprint() */
static void mprint_grow(Format *format, size_t more) {
	char *buf;
	size_t len = format->bufend - format->bufbegin + 1;
	len = (len >= more)
		? len * 2
		: ((len + more) + PRINT_ALLOCSIZE) &~ (PRINT_ALLOCSIZE - 1);
	buf = reinterpret_cast<char*>(erealloc(format->bufbegin, len));
	format->buf	 = buf + (format->buf - format->bufbegin);
	format->bufbegin = buf;
	format->bufend	 = buf + len - 1;
}

/* mprint -- create a string in ealloc space by printing to it */
extern char *mprint (const char * fmt, ...) {
	Format format;
	format.u.n = 1;
	va_start(format.args, fmt);

	format.buf	= reinterpret_cast<char*>(ealloc(PRINT_ALLOCSIZE));
	format.bufbegin	= format.buf;
	format.bufend	= format.buf + PRINT_ALLOCSIZE - 1;
	format.grow	= mprint_grow;
	format.flushed	= 0;

	printfmt(&format, fmt);
	*format.buf = '\0';
	va_end(format.args);
	return format.bufbegin;
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
