/* eval.cxx -- evaluation of lists and trees */

#include "xs.hxx"
#include <string>
#include <term.hxx>
unsigned long evaldepth = 0, maxevaldepth = MAXmaxevaldepth;

static void failexec(const char* file, const List* args) NORETURN;
static void failexec(const char* file, const List* args) {
	List *fn;
	fn = varlookup("fn-%exec-failure", NULL);
	if (fn != NULL) {
		int olderror = errno;
		const List* list = append(fn, mklist(mkstr(file),
                                          const_cast<List*>(args)));
		
		eval(list, NULL, 0);
		errno = olderror;
	}
	eprint("%s: %s\n", file, xsstrerror(errno));
	exit(1);
}

/* forkexec -- fork (if necessary) and exec */
extern List *forkexec(const char *file, const List *list, bool inchild) {
	Vector *env = mkenv(),
		   *args = vectorize(list);
	int pid = efork(!inchild, false);
	if (pid == 0) {
		execve(file, &(*args)[0], &(*env)[0]);
		failexec(file, list);
	}
	
	int status = ewaitfor(pid);
	if ((status & 0xff) == 0) {
		sigint_newline = false;
		SIGCHK();
		sigint_newline = true;
	} else
		SIGCHK();
	printstatus(0, status);
	return mklist(mkterm(mkstatus(status), NULL), NULL);
}

/* Sets each value to each values, with proper semantics for things like 
   (a b) = 1 2 3 */
static void assign_helper(List*& value, List*& values, void *vars) {
	if (!values) value = NULL;
	else if (vars == NULL || values->next == NULL) {
		value = values;
		values = NULL;
	} else {
		value = mklist(values->term, NULL);
		values = values->next;
	}
}

/* assign -- bind a list of values to a list of variables */
static List *assign(Tree* varform, Tree* valueform, Binding* binding) {
	List* vars = glom(varform, binding, false);

	if (vars == NULL)
		fail("xs:assign", "null variable name");

	List* values = glom(valueform, binding, true);
	List* result = values;

	List* value;
	const char* name;
	iterate (vars) {
		name = getstr(vars->term);
		assign_helper(value, values, vars->next);
		vardef(name, binding, value);
	}

	return result;
}

/* letbindings -- create a new Binding containing let-bound (lexical) variables */
static Binding *letbindings(Tree* defn, Binding* binding,
				Binding* context,
				int __attribute__((unused)) evalflags) {
	Tree* assign;
	List *vars, *values, *value;
	const char* name;

	for (; defn != NULL; defn = defn->u[1].p) {
		assert(defn->kind == nList);
		if (defn->u[0].p == NULL)
			continue;

		assign = defn->u[0].p;
		assert(assign->kind == nAssign);
		vars = glom(assign->u[0].p, context, false);
		values = glom(assign->u[1].p, context, true);

		if (vars == NULL)
			fail("xs:letbindings", "null variable name");

		for (; vars != NULL; vars = vars->next) {
			name = getstr(vars->term);
			assign_helper(value, values, vars->next);
			binding = mkbinding(name, value, binding);
		}
	}

	return binding;
}

/* localbind -- recursively convert a Bindings list into dynamic binding */
static const List *localbind(Binding* dynamic, Binding* lexical,
			   Tree* body, int evalflags) {
	if (!dynamic)
		return walk(body, lexical, evalflags);
	else {
		Dyvar p(dynamic->name, dynamic->defn);
		return localbind(dynamic->next, lexical, body, evalflags);
	}
}

/* local -- build, recursively, one layer of local assignment */
const static List *local(Tree *defn, Tree* body,
		   Binding* bindings, int evalflags) {
	Binding* dynamic =
		reversebindings(letbindings(defn, NULL, bindings, evalflags));
	return localbind(dynamic, bindings, body, evalflags);
}

/* forloop -- evaluate a for loop */
const static List *forloop(Tree* defn, Tree* body,
			 Binding* outer, int evalflags) {
	static List MULTIPLE = { NULL, NULL };

	Binding* looping = NULL;
	for (; defn != NULL; defn = defn->u[1].p) {
		assert(defn->kind == nList);
		if (defn->u[0].p == NULL)
			continue;
		Tree* assign = defn->u[0].p;
		assert(assign->kind == nAssign);
		List* vars = glom(assign->u[0].p, outer, false);
		List* list = glom(assign->u[1].p, outer, true);
		if (vars == NULL)
			fail("xs:forloop", "null variable name");
		for (; vars != NULL; vars = vars->next) {
			const char* var = getstr(vars->term);
			looping = mkbinding(var, list, looping);
			list = &MULTIPLE;
		}
		SIGCHK();
	}
	looping = reversebindings(looping);

	bool allnull;
	Binding *bp, *lp, *sequence; 
	List* value;
	const List* result = ltrue;

	try {
		for (;;) {
			allnull = true;
			bp = outer;
			lp = looping;
			sequence = NULL;
			for (; lp != NULL; lp = lp->next) {
				value = NULL;
				if (lp->defn != &MULTIPLE)
					sequence = lp;
				assert(sequence != NULL);
				if (sequence->defn != NULL) {
					value = mklist(sequence->defn->term,
							   NULL);
					sequence->defn = sequence->defn->next;
					allnull = false;
				}
				bp = mkbinding(lp->name, value, bp);
			}
			if (allnull) {
				break;
			}
			result = walk(body, bp, evalflags & eval_exitonfalse);
			SIGCHK();
		}
	} catch (List *e) {
		if (!termeq(e->term, "break"))
			throw e;
		return e->next;
	}
	return result;
}

