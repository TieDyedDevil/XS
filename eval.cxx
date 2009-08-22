/* eval.c -- evaluation of lists and trees ($Revision: 1.2 $) */

#include "es.hxx"
#include <string>
#include <term.hxx>

unsigned long evaldepth = 0, maxevaldepth = MAXmaxevaldepth;

static void failexec(Ref<const char> file, Ref<List> args) NORETURN;
static void failexec(Ref<const char> file, Ref<List> args) {
	List *fn;
	assert(gcisblocked());
	fn = varlookup("fn-%exec-failure", NULL);
	if (fn != NULL) {
		int olderror = errno;
		Ref<List> list = append(fn, mklist(mkstr(file.release()), args.release()));
		gcenable();
		eval(list.release(), NULL, 0);
		errno = olderror;
	}
	eprint("%s: %s\n", file.uget(), esstrerror(errno));
	exit(1);
}

/* forkexec -- fork (if necessary) and exec */
extern List *forkexec(const char *file, List *list, bool inchild) {
	gcdisable();
	Ref<Vector> env = mkenv();
	int pid = efork(!inchild, false);
	if (pid == 0) {
		execve(file, vectorize(list)->vector, env->vector);
		failexec(file, list);
	}
	gcenable();
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

/* Sets each value to each values, with proper semantics for things like (a b) := 1 2 3 */
static void assign_helper(Ref<List>& value, Ref<List>& values, void *vars) {
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
static List *assign(Ref<Tree> varform, Ref<Tree> valueform, Ref<Binding> binding) {
	Ref<List> vars = glom(varform.release(), binding.uget(), false);

	if (vars == NULL)
		fail("es:assign", "null variable name");

	Ref<List> values = glom(valueform.release(), binding.uget(), true);
	Ref<List> result = values;

	Ref<List> value;
	Ref<const char> name;
	for (; vars != NULL; vars = vars->next) {
		name = getstr(vars->term);
		assign_helper(value, values, vars->next);
		vardef(name.release(), binding.uget(), value.release());
	}

	return result.release();
}

/* letbindings -- create a new Binding containing let-bound (lexical) variables */
static Binding *letbindings(Ref<Tree> defn, Ref<Binding> binding,
			    Ref<Binding> context, int evalflags) {
	Ref<Tree> assign;
	Ref<List> vars, values, value;
	Ref<const char> name;

	for (; defn != NULL; defn = defn->u[1].p) {
		assert(defn->kind == nList);
		if (defn->u[0].p == NULL)
			continue;

		assign = defn->u[0].p;
		assert(assign->kind == nAssign);
		vars = glom(assign->u[0].p, context.uget(), false);
		values = glom(assign->u[1].p, context.uget(), true);

		if (vars == NULL)
			fail("es:let", "null variable name");

		for (; vars != NULL; vars = vars->next) {
			name = getstr(vars->term);
			assign_helper(value, values, vars->next);
			binding = mkbinding(name.release(), value.release(), binding.release());
		}
	}

	return binding.release();
}

/* localbind -- recursively convert a Bindings list into dynamic binding */
static List *localbind(Ref<Binding> dynamic, Ref<Binding> lexical,
		       Ref<Tree> body, int evalflags) {
	if (!dynamic)
		return walk(body.uget(), lexical.uget(), evalflags);
	else {
		Push p(dynamic->name, dynamic->defn);
		return localbind(dynamic->next, lexical, body, evalflags);
	}
}

/* local -- build, recursively, one layer of local assignment */
static List *local(Tree *defn, Ref<Tree> body,
		   Ref<Binding> bindings, int evalflags) {
	Ref<Binding> dynamic =
	    reversebindings(letbindings(defn, NULL, bindings, evalflags));
	return localbind(dynamic, bindings, body, evalflags);
}

/* forloop -- evaluate a for loop */
static List *forloop(Ref<Tree> defn, Ref<Tree> body,
		     Ref<Binding> outer, int evalflags) {
	static List MULTIPLE = { NULL, NULL };

	Ref<Binding> looping = NULL;
	for (; defn != NULL; defn = defn->u[1].p) {
		assert(defn->kind == nList);
		if (defn->u[0].p == NULL)
			continue;
		Ref<Tree> assign = defn->u[0].p;
		assert(assign->kind == nAssign);
		Ref<List> vars = glom(assign->u[0].p, outer.uget(), false);
		Ref<List> list = glom(assign->u[1].p, outer.uget(), true);
		if (vars == NULL)
			fail("es:for", "null variable name");
		for (; vars != NULL; vars = vars->next) {
			Ref<const char> var = getstr(vars->term);
			looping = mkbinding(var.release(), list.uget(), looping.release());
			list = &MULTIPLE;
		}
		SIGCHK();
	}
	looping = reversebindings(looping.release());

	bool allnull;
	Ref<Binding> bp, lp, sequence; 
	Ref<List> value;
	Ref<List> result = ltrue;

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
				bp = mkbinding(lp->name, value.release(), bp.release());
			}
			if (allnull) {
				break;
			}
			result = walk(body.uget(), bp.uget(), evalflags & eval_exitonfalse);
			SIGCHK();
		}
	} catch (List *e) {
		if (!termeq(e->term, "break"))
			throwE(e);
		return e->next;
	}
	return result.release();
}

/* matchpattern -- does the text match a pattern? */
static List *matchpattern(Ref<Tree> subjectform, Ref<Tree> patternform,
			  Ref<Binding> binding) {
	StrList *quote = NULL;
	Ref<List> subject = glom(subjectform.release(), binding.uget(), true);
	Ref<List> pattern = glom2(patternform.uget(), binding.uget(), &quote);
	return listmatch(subject.release(), pattern.release(), quote) 
		? ltrue 
		: lfalse;
}

