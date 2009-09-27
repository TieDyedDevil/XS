/* gc.hxx -- garbage collector interface for es ($Revision: 1.1.1.1 $) */
#include <gc/gc.h>

typedef struct Buffer Buffer;
struct Buffer {
	size_t len;
	size_t current;
	char str[1];
};

extern Buffer *openbuffer(size_t minsize);
extern Buffer *expandbuffer(Buffer *buf, size_t minsize);
extern Buffer *bufncat(Buffer *buf, const char *s, size_t len);
extern char *sealcountedbuffer(Buffer *buf);

inline char *sealbuffer(Buffer *buf) {
	char *s = gcdup(buf->str);
	efree(buf);
	return s;
}
inline Buffer *bufcat(Buffer *buf, const char *s) {
	return bufncat(buf, s, strlen(s));
}
inline void freebuffer(Buffer *buf) {
	efree(buf);
}
inline Buffer *bufputc(Buffer *buf, char c) {	
	if (buf->current + 1 >= buf->len) 
		buf = expandbuffer(buf, buf->current + 20);
	buf->str[buf->current++] = c;
	return buf;
}
