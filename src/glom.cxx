/* glom.cxx -- walk parse tree to produce list */

#include "xs.hxx"
#include <sstream>
#include <functional>
#include <boost/lexical_cast.hpp>
using std::binary_function;
using boost::lexical_cast;


static List *calculate(Tree *, Binding *);

/* concat -- cartesion cross product concatenation */
static List *concat(List* list1,List* list2) {
	List* result = NULL;
	List **p = &result;
	iterate (list1) {
		List *lp = list2;
		iterate (lp) {
			*p = mklist(termcat(list1->term, lp->term), NULL);
			p = &(*p)->next;
		}
	}
	return result;
}

/* qcat -- concatenate two quote flag terms */
static const char *qcat(const char* q1,
			const char* q2,
			Term* t1,
			Term* t2)
{
	if (q1 == QUOTED && q2 == QUOTED)
		return QUOTED;
	if (q1 == UNQUOTED && q2 == UNQUOTED)
		return UNQUOTED;

	size_t len1 = (q1 == QUOTED || q1 == UNQUOTED)
		? strlen(getstr(t1))
		: strlen(q1);
	size_t len2 = (q2 == QUOTED || q2 == UNQUOTED)
		? strlen(getstr(t2))
		: strlen(q2);
	char* s = reinterpret_cast<char*>(galloc(len1 + len2 + 1));

	if (q1 == QUOTED)
		memset(s, 'q', len1);
	else if (q1 == UNQUOTED)
		memset(s, 'r', len1);
	else
		memcpy(s, q1, len1);
		
	if (q2 == QUOTED)
		memset(&s[len1], 'q', len2);
	else if (q2 == UNQUOTED)
		memset(&s[len1], 'r', len2);
	else
		memcpy(&s[len1], q2, len2);
	s[len1 + len2] = '\0';

	return s;
}

#define DUAL_ITERATE(list, quote) \
        for(; list != NULL; list = list->next, quote = quote->next)

/* qconcat -- cartesion cross product concatenation; also produces a quote list */
static List *qconcat(List* list1, List* list2,
		     StrList* ql1, StrList* ql2, 
		     StrList **quotep) 
{
	List* result = NULL; 
	List **p = &result;
	StrList **qp = quotep;

	DUAL_ITERATE(list1, ql1) {
		List* lp = list2;
		StrList* qlp = ql2;
		DUAL_ITERATE(lp, qlp) {
			*p = mklist(termcat(list1->term, lp->term), NULL);
			p = &(*p)->next;
			*qp = mkstrlist(
				qcat(ql1->str, qlp->str, list1->term, lp->term),
				NULL);
			qp = &(*qp)->next;
		}
	}
	return result;
}

/* subscript -- variable subscripting */
static List *subscript(List* list, List* subs) {
	int lo, hi, len = length(list), counter = 1;
	List *result = NULL, *current = list;
	List **prevp = &result;
	int r = 0;

	if (subs != NULL && streq(getstr(subs->term), "...")) {
		lo = 1;
		goto mid_range;
	}

	 /* prevp could point to pointer in structure which is forwarded */
	while (subs != NULL) {
		r = 0;
		lo = atoi(getstr(subs->term));
		if (lo < 1) {
			fail("xs:subscript", "bad subscript: %s",
                             getstr(subs->term));
		}
		subs = subs->next;
		if (subs != NULL && streq(getstr(subs->term), "...")) {
		mid_range:
			subs = subs->next;
			if (subs == NULL)
				hi = len;
			else {
				hi = atoi(getstr(subs->term));
				if (hi < 1) {
					fail("xs:subscript",
                                             "bad subscript: %s",
                                             getstr(subs->term));
				}
				if (hi > len)
					hi = len;
				subs = subs->next;
			}
		} else hi = lo;
		if (lo > len) continue;
		if (counter > lo) {
			current = list;
			counter = 1;
		}
		if (lo > hi) { r = 1; int t = lo; lo = hi; hi = t; }
		List **spp = prevp;
		while (counter < lo) ++counter, current = current->next;
		for (; counter <= hi; ++counter, current = current->next) {
			*prevp = mklist(current->term, NULL);
			prevp = &(*prevp)->next;
		}
		if (r) {
			*spp = reverse(*spp);
			List *f = *spp;
			while (f) {
				prevp = &(f->next);
				f = f->next;
			}
		}
	}
	

	return result;
}

