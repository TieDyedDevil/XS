/* print.hxx -- interface to formatted printing routines */

struct Format {
public:
	virtual ~Format() {};
    /* for the formatting routines */
	va_list args;
	long flags, f1, f2;
	int invoker;
    /* for the buffer maintainence routines */
	virtual void put(char c)=0;
	int flushed;
	virtual void append(const char *s, size_t len)=0;
	virtual int size() const=0;
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

extern int print(const char *fmt, ...);
extern int eprint(const char *fmt, ...);
extern int fprint(int fd, const char *fmt, ...);

/* varargs interface to str() */
extern char *strv(const char *fmt, va_list args);

#define	FPRINT_BUFSIZ	1024

inline void fmtcat(Format *format, const char *s) {
	format->append(s, strlen(s));
}
