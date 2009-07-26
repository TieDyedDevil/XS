/* gc.c -- copying garbage collector for es ($Revision: 1.2 $) */

#define	GARBAGE_COLLECTOR	1	/* for es.hxx */

#include "es.hxx"
#include "gc.hxx"

#define	ALIGN(n)	(((n) + sizeof (void *) - 1) &~ (sizeof (void *) - 1))

typedef struct Space Space;
struct Space {
	char *current, *bot, *top;
	Space *next;
};

inline static size_t space_size(const Space *sp) {
	return sp->top - sp->bot;
}
inline static size_t space_free(const Space *sp) {
	return sp->top - sp->current;
}
inline static size_t space_used(const Space *sp) {
	return sp->current - sp->bot;
}
inline static bool in_space(const void *p, Space *sp)	{
	const char *s = reinterpret_cast<const char*>(p);
	return sp->bot <= s && s < sp->top;
}

#define	MIN_minspace	10000

#if GCPROTECT
#define	NSPACES		10
#endif

#if HAVE_SYSCONF
# ifndef _SC_PAGESIZE
#  undef HAVE_SYSCONF
#  define HAVE_SYSCONF 0
# endif
#endif


/* globals */
Root *rootlist;
int gcblocked = 0;
extern Tag StringTag;

/* own variables */
static Space *newSpace, *oldSpace;
#if GCPROTECT
static Space *spaces;
#endif
static Root *globalrootlist;
static size_t minspace = MIN_minspace;	/* minimum number of bytes in a new space */


/*
 * debugging
 */

#if GCVERBOSE
#define	VERBOSE(p)	STMT(if (gcverbose) eprint p)
#else
#define	VERBOSE(p)	NOP
#endif


/*
 * GCPROTECT
 *	to use the GCPROTECT option, you must provide the following functions
 *		initmmu
 *		take
 *		release
 *		invalidate
 *		revalidate
 *	for your operating system
 */

#if GCPROTECT
#if __MACH__

/* mach versions of mmu operations
 * More "native" to OSX, perhaps, but OSX supports the other version too */

#include <mach.h>
#include <mach_error.h>

#define	PAGEROUND(n)	((n) + vm_page_size - 1) &~ (vm_page_size - 1)

/* initmmu -- initialization for memory management calls */
static void initmmu(void) {
}

/* take -- allocate memory for a space */
static void *take(size_t n) {
	vm_address_t addr;
	kern_return_t error = vm_allocate(task_self(), &addr, n, true);
	if (error != KERN_SUCCESS) {
		mach_error("vm_allocate", error);
		exit(1);
	}
	memset((void *) addr, 0xC9, n);
	return (void *) addr;
}

/* release -- deallocate a range of memory */
static void release(void *p, size_t n) {
	kern_return_t error = vm_deallocate(task_self(), (vm_address_t) p, n);
	if (error != KERN_SUCCESS) {
		mach_error("vm_deallocate", error);
		exit(1);
	}
}

/* invalidate -- disable access to a range of memory */
static void invalidate(void *p, size_t n) {
	kern_return_t error = vm_protect(task_self(), (vm_address_t) p, n, false, 0);
	if (error != KERN_SUCCESS) {
		mach_error("vm_protect 0", error);
		exit(1);
	}
}

/* revalidate -- enable access to a range of memory */
static void revalidate(void *p, size_t n) {
	kern_return_t error =
		vm_protect(task_self(), (vm_address_t) p, n, false, VM_PROT_READ|VM_PROT_WRITE);
	if (error != KERN_SUCCESS) {
		mach_error("vm_protect VM_PROT_READ|VM_PROT_WRITE", error);
		exit(1);
	}
	memset(p, 0x4F, n);
}

#else /* !__MACH__ */

/* sunos-derived mmap(2) version of mmu operations */

#include <sys/mman.h>

static int pagesize;
#define	PAGEROUND(n)	((n) + pagesize - 1) &~ (pagesize - 1)

