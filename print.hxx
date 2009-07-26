/* print.hxx -- interface to formatted printing routines ($Revision: 1.1.1.1 $) */

struct Format {
    /* for the formatting routines */
	va_list args;
	long flags, f1, f2;
	int invoker;
    /* for the buffer maintainence routines */
	char *buf, *bufbegin, *bufend;
	int flushed;
	void (*grow)(Format *, size_t);
	union { int n; void *p; } u;
};


/* Format->flags values */
enum {
	FMT_long	= 1,		/* %l */
	FMT_short	= 2,		/* %h */
	FMT_unsigned	= 4,		/* %u */
	FMT_zeropad	= 8,		/* %0 */
	FMT_leftside	= 16,		/* %- */
	FMT_altform	= 32,		/* %# */
	FMT_f1set	= 64,		/* %<n> */
	FMT_f2set	= 128		/* %.<n> */
};

typedef bool (*Conv)(Format *);

extern Conv fmtinstall(int, Conv);
extern int printfmt(Format *, const char *);
extern int fmtprint(Format *, const char *, ...);
extern void fmtappend(Format *, const char *, size_t);

extern int print(const char *fmt, ...);
extern int eprint(const char *fmt, ...);
extern int fprint(int fd, const char *fmt, ...);

extern char *strv(const char *fmt, va_list args);	/* varargs interface to str() */

#define	FPRINT_BUFSIZ	1024

inline void fmtcat(Format *format, const char *s) {
	fmtappend(format, s, strlen(s));
}



inline void fmtputc(Format *f, char c) {
	if (f->buf >= f->bufend)
		(*f->grow)(f, (size_t)32); 
	*f->buf++ = c;
}
