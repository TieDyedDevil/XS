/* var.c -- es variables ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "var.hxx"
#include "term.hxx"
#include <vector>
#include <algorithm>
using std::vector;

#if PROTECT_ENV
#define	ENV_FORMAT	"%F=%W"
#define	ENV_DECODE	"%N"
#else
#define	ENV_FORMAT	"%s=%W"
#define	ENV_DECODE	"%s"
#endif


Dict *vars;
static Dict *noexport;
static Vector env, sortenv;
static bool isdirty = true;
static bool rebound = true;

static bool specialvar(const char *name) {
	return (*name == '*' || *name == '0') && name[1] == '\0';
}

static bool hasbindings(List* list) {
	for (; list != NULL; list = list->next)
		if (isclosure(list->term)) {
			Closure* closure = getclosure(list->term);
			assert(closure != NULL);
			if (closure->binding != NULL)
				return true;
		}
	return false;
}

static Var *mkvar(List* defn) {
	Var* var = gcnew(Var);
	var->env = NULL;
	var->flags = hasbindings(defn) ? var_hasbindings : 0;
	var->defn = defn;
	return var;
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
		fail("es:var", "illegal variable name (is a number): %S", var);
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
	
	for (noexport = mkdict(); list != NULL; list = list->next)
		noexport = dictput(noexport, getstr(list->term), (void *) setnoexport);
	
}

/* varlookup -- lookup a variable in the current context */
extern List *varlookup(const char* name, Binding* bp) {
	if (iscounting(name)) {
		Term* term = nth(varlookup("*", bp), strtol(name, NULL, 10));
		if (term == NULL)
			return NULL;
		return mklist(term, NULL);
	}

	validatevar(name);
	for (; bp != NULL; bp = bp->next)
		if (streq(name, bp->name))
			return bp->defn;

	Var *var = reinterpret_cast<Var*>(dictget(vars, name));
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

static List *callsettor(const char* name, List* defn) {
	List* settor;

	if (specialvar(name) || (settor = varlookup2("set-", name, NULL)) == NULL)
		return defn;

	Push p("0", mklist(mkstr(name), NULL));

	defn = listcopy(eval(append(settor, defn), NULL, 0));

	return defn;
}

extern void vardef(const char* name, Binding* binding, List* defn) {
	validatevar(name);
	for (; binding != NULL; binding = binding->next)
		if (streq(name, binding->name)) {
			binding->defn = defn;
			rebound = true;
			return;
		}

	defn = callsettor(name, defn);
	if (isexported(name))
		isdirty = true;

	Var* var = reinterpret_cast<Var*>(dictget(vars, name));
	if (var != NULL) {
		if (defn != NULL) {
			var->defn = defn;
			var->env = NULL;
			var->flags = hasbindings(defn) ? var_hasbindings : 0;
		} else
			vars = dictput(vars, name, NULL);
	} else if (defn != NULL) {
		var = mkvar(defn);
		vars = dictput(vars, name, var);
	}
}

extern void varpush(Push *push, const char *name, List *defn) {
	validatevar(name);
	push->name = name;

	if (isexported(name))
		isdirty = true;
	defn = callsettor(name, defn);

	Var *var = reinterpret_cast<Var*>(dictget(vars, push->name));
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

}

extern void varpop(Push *push) {
	Var *var;

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

}

static void mkenv0(void *dummy, const char *key, void *value) {
	Var *var = reinterpret_cast<Var*>(value);
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
	env.push_back(var->env);
}


extern Vector* mkenv(void) {
	if (isdirty || rebound) {
		dictforall(vars, mkenv0, NULL);
		
		isdirty = false;
		rebound = false;
		sortenv = env;
		std::sort(sortenv.begin(), sortenv.end(), qstrcmp);
	}
	return &sortenv;
}

/* addtolist -- dictforall procedure to create a list */
extern void addtolist(void *arg, const char *key, void *value) {
	List **listp = reinterpret_cast<List**>(arg);
	Term* term = mkstr(key);
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
	List* varlist;
	dictforall(vars, internal ? listinternal : listexternal, &varlist);
	return (varlist = sortlist(varlist));
}

/* hide -- worker function for dictforall to hide initial state */
static void hide(void *dummy, const char *key, void *value) {
	reinterpret_cast<Var *>(value)->flags |= var_isinternal;
}

/* hidevariables -- mark all variables as internal */
extern void hidevariables(void) {
	dictforall(vars, hide, NULL);
}

/* initvars -- initialize the variable machinery */
extern void initvars(void) {
	vars = mkdict();
	noexport = NULL;
}

/* importvar -- import a single environment variable */
static void importvar(char* name, char* value) {
	char sep[2] = { ENV_SEPARATOR, '\0' };

	List* defn;
	defn = fsplit(sep, mklist(mkstr(value + 1), NULL), false);

	if (strchr(value, ENV_ESCAPE) != NULL) {
		List* list;
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
						  GC_MALLOC(offset
							    + strlen(str2) + 1));
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
						GC_MALLOC(strlen(word)));
					memcpy(str, word, offset);
					strcpy(str + offset, escape + 2);
					list->term->str = str;
					offset += 1;
					break;
				    }
				}
			}
		}
	}
	vardef(name, NULL, defn);
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
			env.push_back(envstr);
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

	efree(buf);
}
