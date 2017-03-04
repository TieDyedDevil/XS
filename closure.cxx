/* closure.c -- operations on bindings, closures, lambdas, and thunks */

#include "xs.hxx"
#include <stdint.h>
#include <map>

extern Closure *mkclosure(Tree* tree, Binding* binding) {
	Closure* closure = gcnew(Closure);
	closure->tree = tree;
	closure->binding = binding;
	return closure;;
}

/* revtree -- destructively reverse a list stored in a tree */
static Tree *revtree(Tree *tree) {
	Tree *prev, *next;
	if (tree == NULL)
		return NULL;
	prev = NULL;
	do {
		assert(tree->kind == nList);
		next = tree->u[1].p;
		tree->u[1].p = prev;
		prev = tree;
	} while ((tree = next) != NULL);
	return prev;
}

typedef struct Chain Chain;
struct Chain {
	Closure *closure;
	Chain *next;
};
static Chain *chain = NULL;

static Binding *extract(Tree *tree, Binding *bindings) {
	static std::map<uint64_t, Binding *, std::less<uint64_t>,
	    traceable_allocator< std::pair<const uint64_t, Binding*> > > bindmap;

	for (; tree != NULL; tree = tree->u[1].p) {
		Tree *iddefn = tree->u[0].p;
		tree = tree->u[1].p;
		Tree *defn = tree->u[0].p;
		assert(tree->kind == nList);
		if (defn != NULL) {
			List *list = NULL;
			Tree *name = defn->u[0].p;
			assert(name->kind == nWord || name->kind == nQword);
			defn = revtree(defn->u[1].p);
			for (; defn != NULL; defn = defn->u[1].p) {
				Term *term = NULL;
				Tree *word = defn->u[0].p;
				NodeKind k = word->kind;
				assert(defn->kind == nList);
				assert(k == nWord || k == nQword || k == nPrim);
				if (k == nPrim) {
					const char *prim = word->u[0].s;
					if (streq(prim, "nestedbinding")) {
						int i, count;
						if (
							(defn = defn->u[1].p) == NULL
						     || defn->u[0].p->kind != nWord
						     || (count = (atoi(defn->u[0].p->u[0].s))) < 0
						) {
							fail("$&parse", "improper use of $&nestedbinding");
							NOTREACHED;
						}
						Chain *cp;
						for (cp = chain, i = 0;; cp = cp->next, i++) {
							if (cp == NULL) {
								fail("$&parse", "bad count in $&nestedbinding: %d", count);
								NOTREACHED;
							}
							if (i == count)
								break;
						}
						term = mkterm(NULL, cp->closure);
					} else {
						fail("$&parse", "bad unquoted primitive in %%closure: $&%s", prim);
						NOTREACHED;
					}
				} else
					term = mkstr(word->u[0].s);
				list = mklist(term, list);
			}

			const char *id_s = iddefn->u[1].p->u[0].p->u[0].s;
			int id = strtoll(id_s, NULL, 16);

			if (!bindmap.count(id)) bindmap[id] = mkbinding(name->u[0].s, list, bindings);
			// The closure should include the same outer bindings as we expect
			assert (bindings == bindmap[id]->next); 
			bindings = bindmap[id];
		}
	}

	return bindings;
}

extern Closure *extractbindings(Tree *tree0) {
	Chain me;
	Tree *volatile tree = tree0;
	Binding *volatile bindings = NULL;

	

	if (tree->kind == nList && tree->u[1].p == NULL)
		tree = tree->u[0].p; 

	me.closure = mkclosure(NULL, NULL);
	me.next = chain;
	chain = &me;

	try {
		while (tree->kind == nClosure) {
			bindings = extract(tree->u[0].p, bindings);
			tree = tree->u[1].p;
			if (tree->kind == nList && tree->u[1].p == NULL)
				tree = tree->u[0].p; 
		}
	} catch (List *e) {
		chain = chain->next;
		throw e;
	}

	chain = chain->next;

	Closure* result = me.closure;
	result->tree = tree;
	result->binding = bindings;
	
	return result;
}


/*
 * Binding garbage collection support
 */

extern Binding *mkbinding(const char* name, List* defn, Binding* next) {
	assert(next == NULL || next->name != NULL);
	validatevar(name);
	Binding* binding = gcnew(Binding);
	binding->name = name;
	binding->defn = defn;
	binding->next = next;
	return binding;
}

extern Binding *reversebindings(Binding *binding) {
	if (binding == NULL)
		return NULL;
	else {
		Binding *prev, *next;
		prev = NULL;
		do {
			next = binding->next;
			binding->next = prev;
			prev = binding;
		} while ((binding = next) != NULL);
		return prev;
	}
}