/* take -- allocate memory for a space */
static void *take(size_t n) {
	caddr_t addr;
#ifdef MAP_ANONYMOUS
	addr = reinterpret_cast<caddr_t>(mmap(0, n, PROT_READ|PROT_WRITE,	MAP_PRIVATE|MAP_ANONYMOUS, -1, 0));
#else
	static int devzero = -1;
	if (devzero == -1)
		devzero = eopen("/dev/zero", oOpen);
	addr = mmap(0, n, PROT_READ|PROT_WRITE, MAP_PRIVATE, devzero, 0);
#endif
	if (addr == (caddr_t) -1)
		panic("mmap: %s", esstrerror(errno));
	memset(addr, 0xA5, n);
	return addr;
}

/* release -- deallocate a range of memory */
static void release(void *p, size_t n) {
	if (munmap(p, n) == -1)
		panic("munmap: %s", esstrerror(errno));
}

/* invalidate -- disable access to a range of memory */
static void invalidate(void *p, size_t n) {
	if (mprotect(p, n, PROT_NONE) == -1)
		panic("mprotect(PROT_NONE): %s", esstrerror(errno));
}

/* revalidate -- enable access to a range of memory */
static void revalidate(void *p, size_t n) {
	if (mprotect(p, n, PROT_READ|PROT_WRITE) == -1)
		panic("mprotect(PROT_READ|PROT_WRITE): %s", esstrerror(errno));
}

/* initmmu -- initialization for memory management calls */
static void initmmu(void) {
#if HAVE_SYSCONF
	pagesize = sysconf(_SC_PAGESIZE);
#else
	pagesize = getpagesize();
#endif
}

#endif	/* !__MACH__ */
#endif	/* GCPROTECT */


/*
 * ``half'' space management
 */

#if GCPROTECT

/* mkspace -- create a new ``half'' space in debugging mode */
static Space *mkspace(Space *space, Space *next) {
	assert(space == NULL || (&spaces[0] <= space && space < &spaces[NSPACES]));

	if (space != NULL) {
		Space *sp;
		if (space->bot == NULL)
			sp = NULL;
		else if (space_size(space) < minspace)
			sp = space;
		else {
			sp = space->next;
			revalidate(space->bot, space_size(space));
		}
		while (sp != NULL) {
			Space *tail = sp->next;
			release(sp->bot, space_size(sp));
			if (&spaces[0] <= space && space < &spaces[NSPACES])
				sp->bot = NULL;
			else
				efree(sp);
			sp = tail;
		}
	}

	if (space == NULL) {
		space = reinterpret_cast<Space*>(ealloc(sizeof(Space)));
		memzero(space, sizeof (Space));
	}
	if (space->bot == NULL) {
		size_t n = PAGEROUND(minspace);
		space->bot = reinterpret_cast<char*>(take(n));
		space->top = space->bot + n / (sizeof (*space->bot));
	}

	space->next = next;
	space->current = space->bot;

	return space;
}
#define	newspace(next)		mkspace(NULL, next)

#else	/* !GCPROTECT */

/* newspace -- create a new ``half'' space */
static Space *newspace(Space *next) {
	size_t n = ALIGN(minspace);
	Space *space = reinterpret_cast<Space*>(ealloc(sizeof (Space) + n));
	space->bot = reinterpret_cast<char *>(&space[1]);
	space->top = space->bot + n;
	space->current = space->bot;
	space->next = next;
	return space;
}

#endif	/* !GCPROTECT */

/* deprecate -- take a space and invalidate it */
static void deprecate(Space *space) {
#if GCPROTECT
	Space *base;
	assert(space != NULL);
	for (base = space; base->next != NULL; base = base->next)
		;
	assert(&spaces[0] <= base && base < &spaces[NSPACES]);
	for (;;) {
		invalidate(space->bot, space_size(space));
		if (space == base)
			break;
		else {
			Space *next = space->next;
			space->next = base->next;
			base->next = space;
			space = next;
		}
	}
#else
	while (space != NULL) {
		Space *old = space;
		space = space->next;
		efree(old);
	}

#endif
}

/* isinspace -- does an object lie inside a given Space? */
extern bool isinspace(Space *space, const void *p) {
	for (; space != NULL; space = space->next)
		if (in_space(p, space)) {
		 	assert(reinterpret_cast<const char*>(p) < space->current);
		 	return true;
		}
	return false;
}


/*
 * root list building and scanning
 */

