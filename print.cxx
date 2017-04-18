/* print.cxx -- formatted printing routines */

#include "xs.hxx"
#include "print.hxx"

/* Should be the > than he the largest numerical value of any normal english character used for fmttab */
/* So for ASCII-derived, 128 should work */
#define	MAXCONV 128

/*
 * conversion functions
 *	true return -> flag changes only, not a conversion
 */

#define	Flag(name, flag) \
static bool name(Format *format) { \
	format->flags |= flag; \
	return true; \
}

Flag(uconv,	FMT_unsigned)
Flag(hconv,	FMT_short)
Flag(longconv,	FMT_long)
Flag(altconv,	FMT_altform)
Flag(leftconv,	FMT_leftside)
Flag(dotconv,	FMT_f2set)

static bool digitconv(Format *format) {
	int c = format->invoker;
	if (format->flags & FMT_f2set)
		format->f2 = 10 * format->f2 + c - '0';
	else {
		format->flags |= FMT_f1set;
		format->f1 = 10 * format->f1 + c - '0';
	}
	return true;
}

static bool zeroconv(Format *format) {
	if (format->flags & (FMT_f1set | FMT_f2set))
		return digitconv(format);
	format->flags |= FMT_zeropad;
	return true;
}

static void pad(Format *format, long len, int c) {
	while (len-- > 0) format->put(c);
}

static bool sconv(Format *format) {
	char *s = va_arg(format->args, char *);
	if ((format->flags & FMT_f1set) == 0)
		fmtcat(format, s);
	else {
		size_t len = strlen(s), width = format->f1 - len;
		if (format->flags & FMT_leftside) {
			format->append(s, len);
			pad(format, width, ' ');
		} else {
			pad(format, width, ' ');
			format->append(s, len);
		}
	}
	return false;
}

static bool fconv(Format *format) {
	double f = va_arg(format->args, double);
	int point, sign;
	const int repprec = 6;
	const int defprec = 6;
	/* ecvt(), though obsolete in POSIX, is exactly what we need. */
	const char *digits = ecvt(f, repprec, &point, &sign);
	/* FINISH - do actual formatting; not temporary visualization. */
	/* We need be concerned with width (format->f1) and precision
	   (format->f2; default = 6). Don't forget to round when
	   precision is less than defprec. Overflow width if needed.
	   Flag `#` means to include a decimal point even for an
	   integral value.
	   Flag `-` causes left-justification.
	   Flag `0` changes padding to zeroes instead of blanks.
	   Add leading zero (before `.`) when point = 0.
	   When point <= -repprec, print 0.0 per width and precision.
	   Handle number = '000000' as a special case, since ecvt()
	   allows point to be either 0 or 1. */
	/*
	format->flags & FMT_leftside
	format->flage & FMT_altform
	format->flags & FMT_zeropad
	format->f1
	format->f2
	*/
	size_t len = strlen(digits);
	format->put(sign ? '-' : '+');
	format->append(digits, len);
	format->put(' ');
#define dpp_buflen 8
	char dpp[dpp_buflen];
	char *p = dpp+dpp_buflen-1;
	int dps = point < 0;
	if (dps) point = -point;
	do {
		*p-- = point % 10 + '0';
		point = point / 10;
	} while (point != 0);
	if (dps) format->put('-');
	format->append(p+1, (p-dpp)-(dpp_buflen-3));
#undef dpp_buflen
	return false;
}

char *utoa(unsigned long long u, char *t, unsigned int radix, const char *digit) {
	if (u >= radix) {
		t = utoa(u / radix, t, radix, digit);
		u %= radix;
	}
	*t++ = digit[u];
	return t;
}

