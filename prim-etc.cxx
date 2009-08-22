/* prim-etc.c -- miscellaneous primitives ($Revision: 1.2 $) */

#include <pwd.h>

#include "es.hxx"
#include "prim.hxx"

PRIM(result) {
	return list;
}

PRIM(echo) {
	const char *eol = "\n";
	if (list != NULL) {
		if (termeq(list->term, "-n")) {
			eol = "";
			list = list->next;
		} else if (termeq(list->term, "--"))
			list = list->next;
        }
	print("%L%s", list.release(), " ", eol);
	return ltrue;
}

PRIM(count) {
	return mklist(mkstr(str("%d", length(list))), NULL);
}

PRIM(setnoexport) {
	setnoexport(list.uget());
	return list;
}

PRIM(version) {
	return mklist(mkstr((char *) version), NULL);
}

PRIM(exec) {
	return eval(list, NULL, evalflags | eval_inchild);
}

PRIM(dot) {
	int c, fd;
	volatile int runflags = (evalflags & eval_inchild);
	const char * const usage = ". [-einvx] file [arg ...]";

	esoptbegin(list.uget(), "$&dot", usage);
	while ((c = esopt("einvx")) != EOF)
		switch (c) {
		case 'e':	runflags |= eval_exitonfalse;	break;
		case 'i':	runflags |= run_interactive;	break;
		case 'n':	runflags |= run_noexec;		break;
		case 'v':	runflags |= run_echoinput;	break;
		case 'x':	runflags |= run_printcmds;	break;
		}

	Ref<List> result;
	Ref<List> lp = esoptend();
	if (lp == NULL)
		fail("$&dot", "usage: %s", usage);

	Ref<const char> file = getstr(lp->term);
	lp = lp->next;
	fd = eopen(file.uget(), oOpen);
	if (fd == -1)
		fail("$&dot", "%s: %s", file.uget(), esstrerror(errno));

	Push star("0", mklist(mkstr(file), NULL));
	Push zero("*", lp.uget());

	result = runfd(fd, file.uget(), runflags);

	return result;
}

PRIM(flatten) {
	if (list == NULL)
		fail("$&flatten", "usage: %%flatten separator [args ...]");
	const char *sep = getstr(list->term);
	list = mklist(mkstr(str("%L", list->next, sep)), NULL);
	return list;
}

PRIM(whatis) {
	/* the logic in here is duplicated in eval() */
	if (list == NULL || list->next != NULL)
		fail("$&whatis", "usage: $&whatis program");
	Ref<Term> term = list->term;
	if (getclosure(term) == NULL) {
		List *fn;
		Ref<const char> prog = getstr(term);
		assert(prog != NULL);
		fn = varlookup2("fn-", prog.uget(), binding.uget());
		if (fn != NULL)
			list = fn;
		else {
			if (isabsolute(prog.uget())) {
				const char *error = checkexecutable(prog.uget());
				if (error != NULL)
					fail("$&whatis", "%s: %s", prog.uget(), error);
			} else
				list = pathsearch(term.uget());
		}
	}
	return list;
}

PRIM(split) {
	if (list == NULL)
		fail("$&split", "usage: %%split separator [args ...]");
	Ref<List> lp = list;
	const char *sep = getstr(lp->term);
	lp = fsplit(sep, lp->next, true);
	return lp;
}

PRIM(fsplit) {
	if (list == NULL)
		fail("$&fsplit", "usage: %%fsplit separator [args ...]");
	Ref<List> lp = list;
	const char *sep = getstr(lp->term);
	lp = fsplit(sep, lp->next, false);
	return lp;
}

PRIM(var) {
	if (list == NULL)
		return NULL;
	Ref<List> rest = list->next;
	Ref<const char> name = getstr(list->term);
	Ref<List> defn = varlookup(name, NULL);
	rest = prim_var(rest, NULL, evalflags);
	Ref<Term> term = mkstr(str("%S = %#L", name.uget(), defn.uget(), " "));
	list = mklist(term, rest);
	return list;
}

