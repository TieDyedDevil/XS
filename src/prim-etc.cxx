/* prim-etc.cxx -- miscellaneous primitives */

#include <pwd.h>

#include "xs.hxx"
#include "prim.hxx"

#include <ffi.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

#include <readline/readline.h>

static int isnumber(const char *s) {
	return strspn(s, "-0123456789.") == strlen(s);
}

static int isfloat(const char *s) {
	return strchr(s, '.') != NULL;
}

static void nextconv(char **s) {
	char *pct = strchr(*s, '%');
	if (pct) {
		const int fw = strspn(++pct, "'-+ #.0123456789");
		*s = pct + fw;
	}
	else *s = NULL;
}

static int validconv(char c) {
	return strchr("%aAcdeEfFgGiosuxX", c) != NULL;
}

static int textconv(char c) {
	return strchr("cs", c) != NULL;
}

static int charconv(char c) {
	return c == 'c';
}

static int stringconv(char c) {
	return c == 's';
}

static int floatconv(char c) {
	return strchr("aAeEfFgG", c) != NULL;
}

static int integralconv(char c) {
	return strchr("diouxX", c) != NULL;
}

PRIM(printf) {
	(void)binding;
	(void)evalflags;
	if (list != NULL) {
		const int printf_max_varargs = 20;
		ffi_cif cif;
		ffi_type *args[printf_max_varargs];
		void *values[printf_max_varargs];
		long longs[printf_max_varargs];
		double doubles[printf_max_varargs];
		char chars[printf_max_varargs];
		const char* strings[printf_max_varargs];
		ffi_arg rc;
		const char *fmt = getstr(list->term);
		list = list->next;
		char out[1024];
		char *p_out = out;
		size_t outsz = sizeof(out);
		size_t *p_outsz = &outsz;
		args[0] = &ffi_type_pointer;
		values[0] = &p_out;
		args[1] = &ffi_type_ulong;
		values[1] = &p_outsz;
		args[2] = &ffi_type_pointer;
		values[2] = &fmt;
		int i = 3;
		char *fcp = (char*)fmt;
		while (list) {
		advance:
			nextconv(&fcp);
			if (!fcp)
				fail("$&printf",
				     "printf: more args than fmts");
			if (*fcp == '%') {
				/* no arg consumed; pass %; advance format */
				++fcp;
				goto advance;
			}
			if (!validconv(*fcp))
				fail("$&printf",
                                     "printf: invalid format specifier: %c",
                                     *fcp);
			const char *arg = getstr(list->term);
			if (!textconv(*fcp) && isnumber(arg)) {
				if (floatconv(*fcp) || isfloat(arg)) {
					if (integralconv(*fcp))
						fail("$&printf",
                                                     "printf: %%%c: integral"
						     " value required",
                                                     *fcp);
					args[i] = &ffi_type_double;
					doubles[i] = strtod(arg, NULL);
					values[i] = &doubles[i];
				} else {
					args[i] = &ffi_type_slong;
					longs[i] = strtol(arg, NULL, 10);
					values[i] = &longs[i];
				}
			} else if (charconv(*fcp)) {
				if (arg[1] != '\0')
					fail("$&printf",
                                             "printf: %%c: character"
					     " value required");
				args[i] = &ffi_type_schar;
				chars[i] = *arg;
				values[i] = &chars[i];
			} else {
				if (!stringconv(*fcp))
					fail("$&printf",
                                             "printf: %%%c: numeric"
					     " value required",
                                             *fcp);
				args[i] = &ffi_type_pointer;
				strings[i] = gcdup(arg);
				values[i] = &strings[i];
			}
			list = list->next;
			++i;
			if (i == printf_max_varargs)
				fail("$&printf", "printf: too many args");
		}
		do {
			nextconv(&fcp);
			if (fcp) {
				if (*fcp == '%') ++fcp;
				else fail("$&printf",
					  "printf: more fmts than args");
			}
		} while (fcp);
		if (ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, 3, i,
                                     &ffi_type_sint, args) == FFI_OK) {
			ffi_call(&cif, FFI_FN(snprintf), &rc, values);
			if ((unsigned long)rc >= outsz)
                                fail("$&printf", "printf: output too long");
			print("%s", out);
		}
	} else fail("$&printf", "printf: format missing");
	return ltrue;
}

PRIM(result) {
	(void)binding;
	(void)evalflags;
	return list;
}

PRIM(echo) {
	(void)binding;
	(void)evalflags;
	const char *eol = "\n";
	if (list != NULL) {
		if (termeq(list->term, "-n")) {
			eol = "";
			list = list->next;
		} else if (termeq(list->term, "--"))
			list = list->next;
        }
	print("%L%s", list, " ", eol);
	return ltrue;
}

PRIM(count) {
	(void)binding;
	(void)evalflags;
	return mklist(mkstr(str("%d", length(list))), NULL);
}

PRIM(setnoexport) {
	(void)binding;
	(void)evalflags;
	setnoexport(list);
	return list;
}