/* glom1 -- glom when we don't need to produce a quote list */
static List *glom1(Tree* tree, Binding* binding) {
	List* result = NULL;
	List* tail = NULL;

	while (tree != NULL) {
		List* list = NULL;

		switch (tree->kind) {
		case nQword:
			list = mklist(mkterm(tree->u[0].s, NULL), NULL);
			tree = NULL;
			break;
		case nWord:
			list = mklist(mkterm(tree->u[0].s, NULL), NULL);
			tree = NULL;
			break;
		case nThunk:
		case nLambda:
			list = mklist(mkterm(NULL, mkclosure(tree, binding)),
                                      NULL);
			tree = NULL;
			break;
		case nPrim:
			list = mklist(mkterm(NULL, mkclosure(tree, NULL)),
                                      NULL);
			tree = NULL;
			break;
		case nVar: {
			List* var = glom1(tree->u[0].p, binding);
			tree = NULL;
			for (; var != NULL; var = var->next) {
				list = listcopy(varlookup(getstr(var->term),
                                                binding));
				if (list != NULL) {
					if (result == NULL)
						tail = result = list;
					else
						tail->next = list;
					for (; tail->next != NULL;
                                             tail = tail->next)
						;
				}
				list = NULL;
			}
			break;
		}
		case nVarsub:
			list = glom1(tree->u[0].p, binding);
			if (list == NULL) fail("xs:glom1",
                                               "null variable name in subscript");
			if (list->next != NULL)
                                fail("xs:glom1",
                                     "multi-word variable name in subscript");

			{
				const char* name = getstr(list->term);
				list = varlookup(name, binding);
				List* sub = glom1(tree->u[1].p, binding);
				tree = NULL;
				list = subscript(list, sub);
			}
			break;
		case nArith:
			list = calculate(tree->u[0].p, binding);
			tree = NULL;
			break;
		case nCall:
			list = listcopy(walk(tree->u[0].p, binding, 0));
			tree = NULL;
			break;
		case nList:
			list = glom1(tree->u[0].p, binding);
			tree = tree->u[1].p;
			break;
		case nConcat: {
			List* l = glom1(tree->u[0].p, binding);
			List* r = glom1(tree->u[1].p, binding);
			tree = NULL;
			list = concat(l, r);
			break;
	        }
		default:
			fail("xs:glom1", "bad node kind %d", tree->kind);
		}

		if (list != NULL) {
			if (result == NULL) 	tail = result = list;
			else			tail->next = list;
			while(tail->next != NULL) tail = tail->next;
		}
	}

	return result;
}

/* glom2 -- glom and produce a quoting list */
extern List *glom2(Tree* tree, Binding* binding, StrList **quotep) {
	List* result = NULL;
	List* tail = NULL;
	StrList* qtail = NULL;

	assert(quotep != NULL);

	/*
	 * this loop covers only the cases where we might produce some
	 * unquoted (raw) values.  all other cases are handled in glom1
	 * and we just add quoted word flags to them.
	 */

	while (tree != NULL) {
		List* list = NULL;
		StrList* qlist = NULL;

		switch (tree->kind) {
		case nWord:
			list = mklist(mkterm(tree->u[0].s, NULL), NULL);
			qlist = mkstrlist(UNQUOTED, NULL);
			tree = NULL;
			break;
		case nList:
			list = glom2(tree->u[0].p, binding, &qlist);
			tree = tree->u[1].p;
			break;
		case nConcat: {
			StrList *ql = NULL, *qr = NULL;
			List *l = glom2(tree->u[0].p, binding, &ql),
			     *r = glom2(tree->u[1].p, binding, &qr);
			list = qconcat(l, r, ql, qr, &qlist);
			tree = NULL;
			break;
		}
		default:
			list = glom1(tree, binding);
			for (List* lp = list; lp != NULL; lp = lp->next)
				qlist = mkstrlist(QUOTED, qlist);
			tree = NULL;
			break;
		}

		if (list != NULL) {
			if (result == NULL) {
				assert(*quotep == NULL);
				result = tail = list;
				*quotep = qtail = qlist;
			} else {
				assert(*quotep != NULL);
				tail->next = list;
				qtail->next = qlist;
			}
			for (; tail->next != NULL;
                             tail = tail->next, qtail = qtail->next)
				;
			assert(qtail->next == NULL);
		}
	}

	return result;
}