PRIM(sethistory) {
	if (list == NULL) {
		sethistory(NULL);
		return NULL;
	}
	sethistory(getstr(list->term));
	return list;
}

PRIM(parse) {
	List *result;
	Tree *tree;
	Ref<const char> prompt1 = NULL;
	Ref<const char> prompt2 = NULL;
	if (list != NULL) {
		prompt1 = getstr(list->term);
		if ((list = list->next) != NULL)
			prompt2 = getstr(list->term);
	}
	tree = parse(prompt1.release(), prompt2.release());
	result = (tree == NULL)
		   ? NULL
		   : mklist(mkterm(NULL, mkclosure(mk(nThunk, tree), NULL)),
			    NULL);
	return result;
}

PRIM(exitonfalse) {
	return eval(list, NULL, evalflags | eval_exitonfalse);
}

PRIM(batchloop) {
	Ref<List> result = ltrue;
	Ref<List> dispatch;

	SIGCHK();

	try {
		for (;;) {
			List *parser, *cmd;
			parser = varlookup("fn-%parse", NULL);
			cmd = (parser == NULL)
					? prim("parse", NULL, NULL, 0).release()
					: eval(parser, NULL, 0);
			SIGCHK();
			dispatch = varlookup("fn-%dispatch", NULL);
			if (cmd != NULL) {
				if (dispatch != NULL)
					cmd = append(dispatch, cmd);
				result = eval(cmd, NULL, evalflags);
				SIGCHK();
			}
		}
	} catch (List *e) {

		if (!termeq(e->term, "eof"))
			throwE(e);
		return result;

	}
	NOTREACHED;
	return NULL; /* Quiet warnings */
}

PRIM(collect) {
	gc();
	return ltrue;
}

PRIM(home) {
	struct passwd *pw;
	if (list == NULL)
		return varlookup("home", NULL);
	if (list->next != NULL)
		fail("$&home", "usage: %%home [user]");
	pw = getpwnam(getstr(list->term));
	return (pw == NULL) ? NULL : mklist(mkstr(gcdup(pw->pw_dir)), NULL);
}

PRIM(vars) {
	return listvars(false);
}

PRIM(internals) {
	return listvars(true);
}

PRIM(isinteractive) {
	return isinteractive() ? ltrue : lfalse;
}

PRIM(setmaxevaldepth) {
	char *s;
	long n;
	if (list == NULL) {
		maxevaldepth = MAXmaxevaldepth;
		return NULL;
	}
	if (list->next != NULL)
		fail("$&setmaxevaldepth", "usage: $&setmaxevaldepth [limit]");
	n = strtol(getstr(list->term), &s, 0);
	if (n < 0 || (s != NULL && *s != '\0'))
		fail("$&setmaxevaldepth", "max-eval-depth must be set to a positive integer");
	if (n < MINmaxevaldepth)
		n = (n == 0) ? MAXmaxevaldepth : MINmaxevaldepth;
	maxevaldepth = n;
	return list;
}

#if READLINE
PRIM(resetterminal) {
	resetterminal = true;
	return ltrue;
}
#include <readline/readline.h>
PRIM(promptignore) {
	static const char s[] = { RL_PROMPT_START_IGNORE, '\0' };
	return mklist(mkstr(s), NULL);
}
PRIM(nopromptignore) {
	static const char s[] = { RL_PROMPT_END_IGNORE, '\0' };
	return mklist(mkstr(s), NULL);
}
#endif


/*
 * initialization
 */

extern void initprims_etc(Prim_dict& primdict) {
	X(echo);
	X(count);
	X(version);
	X(exec);
	X(dot);
	X(flatten);
	X(whatis);
	X(sethistory);
	X(split);
	X(fsplit);
	X(var);
	X(parse);
	X(batchloop);
	X(collect);
	X(home);
	X(setnoexport);
	X(vars);
	X(internals);
	X(result);
	X(isinteractive);
	X(exitonfalse);
	X(setmaxevaldepth);
#if READLINE
	X(resetterminal);
	X(promptignore);
	X(nopromptignore);
#endif
}
