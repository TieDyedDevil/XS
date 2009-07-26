
/* input.c -- read input from files or strings ($Revision: 1.2 $) */

#include "es.hxx"
#include "term.hxx"
#include "input.hxx"


/*
 * constants
 */

#define	BUFSIZE		((size_t) 1024)		/* buffer size to fill reads into */


/*
 * macros
 */

#define	ISEOF(in)	((in)->fill == eoffill)


/*
 * globals
 */

Input *input;
const char *prompt, *prompt2;

bool disablehistory = false;
bool resetterminal = false;
static const char *history;
static int historyfd = -1;

#if READLINE
#include <stdio.h>
#include <readline/readline.h>
#include <readline/history.h>
int rl_meta_chars;	/* for editline; ignored for gnu readline */

#if 0 /* Add support for using this when header is unavailable? */
extern char *readline(char *);
extern void add_history(char *);
extern void rl_reset_terminal(char *);
extern char *rl_basic_word_break_characters;
extern char *rl_completer_quote_characters;
#endif


#endif


/*
 * errors and warnings
 */

/* locate -- identify where an error came from */
static const char *locate(Input *in, const char *s) {
	return (in->runflags & run_interactive)
		? s
		: str("%s:%d: %s", in->name, in->lineno, s);
}

static const char *error = NULL;

/* yyerror -- yacc error entry point */
extern void yyerror(const char *s) {
#if sgi
	/* this is so that trip.es works */
	if (streq(s, "Syntax error"))
		s = "syntax error";
#endif
	if (error == NULL)	/* first error is generally the most informative */
		error = locate(input, s);
}

/* warn -- print a warning */
static void warn(const char *s) {
	eprint("warning: %s\n", locate(input, s));
}


/*
 * history
 */

/* loghistory -- write the last command out to a file */
static void loghistory(const char *cmd, size_t len) {
	const char *s, *end;
	if (history == NULL || disablehistory)
		return;
	if (historyfd == -1) {
		historyfd = eopen(history, oAppend);
		if (historyfd == -1) {
			eprint("history(%s): %s\n", history, esstrerror(errno));
			vardef("history", NULL, NULL);
			return;
		}
	}
	/* skip empty lines and comments in history */
	for (s = cmd, end = s + len; s < end; s++)
		switch (*s) {
		case '#': case '\n':	return;
		case ' ': case '\t':	break;
		default:		goto writeit;
		}

	/*
	 * Small unix hack: since read() reads only up to a newline
	 * from a terminal, then presumably this write() will write at
	 * most only one input line at a time.
	 */
writeit:
	ewrite(historyfd, cmd, len);
}

/* sethistory -- change the file for the history log */
extern void sethistory(const char *file) {
	if (historyfd != -1) {
		close(historyfd);
		historyfd = -1;
	}
	history = file;
}


/*
 * unget -- character pushback
 */

/* ungetfill -- input->fill routine for ungotten characters */
static int ungetfill(Input *in) {
	int c;
	assert(in->ungot > 0);
	c = in->unget[--in->ungot];
	if (in->ungot == 0) {
		assert(in->rfill != NULL);
		in->fill = in->rfill;
		in->rfill = NULL;
		assert(in->rbuf != NULL);
		in->buf = in->rbuf;
		in->rbuf = NULL;
	}
	return c;
}

/* unget -- push back one character */
extern void unget(Input *in, int c) {
	if (in->ungot > 0) {
		assert(in->ungot < MAXUNGET);
		in->unget[in->ungot++] = c;
	} else if (in->bufbegin < in->buf && in->buf[-1] == c && (input->runflags & run_echoinput) == 0)
		--in->buf;
	else {
		assert(in->rfill == NULL);
		in->rfill = in->fill;
		in->fill = ungetfill;
		assert(in->rbuf == NULL);
		in->rbuf = in->buf;
		in->buf = in->bufend;
		assert(in->ungot == 0);
		in->ungot = 1;
		in->unget[0] = c;
	}
}


/*
 * getting characters
 */

/* get -- get a character, filter out nulls */
static int get(Input *in) {
	int c;
	while ((c = (in->buf < in->bufend ? *in->buf++ : (*in->fill)(in))) == '\0')
		warn("null character ignored");
	return c;
}