PRIM(version) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return mklist(mkstr((char *) version), NULL);
}

PRIM(exec) {
	(void)binding;
	return eval(list, NULL, evalflags | eval_inchild);
}

PRIM(dot) {
	(void)binding;
	int c, fd;
	volatile int runflags = (evalflags & eval_inchild);
	const char * const usage = ". [-einvx] file [arg ...]";

	esoptbegin(list, "$&dot", usage);
	while ((c = esopt("einvx")) != EOF)
		switch (c) {
		case 'e':	runflags |= eval_exitonfalse;	break;
		case 'i':	runflags |= run_interactive;	break;
		case 'n':	runflags |= run_noexec;		break;
		case 'v':	runflags |= run_echoinput;	break;
		case 'x':	runflags |= run_printcmds;	break;
		}

	List* lp = esoptend();
	if (lp == NULL)
		fail("$&dot", "usage: %s", usage);

	const char* file = getstr(lp->term);
	lp = lp->next;
	fd = eopen(file, oOpen);
	if (fd == -1)
		fail("$&dot", "%s: %s", file, esstrerror(errno));

	Dyvar zero("0", mklist(mkstr(file), NULL));
	Dyvar star("*", lp);

	return runfd(fd, file, runflags);
}

PRIM(flatten) {
	(void)binding;
	(void)evalflags;
	if (list == NULL)
		fail("$&flatten", "usage: %%flatten separator [args ...]");
	const char *sep = getstr(list->term);
	list = mklist(mkstr(str("%L", list->next, sep)), NULL);
	return list;
}

PRIM(whats) {
	(void)evalflags;
	/* the logic in here is duplicated in eval() */
	if (list == NULL || list->next != NULL)
		fail("$&whats", "usage: $&whats program");
	Term* term = list->term;
	if (getclosure(term) == NULL) {
		const char* prog = getstr(term);
		assert(prog != NULL);
		List *fn = varlookup2("fn-", prog, binding);
		if (fn != NULL) return fn;
		else if (isabsolute(prog)) {
				const char *error = checkexecutable(prog);
				if (error != NULL)
					fail("$&whats", "%s: %s", prog, error);
		}
		else return pathsearch(term);
	}
	return list;
}

PRIM(split) {
	(void)binding;
	(void)evalflags;
	if (list == NULL)
		fail("$&split", "usage: %%split separator [args ...]");
	List* lp = list;
	const char *sep = getstr(lp->term);
	lp = fsplit(sep, lp->next, true);
	return lp;
}

PRIM(fsplit) {
	(void)binding;
	(void)evalflags;
	if (list == NULL)
		fail("$&fsplit", "usage: %%fsplit separator [args ...]");
	List* lp = list;
	const char *sep = getstr(lp->term);
	lp = fsplit(sep, lp->next, false);
	return lp;
}

PRIM(var) {
	(void)binding;
	if (list == NULL)
		return NULL;
	const char* name = getstr(list->term);
	List* defn = varlookup(name, NULL);
	const List *rest = prim_var(list->next, NULL, evalflags);
	Term* term = mkstr(str("%S = %#L", name, defn, " "));
	return mklist(term, const_cast<List*>(rest));
}

PRIM(sethistory) {
	(void)binding;
	(void)evalflags;
	if (list == NULL) {
		sethistory(NULL);
		return NULL;
	}
	sethistory(getstr(list->term));
	return list;
}

/* mark zero-width character sequences for readline() */
const char *mzwcs(const char *prompt) {
	if (!prompt) return prompt;

	int esc = 0, csi = 0, osc = 0, stt = 0, ste = 0, mark = 0;
	char outbuf[1024];
	char *f = (char*)prompt, *t = (char*)&outbuf[0];
	while (*f) {
		if (t >= &outbuf[sizeof(outbuf)-3]) return prompt;
		if (*f == '\e') {
			esc = 1;
			if (!mark) *t++ = RL_PROMPT_START_IGNORE;
			mark = 1;
		}
		if (esc && *f == '[') {esc = 0; csi = 1;}
		if (esc && *f == ']') {esc = 0; osc = 1; stt = 1;}
		if (esc && strchr("PX^_", *f)) {esc = 0; stt = 1;}
		if (esc && isalpha(*f)) {
			*t++ = *f++;
			*t++ = RL_PROMPT_END_IGNORE;
			esc = 0;
			continue;
		}
		if (iscntrl(*f) && !strchr("\a\e\n\r\t", *f)) {
			if (!mark) *t++ = RL_PROMPT_START_IGNORE;
			mark = 1;
		}
		if (csi && isalpha(*f)) {
			*t++ = *f++; *t++ = RL_PROMPT_END_IGNORE;
			csi = 0; mark = 0;
			continue;
		}
		if (osc && *f == '\a') {
			*t++ = *f++; *t++ = RL_PROMPT_END_IGNORE;
			osc = 0; stt = 0; mark = 0;
			continue;
		}
		if (ste) {
			if (*f == '\\') {
				*t++ = *f++; *t++ = RL_PROMPT_END_IGNORE;
				stt = 0; mark = 0;
				continue;
			}
			ste = 0;
		}
		if (stt && *f == '\e') ste = 1;
		*t++ = *f++;
	}
	if (mark) *t++ = RL_PROMPT_END_IGNORE;
	*t = '\0';
	return (const char*)gcdup(outbuf);
}

