/* es.hxx -- definitions for higher order shell ($Revision: 1.2 $) */

#include "config.h"
#include "stdenv.hxx"

/*
 * meta-information for exported environment strings
 */

#define ENV_SEPARATOR	'\001'		/* control-A */
#define	ENV_ESCAPE	'\002'		/* control-B */


/*
 * the fundamental es data structures.
 */

typedef struct Tree Tree;
typedef struct Term Term;
typedef struct List List;
typedef struct Binding Binding;
typedef struct Closure Closure;

struct List {
	Term *term;
	List *next;
};

struct Binding {
	const char *name;
	List *defn;
	Binding *next;
};

struct Closure {
	Binding	*binding;
	Tree *tree;
};


/*
 * parse trees
 */

typedef enum {
	nAssign, nCall, nClosure, nConcat, nFor, nLambda, nLet, nList, nLocal,
	nMatch, nExtract, nPrim, nQword, nThunk, nVar, nVarsub, nWord,
	nRedir, nPipe		/* only appear during construction */
} NodeKind;

struct Tree {
	NodeKind kind;
	union {
		Tree *p;
		const char *s;
		int i;
	} u[2];
};


/*
 * miscellaneous data structures
 */

typedef struct StrList StrList;
struct StrList {
	const char *str;
	StrList *next;
};

typedef struct {
	int alloclen, count;
	/* Variable size */
	char *vector[1];
} Vector;			/* environment or arguments */


/*
 * our programming environment
 */

/* print.c -- see print.hxx for more */

extern int print(const char *fmt, ...);
extern int eprint(const char *fmt, ...);
extern int fprint(int fd, const char *fmt, ...);
extern void panic(const char *fmt, ...) NORETURN;



/* gc.cxx -- see gc.hxx for more */


typedef struct Root Root;
struct Root {
	void **p;
	Root *next;
};

extern Root *rootlist;
#if REF_ASSERTIONS
#define	refassert(e)	assert(e)
#else
#define	refassert(e)	NOP
#endif

extern bool gcisblocked();			/* is collection disabled? */

#include "gc_ptr.hxx"

typedef struct Tag Tag;
#define	gcnew(type)	(reinterpret_cast<type *>(gcalloc(sizeof (type), &(CONCAT(type,Tag)))))

extern void *gcalloc(size_t n, Tag *t);		/* allocate n with collection tag t */
extern char *gcdup(const char *s);		/* copy a 0-terminated string into gc space */
extern char *gcndup(Ref<const char> s, size_t n);	/* copy a counted string into gc space */

extern void initgc(void);			/* must be called at the dawn of time */
extern void gc(void);				/* provoke a collection, if enabled */
extern void gcreserve(size_t nbytes);		/* provoke a collection, if enabled and not enough space */
extern void gcenable();				/* enable collections */
/* disable collections */
inline void gcdisable() {
	extern int gcblocked;
	assert(gcblocked >= 0);
	++gcblocked;
}

/* gcisblocked -- is collection disabled? */
inline bool gcisblocked() {
	extern int gcblocked;
	assert(gcblocked >= 0);
	return gcblocked != 0;
}


/*
 * garbage collector tags
 */
#define	RefAdd(e) \
	{ \
		Root __root__; \
		__root__.p = (void **) &e; \
		__root__.next = rootlist; \
		rootlist = &__root__; \
	try {

#define	RefRemove(e) \
		refassert(rootlist == &__root__); \
		refassert(rootlist->p == (void **) &e); \
		rootlist = rootlist->next; \
	} catch (List *t) { \
		refassert(rootlist == &__root__); \
		refassert(rootlist->p == (void **) &e); \
		rootlist = rootlist->next; \
		throwE(t); \
	} \
	}


/* main.c */

#if GCVERBOSE
extern bool gcverbose;		/* -G */
#endif
#if GCINFO
extern bool gcinfo;			/* -I */
#endif


/* initial.c (for es) or dump.c (for esdump) */

extern void runinitial(void);


/* fd.c */

extern void mvfd(int oldfd, int newfd);
extern int newfd(void);

#define	UNREGISTERED	(-999)
extern void registerfd(int *fdp, bool closeonfork);
extern void unregisterfd(int *fdp);
extern void releasefd(int fd);
extern void closefds(void);

extern int fdmap(int fd);
extern int defer_mvfd(bool parent, int oldfd, int newfd);
extern int defer_close(bool parent, int fd);
extern void undefer(int ticket);


/* term.c */

