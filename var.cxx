/* var.c -- es variables ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"
#include "var.hxx"
#include "term.hxx"

#if PROTECT_ENV
#define	ENV_FORMAT	"%F=%W"
#define	ENV_DECODE	"%N"
#else
#define	ENV_FORMAT	"%s=%W"
#define	ENV_DECODE	"%s"
#endif


Dict *vars;
static Dict *noexport;
static Vector *env, *sortenv;
static int envmin;
static bool isdirty = true;
static bool rebound = true;

DefineTag(Var, static);

static bool specialvar(const char *name) {
	return (*name == '*' || *name == '0') && name[1] == '\0';
}

static bool hasbindings(List *list) {
	for (; list != NULL; list = list->next)
		if (isclosure(list->term)) {
			Closure *closure = getclosure(list->term);
			assert(closure != NULL);
			if (closure->binding != NULL)
				return true;
		}
	return false;
}

static Var *mkvar(List *defn) {
	Ref(Var *, var, NULL);
	Ref(List *, lp, defn);
	var = gcnew(Var);
	var->env = NULL;
	var->defn = lp;
	var->flags = hasbindings(lp) ? var_hasbindings : 0;
	RefEnd(lp);
	RefReturn(var);
}

static void *VarCopy(void *op) {
	void *np = gcnew(Var);
	memcpy(np, op, sizeof (Var));
	return np;
}

static size_t VarScan(void *p) {
	Var *var = reinterpret_cast<Var*>(p);
	var->defn = reinterpret_cast<List*>(forward(var->defn));
	var->env = reinterpret_cast<char*>(((var->flags & var_hasbindings) && rebound) ? NULL : forward(var->env));
	return sizeof (Var);
}

/* iscounting -- is it a counter number, i.e., an integer > 0 */
static bool iscounting(const char *name) {
	int c;
	const char *s = name;
	while ((c = *s++) != '\0')
		if (!isdigit(c))
			return false;
	if (streq(name, "0"))
		return false;
	return name[0] != '\0';
}


/*
 * public entry points
 */

/* validatevar -- ensure that a variable name is valid */
extern void validatevar(const char *var) {
	if (*var == '\0')
		fail("es:var", "zero-length variable name");
	if (iscounting(var))
		fail("es:var", "illegal variable name: %S", var);
#if !PROTECT_ENV
	if (strchr(var, '=') != NULL)
		fail("es:var", "'=' in variable name: %S", var);
#endif
}

/* isexported -- is a variable exported? */
static bool isexported(const char *name) {
	if (specialvar(name))
		return false;
	if (noexport == NULL)
		return true;
	return dictget(noexport, name) == NULL;
}

/* setnoexport -- mark a list of variable names not for export */
extern void setnoexport(List *list) {
	isdirty = true;
	if (list == NULL) {
		noexport = NULL;
		return;
	}
	gcdisable();
	for (noexport = mkdict(); list != NULL; list = list->next)
		noexport = dictput(noexport, getstr(list->term), (void *) setnoexport);
	gcenable();
}

/* varlookup -- lookup a variable in the current context */
extern List *varlookup(const char *name, Binding *bp) {
	Var *var;

	if (iscounting(name)) {
		Term *term = nth(varlookup("*", bp), strtol(name, NULL, 10));
		if (term == NULL)
			return NULL;
		return mklist(term, NULL);
	}

	validatevar(name);
	for (; bp != NULL; bp = bp->next)
		if (streq(name, bp->name))
			return bp->defn;

	var = reinterpret_cast<Var*>(dictget(vars, name));
	if (var == NULL)
		return NULL;
	return var->defn;
}

extern List *varlookup2(const char *name1, const char *name2, Binding *bp) {
	Var *var;
	
	for (; bp != NULL; bp = bp->next)
		if (streq2(bp->name, name1, name2))
			return bp->defn;

	var = reinterpret_cast<Var*>(dictget2(vars, name1, name2));
	if (var == NULL)
		return NULL;
	return var->defn;
}

static List *callsettor(const char *name, List *defn) {
	Push p;
	List *settor;

	if (specialvar(name) || (settor = varlookup2("set-", name, NULL)) == NULL)
		return defn;

	Ref(List *, lp, defn);
	Ref(List *, fn, settor);
	varpush(&p, "0", mklist(mkstr(name), NULL));

	lp = listcopy(eval(append(fn, lp), NULL, 0));

	varpop(&p);
	RefEnd(fn);
	RefReturn(lp);
}