/* getverbose -- get a character, print it to standard error */
static int getverbose(Input *in) {
	if (in->fill == ungetfill)
		return get(in);
	else {
		int c = get(in);
		if (c != EOF) {
			char buf = c;
			ewrite(2, &buf, 1);
		}
		return c;
	}
}

/* eoffill -- report eof when called to fill input buffer */
static int eoffill(Input *in) {
	assert(in->fd == -1);
	return EOF;
}

#if READLINE
/* callreadline -- readline wrapper */
static char *callreadline(const char *prompt) {
	char *r;
	if (resetterminal) {
		rl_reset_terminal(NULL);
		resetterminal = false;
	}
	interrupted = false;
	if (!setjmp(slowlabel)) {
		slow = true;
		r = interrupted ? NULL : readline(prompt);
	} else
		r = NULL;
	slow = false;
	if (r == NULL)
		errno = EINTR;
	SIGCHK();
	return r;
}

static rl_quote_func_t * default_quote_function ;
static char * quote_func(char *text, int match_Type, char *quote_pointer) {
	char *pos;
	char *newHome = NULL;
	if ((pos = strstr(text, "~"))) {
		/* Expand ~, otherwise quoting will make the filename invalid */
		const char *home = varlookup("HOME", NULL)->term->str;
		int hLen = strlen(home);
		int len = strlen(text) + hLen +1;
		/* consider gc usage here? */
		newHome = reinterpret_cast<char*>(ealloc(len));
		strcpy(newHome, home);
		strcpy(newHome + hLen, pos + 1);
		text = newHome;
	}
        char *result = default_quote_function(text, match_Type, quote_pointer);
	if (newHome) efree(newHome);
	return result;
}

static inline char * basename(char *str) {
	return rindex(str, '/') + 1;
}

#include "var.hxx"
/* TODO Variable completion on $ */
static char ** command_completion(const char *text, int start, int end) {
	{
		int i = 0;
		while (isspace(text[i])) ++i;
		if (start > i) return NULL; /* Only for first word on line */	
		else text += i;
	}
	char **results = NULL;
	
	/* Leave room for \0, and special first element */
	int result_p = 1;
	int results_size = 2;

	/* Lookup matching commands */
	for (SRef<List> paths = varlookup("path", NULL);
	     paths != NULL;
	     paths = paths->next)
	{
		int l_path = strlen(paths->term->str);
		char *path = reinterpret_cast<char*>(ealloc(l_path + 2));
		strcpy(path, paths->term->str);
		path[l_path] = '/';
		path[l_path + 1] = '\0';
	
		char * glob_string = reinterpret_cast<char*>(ealloc(sizeof(char) * (end - start + 2)));
		memcpy(glob_string, text, (end - start) * sizeof(char));
		*(glob_string + end - start) = '*';
		*(glob_string + end - start + 1) = '\0';	

		SRef<List> glob_result = dirmatch(path, path, glob_string, UNQUOTED);
		efree(path);

		int l = length(glob_result);
		if (l == 0) continue;
		
		results_size += l;
		results = reinterpret_cast<char**>(erealloc(results, results_size * sizeof(char*)));
		for (SRef<List> i = glob_result; i != NULL; i = i->next, ++result_p) {
			/* Can't directly use gc_string, because readline
			 * needs to free() the result 
			 */
			results[result_p] = strdup(basename(i->term->str));
		}
	}

	SRef<List> lvars;
	dictforall(vars, addtolist, &lvars);
	/* Match (some) variables - can't easily match lexical/local because that would require partially
	 * parsing/evaluating the input (which would contain a let/local somewhere in it) */
	for (; lvars; lvars = lvars->next) {
		SRef<const char> str = getstr(lvars->term);
		if (strncmp("fn-", str.uget(), 3) != 0
		   || strncmp(text, str.uget() + 3, end - start) != 0) continue;
		++results_size;
		results = reinterpret_cast<char**>(erealloc(results, results_size * sizeof(char*)));
		results[result_p++] = strdup(str.release() + 3);
	}

	assert (result_p == results_size - 1);
	int num_results = results_size - 2;
	
	if (num_results > 0) {
		results[results_size - 1] = NULL;
		results[0] = strdup(num_results == 1 ? results[1] : text) ;
	} else assert (results == NULL);
	return results;
}