extern Ref<Term> mkterm(Ref<const char> str, Ref<Closure> closure);
extern Ref<Term> mkstr(Ref<const char> str);
extern const char *getstr(Ref<Term> term);
extern Closure *getclosure(Ref<Term> term);
extern Ref<Term> termcat(Ref<Term> t1, Ref<Term> t2);
extern bool termeq(Term *term, const char *s);
extern bool isclosure(Term *term);


/* list.c */

extern List *mklist(Ref<Term> term, Ref<List> next);
extern List *reverse(List *list);
extern List *append(Ref<List> head, Ref<List> tail);
extern List *listcopy(List *list);
extern int length(Ref<List> list);
extern List *listify(int argc, char **argv);
extern Term *nth(List *list, int n);
extern Ref<List> sortlist(Ref<List> list);


/* tree.c */

extern Tree *mk(NodeKind , ...);


/* closure.c */

extern Closure *mkclosure(Ref<Tree> tree, Ref<Binding> binding);
extern Closure *extractbindings(Tree *tree);
extern Binding *mkbinding(Ref<const char> name, Ref<List> defn, Ref<Binding> next);
extern Binding *reversebindings(Binding *binding);


/* eval.c */

extern Binding *bindargs(Ref<Tree> params, Ref<List> args, Ref<Binding> binding);
extern List *forkexec(const char *file, List *list, bool inchild);
extern List *walk(Ref<Tree> tree, Ref<Binding> binding, int flags);
extern List *eval(Ref<List> list, Ref<Binding> binding, int flags);
extern List *pathsearch(Term *term);

/* eval1 -- evaluate a term, producing a list */
inline List *eval1(Term *term, int flags) {
	return eval(mklist(term, NULL), NULL, flags);
}

extern unsigned long evaldepth, maxevaldepth;
#define	MINmaxevaldepth		100
#define	MAXmaxevaldepth		0xffffffffU

#define	eval_inchild		1
#define	eval_exitonfalse	2
#define	eval_flags		(eval_inchild|eval_exitonfalse)


/* glom.c */

extern Ref<List> glom(Ref<Tree> tree, Ref<Binding> binding, bool globit);
extern List *glom2(Ref<Tree> tree, Ref<Binding> binding, StrList **quotep);


/* glob.c */

extern const char *QUOTED, *UNQUOTED;

extern Ref<List> glob(Ref<List> list, Ref<StrList> quote);
extern bool haswild(const char *pattern, const char *quoting);
/* Needed for some of the readline tab-completion */
extern Ref<List> dirmatch(Ref<const char> prefix, 
		      Ref<const char> dirname,
		      Ref<const char> pattern, 
		      Ref<const char> quote);


/* match.c */
extern bool match(const char *subject, const char *pattern, const char *quote);
extern bool listmatch(Ref<List> subject, Ref<List> pattern, Ref<StrList> quote);
extern List *extractmatches(List *subjects, List *patterns, StrList *quotes);


/* var.c */

extern void initvars(void);
extern void initenv(char **envp, bool isprotected);
extern void hidevariables(void);
extern void validatevar(const char *var);
extern List *varlookup(Ref<const char> name, Ref<Binding> binding);
extern List *varlookup2(const char *name1, const char *name2, Binding *binding);
extern void vardef(Ref<const char>, Ref<Binding>, Ref<List>);
extern Ref<Vector> mkenv(void);
extern void setnoexport(List *list);
extern void addtolist(void *arg, const char *key, void *value);
extern List *listvars(bool internal);

typedef struct Push Push;
extern void varpush(Push *, const char *, List *);
extern void varpop(Push *);


/* status.c */

extern List *ltrue, *lfalse;
extern bool istrue(List *status);
extern int exitstatus(List *status);
extern char *mkstatus(int status);
extern void printstatus(int pid, int status);


/* access.c */

extern const char *checkexecutable(const char *file);


/* proc.c */

extern bool hasforked;
extern int efork(bool parent, bool background);
extern int ewait(int pid, bool interruptible, void *rusage);
#define	ewaitfor(pid)	ewait(pid, false, NULL)


/* dict.c */

typedef struct Dict Dict;
extern Dict *mkdict(void);
extern void dictforall(Ref<Dict> dict, void (*proc)(void *, const char *, void *), Ref<void> arg);
extern void *dictget(Dict *dict, const char *name);
extern Dict *dictput(Dict *dict, const char *name, void *value);
extern void *dictget2(Dict *dict, const char *name1, const char *name2);


