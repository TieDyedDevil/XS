/* xs.hxx -- definitions for higher order shell */
#ifndef XS_HXX
#define XS_HXX

#include "config.h"
#include "stdenv.hxx"
#include <algorithm>
#include <functional>
#include <string>

#define iterate(list) for (; list != NULL; list = list->next)

/*
 * meta-information for exported environment strings
 */

#define ENV_SEPARATOR	'\001'		/* control-A */
#define	ENV_ESCAPE	'\002'		/* control-B */


/*
 * the fundamental xs data structures.
 */

struct Term;

struct List {
	Term *term;
	List *next;
};

struct Binding {
	const char *name;
	List *defn;
	Binding *next;
};

struct Tree;

struct Closure {
	Binding	*binding;
	Tree *tree;
};


/*
 * parse trees
 */

enum NodeKind {
	nAssign, nCall, nClosure, nConcat, nFor, nLambda, nLet, nList, nLocal,
	nMatch, nExtract, nPrim, nQword, nThunk, nVar, nVarsub, nWord,
	nArith, nPlus, nMinus, nMult, nDivide, nModulus, nInt, nFloat,
	nRedir, nPipe		/* only appear during construction */
};

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

struct StrList {
	const char *str;
	StrList *next;
};

/* environment or arguments */
// Inherit from gc_cleanup so if the collector ever collects the vector,
// the internal memory is cleaned up too.
class Vector : public std::vector< char*, gc_allocator<char*> >, 
	       public gc_cleanup 
{
public: void sort() {
        extern int qstrcmp(const char *, const char *);
        std::sort(begin(), end(), qstrcmp);
    }
};


/*
 * our programming environment
 */

/* main.cxx */

extern bool islogin();

/* print.cxx -- see print.hxx for more */

extern int print(const char *fmt, ...);
extern int eprint(const char *fmt, ...);
extern int fprint(int fd, const char *fmt, ...);
extern void panic(const char *fmt, ...) NORETURN;

/* GC-related convenience functions */

#define	gcnew(type)	new (UseGC) type
#define galloc	GC_MALLOC

/* util.cxx: copy a counted string into gc space */
extern char *gcndup(const char* s, size_t n);

/* copy a 0-terminated string into gc space */
inline char *gcdup(const char *s) {
	return gcndup(s, strlen(s));
}
/* initial.cxx (for xs) or dump.cxx (for xsdump) */

extern void runinitial(void);


/* fd.cxx */

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


/* term.cxx */

extern Term* mkterm(const char* str, Closure* closure);
extern Term* mkstr(const char* str);
extern const char *getstr(Term* term);
extern Closure *getclosure(Term* term);
extern Term* termcat(Term* t1, Term*t2);
extern bool termeq(Term *term, const char *s);
extern bool isclosure(Term *term);


/* list.cxx */

extern List *mklist(Term* term, List* next);
extern List *reverse(List *list);
extern List *append(const List* head, List* tail);
extern List *listcopy(const List *list);
extern int length(List* list);
extern List *listify(int argc, char **argv);
extern Term *nth(List *list, int n);
extern List* sortlist(List* list);


/* tree.cxx */

extern Tree *mk(int, ...);
/* ... Tree *mk(NodeKind, ...); */

/* closure.cxx */

extern Closure *mkclosure(Tree* tree, Binding* binding);
extern Closure *extractbindings(Tree *tree);
extern Binding *mkbinding(const char* name, List* defn, Binding* next);
extern Binding *reversebindings(Binding *binding);


/* eval.cxx */

extern Binding *bindargs(Tree* params, List* args, Binding* binding);
extern List *forkexec(const char *file, const List *list, bool inchild);
extern const List *walk(Tree* tree, Binding* binding, int flags);
extern const List *eval(const List* list, Binding* binding, int flags);
extern const List *pathsearch(Term *term);

/* eval1 -- evaluate a term, producing a list */
inline const List *eval1(Term *term, int flags) {
	assert (term != NULL);
	return eval(mklist(term, NULL), NULL, flags);
}

extern unsigned long evaldepth, maxevaldepth;
#define	MINmaxevaldepth		100
#define	MAXmaxevaldepth		0xffffffffU

#define	eval_inchild		1
#define	eval_exitonfalse	2
#define	eval_flags		(eval_inchild|eval_exitonfalse)


/* glom.cxx */

extern List* glom(Tree* tree, Binding* binding, bool globit);
extern List *glom2(Tree* tree, Binding* binding, StrList **quotep);


/* glob.cxx */

extern const char *QUOTED, *UNQUOTED;
#define IS_RAW(q) *q == 'r'

