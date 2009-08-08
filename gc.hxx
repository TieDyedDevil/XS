/* gc.hxx -- garbage collector interface for es ($Revision: 1.1.1.1 $) */

/* see also es.hxx for more generally applicable definitions */

/*
 * tags
 */

struct Tag {
	void *(*copy)(void *);
	size_t (*scan)(void *);
#if ASSERTIONS || GCVERBOSE
	long magic;
	const char *tname;
#endif
};

extern Tag StringTag;

#if ASSERTIONS || GCVERBOSE
enum {TAGMAGIC = 0xDefaced};
#define	DefineTag(t, storage) \
	static void *CONCAT(t,Copy)(void *arg); \
	static size_t CONCAT(t,Scan)(void *arg); \
	storage Tag CONCAT(t,Tag) = { CONCAT(t,Copy), CONCAT(t,Scan), TAGMAGIC, STRING(t) }
#else
#define	DefineTag(t, storage) \
	static void *CONCAT(t,Copy)(void *arg); \
	static size_t CONCAT(t,Scan)(void *arg); \
	storage Tag CONCAT(t,Tag) = { CONCAT(t,Copy), CONCAT(t,Scan) }
#endif

/*
 * allocation
 */

extern void *gcalloc(size_t, Tag *);

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

template <class T>
inline T* forward(T *p) {
	extern void * forward_v(void *);
	return (T*) forward_v((void *) p);
}
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