/* conv.c */

extern void initconv(void);



/* str.c */

extern char *str(const char *fmt, ...);	/* create a gc space string by printing */
extern char *mprint(const char *fmt, ...);	/* create an ealloc space string by printing */
extern Ref<StrList> mkstrlist(Ref<const char> str, Ref<StrList> next);


/* vec.c */

extern Ref<Vector> mkvector(int n);
extern Ref<Vector> vectorize(Ref<List> list);
extern void sortvector(Ref <Vector> v);


/* util.c */

extern const char *esstrerror(int err);
extern void uerror(const char *msg);
extern void *ealloc(size_t n);
extern void *erealloc(void *p, size_t n);
extern void ewrite(int fd, const char *s, size_t n);
extern long eread(int fd, char *buf, size_t n);
extern bool isabsolute(const char *path);
extern bool streq2(const char *s, const char *t1, const char *t2);

/* efree -- error checked free */
inline void efree(void *p) {
	assert(p != NULL);
	free(p);
}


/* input.c */

extern const char *prompt, *prompt2;
#if READLINE
extern bool continued_input;
#endif
extern Tree *parse(const char *esprompt1, const char *esprompt2);
extern Tree *parsestring(const char *str);
extern void sethistory(const char *file);
extern bool isinteractive(void);
extern void initinput(void);
extern void resetparser(void);

extern List *runfd(int fd, const char *name, int flags);
extern List *runstring(const char *str, const char *name, int flags);

/* eval_* flags are also understood as runflags */
#define	run_interactive		 4	/* -i or $0[0] = '-' */
#define	run_noexec		 8	/* -n */
#define	run_echoinput		16	/* -v */
#define	run_printcmds		32	/* -x */
#define	run_lisptrees		64	/* -L and defined(LISPTREES) */

#if READLINE
extern bool resetterminal;
#endif


/* opt.c */

extern void esoptbegin(List *list, const char *caller, const char *usage);
extern int esopt(const char *options);
extern Term *esoptarg(void);
extern List *esoptend(void);


/* prim.c */

extern Ref<List> prim(const char *s, Ref<List> list, Ref<Binding> binding, int evalflags);
extern void initprims(void);


/* split.c */

extern void startsplit(const char *sep, bool coalesce);
extern void splitstring(const char *in, size_t len, bool endword);
extern Ref<List> endsplit(void);
extern Ref<List> fsplit(const char *sep, Ref<List> list, bool coalesce);


/* signal.c */

extern int signumber(const char *name);
extern char *signame(int sig);
extern char *sigmessage(int sig);

#define	SIGCHK() sigchk()
typedef enum {
	sig_nochange, sig_catch, sig_default, sig_ignore, sig_noop, sig_special
} Sigeffect;
extern Sigeffect esignal(int sig, Sigeffect effect);
extern void setsigeffects(const Sigeffect effects[]);
extern void getsigeffects(Sigeffect effects[]);
extern List *mksiglist(void);
extern void initsignals(bool interactive, bool allowdumps);
extern Atomic slow, interrupted;
extern jmp_buf slowlabel;
extern bool sigint_newline;
extern void sigchk(void);
extern bool issilentsignal(List *e);
extern void setsigdefaults(void);
extern void blocksignals(void);
extern void unblocksignals(void);


/* open.c */

enum OpenKind { oOpen, oCreate, oAppend, oReadWrite, oReadCreate, oReadAppend };
extern int eopen(const char *name, OpenKind k);


/* version.c */

extern const char * const version;


extern void globalroot(void *addr);

/* struct Push -- varpush() placeholder */

struct Push {
	Push(const char *name, List *defn) {
		varpush(this, name, defn);
	}
	~Push() {
		varpop(this);
	}
	Push *next;
	const char *name;
	List *defn;
	int flags;
	Root nameroot, defnroot;
};


/*
 * exception handling
 *
 *	ExceptionHandler
 *		... body ...
 *	CatchException (e)
 *		... catching code using e ...
 *	EndExceptionHandler
 *
 */

typedef struct Handler Handler;
struct Handler {
	Handler *up;
	Root *rootlist;
	Push *pushlist;
	unsigned long evaldepth;
	jmp_buf label;
};

extern Handler *tophandler, *roothandler;
extern List *exception;
extern void pophandler(Handler *handler);
extern void throwE(List *exc) NORETURN;
extern void fail(const char *from, const char *name, ...) NORETURN;
extern void print_exception(List *e);