extern List* glob(List* list, StrList* quote);
extern bool haswild(const char *pattern, const char *quoting);
/* Needed for some of the readline tab-completion */
extern List* dirmatch(const char* prefix,
		      const char* dirname,
		      const char* pattern,
		      const char* quote);


/* match.cxx */
extern bool match(const char *subject, const char *pattern, const char *quote);
extern bool listmatch(List* subject, List* pattern, StrList* quote);
extern List *extractmatches(List *subjects, List *patterns, StrList *quotes);


/* var.cxx */

extern void initenv(char **envp, bool isprotected);
extern void hidevariables(void);
extern void validatevar(const char *var);
extern List *varlookup(const char* name, Binding* binding);
extern List *varlookup2(const char *name1, const char *name2, Binding *binding);
extern void vardef(const char*, Binding*, List*);
extern Vector* mkenv(void);
extern void setnoexport(List *list);
extern void addtolist(void *arg, const char *key, void *value);
extern List *listvars(bool internal);

/* struct Push -- varpush() placeholder */

class Dyvar {
public:
	Dyvar(const char *name, List *defn);
	~Dyvar();
private:
	const char *name;
	List *defn;
	int flags;
};

/* status.cxx */

extern const List *ltrue, *lfalse;
extern bool istrue(const List *status);
extern int exitstatus(const List *status);
extern char *mkstatus(int status);
extern void printstatus(int pid, int status);


/* access.cxx */

extern const char *checkexecutable(const char *file);


/* proc.cxx */

extern bool hasforked;
extern int efork(bool parent, bool background);
extern int ewait(int pid, bool interruptible, void *rusage);
#define	ewaitfor(pid)	ewait(pid, false, NULL)


/* dict.cxx */

struct Var;
typedef map<
		std::string, Var*, 
		std::less<std::string>, 
		gc_allocator< std::pair<std::string, Var*> > >
        Dict_map;
class Dict : public Dict_map,
	     public gc_cleanup
{
public:
    Var*& operator[](std::string index) {
#if ASSERTIONS
        int icount = count(index);
#endif
        Var*& res = Dict_map::operator[](index);
        assert (res != NULL || icount == 0);
        return res;
    }
};

extern void dictforall(Dict* dict, void (*proc)(void *, const char *, void *),
                       void* arg);
/* conv.cxx */

extern void initconv(void);



/* str.cxx */

/* create a gc space string by printing */
extern char *str(const char *fmt, ...);
extern StrList* mkstrlist(const char* str, StrList* next);


/* vec.cxx */

extern Vector* vectorize(const List* list);

/* util.cxx */

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


/* input.cxx */

extern const char *prompt, *prompt2;
extern bool continued_input;
extern Tree *parse(const char *esprompt1, const char *esprompt2);
extern Tree *parsestring(const char *str);
extern void sethistory(const char *file);
extern void inithistory(void);
extern bool isinteractive(void);
extern void initinput(void);
extern void resetparser(void);

extern const List *runfd(int fd, const char *name, int flags);
extern const List *runstring(const char *str, const char *name, int flags);

extern void terminal_size();

/* eval_* flags are also understood as runflags */
#define	run_interactive		 4	/* -i or $0[0] = '-' */
#define	run_noexec		 8	/* -n */
#define	run_echoinput		16	/* -v */
#define	run_printcmds		32	/* -x */

extern bool resetterminal;


/* opt.cxx */

extern void esoptbegin(List *list, const char *caller, const char *usage);
extern int esopt(const char *options);
extern Term *esoptarg(void);
extern List *esoptend(void);


/* prim.cxx */

extern const List* 
prim(const char *s, List* list, Binding* binding, int evalflags);

extern void initprims(void);


/* split.cxx */

extern void startsplit(const char *sep, bool coalesce);
extern void splitstring(const char *in, size_t len, bool endword);
extern List* endsplit(void);
extern List* fsplit(const char *sep, List* list, bool coalesce);


/* signal.cxx */

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
extern xs_jmp_buf slowlabel;
extern bool sigint_newline;
extern void sigchk(void);
extern bool issilentsignal(List *e);
extern void setsigdefaults(void);
extern void blocksignals(void);
extern void unblocksignals(void);


/* open.cxx */

enum OpenKind { oOpen, oCreate, oAppend, oReadWrite, oReadCreate, oReadAppend };
extern int eopen(const char *name, OpenKind k);


/* version.cxx */

extern const char * const version;



extern void fail(const char *from, const char *name, ...) NORETURN;
inline void print_exception(List *e) {
	eprint("%L\n", e, " ");
}

#endif