extern void vardef(const char *name, Binding *binding, List *defn) {
	Var *var;

	validatevar(name);
	for (; binding != NULL; binding = binding->next)
		if (streq(name, binding->name)) {
			binding->defn = defn;
			rebound = true;
			return;
		}

	RefAdd(name);
	defn = callsettor(name, defn);
	if (isexported(name))
		isdirty = true;

	var = reinterpret_cast<Var*>(dictget(vars, name));
	if (var != NULL)
		if (defn != NULL) {
			var->defn = defn;
			var->env = NULL;
			var->flags = hasbindings(defn) ? var_hasbindings : 0;
		} else
			vars = dictput(vars, name, NULL);
	else if (defn != NULL) {
		var = mkvar(defn);
		vars = dictput(vars, name, var);
	}
	RefRemove(name);
}

extern void varpush(Push *push, const char *name, List *defn) {
	Var *var;

	validatevar(name);
	push->name = name;
	push->nameroot.next = rootlist;
	push->nameroot.p = (void **) &push->name;
	rootlist = &push->nameroot;

	if (isexported(name))
		isdirty = true;
	defn = callsettor(name, defn);

	var = reinterpret_cast<Var*>(dictget(vars, push->name));
	if (var == NULL) {
		push->defn	= NULL;
		push->flags	= 0;
		var		= mkvar(defn);
		vars		= dictput(vars, push->name, var);
	} else {
		push->defn	= var->defn;
		push->flags	= var->flags;
		var->defn	= defn;
		var->env	= NULL;
		var->flags	= hasbindings(defn) ? var_hasbindings : 0;
	}

	push->next = pushlist;
	pushlist = push;

	push->defnroot.next = rootlist;
	push->defnroot.p = (void **) &push->defn;
	rootlist = &push->defnroot;
}

extern void varpop(Push *push) {
	Var *var;
	
	assert(pushlist == push);
	assert(rootlist == &push->defnroot);
	assert(rootlist->next == &push->nameroot);

	if (isexported(push->name))
		isdirty = true;
	push->defn = callsettor(push->name, push->defn);
	var = reinterpret_cast<Var*>(dictget(vars, push->name));

	if (var != NULL)
		if (push->defn != NULL) {
			var->defn = push->defn;
			var->flags = push->flags;
			var->env = NULL;
		} else
			vars = dictput(vars, push->name, NULL);
	else if (push->defn != NULL) {
		var = mkvar(NULL);
		var->defn = push->defn;
		var->flags = push->flags;
		vars = dictput(vars, push->name, var);
	}

	pushlist = pushlist->next;
	rootlist = rootlist->next->next;
}

static void mkenv0(void *dummy, const char *key, void *value) {
	Var *var = reinterpret_cast<Var*>(value);
	assert(gcisblocked());
	if (
		   var == NULL
		|| var->defn == NULL
		|| (var->flags & var_isinternal)
		|| !isexported(key)
	)
		return;
	if (var->env == NULL || (rebound && (var->flags & var_hasbindings))) {
		char *envstr = str(ENV_FORMAT, key, var->defn);
		var->env = envstr;
	}
	assert(env->count < env->alloclen);
	env->vector[env->count++] = var->env;
	if (env->count == env->alloclen) {
		Vector *newenv = mkvector(env->alloclen * 2);
		newenv->count = env->count;
		memcpy(newenv->vector, env->vector, env->count * sizeof *env->vector);
		env = newenv;
	}
}
	
extern Vector *mkenv(void) {
	if (isdirty || rebound) {
		env->count = envmin;
		gcdisable();		/* TODO: make this a good guess */
		dictforall(vars, mkenv0, NULL);
		gcenable();
		env->vector[env->count] = NULL;
		isdirty = false;
		rebound = false;
		if (sortenv == NULL || env->count > sortenv->alloclen)
			sortenv = mkvector(env->count * 2);
		sortenv->count = env->count;
		memcpy(sortenv->vector, env->vector, sizeof (char *) * (env->count + 1));
		sortvector(sortenv);
	}
	return sortenv;
}