/* globalroot -- add an external to the list of global roots */
extern void globalroot(void *addr) {
	Root *root;
#if ASSERTIONS
	for (root = globalrootlist; root != NULL; root = root->next)
		assert(root->p != addr);
#endif
	root = reinterpret_cast<Root*>(ealloc(sizeof (Root)));
	root->p = reinterpret_cast<void**>(addr);
	root->next = globalrootlist;
	globalrootlist = root;
}

/* not portable to word addressed machines */
/* Must be macro to be used as lvalue */
static inline Tag*& tag(void *p) {
	return reinterpret_cast<Tag **>(p)[-1];
}
static inline bool forwarded(Tag *tagp) {
	return (int) (tagp) & 1;
}
static inline Tag *follow_to(char *p) {
	return (Tag *) (p + 1);
}
static inline void *follow(Tag *tagp) {
	return (void *) ((int) (tagp) - 1);
}

/* forward -- forward an individual pointer from old space
 * NOTE: forward will NEVER modify the contents of p.
 */
extern void *forward(void *p) {
	Tag *ptag;
	void *np;

	if (!isinspace(oldSpace, p)) {
		VERBOSE(("GC %8ux : <<not in old space>>\n", p));
		return p;
	}

	VERBOSE(("GC %8ux : ", p));

	ptag = tag(p);
	assert(ptag != NULL);
	if (forwarded(ptag)) {
		np = follow(ptag);
		assert(tag(np)->magic == TAGMAGIC);
		VERBOSE(("%s	-> %8ux (followed)\n", tag(np)->tname, np));
	} else {
		assert(ptag->magic == TAGMAGIC);
		np = (*ptag->copy)(p);
		VERBOSE(("%s	-> %8ux (forwarded)\n", ptag->tname, np));
		tag(p) = follow_to(reinterpret_cast<char*>(np));
	}
	return np;
}

/* scanroots -- scan a rootlist */
static void scanroots(Root *rootlist) {
	Root *root;
	for (root = rootlist; root != NULL; root = root->next) {
		VERBOSE(("GC root at %8lx: %8lx\n", root->p, *root->p));
		*root->p = forward(*root->p);
	}
}

/* scanspace -- scan new space until it is up to date */
static void scanspace(void) {
	Space *sp, *scanned;
	for (scanned = NULL;;) {
		Space *front = newSpace;
		for (sp = newSpace; sp != scanned; sp = sp->next) {
			assert(sp != NULL);
			char *scan = sp->bot;
			while (scan < sp->current) {
				Tag *tag = *(Tag **) scan;
				assert(tag->magic == TAGMAGIC);
				scan += sizeof (Tag *);
				VERBOSE(("GC %8ux : %s	scan\n", scan, tag->tname));
				scan += ALIGN((*tag->scan)(scan));
			}
		}
		if (newSpace == front)
			break;
		scanned = front;
	}
}


/*
 * the garbage collector public interface
 */

/* gcenable -- enable collections */
extern void gcenable(void) {
	assert(gcblocked > 0);
	--gcblocked;

	if (!gcblocked && newSpace->next != NULL)
		gc();
}

/* gcdisable -- disable collections */
extern void gcdisable(void) {
	assert(gcblocked >= 0);
	++gcblocked;
}

/* gcreserve -- provoke a collection if there's not a certain amount of space around */
extern void gcreserve(size_t minfree) {
	if (space_free(newSpace) < minfree) {
		if (minspace < minfree)
			minspace = minfree;
		gc();
	}
#if GCALWAYS
	else
		gc();
#endif
}

/* gcisblocked -- is collection disabled? */
extern bool gcisblocked(void) {
	assert(gcblocked >= 0);
	return gcblocked != 0;
}

