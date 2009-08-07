/* glom.c -- walk parse tree to produce list ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

/* concat -- cartesion cross product concatenation */
static List *concat(Ref<List> list1,Ref<List> list2) {
	Ref<List> result = NULL;

	for (List **p = result.rget(); list1 != NULL; list1 = list1->next) {
		for (Ref<List> lp = list2;
		     lp != NULL;
		     p = &(*p)->next, lp = lp->next)
		
			*p = mklist(termcat(list1->term, lp->term), NULL);
	}
	return result.release();
}

/* qcat -- concatenate two quote flag terms */
static const char *qcat(Ref<const char> q1,
			Ref<const char> q2,
			Ref<Term> t1,
			Ref<Term> t2)
{
	if (q1 == QUOTED && q2 == QUOTED)
		return QUOTED;
	if (q1 == UNQUOTED && q2 == UNQUOTED)
		return UNQUOTED;

	size_t len1 = (q1 == QUOTED || q1 == UNQUOTED)
		? strlen(getstr(t1.uget()))
		: strlen(q1.uget());
	size_t len2 = (q2 == QUOTED || q2 == UNQUOTED)
		? strlen(getstr(t2.uget()))
		: strlen(q2.uget());
	Ref<char> s = reinterpret_cast<char*>(gcalloc(len1 + len2 + 1, &StringTag));

	if (q1 == QUOTED)
		memset(s.uget(), 'q', len1);
	else if (q1 == UNQUOTED)
		memset(s.uget(), 'r', len1);
	else
		memcpy(s.uget(), q1.uget(), len1);
		
	if (q2 == QUOTED)
		memset(&s[len1], 'q', len2);
	else if (q2 == UNQUOTED)
		memset(&s[len1], 'r', len2);
	else
		memcpy(&s[len1], q2.uget(), len2);
	s[len1 + len2] = '\0';

	return s.release();
}

/* qconcat -- cartesion cross product concatenation; also produces a quote list */
static List *qconcat(Ref<List> list1, Ref<List> list2,
		     Ref<StrList> ql1, Ref<StrList> ql2, 
		     StrList **quotep) 
{
	Ref<List> result; 
	List **p;
	StrList **qp;

	for (p = result.rget(), qp = quotep; list1 != NULL; list1 = list1->next, ql1 = ql1->next) {
		Ref<List> lp;
		Ref<StrList> qlp;
		for (lp = list2, qlp = ql2; lp != NULL; lp = lp->next, qlp = qlp->next) {
			*p = mklist(termcat(list1->term, lp->term), NULL);
			p = &(*p)->next;
			*qp = mkstrlist(
				qcat(ql1->str, qlp->str, list1->term, lp->term),
				NULL).release();
			qp = &(*qp)->next;
		}
	}
	return result.release();
}