/* addtolist -- dictforall procedure to create a list */
extern void addtolist(void *arg, const char *key, void *value) {
	List **listp = reinterpret_cast<List**>(arg);
	Term *term = mkstr(key);
	*listp = mklist(term, *listp);
}

static void listexternal(void *arg, const char *key, void *value) {
	if ((((Var *) value)->flags & var_isinternal) == 0 && !specialvar(key))
		addtolist(arg, key, value);
}

static void listinternal(void *arg, const char *key, void *value) {
	if (((Var *) value)->flags & var_isinternal)
		addtolist(arg, key, value);
}

/* listvars -- return a list of all the (dynamic) variables */
extern List *listvars(bool internal) {
	Ref(List *, varlist, NULL);
	dictforall(vars, internal ? listinternal : listexternal, &varlist);
	varlist = sortlist(varlist);
	RefReturn(varlist);
}

/* hide -- worker function for dictforall to hide initial state */
static void hide(void *dummy, const char *key, void *value) {
	((Var *) value)->flags |= var_isinternal;
}

/* hidevariables -- mark all variables as internal */
extern void hidevariables(void) {
	dictforall(vars, hide, NULL);
}

/* initvars -- initialize the variable machinery */
extern void initvars(void) {
	globalroot(&vars);
	globalroot(&noexport);
	globalroot(&env);
	globalroot(&sortenv);
	vars = mkdict();
	noexport = NULL;
	env = mkvector(10);
#if ABUSED_GETENV
# if READLINE
	initgetenv();
# endif
#endif
}

/* importvar -- import a single environment variable */
static void importvar(char *name0, char *value) {
	char sep[2] = { ENV_SEPARATOR, '\0' };

	Ref(char *, name, name0);
	Ref(List *, defn, NULL);
	defn = fsplit(sep, mklist(mkstr(value + 1), NULL), false);

	if (strchr(value, ENV_ESCAPE) != NULL) {
		List *list;
		gcdisable();
		for (list = defn; list != NULL; list = list->next) {
			int offset = 0;
			const char *word = list->term->str;
			const char *escape;
			while ((escape = strchr(word + offset, ENV_ESCAPE))
			       != NULL) {
				offset = escape - word + 1;
				switch (escape[1]) {
				    case '\0':
					if (list->next != NULL) {
						const char *str2
						  = list->next->term->str;
						char *str =
						  reinterpret_cast<char*>(
						  gcalloc(offset
							    + strlen(str2) + 1,
							  &StringTag));
						memcpy(str, word, offset - 1);
						str[offset - 1]
						  = ENV_SEPARATOR;
						strcpy(str + offset, str2);
						list->term->str = str;
						list->next = list->next->next;
					}
					break;
				    case ENV_ESCAPE: {
				    	char *str = reinterpret_cast<char*>(
						gcalloc(strlen(word),
							&StringTag));
					memcpy(str, word, offset);
					strcpy(str + offset, escape + 2);
					list->term->str = str;
					offset += 1;
					break;
				    }
				}
			}
		}
		gcenable();
	}
	vardef(name, NULL, defn);
	RefEnd2(defn, name);
}


/* initenv -- load variables from the environment */
extern void initenv(char **envp, bool isprotected) {
	char *envstr;
	size_t bufsize = 1024;
	char *buf = reinterpret_cast<char*>(ealloc(bufsize));

	for (; (envstr = *envp) != NULL; envp++) {
		size_t nlen;
		char *eq = strchr(envstr, '=');
		char *name;
		if (eq == NULL) {
			env->vector[env->count++] = envstr;
			if (env->count == env->alloclen) {
				Vector *newenv = mkvector(env->alloclen * 2);
				newenv->count = env->count;
				memcpy(newenv->vector, env->vector,
				       env->count * sizeof *env->vector);
				env = newenv;
			}
			continue;
		}
		for (nlen = eq - envstr; nlen >= bufsize; bufsize *= 2)
			buf = reinterpret_cast<char*>(erealloc(buf, bufsize));
		memcpy(buf, envstr, nlen);
		buf[nlen] = '\0';
		name = str(ENV_DECODE, buf);
		if (!isprotected
		    || (!hasprefix(name, "fn-") && !hasprefix(name, "set-")))
			importvar(name, eq);
	}

	envmin = env->count;
	efree(buf);
}