/* gc -- actually do a garbage collection */
extern void gc(void) {
	do {
		Space *space;

#if GCINFO
		size_t olddata = 0;
		if (gcinfo)
			for (space = newSpace; space != NULL; space = space->next)
				olddata += space_used(space);
#endif

		if (gcisblocked()) return;
		gcdisable();

		assert(newSpace != NULL);
		assert(oldSpace == NULL);
		oldSpace = newSpace;
#if GCPROTECT
		for (; newSpace->next != NULL; newSpace = newSpace->next)
			;
		if (++newSpace >= &spaces[NSPACES])
			newSpace = &spaces[0];
		newSpace = mkspace(newSpace, NULL);
#else
		newSpace = newspace(NULL);
#endif
		VERBOSE(("\nGC collection starting\n"));
#if GCVERBOSE
		for (space = oldSpace; space != NULL; space = space->next)
			VERBOSE(("GC old space = %ux ... %ux\n", space->bot, space->current));
#endif
		VERBOSE(("GC new space = %ux ... %ux\n", newSpace->bot, newSpace->top));
		VERBOSE(("GC scanning root list\n"));
		scanroots(rootlist);
		VERBOSE(("GC scanning global root list\n"));
		scanroots(globalrootlist);
		VERBOSE(("GC scanning new space\n"));
		scanspace();
		VERBOSE(("GC collection done\n\n"));

		deprecate(oldSpace);
		oldSpace = NULL;

		size_t livedata;
		for (livedata = 0, space = newSpace; space != NULL; space = space->next)
			livedata += space_used(space);

#if GCINFO
		if (gcinfo)
			eprint(
				"[GC: old %8d  live %8d  min %8d  (pid %5d)]\n",
				olddata, livedata, minspace, getpid()
			);
#endif

		if (minspace < livedata * 2)
			minspace = livedata * 4;
		else if (minspace > livedata * 12 && minspace > (MIN_minspace * 2))
			minspace /= 2;

		--gcblocked;
	} while (newSpace->next != NULL);
}

/* initgc -- initialize the garbage collector */
extern void initgc(void) {
#if GCPROTECT
	initmmu();
	spaces = reinterpret_cast<Space*>(ealloc(NSPACES * sizeof (Space)));
	memzero(spaces, NSPACES * sizeof (Space));
	newSpace = mkspace(&spaces[0], NULL);
#else
	newSpace = newspace(NULL);
#endif
	oldSpace = NULL;
}


/*
 * allocation
 */

/* gcalloc -- allocate an object in new space */
extern void *gcalloc(size_t nbytes, Tag *tag) {
	size_t n = ALIGN(nbytes + sizeof (Tag *));
#if GCALWAYS
	gc();
#endif
	assert(tag == NULL || tag->magic == TAGMAGIC);
	for (;;) {
		Tag **p = reinterpret_cast<Tag **>(newSpace->current);
		char *q = ((char *) p) + n;
		if (q <= newSpace->top) {
			newSpace->current = q;
			*p++ = tag;
			return p;
		}
		if (minspace < nbytes)
			minspace = nbytes + sizeof (Tag *);
		if (gcblocked)
			newSpace = newspace(newSpace);
		else
			gc();
	}
}


/*
 * strings
 */

#define notstatic
DefineTag(String, notstatic);

extern char *gcndup(SRef<const char> s, size_t n) {
	SRef<char> ns = reinterpret_cast<char*>(gcalloc((n + 1) * sizeof (char), &StringTag));
	memcpy(ns.uget(), s.uget(), n);
	ns[n] = '\0';
	assert(strlen(ns.uget()) == n);

	return ns.release();
}

extern char *gcdup(const char *s) {
	return gcndup(s, strlen(s));
}

void *StringCopy(void *op) {
	size_t n = strlen(reinterpret_cast<const char*>(op)) + 1;
	char *np = reinterpret_cast<char*>(gcalloc(n, &StringTag));
	memcpy(np, op, n);
	return np;
}

