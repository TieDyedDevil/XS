/* tree.c -- functions for manipulating parse-trees. (create, copy, scan) ($Revision: 1.1.1.1 $) */

#include "es.hxx"

template <int size>
static Tree* newtree() {
	return reinterpret_cast<Tree*>(galloc(offsetof(Tree, u[size])));
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
		n = newtree<1>();
		n->u[0].s = va_arg(ap, char *);
		break;
	    case nCall: case nThunk: case nVar:
		n = newtree<1>();
		n->u[0].p = va_arg(ap, Tree *);
		break;
	    case nAssign:  case nConcat: case nClosure: case nFor:
	    case nLambda: case nLet: case nList:  case nLocal:
	    case nVarsub: case nMatch: case nExtract:
	    case nRedir:
		n = newtree<2>();
		n->u[0].p = va_arg(ap, Tree *);
		n->u[1].p = va_arg(ap, Tree *);
		break;
	    case nPipe:
		n = newtree<2>();
		n->u[0].i = va_arg(ap, int);
		n->u[1].i = va_arg(ap, int);
		break;
 	}
	n->kind = t;
	va_end(ap);
	
	return n;
}