static void intconv(Format *format, unsigned int radix, int upper, const char *altform) {
	static const char * table[] = {
		"0123456789abcdefghijklmnopqrstuvwxyz",
		"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	};
	char padchar;
	size_t len, pre, zeroes, padding, width;
	long long n; 
	long flags;
	unsigned long long u;
	char number[999], prefix[20];

	if (radix > 36)
		return;

	flags = format->flags;
	if (flags & FMT_long)
		n = va_arg(format->args, long long);
	else if (flags & FMT_short)
		n = va_arg(format->args, int);
	else
		n = va_arg(format->args, int);

	pre = 0;
	if ((flags & FMT_unsigned) || n >= 0)
		u = n;
	else {
		prefix[pre++] = '-';
		u = -n;
	}

	if (flags & FMT_altform)
		while (*altform != '\0')
			prefix[pre++] = *altform++;

	len = utoa(u, number, radix, table[upper]) - number;
	if ((flags & FMT_f2set) && (size_t) format->f2 > len)
		zeroes = format->f2 - len;
	else
		zeroes = 0;

	width = pre + zeroes + len;
	if ((flags & FMT_f1set) && (size_t) format->f1 > width) {
		padding = format->f1 - width;
	} else
		padding = 0;

	padchar = ' ';
	if (padding > 0 && flags & FMT_zeropad) {
		padchar = '0';
		if ((flags & FMT_leftside) == 0) {
			zeroes += padding;
			padding = 0;
		}
	}

	if ((flags & FMT_leftside) == 0)
		pad(format, padding, padchar);
	format->append(prefix, pre);
	pad(format, zeroes, '0');
	format->append(number, len);
	if (flags & FMT_leftside)
		pad(format, padding, padchar);
}

static bool cconv(Format *format) {
	format->put(va_arg(format->args, int));
	return false;
}

static bool dconv(Format *format) {
	intconv(format, 10, 0, "");
	return false;
}

static bool oconv(Format *format) {
	intconv(format, 8, 0, "0");
	return false;
}

static bool xconv(Format *format) {
	intconv(format, 16, 0, "0x");
	return false;
}

static bool pctconv(Format *format) {
	format->put('%');
	return false;
}

static bool badconv(Format *format) {
#if HAVE_LIBFFI
	fail("printfmt", "bad conversion character: %%%c", format->invoker);
#else
	panic("bad conversion character in printfmt: %%%c", format->invoker);
	NOTREACHED;
#endif
}


/*
 * conversion table management
 */

static Conv *fmttab = NULL;

static void inittab(void) {
	int i;

	fmttab = reinterpret_cast<Conv*>(ealloc(MAXCONV * sizeof (Conv)));
	for (i = 0; i < MAXCONV; i++)
		fmttab[i] = badconv;

	fmttab['s'] = sconv;
	fmttab['c'] = cconv;
	fmttab['d'] = dconv;
	fmttab['f'] = fconv;
	fmttab['o'] = oconv;
	fmttab['x'] = xconv;
	fmttab['%'] = pctconv;

	fmttab['u'] = uconv;
	fmttab['h'] = hconv;
	fmttab['l'] = longconv;
	fmttab['#'] = altconv;
	fmttab['-'] = leftconv;
	fmttab['.'] = dotconv;

	fmttab['0'] = zeroconv;
	for (i = '1'; i <= '9'; i++)
		fmttab[i] = digitconv;
}

Conv fmtinstall(int c, Conv f) {
	Conv oldf;
	if (fmttab == NULL)
		inittab();
	c &= MAXCONV - 1;
	oldf = fmttab[c];
	if (f != NULL)
		fmttab[c] = f;
	return oldf;
}

/*
 * printfmt -- the driver routine
 */

extern int printfmt(Format *format, const char *fmt) {
	unsigned char *s = (unsigned char *) fmt;

	if (fmttab[0] == NULL)
		inittab();

	for (;;) {
		int c = *s++;
		switch (c) {
		case '%':
			format->flags = format->f1 = format->f2 = 0;
			do
				format->invoker = c = *s++;
			while ((*fmttab[c])(format));
			break;
		case '\0':
			return format->size() + format->flushed;
		default:
			format->put(c);
			break;
		}
	}
}


/*
 * the public entry points
 */

extern int fmtprint (Format * format,  const char * fmt, ...) {
	int n = -format->flushed;
	va_list saveargs;
	va_copy(saveargs, format->args);


	va_start(format->args, fmt);
	n += printfmt(format, fmt);
	va_end(format->args);

	va_copy(format->args, saveargs);

	return n + format->flushed;
}

struct FD_format : public Format {
	char *buf, *bufbegin, *bufend;
	int fd;
	void put(char c) {
		if (buf >= bufend)
			grow(32);
		*buf++ = c;
	}
	void append(const char *s, size_t len) {
		while (buf + len > bufend) {
			size_t split = bufend - buf;
			memcpy(buf, s, split);
			buf += split;
			s += split;
			len -= split;
			grow(len);
		}
		memcpy(buf, s, len);
		buf += len;
	}
	int size() const {
		return buf - bufbegin;
	}

	void grow(size_t s) {
		size_t n = buf - bufbegin;
		char *obuf = bufbegin;
	
		flushed += n;
		buf = bufbegin;
		while (n != 0) {
			int written = write(fd, obuf, n);
			if (written == -1) {
				if (fd != 2)
					uerror("write");
				exit(1);
			}
			n -= written;
		}
	}
};

static void fdprint(FD_format *format, int fd, const char *fmt) {
	char buf[FPRINT_BUFSIZ];

	format->buf	= buf;
	format->bufbegin = buf;
	format->bufend	= buf + sizeof buf;
	format->flushed	= 0;
	format->fd	= fdmap(fd);

	
	printfmt(format, fmt);
	format->grow(0);
	
}

#define FORMATPRINT(fd) FD_format format; \
	va_start(format.args, fmt); \
	fdprint(&format, fd, fmt); \
	va_end(format.args); \
	return format.flushed;

extern int fprint (int fd,  const char * fmt, ...) {
	FORMATPRINT(fd);
}

extern int print (const char * fmt, ...) {
	FORMATPRINT(1);
}

extern int eprint (const char * fmt, ...) {
	FORMATPRINT(2);
}

extern void panic (const char * fmt, ...) {
	FD_format format;
	
	va_start(format.args, fmt);
	eprint("xs panic: ");
	fdprint(&format, 2, fmt);
	va_end(format.args);
	eprint("\n");
	exit(1);
}