size_t StringScan(void *p) {
	return strlen(reinterpret_cast<const char*>(p)) + 1;
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
	buf = reinterpret_cast<Buffer*>(erealloc(buf, offsetof(Buffer, str[0]) + buf->len));
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

#if GCVERBOSE
/*
 * memdump -- print out all of gc space, as best as possible
 */

static char    *
tree1name(NodeKind k)
{
    switch (k) {
    default:
	panic("tree1name: bad node kind %d", k);
    case nPrim:
	return "Prim";
    case nQword:
	return "Qword";
    case nCall:
	return "Call";
    case nThunk:
	return "Thunk";
    case nVar:
	return "Var";
    case nWord:
	return "Word";
    }
}

static char    *
tree2name(NodeKind k)
{
    switch (k) {
    default:
	panic("tree2name: bad node kind %d", k);
    case nAssign:
	return "Assign";
    case nConcat:
	return "Concat";
    case nClosure:
	return "Closure";
    case nFor:
	return "For";
    case nLambda:
	return "Lambda";
    case nLet:
	return "Let";
    case nList:
	return "List";
    case nLocal:
	return "Local";
    case nMatch:
	return "Match";
    case nExtract:
	return "Extract";
    case nVarsub:
	return "Varsub";
    }
}

/*
 * having these here violates every data hiding rule in the book 
 */

typedef struct {
    char           *name;
    void           *value;
} Assoc;
struct Dict {
    int             size,
                    remain;
    Assoc           table[1];	/* variable length */
};

#include "var.hxx"
#include "term.hxx"


static size_t
dump(Tag * t, void *p)
{
    const char     *s = t->tname;
    print("%8ux %s\t", p, s);

    if (streq(s, "String")) {
	print("%s\n", p);
	return strlen(reinterpret_cast < char *>(p)) +1;
    }

    if (streq(s, "Term")) {
	Term           *t = reinterpret_cast < Term * >(p);
	print("str = %ux  closure = %ux\n", t->str, t->closure);
	return sizeof(Term);
    }

    if (streq(s, "List")) {
	List           *l = reinterpret_cast < List * >(p);
	print("term = %ux  next = %ux\n", l->term, l->next);
	return sizeof(List);
    }

    if (streq(s, "StrList")) {
	StrList        *l = reinterpret_cast < StrList * >(p);
	print("str = %ux  next = %ux\n", l->str, l->next);
	return sizeof(StrList);
    }

    if (streq(s, "Closure")) {
	Closure        *c = reinterpret_cast < Closure * >(p);
	print("tree = %ux  binding = %ux\n", c->tree, c->binding);
	return sizeof(Closure);
    }

    if (streq(s, "Binding")) {
	Binding        *b = reinterpret_cast < Binding * >(p);
	print("name = %ux  defn = %ux  next = %ux\n", b->name, b->defn,
	      b->next);
	return sizeof(Binding);
    }

    if (streq(s, "Var")) {
	Var            *v = reinterpret_cast < Var * >(p);
	print("defn = %ux  env = %ux  flags = %d\n",
	      v->defn, v->env, v->flags);
	return sizeof(Var);
    }

    if (streq(s, "Tree1")) {
	Tree           *t = reinterpret_cast < Tree * >(p);
	print("%s	%ux\n", tree1name(t->kind), t->u[0].p);
	return offsetof(Tree, u[1]);
    }

    if (streq(s, "Tree2")) {
	Tree           *t = reinterpret_cast < Tree * >(p);
	print("%s	%ux  %ux\n", tree2name(t->kind), t->u[0].p,
	      t->u[1].p);
	return offsetof(Tree, u[2]);
    }

    if (streq(s, "Vector")) {
	Vector         *v = reinterpret_cast < Vector * >(p);
	int             i;
	print("alloclen = %d  count = %d [", v->alloclen, v->count);
	for (i = 0; i <= v->alloclen; i++)
	    print("%s%ux", i == 0 ? "" : " ", v->vector[i]);
	print("]\n");
	return offsetof(Vector, vector[0]) + sizeof(char *) * (v->alloclen + 1);
    }

    if (streq(s, "Dict")) {
	Dict           *d = reinterpret_cast < Dict * >(p);
	int             i;
	print("size = %d  remain = %d\n", d->size, d->remain);
	for (i = 0; i < d->size; i++)
	    print("\tname = %ux  value = %ux\n",
		  d->table[i].name, d->table[i].value);
	return offsetof(Dict, table[0]) + sizeof(char *) * (d->size);
    }

    print("<<unknown>>\n");
    return 0;
}

extern void
memdump(void)
{
    Space          *sp;
    for (sp = newSpace; sp != NULL; sp = sp->next) {
	char           *scan = sp->bot;
	while (scan < sp->current) {
	    Tag            *tag = *(Tag **) scan;
	    assert(tag->magic == TAGMAGIC);
	    scan += sizeof(Tag *);
	    scan += ALIGN(dump(tag, scan));
	}
    }
}
#endif

