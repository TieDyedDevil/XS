/* conv.c -- convert between internal and external forms ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "print.hxx"


/* %L -- print a list */
static Boolean Lconv(Format *f) {
	const char *fmt = (f->flags & FMT_altform) ? "%S%s" : "%s%s";
	List *lp = va_arg(f->args, List *);
	char *sep = va_arg(f->args, char *);
	List *next;

	for (; lp != NULL; lp = next) {
		next = lp->next;
		fmtprint(f, fmt, getstr(lp->term), next == NULL ? "" : sep);
	}
	return FALSE;
}

/* treecount -- count the number of nodes in a flattened tree list */
static int treecount(Tree *tree) {
	return tree == NULL
		 ? 0
		 : tree->kind == nList
		    ? treecount(tree->u[0].p) + treecount(tree->u[1].p)
		    : 1;
}

/* binding -- print a binding statement */
static void binding(Format *f, char *keyword, Tree *tree) {
	fmtprint(f, "%s(", keyword);
	char *sep = "";
	for (Tree *np = tree->u[0].p; np != NULL; np = np->u[1].p) {
		assert(np->kind == nList);
		Tree *binding = np->u[0].p;
		assert(binding != NULL);
		assert(binding->kind == nAssign);
		fmtprint(f, "%s%#T:=%T", sep, binding->u[0].p, binding->u[1].p);
		sep = ";";
	}
	fmtprint(f, ")");
}

/* %T -- print a tree */
static Boolean Tconv(Format *f) {
	Tree *n = va_arg(f->args, Tree *);
	Boolean group = (f->flags & FMT_altform) != 0;


#define	tailcall(tree, altform) \
	STMT(n = (tree); group = (altform); goto top)

top:
	if (n == NULL) {
		if (group)
			fmtcat(f, "()");
		return FALSE;
	}

	switch (n->kind) {

	case nWord:
		fmtprint(f, "%s", n->u[0].s);
		return FALSE;

	case nQword:
		fmtprint(f, "%#S", n->u[0].s);
		return FALSE;

	case nPrim:
		fmtprint(f, "$&%s", n->u[0].s);
		return FALSE;

	case nAssign:
		fmtprint(f, "%#T:=", n->u[0].p);
		tailcall(n->u[1].p, FALSE);

	case nConcat:
		fmtprint(f, "%#T^", n->u[0].p);
		tailcall(n->u[1].p, TRUE);

	case nMatch:
		fmtprint(f, "~ %#T ", n->u[0].p);
		tailcall(n->u[1].p, FALSE);

	case nExtract:
		fmtprint(f, "~~ %#T ", n->u[0].p);
		tailcall(n->u[1].p, FALSE);

	case nThunk:
		fmtprint(f, "{%T}", n->u[0].p);
		return FALSE;

	case nVarsub:
		fmtprint(f, "$%#T(%T)", n->u[0].p, n->u[1].p);
		return FALSE;


	case nLocal:
		binding(f, "local", n);
		tailcall(n->u[1].p, FALSE);

	case nLet:
		binding(f, "let", n);
		tailcall(n->u[1].p, FALSE);

	case nFor:
		binding(f, "for", n);
		tailcall(n->u[1].p, FALSE);

	case nClosure:
		binding(f, "%closure", n);
		tailcall(n->u[1].p, FALSE);


	case nCall: {
		Tree *t = n->u[0].p;
		fmtprint(f, "<=");
		if (t != NULL && (t->kind == nThunk || t->kind == nPrim))
			tailcall(t, FALSE);
		fmtprint(f, "{%T}", t);
		return FALSE;
	}

	case nVar:
		fmtputc(f, '$');
		n = n->u[0].p;
		if (n == NULL || n->kind == nWord || n->kind == nQword)
			goto top;
		fmtprint(f, "(%#T)", n);
		return FALSE;

	case nLambda:
		fmtprint(f, "@ ");
		if (n->u[0].p == NULL)
			fmtprint(f, "* ");
		else
			fmtprint(f, "%T", n->u[0].p);
		fmtprint(f, "{%T}", n->u[1].p);
		return FALSE;

	case nList:
		if (!group) {
			for (; n->u[1].p != NULL; n = n->u[1].p)
				fmtprint(f, "%T ", n->u[0].p);
			n = n->u[0].p;
			goto top;
		}
		switch (treecount(n)) {
		case 0:
			fmtcat(f, "()");
			break;
		case 1:
			fmtprint(f, "%T%T", n->u[0].p, n->u[1].p);
			break;
		default:
			fmtprint(f, "(%T", n->u[0].p);
			while ((n = n->u[1].p) != NULL) {
				assert(n->kind == nList);
				fmtprint(f, " %T", n->u[0].p);
			}
			fmtputc(f, ')');
		}
		return FALSE;

	default:
		panic("bad node kind: %d", n->kind);

	}
	NOTREACHED;
}