#endif	/* READLINE */

/* fdfill -- fill input buffer by reading from a file descriptor */
static int fdfill(Input *in) {
	long nread;
	assert(in->buf == in->bufend);
	assert(in->fd >= 0);

#if READLINE
	if (in->runflags & run_interactive && in->fd == 0) {
		char *rlinebuf = callreadline(prompt);
		if (rlinebuf == NULL)

			nread = 0;
		else {
			if (*rlinebuf != '\0')
				add_history(rlinebuf);
			nread = strlen(rlinebuf) + 1;
			if (in->buflen < (unsigned long) nread) {
				while (in->buflen < (unsigned) nread)
					in->buflen *= 2;
				efree(in->bufbegin);
				in->bufbegin = reinterpret_cast<unsigned char*>(erealloc(in->bufbegin, in->buflen));
			}
			memcpy(in->bufbegin, rlinebuf, nread - 1);
			in->bufbegin[nread - 1] = '\n';
		}
	} else
#endif
	do {
		nread = eread(in->fd, (char *) in->bufbegin, in->buflen);
		SIGCHK();
	} while (nread == -1 && errno == EINTR);

	if (nread <= 0) {
		close(in->fd);
		in->fd = -1;
		in->fill = eoffill;
		in->runflags &= ~run_interactive;
		if (nread == -1)
			fail("$&parse", "%s: %s", in->name == NULL ? "es" : in->name, esstrerror(errno));
		return EOF;
	}

	if (in->runflags & run_interactive)
		loghistory((char *) in->bufbegin, nread);

	in->buf = in->bufbegin;
	in->bufend = &in->buf[nread];
	return *in->buf++;
}


/*
 * the input loop
 */

/* parse -- call yyparse(), but disable garbage collection and catch errors */
extern Tree *parse(const char *pr1, const char *pr2) {
	int result;
	assert(error == NULL);

	inityy();
	emptyherequeue();

	if (ISEOF(input))
		throwE(mklist(mkstr("eof"), NULL));

#if READLINE
	prompt = (pr1 == NULL) ? "" : pr1;
#else
	if (pr1 != NULL)
		eprint("%s", pr1);
#endif
	prompt2 = pr2;

	gcreserve(300 * sizeof (Tree));
	gcdisable();
	result = yyparse();
	gcenable();

	if (result || error != NULL) {
		assert(error != NULL);
		const char *e = error;
		error = NULL;
		fail("$&parse", "%s", e);
	}
#if LISPTREES
	if (input->runflags & run_lisptrees)
		eprint("%B\n", parsetree);
#endif
	return parsetree;
}

/* resetparser -- clear parser errors in the signal handler */
extern void resetparser(void) {
	error = NULL;
}

/* runinput -- run from an input source */
extern List *runinput(Input *in, int runflags) {
	volatile int flags = runflags;
	volatile SRef<List> result;
	SRef<List> repl, dispatch;
	Push push;
	const char *dispatcher[] = {
		"fn-%eval-noprint",
		"fn-%eval-print",
		"fn-%noeval-noprint",
		"fn-%noeval-print",
	};

	flags &= ~eval_inchild;
	in->runflags = flags;
	in->get = (flags & run_echoinput) ? getverbose : get;
	in->prev = input;
	input = in;

	ExceptionHandler

		dispatch
	          = varlookup(dispatcher[((flags & run_printcmds) ? 1 : 0)
					 + ((flags & run_noexec) ? 2 : 0)],
			      NULL);
		if (flags & eval_exitonfalse)
			dispatch = mklist(mkstr("%exit-on-false"), dispatch);
		varpush(&push, "fn-%dispatch", dispatch.uget());

		repl = varlookup((flags & run_interactive)
				   ? "fn-%interactive-loop"
				   : "fn-%batch-loop",
				 NULL);
		result = (repl == NULL)
				? prim("batchloop", NULL, NULL, flags).release()
				: eval(repl, NULL, flags);

		varpop(&push);

	CatchException (e)

		(*input->cleanup)(input);
		input = input->prev;
		throwE(e);

	EndExceptionHandler

	input = in->prev;
	(*in->cleanup)(in);
	return result.release();
}


/*
 * pushing new input sources
 */