/* glom -- top level glom dispatching */
extern List* glom(Tree* tree, Binding* binding, bool globit) {
	if (globit) {
		StrList* quote = NULL;
		List* list = glom2(tree, binding, &quote);
		return glob(list, quote);
	} else return glom1(tree, binding);
}

/* Arithmetic code 
 * Currently horifically inefficient on account of constantly 
   converting to-and-from string representation.
 */

static List *tolist(int x) {
	return mklist(mkstr(str("%d", x)), NULL);
}
static List *tolist(double x) {
	std::stringstream s;
	s.setf(std::ios_base::showpoint);
	s << x;
	return mklist(mkstr(gcdup(s.str().c_str())), NULL);
}
static bool isint(List *x) {
	return strchr(getstr(x->term), '.') == NULL;
}


static int toint(List *x) {
	try {
		return lexical_cast<int>(getstr(x->term));
	} catch (boost::bad_lexical_cast) {
		fail("glom:arith:toint",
                     "Could not handle integer input");
	}
}
static double todouble(List *x) {
	try {
		return lexical_cast<double>(getstr(x->term));
	} catch (boost::bad_lexical_cast) {
		fail("glom:arith:todouble",
		     "Could not handle floating point input");
	}
}

#define OP(f, x, y) op(f<int>(), f<double>(), x, y)

template <typename ftint, typename ftdouble>
static List *op(ftint intf, 
		ftdouble doublef, 
		List *x, List *y) {
	return isint(x) && isint(y)
		? tolist(intf(toint(x), toint(y)))
		: tolist(doublef(todouble(x), todouble(y)));
}

/* calculate -- Take an arithmetic tree, produce result */
static List *calculate(Tree *expr, Binding *binding) {
	switch (expr->kind) {
	case nInt:
		return tolist(lexical_cast<int>(expr->u[0].s));
	case nFloat:
		return tolist(lexical_cast<double>(expr->u[0].s));
	case nVar:
		{
		List *var = glom1(expr->u[0].p, binding);
		List *value = varlookup(getstr(var->term), binding);
		if (value == NULL) return tolist(0);
		/* FIXME: Add some validity checks, not everything is a number */
		return value;
		}
#define EXPR1 calculate(expr->u[0].p, binding)
#define EXPR2 calculate(expr->u[1].p, binding)
	case nPlus:
		return OP(std::plus, EXPR1, EXPR2);
	case nMinus:
		return OP(std::minus, EXPR1, EXPR2);
	case nMult:
		return OP(std::multiplies, EXPR1, EXPR2);
	case nDivide:
		{
		List *a = EXPR1, *b = EXPR2;
		// Integer division by 0 causes issues
		if (isint(b) and toint(b) == 0)
			return tolist(std::numeric_limits<double>::infinity());
		return OP(std::divides, a, b);
		}
	case nModulus:
		{
		List *a = EXPR1, *b = EXPR2;
		if (isint(b) and toint(b) == 0)
			return tolist(std::numeric_limits<double>::infinity());
		if (not isint(b) and todouble(b) == 0.0)
			return tolist(std::numeric_limits<double>::infinity());
		double r = std::fmod(todouble(a), todouble(b));
		if (isint(a) and isint(b)) return tolist(static_cast<int>(r));
		else return tolist(r);
		}
#undef EXPR1
#undef EXPR2
	default:
		fail("xs:calculate", "bad expr kind %d", expr->kind);
	}
}