/* subscript -- variable subscripting */
static List *subscript(Ref<List> list, Ref<List> subs) {
	int lo, hi, len = length(list.uget()), counter = 1;
	Ref<List> result, current = list;
	List **prevp = result.rget();

	if (subs != NULL && streq(getstr(subs->term), "...")) {
		lo = 1;
		goto mid_range;
	}

	gcdisable(); /* prevp could point to pointer in structure which is forwarded */
	while (subs != NULL) {
		lo = atoi(getstr(subs->term));
		if (lo < 1) {
			fail("es:subscript", "bad subscript: %s", getstr(subs->term));
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
					fail("es:subscript", "bad subscript: %s", getstr(subs->term));
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
		while (counter < lo) ++counter, current = current->next;
		for (; counter <= hi; ++counter, current = current->next) {
			*prevp = mklist(current->term, NULL);
			prevp = &(*prevp)->next;
		}
	}
	gcenable();

	return result.release();
}

/* glom1 -- glom when we don't need to produce a quote list */
static List *glom1(Ref<Tree> tree, Ref<Binding> binding) {
	Ref<List> result;
	Ref<List> tail;

	assert(!gcisblocked());

	while (tree != NULL) {
		Ref<List> list;

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
			list = mklist(mkterm(NULL, mkclosure(tree, binding)), NULL);
			tree = NULL;
			break;
		case nPrim:
			list = mklist(mkterm(NULL, mkclosure(tree, NULL)), NULL);
			tree = NULL;
			break;
		case nVar: {
			Ref<List> var = glom1(tree->u[0].p, binding);
			tree = NULL;
			for (; var != NULL; var = var->next) {
				list = listcopy(varlookup(getstr(var->term), binding));
				if (list != NULL) {
					if (result == NULL)
						tail = result = list;
					else
						tail->next = list.uget();
					for (; tail->next != NULL; tail = tail->next)
						;
				}
				list = NULL;
			}
			break;
		}
		case nVarsub:
			list = glom1(tree->u[0].p, binding);
			if (list == NULL) fail("es:glom", "null variable name in subscript");
			if (list->next != NULL) fail("es:glom", "multi-word variable name in subscript");

			{
				Ref<const char> name = getstr(list->term);
				list = varlookup(name, binding);
				Ref<List> sub = glom1(tree->u[1].p, binding);
				tree = NULL;
				list = subscript(list.uget(), sub.uget());
			}
			break;
		case nCall:
			list = listcopy(walk(tree->u[0].p, binding.uget(), 0));
			tree = NULL;
			break;
		case nList:
			list = glom1(tree->u[0].p, binding);
			tree = tree->u[1].p;
			break;
		case nConcat: {
			Ref<List> l = glom1(tree->u[0].p, binding);
			Ref<List> r = glom1(tree->u[1].p, binding);
			tree = NULL;
			list = concat(l, r);
			break;
	        }
		default:
			fail("es:glom", "glom1: bad node kind %d", tree->kind);
		}

		if (list != NULL) {
			if (result == NULL) 	tail = result = list;
			else			tail->next = list.uget();
			while(tail->next != NULL) tail = tail->next;
		}
	}

	return result.release();
}

/* glom2 -- glom and produce a quoting list */
extern List *glom2(Ref<Tree> tree, Ref<Binding> binding, StrList **quotep) {
	Ref<List> result;
	Ref<List> tail;
	Ref<StrList> qtail;

	assert(!gcisblocked());
	assert(quotep != NULL);

	/*
	 * this loop covers only the cases where we might produce some
	 * unquoted (raw) values.  all other cases are handled in glom1
	 * and we just add quoted word flags to them.
	 */

	while (tree != NULL) {
		Ref<List> list;
		Ref<StrList> qlist;

		switch (tree->kind) {
		case nWord:
			list = mklist(mkterm(tree->u[0].s, NULL), NULL);
			qlist = mkstrlist(UNQUOTED, NULL);
			tree = NULL;
			break;
		case nList:
			list = glom2(tree->u[0].p, binding, qlist.rget());
			tree = tree->u[1].p;
			break;
		case nConcat: {
			Ref<StrList> ql, qr;
			Ref<List> l = glom2(tree->u[0].p, binding, ql.rget()),
				   r = glom2(tree->u[1].p, binding, qr.rget());
			{
				list = qconcat(l, r, ql, qr, qlist.rget());
			}
			tree = NULL;
			break;
		}
		default:
			list = glom1(tree.uget(), binding.uget());
			for (Ref<List> lp = list; lp != NULL; lp = lp->next)
				qlist = mkstrlist(QUOTED, qlist.release());
			tree = NULL;
			break;
		}

		if (list != NULL) {
			if (result == NULL) {
				assert(*quotep == NULL);
				result = tail = list;
				*quotep = (qtail = qlist).uget();
			} else {
				assert(*quotep != NULL);
				tail->next = list.uget();
				qtail->next = qlist.uget();
			}
			for (; tail->next != NULL; tail = tail->next, qtail = qtail->next)
				;
			assert(qtail->next == NULL);
		}
	}

	return result.release();
}

/* glom -- top level glom dispatching */
extern Ref<List> glom(Ref<Tree> tree, Ref<Binding> binding, bool globit) {
	if (globit) {
		Ref<StrList> quote;
		Ref<List> list = glom2(tree.release(), binding.release(), quote.rget());
		return glob(list, quote);
	} else return glom1(tree.release(), binding.release());
}