/* fdcleanup -- cleanup after running from a file descriptor */
static void fdcleanup(Input *in) {
	unregisterfd(&in->fd);
	if (in->fd != -1)
		close(in->fd);
	efree(in->bufbegin);
}

/* runfd -- run commands from a file descriptor */
extern List *runfd(int fd, const char *name, int flags) {
	Input in;
	List *result;

	memzero(&in, sizeof (Input));
	in.lineno = 1;
	in.fill = fdfill;
	in.cleanup = fdcleanup;
	in.fd = fd;
	registerfd(&in.fd, true);
	in.buflen = BUFSIZE;
	in.bufbegin = in.buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen));
	in.bufend = in.bufbegin;
	in.name = (name == NULL) ? str("fd %d", fd) : name;

	RefAdd(in.name);
	result = runinput(&in, flags);
	RefRemove(in.name);

	return result;
}

/* stringcleanup -- cleanup after running from a string */
static void stringcleanup(Input *in) {
	efree(in->bufbegin);
}

/* stringfill -- placeholder than turns into EOF right away */
static int stringfill(Input *in) {
	in->fill = eoffill;
	return EOF;
}

/* runstring -- run commands from a string */
extern List *runstring(const char *str, const char *name, int flags) {
	Input in;
	List *result;
	unsigned char *buf;

	assert(str != NULL);

	memzero(&in, sizeof (Input));
	in.fd = -1;
	in.lineno = 1;
	in.name = (name == NULL) ? str : name;
	in.fill = stringfill;
	in.buflen = strlen(str);
	buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen + 1));
	memcpy(buf, str, in.buflen);
	in.bufbegin = in.buf = buf;
	in.bufend = in.buf + in.buflen;
	in.cleanup = stringcleanup;

	RefAdd(in.name);
	result = runinput(&in, flags);
	RefRemove(in.name);
	return result;
}

/* parseinput -- turn an input source into a tree */
extern Tree *parseinput(Input *in) {
	Tree * volatile result;

	in->prev = input;
	in->runflags = 0;
	in->get = get;
	input = in;

	ExceptionHandler
		result = parse(NULL, NULL);
		if (get(in) != EOF)
			fail("$&parse", "more than one value in term");
	CatchException (e)
		(*input->cleanup)(input);
		input = input->prev;
		throwE(e);
	EndExceptionHandler

	input = in->prev;
	(*in->cleanup)(in);
	return result;
}

/* parsestring -- turn a string into a tree; must be exactly one tree */
extern Tree *parsestring(const char *str) {
	Input in;
	Tree *result;
	unsigned char *buf;

	assert(str != NULL);

	/* TODO: abstract out common code with runstring */

	memzero(&in, sizeof (Input));
	in.fd = -1;
	in.lineno = 1;
	in.name = str;
	in.fill = stringfill;
	in.buflen = strlen(str);
	buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen + 1));
	memcpy(buf, str, in.buflen);
	in.bufbegin = in.buf = buf;
	in.bufend = in.buf + in.buflen;
	in.cleanup = stringcleanup;

	RefAdd(in.name);
	result = parseinput(&in);
	RefRemove(in.name);
	return result;
}

/* isinteractive -- is the innermost input source interactive? */
extern bool isinteractive(void) {
	return input == NULL ? false : ((input->runflags & run_interactive) != 0);
}


/*
 * initialization
 */

/* initinput -- called at dawn of time from main() */
extern void initinput(void) {
	input = NULL;

	/* declare the global roots */
	globalroot(&history);		/* history file */
	globalroot(&error);		/* parse errors */
	globalroot(&prompt);		/* main prompt */
	globalroot(&prompt2);		/* secondary prompt */

	/* mark the historyfd as a file descriptor to hold back from forked children */
	registerfd(&historyfd, true);

	/* call the parser's initialization */
	initparse();

#if READLINE
	rl_meta_chars = 0;
	/* = basically works here for := */
	rl_basic_word_break_characters = " \t\n\\'`$><=;|&{()}";
	rl_completer_quote_characters = "'";
	/* Either = or : has to be here to safeguard := */
	rl_filename_quote_characters = "\t\n\\'`$><;|&{()}";
	default_quote_function = rl_filename_quoting_function;
	rl_filename_quoting_function = quote_func;
	rl_attempted_completion_function = command_completion;
#endif
}
