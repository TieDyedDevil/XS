/* gc.c -- copying garbage collector for es ($Revision: 1.2 $) */

#define	GARBAGE_COLLECTOR	1	/* for es.hxx */

#include "es.hxx"
#include "gc.hxx"

/* globals */

extern char *gcndup(const char* s, size_t n) {
	char* ns = reinterpret_cast<char*>(GC_MALLOC((n + 1) * sizeof (char)));
	memcpy(ns, s, n);
	ns[n] = '\0';
	assert(strlen(ns) == n);

	return ns;
}

/*
 * allocation of large, contiguous buffers for large object creation
 *	see the use of this in str().  note that this region may not
 *	contain pointers or '\0' until after sealbuffer() has been called.
 */

extern Buffer *openbuffer(size_t minsize) {
	Buffer *buf;
	if (minsize < 500)
		minsize = 500;
	buf = reinterpret_cast<Buffer*>(ealloc(offsetof(Buffer, str[0]) + minsize));
	buf->len = minsize;
	buf->current = 0;
	return buf;
}

extern Buffer *expandbuffer(Buffer *buf, size_t minsize) {
	buf->len += (minsize > buf->len) ? minsize : buf->len;
	buf = reinterpret_cast<Buffer*>(
                erealloc(buf, offsetof(Buffer, str[0]) + buf->len));
	return buf;
}

extern char *sealcountedbuffer(Buffer *buf) {
	char *s = gcndup(buf->str, buf->current);
	efree(buf);
	return s;
}

extern Buffer *bufncat(Buffer *buf, const char *s, size_t len) {
	while (buf->current + len >= buf->len)
		buf = expandbuffer(buf, buf->current + len - buf->len);
	memcpy(buf->str + buf->current, s, len);
	buf->current += len;
	return buf;
}
