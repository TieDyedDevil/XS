/* dump.c -- dump es's internal state as a c program ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "var.hxx"
#include "term.hxx"
#include "print.hxx"
#include <sstream>
#include <map>
#include <set>
#include <string>
using std::map;
using std::set;
using std::string;

#define	MAXVARNAME 20

/*
 * the $&dumpstate prints the appropriate C data structures for
 * representing the parts of es's memory that can be stored in
 * the text (read-only) segment of the program.  (some liberties
 * are taken with regard to what the initial.es routines can do
 * regarding changing lexically bound values in order that more
 * things can be here.)
 *
 * since these things are read-only they cannot point to structures
 * that need to be garbage collected.  (think of this like a very
 * old generation in a generational collector.)
 *
 * to simplify matters, all values are stored in C variables with
 * idiosyncratic names:
 *	S_string	"string"
 *	X_address	string at address, when name wouldn't fit
 *	L_address	List at address
 *	E_address	Term at address
 *	T_address	Tree at address
 *	B_address	Binding at address
 *	C_address	Closure at address
 *
 * in order that addresses are internally consistent, garbage collection
 * is disabled during the dumping process.
 */

static set<string> cvars; 
static map<string, string> strings;

static bool allprintable(const char *s) {
	int c;
	for (; (c = *(unsigned const char *) s) != '\0'; s++)
		if (!isprint(c) || c == '"' || c == '\\')
			return false;
	return true;
}

static const char *dumpstring(const char *string) {
	if (string == NULL)
		return "NULL";
	if (strings.count(string) == 0) {
		const char *name = str("S_%F", string);
		if (strlen(name) > MAXVARNAME)
			name = str("X_%ulx", (long long) string);
		print("static const char %s[] = ", name);
		if (allprintable(string))
			print("\"%s\";\n", string);
		else {
			int c;
			print("{ ");
			for (const char *s = string; (c = *(unsigned const char *) s) != '\0'; s++) {
				switch (c) {
				case '\a':	print("'\\a'");		break;
				case '\b':	print("'\\b'");		break;
				case '\f':	print("'\\f'");		break;
				case '\n':	print("'\\n'");		break;
				case '\r':	print("'\\r'");		break;
				case '\t':	print("'\\t'");		break;
				case '\'':	print("'\\''");		break;
				case '\\':	print("'\\\\'");	break;
				default:	print(isprint(c) ? "'%c'" :"%d", c); break;
				}
				print(", ");
			}
			print("'\\0', };\n");
		}
		strings[string] = name;
		return name;
	} else return strings[string].c_str();
}

static const char *dumplist(List *list);

static const char *nodename(NodeKind k) {
	switch(k) {

	case nAssign:	return "Assign";
	case nCall:	return "Call";
	case nClosure:	return "Closure";
	case nConcat:	return "Concat";
	case nFor:	return "For";
	case nLambda:	return "Lambda";
	case nLet:	return "Let";
	case nList:	return "List";
	case nLocal:	return "Local";
	case nMatch:	return "Match";
	case nExtract:	return "Extract";
	case nPrim:	return "Prim";
	case nQword:	return "Qword";
	case nThunk:	return "Thunk";
	case nVar:	return "Var";
	case nVarsub:	return "Varsub";
     	case nWord:	return "Word";
	default:	panic("nodename: bad node kind %d", k);
	}
}

static const char *dumptree(Tree *tree) {
	if (tree == NULL)
		return "NULL";
	const char *name = str("&T_%ulx", (long long) tree);
	if (cvars.count(name) == 0) {
		switch (tree->kind) {
		    default:
			panic("dumptree: bad node kind %d", tree->kind);
		    case nWord: case nQword: case nPrim:
			print("static Tree_s %s = { n%s, { { %s } } };\n",
			      name + 1, nodename(tree->kind), dumpstring(tree->u[0].s));
			break;
		    case nCall: case nThunk: case nVar:
			print("static Tree_p %s = { n%s, { { (Tree *) %s } } };\n",
			      name + 1, nodename(tree->kind), dumptree(tree->u[0].p));
			break;
		    case nAssign:  case nConcat: case nClosure: case nFor:
		    case nLambda: case nLet: case nList:  case nLocal:
		    case nVarsub: case nMatch: case nExtract:
			print("static Tree_pp %s = { n%s, { { (Tree *) %s }, { (Tree *) %s } } };\n",
			      name + 1, nodename(tree->kind), dumptree(tree->u[0].p), dumptree(tree->u[1].p));
		}
		cvars.insert(name);
	}
	return name;
}

