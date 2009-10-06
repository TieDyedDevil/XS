/* tree.c -- functions for manipulating parse-trees. (create, copy, scan) ($Revision: 1.1.1.1 $) */

#include "es.hxx"

static Tree* tgalloc(size_t s) {
	return reinterpret_cast<Tree*>(galloc(s));
}

/* mk -- make a new node; used to generate the parse tree */
extern Tree *mk (NodeKind  t, ...) {
	va_list ap;
	Tree* n;

	va_start(ap, t);
	switch (t) {
	    default:
		panic("mk: bad node kind %d", t);
	    case nWord: case nQword: case nPrim:
		n = tgalloc(offsetof(Tree, u[1]));
		n->u[0].s = va_arg(ap, char *);
		break;
	    case nCall: case nThunk: case nVar:
		n = tgalloc(offsetof(Tree, u[1]));
		n->u[0].p = va_arg(ap, Tree *);
		break;
	    case nAssign:  case nConcat: case nClosure: case nFor:
	    case nLambda: case nLet: case nList:  case nLocal:
	    case nVarsub: case nMatch: case nExtract:
		n = tgalloc(offsetof(Tree, u[2]));
		n->u[0].p = va_arg(ap, Tree *);
		n->u[1].p = va_arg(ap, Tree *);
		break;
	    case nRedir:
		n = tgalloc(offsetof(Tree, u[2]));
		n->u[0].p = va_arg(ap, Tree *);
		n->u[1].p = va_arg(ap, Tree *);
		break;
	    case nPipe:
		n = tgalloc(offsetof(Tree, u[2]));
		n->u[0].i = va_arg(ap, int);
		n->u[1].i = va_arg(ap, int);
		break;
 	}
	n->kind = t;
	va_end(ap);

	
	return n;
}