/* enclose -- build up a closure */
static void enclose(Format *f, Binding *binding, const char *sep) {
	if (binding != NULL) {
		Binding *next = binding->next;
		enclose(f, next, ";");
		fmtprint(f, "%S=%#L%s", binding->name, binding->defn, " ", sep);
	}
}

/* TODO: investigate/eliminte #if 0'd oode */

#if 0
typedef struct Chain Chain;
struct Chain {
	Closure *closure;
	Chain *next;
};
static Chain *chain = NULL;
#endif

/* %C -- print a closure */
static Boolean Cconv(Format *f) {
	Closure *closure = va_arg(f->args, Closure *);
	Tree *tree = closure->tree;
	Binding *binding = closure->binding;
	Boolean altform = (f->flags & FMT_altform) != 0;

#if 0
	int i;
	Chain me, *cp;
	assert(tree->kind == nThunk || tree->kind == nLambda || tree->kind == nPrim);
	assert(binding == NULL || tree->kind != nPrim);

	for (cp = chain, i = 0; cp != NULL; cp = cp->next, i++)
		if (cp->closure == closure) {
			fmtprint(f, "%d $&nestedbinding", i);
			return FALSE;
		}
	me.closure = closure;
	me.next = chain;
	chain = &me;
#endif

	if (altform)
		fmtprint(f, "%S", str("%C", closure));
	else {
		if (binding != NULL) {
			fmtprint(f, "%%closure(");
			enclose(f, binding, "");
			fmtprint(f, ")");
		}
		fmtprint(f, "%T", tree);
	}

#if 0
	chain = chain->next;	/* TODO: exception unwinding? */
#endif
	return FALSE;
}

/* %E -- print a term */
static Boolean Econv(Format *f) {
	Term *term = va_arg(f->args, Term *);
	Closure *closure = getclosure(term);

	if (closure != NULL)
		fmtprint(f, (f->flags & FMT_altform) ? "%#C" : "%C", closure);
	else
		fmtprint(f, (f->flags & FMT_altform) ? "%S" : "%s", getstr(term));
	return FALSE;
}

/* %S -- print a string with conservative quoting rules */
static Boolean Sconv(Format *f) {
	int c;
	enum { Begin, Quoted, Unquoted } state = Begin;
	const unsigned char *s, *t;
	extern const char nw[];

	s = va_arg(f->args, const unsigned char *);
	if (f->flags & FMT_altform || *s == '\0')
		goto quoteit;
	for (t = s; (c = *t) != '\0'; t++)
		if (nw[c] || c == '@')
			goto quoteit;
	fmtprint(f, "%s", s);
	return FALSE;

quoteit:

	for (t = s; (c = *t); t++)
		if (!isprint(c)) {
			if (state == Quoted)
				fmtputc(f, '\'');
			if (state != Begin)
				fmtputc(f, '^');
			switch (c) {
			    case '\a':	fmtprint(f, "\\a");	break;
			    case '\b':	fmtprint(f, "\\b");	break;
			    case '\f':	fmtprint(f, "\\f");	break;
			    case '\n':	fmtprint(f, "\\n");	break;
			    case '\r':	fmtprint(f, "\\r");	break;
			    case '\t':	fmtprint(f, "\\t");	break;
		            case '\33':	fmtprint(f, "\\e");	break;
			    default:	fmtprint(f, "\\%o", c);	break;
			}
			state = Unquoted;
		} else {
			if (state == Unquoted)
				fmtputc(f, '^');
			if (state != Quoted)
				fmtputc(f, '\'');
			if (c == '\'')
				fmtputc(f, '\'');
			fmtputc(f, c);
			state = Quoted;
		}

	switch (state) {
	    case Begin:
		fmtprint(f, "''");
		break;
	    case Quoted:
		fmtputc(f, '\'');
		break;
	    case Unquoted:
		break;
	}

	return FALSE;
}

/* %Z -- print a StrList */
static Boolean Zconv(Format *f) {
	char *sep = va_arg(f->args, char *);
	for (StrList *lp = va_arg(f->args, StrList *), *next; lp != NULL; lp = next) {
		next = lp->next;
		fmtprint(f, "%s%s", lp->str, next == NULL ? "" : sep);
	}
	return FALSE;
}