static const char *dumpbinding(Binding *binding) {
	char *name;
	if (binding == NULL)
		return "NULL";
	name = str("&B_%ulx", (long long) binding);
	if (cvars.count(name) == 0) {
		print(
			"static Binding %s = { %s, %s, %s };\n",
			name + 1,
			dumpstring(binding->name),
			dumplist(binding->defn),
			dumpbinding(binding->next)
		);
		cvars.insert(name);
	}
	return name;
}

static const char *dumpclosure(Closure *closure) {
	if (closure == NULL)
		return "NULL";
	const char *name = str("&C_%ulx",  (long long) closure);
	if (cvars.count(name) == 0) {
		print(
			"static Closure %s = { (Binding *) %s, (Tree *) %s };\n",
			name + 1,
			dumpbinding(closure->binding),
			dumptree(closure->tree)
		);
		cvars.insert(name);
	}
	return name;
}

static const char *dumpterm(Term *term) {
	if (term == NULL)
		return "NULL";
	const char *name = str("&E_%ulx", (long long) term);
	if (cvars.count(name) == 0) {
		print(
			"static Term %s = { %s, (Closure *) %s };\n",
			name + 1,
			dumpstring(term->str),
			dumpclosure(term->closure)
		);
		cvars.insert(name);
	}
	return name;
}

static const char *dumplist(List *list) {
	if (list == NULL)
		return "NULL";
	const char *name = str("&L_%ulx", (long long) list);
	if (cvars.count(name) == 0) {
		print(
			"static List %s = { %s, %s };\n",
			name + 1,
			dumpterm(list->term),
			dumplist(list->next)
		);
		cvars.insert(name);
	}
	return name;
}

static void dumpvar(const char *key, Var *var) {
	dumpstring(key);
	dumplist(var->defn);
}

static std::stringstream varbuf;

static void dumpdef(const char *name, Var *var) {
	varbuf << str("\t{ %s, (List *) %s },\n", dumpstring(name), dumplist(var->defn));
}

static void dumpfunctions(const char *key, Var *value) {
	if (hasprefix(key, "fn-")) dumpdef(key, value);
}

static void dumpsettors(const char *key, Var *value) {
	if (hasprefix(key, "set-")) dumpdef(key, value);
}

static void dumpvariables(const char *key, Var *value) {
	if (!hasprefix(key, "fn-") && !hasprefix(key, "set-"))
		dumpdef(key, value);
}

#define TreeTypes \
	typedef struct { NodeKind k; struct { const char *s; } u[1]; } Tree_s; \
	typedef struct { NodeKind k; struct { Tree *p; } u[1]; } Tree_p; \
	typedef struct { NodeKind k; struct { Tree *p; } u[2]; } Tree_pp;
TreeTypes
#define	PPSTRING(s)	STRING(s)

static void printheader(const List *title) {
	if (
		   offsetof(Tree, u[0].s) != offsetof(Tree_s,  u[0].s)
		|| offsetof(Tree, u[0].p) != offsetof(Tree_p,  u[0].p)
		|| offsetof(Tree, u[0].p) != offsetof(Tree_pp, u[0].p)
		|| offsetof(Tree, u[1].p) != offsetof(Tree_pp, u[1].p)
	)
		panic("dumpstate: Tree union sizes do not match struct sizes");

	print("/* %L */\n\n#include \"es.hxx\"\n#include \"term.hxx\"\n\n", title, " ");
	print("%s\n\n", PPSTRING(TreeTypes));
}



extern void runinitial(void) {
	const List *title = runfd(0, "initial.xs", 0);

	printheader(title);
	foreach (Dict::value_type var, vars) dumpvar(var.first.c_str(), var.second);

	/* these must be assigned in this order, or things just won't work */
	varbuf << "\nstatic const struct { const char *name; List *value; } defs[] = {\n";
	foreach (Dict::value_type var, vars) dumpfunctions(var.first.c_str(), var.second);
	foreach (Dict::value_type var, vars) dumpsettors(var.first.c_str(), var.second);
	foreach (Dict::value_type var, vars) dumpvariables(var.first.c_str(), var.second);
	varbuf << "\t{ NULL, NULL }\n"
		  "};\n\n";
	print(varbuf.str().c_str());

	print("\nextern void runinitial(void) {\n");
	print("\tint i;\n");
	print("\tfor (i = 0; defs[i].name != NULL; i++)\n");
	print("\t\tvardef(defs[i].name, NULL, defs[i].value);\n");
	print("}\n");

	exit(0);
}
