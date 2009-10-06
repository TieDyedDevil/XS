/* var.c -- es variables ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "var.hxx"
#include "term.hxx"
#include <vector>
#include <algorithm>
#include <set>
#include <string>
using std::string;
using std::set;
using std::vector;

#if PROTECT_ENV
#define	ENV_FORMAT	"%F=%W"
#define	ENV_DECODE	"%N"
#else
#define	ENV_FORMAT	"%s=%W"
#define	ENV_DECODE	"%s"
#endif

static set<string> noexport;
Dict vars;

static Vector env, sortenv;
static bool isdirty = true;
static bool rebound = true;

static bool specialvar(string name) {
	return (name[0] == '*' || name[0] == '0') && name[1] == '\0';
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
static bool isexported(string name) {
	if (specialvar(name))
		return false;
	if (noexport.empty())
		return true;
	return noexport.count(name) == 0;
}

/* setnoexport -- mark a list of variable names not for export */
extern void setnoexport(List *list) {
	isdirty = true;
	noexport.clear();
	for (; list != NULL; list = list->next)
		noexport.insert(getstr(list->term));
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

	return vars.count(name) == 0
		? NULL
		: vars[name]->defn;
}

extern List *varlookup2(const char *name1, const char *name2, Binding *bp) {
	string name = string(name1) + name2;
        return varlookup(name.c_str(), bp);
}

static List *callsettor(const char* name, List* defn) {
	List* settor;

	if (specialvar(name) || (settor = varlookup2("set-", name, NULL)) == NULL)
		return defn;

	Dyvar p("0", mklist(mkstr(name), NULL));

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

	if (vars.count(name) != 0) {
		if (defn != NULL) {
			Var* var = vars[name];
			var->defn = defn;
			var->env = NULL;
			var->flags = hasbindings(defn) ? var_hasbindings : 0;
		} else vars.erase(name);
	} else if (defn != NULL) {
		vars[name] = mkvar(defn);
	}
}

extern Dyvar::Dyvar(const char *_name, List *vardefn) {
	validatevar(_name);
	name = _name;

	if (isexported(name))
		isdirty = true;
	defn = callsettor(name, vardefn);

	if (vars.count(name) == 0) {
		defn	= NULL;
		flags	= 0;
		vars[name] = mkvar(vardefn);
	} else {
		Var *var = vars[name];
                assert (var != NULL);
		defn		= var->defn;
		flags		= var->flags;
		var->defn	= vardefn;
		var->env	= NULL;
		var->flags	= hasbindings(vardefn) ? var_hasbindings : 0;
	}

}

extern Dyvar::~Dyvar() {
	if (isexported(name))
		isdirty = true;
	defn = callsettor(name, defn);

	if (vars.count(name) != 0)
		if (defn != NULL) {
			Var *var = vars[name];
                        assert (var != NULL);
			var->defn = defn;
			var->flags = flags;
			var->env = NULL;
		} else vars.erase(name);
	else if (defn != NULL) {
		Var *var = mkvar(NULL);
		var->defn = defn;
		var->flags = flags;
		vars[name] = var;
	}

}

static void mkenv0(Dict::value_type pair) {
	Var *var = pair.second;
	if (
		   var == NULL
		|| var->defn == NULL
		|| (var->flags & var_isinternal)
		|| !isexported(pair.first)
	)
		return;
	if (var->env == NULL || (rebound && (var->flags & var_hasbindings))) {
		char *envstr = str(ENV_FORMAT, pair.first.c_str(), var->defn);
		var->env = envstr;
	}
	env.push_back(var->env);
}


extern Vector* mkenv(void) {
	if (isdirty || rebound) {
		std::for_each(vars.begin(), vars.end(), mkenv0);
		
		isdirty = false;
		rebound = false;
		sortenv = env;
		std::sort(sortenv.begin(), sortenv.end(), qstrcmp);
	}
	return &sortenv;
}

/* listvars -- return a list of all the (dynamic) variables */
extern List *listvars(bool internal) {
	List* varlist = NULL;
	if (internal) {
		foreach (Dict::value_type x, vars)
			if (x.second->flags & var_isinternal)
				varlist = mklist(mkstr(x.first.c_str()), varlist);
	} else { // external only
		foreach (Dict::value_type x, vars)
			if (x.second->flags & var_isinternal == 0 && !specialvar(x.first))
				varlist = mklist(mkstr(x.first.c_str()), varlist);
	}
	
	return (varlist = sortlist(varlist));
}

/* hide -- worker function for dictforall to hide initial state */
static void hide(void *dummy, const char *key, void *value) {
	reinterpret_cast<Var *>(value)->flags |= var_isinternal;
}

/* hidevariables -- mark all variables as internal */
extern void hidevariables(void) {
	foreach (Dict::value_type x, vars) x.second->flags |= var_isinternal;
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
						  galloc(offset
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
						galloc(strlen(word)));
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