/* %F -- protect an exported name from brain-dead shells */
static Boolean Fconv(Format *f) {
	unsigned char *name = va_arg(f->args, unsigned char *);
	int c;

	for (unsigned char *s = name; (c = *s) != '\0'; s++)
		if ((s == name ? isalpha(c) : isalnum(c))
		    || (c == '_' && s[1] != '_'))
			fmtputc(f, c);
		else
			fmtprint(f, "__%02x", c);
	return FALSE;
}

/* %N -- undo %F */
static Boolean Nconv(Format *f) {
	int c;
	unsigned char *s = va_arg(f->args, unsigned char *);

	while ((c = *s++) != '\0') {
		if (c == '_' && *s == '_') {
			static const char hexchar[] = "0123456789abcdef";
			const char *h1 = strchr(hexchar, s[1]);
			const char *h2 = strchr(hexchar, s[2]);
			if (h1 != NULL && h2 != NULL) {
				c = ((h1 - hexchar) << 4) | (h2 - hexchar);
				s += 3;
			}
		}
		fmtputc(f, c);
	}
	return FALSE;
}

/* %W -- print a list for exporting to the environment, merging and quoting */
static Boolean Wconv(Format *f) {
	List *lp, *next;

	for (lp = va_arg(f->args, List *); lp != NULL; lp = next) {
		int c;
		const char *s;
		for (s = getstr(lp->term); (c = *s) != '\0'; s++) {
			if (c == ENV_ESCAPE || c == ENV_SEPARATOR)
				fmtputc(f, ENV_ESCAPE);
			fmtputc(f, c);
		}
		next = lp->next;
		if (next != NULL)
			fmtputc(f, ENV_SEPARATOR);
	}
	return FALSE;
}


#if LISPTREES
static Boolean Bconv(Format *f) {
	Tree *n = va_arg(f->args, Tree *);
	if (n == NULL) {
		fmtprint(f, "nil");
		return FALSE;
	}
	switch (n->kind) {
#define SINGLE_CASE(kind, formatString, type)			\
		case kind: \
			fmtprint(f, formatString, n->u[0].type); \
			return FALSE;
#define DOUBLE_CASE(kind, formatString, type)				\
		case kind: \
			fmtprint(f, formatString, n->u[0].type, n->u[1].type); \
			return FALSE;
	SINGLE_CASE(nWord, "(word \"%s\")", s);
	SINGLE_CASE(nQword, "(qword \"%s\")", s);
	SINGLE_CASE(nPrim, "(prim %s)", s);
	SINGLE_CASE(nCall, "(call %B)", p);
	SINGLE_CASE(nThunk, "(thunk %B)", p);
	SINGLE_CASE(nVar, "(var %B)", p);
	DOUBLE_CASE(nAssign, "(assign %B %B)", p);
	DOUBLE_CASE(nConcat, "(concat %B %B)", p);
	DOUBLE_CASE(nClosure, "(%%closure %B %B)", p);
	DOUBLE_CASE(nFor, "(for %B $B)", p);
	DOUBLE_CASE(nLambda, "(lambda %B $B)", p);
	DOUBLE_CASE(nLet, "(let %B %B)", p);
	DOUBLE_CASE(nLocal, "(local %B %B)", p);
	DOUBLE_CASE(nMatch, "(match %B %B)", p);
	DOUBLE_CASE(nExtract, "(extract %B %B)", p);
	DOUBLE_CASE(nRedir, "(redir %B %B)", p);
	DOUBLE_CASE(nVarsub, "(varsub %B %B)", p);
	DOUBLE_CASE(nPipe, "(pipe %d %d)", i);
	case nList: {
		fmtprint(f, "(list");
		do {
			assert(n->kind == nList);
			fmtprint(f, " %B", n->u[0].p);
		} while ((n = n->u[1].p) != NULL);
		fmtprint(f, ")");
		return FALSE;
	}

	default: NOTREACHED;
	}
}
#endif

/* install the conversion routines */
void initconv(void) {
	fmtinstall('C', Cconv);
	fmtinstall('E', Econv);
	fmtinstall('F', Fconv);
	fmtinstall('L', Lconv);
	fmtinstall('N', Nconv);
	fmtinstall('S', Sconv);
	fmtinstall('T', Tconv);
	fmtinstall('W', Wconv);
	fmtinstall('Z', Zconv);
#if LISPTREES
	fmtinstall('B', Bconv);
#endif
}