PRIM(parse) {
	(void)binding;
	(void)evalflags;
	List *result;
	Tree *tree;
	const char* prompt1 = NULL;
	const char* prompt2 = NULL;
	if (list != NULL) {
		prompt1 = getstr(list->term);
		if ((list = list->next) != NULL)
			prompt2 = getstr(list->term);
	}
	tree = parse(mzwcs(prompt1), mzwcs(prompt2));
	result = (tree == NULL)
		   ? NULL
		   : mklist(mkterm(NULL, mkclosure(mk(nThunk, tree), NULL)),
			    NULL);
	return result;
}

PRIM(exitonfalse) {
	(void)binding;
	return eval(list, NULL, evalflags | eval_exitonfalse);
}

PRIM(batchloop) {
	(void)list;
	(void)binding;
	const List* result = ltrue;
	List* dispatch;

	SIGCHK();

	try {
		for (;;) {
			List *parser = varlookup("fn-%parse", NULL);
			const List *cmd = (parser == NULL)
					? prim("parse", NULL, NULL, 0)
					: eval(parser, NULL, 0);
			SIGCHK();
			dispatch = varlookup("fn-%dispatch", NULL);
			if (cmd != NULL) {
				if (dispatch != NULL)
					cmd = append
                                            (dispatch, const_cast<List*>(cmd));
				result = eval(cmd, NULL, evalflags);
				SIGCHK();
			}
		}
	} catch (List *e) {

		if (!termeq(e->term, "eof"))
			throw e;
		return result;

	}
	NOTREACHED;
	return NULL; /* Quiet warnings */
}

PRIM(collect) {
	(void)list;
	(void)binding;
	(void)evalflags;
	GC_gcollect();
	return ltrue;
}

PRIM(home) {
	(void)binding;
	(void)evalflags;
	struct passwd *pw;
	if (list == NULL)
		return varlookup("home", NULL);
	if (list->next != NULL)
		fail("$&home", "usage: %%home [user]");
	pw = getpwnam(getstr(list->term));
	return (pw == NULL) ? NULL : mklist(mkstr(gcdup(pw->pw_dir)), NULL);
}

PRIM(vars) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return listvars(false);
}

PRIM(internals) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return listvars(true);
}

PRIM(isinteractive) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return isinteractive() ? ltrue : lfalse;
}

PRIM(islogin) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return islogin() ? ltrue : lfalse;
}

PRIM(setmaxevaldepth) {
	(void)binding;
	(void)evalflags;
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
		fail("$&setmaxevaldepth",
                     "max-eval-depth must be set to a positive integer");
	if (n < MINmaxevaldepth)
		n = (n == 0) ? MAXmaxevaldepth : MINmaxevaldepth;
	maxevaldepth = n;
	return list;
}

PRIM(resetterminal) {
	(void)list;
	(void)binding;
	(void)evalflags;
	rl_reset_terminal(NULL);
	return ltrue;
}

static void initrandom() {
	srandom(time(NULL));
}

PRIM(random) {
	(void)list;
	(void)binding;
	(void)evalflags;
	return mklist(mkstr(str("%d", random())), NULL);
}

PRIM(len) {
	(void)binding;
	(void)evalflags;
	if (list == NULL)
		fail("$&len", "usage: %%len [args ...]");
	List *result = NULL;
	List *tail = NULL;
	while (list) {
		size_t n = mbstowcs(NULL, getstr(list->term), 0);
		if (n == (size_t)-1)
			fail("$&len", "len: invalid character");
		Term *elt = mkstr(str("%ld", n, 0));
		if (!result) {result = mklist(elt, NULL); tail = result;}
		else tail = tail->next = mklist(elt, NULL);
		list = list->next;
	}
	return result;
}

PRIM(wid) {
	(void)binding;
	(void)evalflags;
	if (list == NULL)
		fail("$&wid", "usage: %%wid [args ...]");
	List *result = NULL;
	List *tail = NULL;
	while (list) {
		const size_t limwid = 512;
		wchar_t d[limwid];
		size_t n = mbstowcs(d, getstr(list->term), limwid);
		if (n == (size_t)-1)
			fail("$&wid", "wid: invalid character");
		if (n == limwid)
			fail("$&wid", "wid: word is too wide");
		Term *elt = mkstr(str("%d", wcswidth(d, limwid)));
		if (!result) {result = mklist(elt, NULL); tail = result;}
		else tail = tail->next = mklist(elt, NULL);
		list = list->next;
	}
	return result;
}


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
	X(whats);
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
	X(islogin);
	X(exitonfalse);
	X(setmaxevaldepth);
	initrandom();
	X(random);
	X(len);
	X(wid);
	X(resetterminal);
	X(printf);
}