/* extractpattern -- Like matchpattern, but returns matches */
static List *extractpattern(Ref<Tree> subjectform, Ref<Tree> patternform,
			    Ref<Binding> binding) {
	StrList *quote = NULL;
	Ref<List> subject = glom(subjectform.uget(), binding.uget(), true);
	Ref<List> pattern = glom2(patternform.uget(), binding.uget(), &quote);
	return extractmatches(subject.release(), pattern.release(), quote);
}

/* walk -- walk through a tree, evaluating nodes */
extern List *walk(Ref<Tree> tree, Ref<Binding> binding, int flags) {
	SIGCHK();

top:
	if (tree == NULL) return ltrue;

	switch (tree->kind) {
	    case nConcat: case nList: case nQword: case nVar: case nVarsub:
	    case nWord: case nThunk: case nLambda: case nCall: case nPrim: {
		Ref<List> list = glom(tree, binding, true);
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
extern Binding *bindargs(Ref<Tree> params, Ref<List> args, Ref<Binding> binding) {
	if (!params) return mkbinding("*", args.release(), binding.release());

	Ref<List> value;
	Ref<Tree> param;
	for (; params; params = params->u[1].p) {
		assert(params->kind == nList);
		param = params->u[0].p;
		assert(param->kind == nWord || param->kind == nQword);
		assign_helper(value, args, params->u[1].p);
		binding = mkbinding(param->u[0].s, value.release(), binding.release());
	}

	return binding.release();
}

/* pathsearch -- evaluate fn %pathsearch + some argument */
extern List *pathsearch(Term *term) {
	List *search, *list;
	search = varlookup("fn-%pathsearch", NULL);
	if (search == NULL)
		fail("es:pathsearch", "%E: fn %%pathsearch undefined", term);
	list = mklist(term, NULL);
	return eval(append(search, list), NULL, 0);
}

class Depth_tracker {
	public:
		Depth_tracker() {
			if (++evaldepth >= maxevaldepth)
				fail("es:eval", "max-eval-depth exceeded");
		}
		~Depth_tracker() {
			--evaldepth;
		}
};

/* eval -- evaluate a list, producing a list */
extern List *eval(Ref<List> list, Ref<Binding> binding, int flags) {
	Depth_tracker t;

	Closure *volatile cp;

	Ref<const char> name, funcname;
	Ref<List> fn;

restart:
	if (list == NULL) return ltrue;
	assert(list->term != NULL);

	if ((cp = getclosure(list->term)) != NULL) {
		switch (cp->tree->kind) {
		    case nPrim:
			assert(cp->binding == NULL);
			list = prim(cp->tree->u[0].s, list->next, binding.uget(), flags);
			break;
		    case nThunk:
			list = walk(cp->tree->u[0].p, cp->binding, flags);
			break;
		    case nLambda:
		    {
			Ref<Tree> tree = cp->tree;
			      
			/* define a return function */

			static unsigned int retid = 0;

			/* We use string here to work-around the gc's lack of knowledge about id.
			 * Disabling the gc would work, too, but that would disable gc for a lot of code
			 */
			std::string id = str("%ud", retid++);
			Term id_term = { id.c_str(), NULL };
			List id_def = { &id_term, NULL };

			static Term return_term = { "return", NULL };
			List return_def = { &return_term, &id_def };

			static Term throw_term = { "throw", NULL };
			List throw_def = { &throw_term, &return_def };
			assert(termeq(&return_term, "return") && return_def.next && termeq(return_def.next->term, id.c_str()));

			try {
				Ref<Binding> context =  bindargs(tree->u[0].p,
							 list->next,
							 cp->binding);

				context = mkbinding("fn-return", &throw_def, context);

#define WALKFN walk(tree->u[1].p, context, flags)
				if (funcname) {
					Push p("0",
					     mklist(mkterm(funcname.uget(),
							  NULL),
					 	    NULL));

					list = WALKFN;
				} else list = WALKFN;
#undef WALKFN
			} catch (List *e) {
				if (termeq(e->term, "return") && e->next && termeq(e->next->term, id.c_str())) {
					list = e->next->next;
					goto done;
				}
				throwE(e);
			}	
		    }
		    break;
		    case nList: {
			list = glom(cp->tree, cp->binding, true);
			list = append(list, list->next);
			goto restart;
		    }
		    default:
			panic("eval: bad closure node kind %d",
			      cp->tree->kind);
		    }
		goto done;
	}

	/* the logic here is duplicated in $&whatis */

	name = getstr(list->term);
	fn = varlookup2("fn-", name.uget(), binding.uget());
	if (fn != NULL) {
		funcname = name;
		list = append(fn, list->next);
		goto restart;
	}
	if (isabsolute(name.uget())) {
		const char *error = checkexecutable(name.uget());
		if (error)
			fail("$&whatis", "%s: %s", name.uget(), error);
		list = forkexec(name.uget(), list.release(), flags & eval_inchild);
		goto done;
	}

	fn = pathsearch(list->term);
	if (fn != NULL && fn->next == NULL
	    && (cp = getclosure(fn->term)) == NULL) {
		const char *name = getstr(fn->term);
		list = forkexec(name, list.release(), flags & eval_inchild);
		goto done;
	}

	list = append(fn, list->next);
	goto restart;

done:
	if ((flags & eval_exitonfalse) && !istrue(list.uget()))
		exit(exitstatus(list.uget()));
	return list.release();
}