/* matchpattern -- does the text match a pattern? */
static const List *matchpattern(Tree* subjectform, Tree* patternform,
			  Binding* binding) {
	StrList *quote = NULL;
	List* subject = glom(subjectform, binding, true);
	List* pattern = glom2(patternform, binding, &quote);
	return listmatch(subject, pattern, quote) 
		? ltrue 
		: lfalse;
}

/* extractpattern -- Like matchpattern, but returns matches */
static List *extractpattern(Tree* subjectform, Tree* patternform,
				Binding* binding) {
	StrList *quote = NULL;
	List* subject = glom(subjectform, binding, true);
	List* pattern = glom2(patternform, binding, &quote);
	return extractmatches(subject, pattern, quote);
}

/* walk -- walk through a tree, evaluating nodes */
extern const List *walk(Tree* tree, Binding* binding, int flags) {
	SIGCHK();

top:
	if (tree == NULL) return ltrue;

	switch (tree->kind) {
		case nConcat: case nList: case nQword: case nVar: case nVarsub:
		case nWord: case nThunk: case nLambda: case nCall: case nPrim: {
		List* list = glom(tree, binding, true);
		return eval(list, binding, flags);
		}

		case nAssign:
		return assign(tree->u[0].p, tree->u[1].p, binding);

		case nLet: case nClosure: {
		binding = letbindings(tree->u[0].p, binding, binding, flags);
		tree = tree->u[1].p;
		}
		goto top;

		case nLocal:
		return local(tree->u[0].p, tree->u[1].p, binding, flags);

		case nFor:
		return forloop(tree->u[0].p, tree->u[1].p, binding, flags);

		case nMatch:
		return matchpattern(tree->u[0].p, tree->u[1].p, binding);

		case nExtract:
		return extractpattern(tree->u[0].p, tree->u[1].p, binding);

		default:
		panic("walk: bad node kind %d", tree->kind);

	}
	NOTREACHED;
}


/* bindargs -- bind an argument list to the parameters of a lambda */
extern Binding *bindargs(Tree* params, List* args, Binding* binding) {
	List* value;
	Tree* param;
	for (; params; params = params->u[1].p) {
		assert(params->kind == nList);
		param = params->u[0].p;
		assert(param->kind == nWord || param->kind == nQword);
		assign_helper(value, args, params->u[1].p);
		binding = mkbinding(param->u[0].s, value, binding);
	}

	return binding;
}

/* pathsearch -- evaluate fn %pathsearch + some argument */
extern const List *pathsearch(Term *term) {
	List *search, *list;
	search = varlookup("fn-%pathsearch", NULL);
	if (search == NULL)
		fail("xs:pathsearch", "%E: fn %%pathsearch undefined", term);
	list = mklist(term, NULL);
	return eval(append(search, list), NULL, 0);
}

class Depth_tracker {
	public:
		Depth_tracker() {
			if (++evaldepth >= maxevaldepth)
				fail("xs:eval", "max-eval-depth exceeded");
		}
		~Depth_tracker() {
			--evaldepth;
		}
};

/* eval -- evaluate a list, producing a list */
extern const List *eval(const List* list, Binding* binding, int flags) {
	Depth_tracker t;

	Closure *volatile cp;

	const char *name, *funcname = NULL;
	const List* fn;

restart:
	if (list == NULL) return ltrue;
	assert(list->term != NULL);

	if ((cp = getclosure(list->term)) != NULL) {
		switch (cp->tree->kind) {
			case nPrim:
			assert(cp->binding == NULL);
			list = prim(cp->tree->u[0].s, list->next, binding, flags);
			break;
			case nThunk:
			list = walk(cp->tree->u[0].p, cp->binding, flags);
			break;
			case nLambda:
			{
				Tree* tree = cp->tree;
				  
				Binding* context =  bindargs(tree->u[0].p,
							 list->next,
							 cp->binding);

#define WALKFN walk(tree->u[1].p, context, flags)
				if (funcname) {
					Dyvar p("0",
						 mklist(mkterm(funcname,
							  NULL),
					 	    NULL));

					list = WALKFN;
				} else list = WALKFN;
#undef WALKFN
			}
			break;
			case nList: {
			List *t = glom(cp->tree, cp->binding, true);
			list = append(t, t->next);
			goto restart;
			}
			default:
			panic("eval: bad closure node kind %d",
				  cp->tree->kind);
			}
		goto done;
	}

	/* the logic here is duplicated in $&whats */

	name = getstr(list->term);
	fn = varlookup2("fn-", name, binding);
	if (fn != NULL) {
		funcname = name;
		list = append(fn, list->next);
		goto restart;
	}
	if (isabsolute(name)) {
		const char *error = checkexecutable(name);
		if (error)
			fail("$&whats", "%s: %s", name, error);
		list = forkexec(name, list, flags & eval_inchild);
		goto done;
	}

	fn = pathsearch(list->term);
	if (fn != NULL && fn->next == NULL
		&& (cp = getclosure(fn->term)) == NULL) {
		const char *name = getstr(fn->term);
		list = forkexec(name, list, flags & eval_inchild);
		goto done;
	}

	list = append(fn, list->next);
	goto restart;

done:
	if ((flags & eval_exitonfalse) && !istrue(list))
		exit(exitstatus(list));
	return list;
}

