/* tree.cxx -- functions for manipulating parse-trees. (create, copy, scan) */

#include "xs.hxx"

template <int size>
static Tree* newtree() {
	return reinterpret_cast<Tree*>(galloc(offsetof(Tree, u[size])));
}

/* mk -- make a new node; used to generate the parse tree */
extern Tree *mk (int t, ...) {
	/* t is NodeKind, which is incompatible with va_start because the
           compiler gets to decide the default promotion. So we declare
	   t as int and check the range here. It won't stop you from
	   passing the wrong type, but it's the best we can do. */
	va_list ap;
	Tree* n;

	va_start(ap, t);
	switch (t) {
	    default:
		panic("mk: bad node kind %d", t);
	    case nWord: case nQword: case nPrim:
	    case nInt: case nFloat:
		n = newtree<1>();
		n->u[0].s = va_arg(ap, char *);
		break;
	    case nCall: case nThunk: case nVar: case nArith:
		n = newtree<1>();
		n->u[0].p = va_arg(ap, Tree *);
		break;
	    case nAssign:  case nConcat: case nClosure: case nFor:
	    case nLambda: case nLet: case nList:  case nLocal:
	    case nVarsub: case nMatch: case nExtract:
	    case nRedir: case nMinus: case nPlus:
	    case nMult: case nDivide: case nModulus: case nPow:
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
	n->kind = (NodeKind)t;
	va_end(ap);
	
	return n;
}
