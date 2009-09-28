
/* input.c -- read input from files or strings ($Revision: 1.2 $) */

#include "es.hxx"
#include "term.hxx"
#include "input.hxx"
#include "parse.h"


/*
 * constants
 */

#define	BUFSIZE		((size_t) 1024)		/* buffer size to fill reads into */


/*
 * macros
 */
#define EOF_FD -4
#define	ISEOF(in)	((in)->fd == EOF_FD)


/*
 * globals
 */

Input *input;
const char *prompt, *prompt2;

bool disablehistory = false;
static const char *history;
static int historyfd = -1;

#if READLINE
#include <stdio.h>
#include <readline/readline.h>
#include <readline/history.h>
bool continued_input = false;
int rl_meta_chars;	/* for editline; ignored for gnu readline */

#endif


/*
 * errors and warnings
 */

/* locate -- identify where an error came from */
static const char *locate(Input *in, const char *s) {
	return (in->runflags & run_interactive)
		? str("columns %d-%d %s", yylloc.first_column, yylloc.last_column, s)
		: str("%s:%d-%d:%d-%d %s", in->name,  yylloc.first_line, yylloc.last_line, yylloc.first_column, yylloc.last_column, s);
}

static const char *error = NULL;

/* yyerror -- yacc error entry point */
extern void yyerror(const char *s) {
	if (error == NULL)   /* first error is generally the most informative */
		error = locate(input, s);
}

/* warn -- print a warning */
static void warn(const char *s) {
	eprint("warning: %s\n", locate(input, s));
}


/*
 * history
 */

#if READLINE
static int hist_from = 0;

/* No real need to use the history fd, since it
 * doesn't consider issues like unsynced output
 */
static int lines() {
	int x = 0;
	FILE *f = fopen(history, "r");
	if (!f) return -1; /* see update_hist, this should work */
	int c;
	while (c = getc(f), c != EOF) if (c == '\n') ++x;
	return x;
}

static void update_hist() {
	if (historyfd == -1) return;
	// This tries it's best to load all the changes made to the history file each time
	// only once
	// But it may load multiple times, especially if you operate on two interactive
	// shells at once (on the other hand, how common is that?!?),
	// or write a very long history file
	// Also, see the ++hist_from, which isn't even guaranteed to be correct due to sync issues
	int l = lines();
	if (l < hist_from) hist_from = 0; // history file was definately truncated/replaced
	read_history_range(history, hist_from, -1);
	hist_from = l;
}
#endif



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


#if READLINE
	update_hist();
#endif
	/*
	 * Small unix hack: since read() reads only up to a newline
	 * from a terminal, then presumably this write() will write at
	 * most only one input line at a time.
	 */
writeit:
	ewrite(historyfd, cmd, len);
#if READLINE
	++hist_from;
#endif
}
/* sethistory -- change the file for the history log */
extern void sethistory(const char *file) {
	if (historyfd != -1) {
		close(historyfd);
		historyfd = -1;
	}
	history = file;
#if READLINE
	hist_from = 0;
	update_hist();
#endif
}

int GETC() {
	int c = input->get();
	switch (c) {
	case '\t': yylloc.last_column = (yylloc.last_column / 8 + 1) * 8; break;
	case '\n':
		yylloc.first_column = yylloc.last_column = 0;
		++yylloc.last_line;
		break;
	default: ++yylloc.last_column;
	}
	return c;
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
		in->unget_fill = false;
		assert(in->rbuf != NULL);
		in->buf = in->rbuf;
		in->rbuf = NULL;
	}
	return c;
}

/* unget -- push back one character */
extern void unget(Input *in, int c) {
	--yylloc.last_column;
	if (yylloc.first_column > yylloc.last_column) yylloc.first_column = yylloc.last_column;

	if (in->ungot > 0) {
		assert(in->ungot < MAXUNGET);
		in->unget[in->ungot++] = c;
	} else if (in->bufbegin < in->buf && in->buf[-1] == c && (input->runflags & run_echoinput) == 0)
		--in->buf;
	else {
		in->unget_fill = true;
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
int Input::get() {
	int c;
	while ((c = (buf < bufend ? *buf++ : fill())) == '\0')
		warn("null character ignored");
	if ((runflags & run_echoinput) && c != EOF) {
		char buffer = c;
		ewrite(2, &buffer, 1);
	}
	return c;
}

#if READLINE
/* callreadline -- readline wrapper */
static char *callreadline() {
	char *r;
	interrupted = false;
	if (!setjmp(slowlabel)) {
		slow = true;
		update_hist();
		r = interrupted ? NULL : readline(continued_input ? prompt2 : prompt);
	} else  r = NULL;
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
		newHome = reinterpret_cast<char*>(GC_MALLOC(len));
		strcpy(newHome, home);
		strcpy(newHome + hLen, pos + 1);
		text = newHome;
	}
        char *result = default_quote_function(text, match_Type, quote_pointer);
	return result;
}

static inline const char * simple_basename(const char *str) {
	return rindex(str, '/') + 1;
}

#include "var.hxx"
/* TODO Variable completion on $ */
static char ** command_completion(const char *text, int start, int end) {
	{
		int i = 0;
		while (isspace(text[i])) ++i;
		if (start > i) {
			if (text[start] == '$') puts("$ completion concept");
			/* Only for first word on line */
			return NULL;
		}
		else text += i;
	}
	char **results = NULL;

	/* Leave room for \0, and special first element */
	int result_p = 1;
	int results_size = 2;

	/* Lookup matching commands */
	for (List* paths = varlookup("path", NULL);
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

		List* glob_result = dirmatch(path, path, glob_string, UNQUOTED);
		efree(path);

		int l = length(glob_result);
		if (l == 0) continue;

		results_size += l;
		results = reinterpret_cast<char**>(erealloc(results, results_size * sizeof(char*)));
		for (List* i = glob_result; i != NULL; i = i->next, ++result_p) {
			/* Can't directly use basename, because readline
			 * needs to free() the result
			 */
			results[result_p] = strdup(simple_basename(i->term->str));
		}
	}

	List* lvars;
	dictforall(vars, addtolist, &lvars);
	/* Match (some) variables - can't easily match lexical/local because that would require partially
	 * parsing/evaluating the input (which would contain a let/local somewhere in it) */
	for (; lvars; lvars = lvars->next) {
		const char* str = getstr(lvars->term);
		if (strncmp("fn-", str, 3) != 0
		   || strncmp(text, str + 3, end - start) != 0) continue;
		++results_size;
		results = reinterpret_cast<char**>(erealloc(results, results_size * sizeof(char*)));
		results[result_p++] = strdup(str + 3);
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
		char *rlinebuf = callreadline();
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
		in->fd = EOF_FD;
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

	result = yyparse();


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
	int flags = runflags;
	List* result;
	List *repl, *dispatch;
	const char *dispatcher[] = {
		"fn-%eval-noprint",
		"fn-%eval-print",
		"fn-%noeval-noprint",
		"fn-%noeval-print",
	};

	flags &= ~eval_inchild;
	in->runflags = flags;
	in->prev = input;
	input = in;

	try {
		dispatch
	          = varlookup(dispatcher[((flags & run_printcmds) ? 1 : 0)
					 + ((flags & run_noexec) ? 2 : 0)],
			      NULL);
		if (flags & eval_exitonfalse)
			dispatch = mklist(mkstr("%exit-on-false"), dispatch);

		Push push("fn-%dispatch", dispatch);

		repl = varlookup((flags & run_interactive)
				   ? "fn-%interactive-loop"
				   : "fn-%batch-loop",
				 NULL);
		result = (repl == NULL)
				? prim("batchloop", NULL, NULL, flags)
				: eval(repl, NULL, flags);
	} catch (List *e) {
		input = input->prev;
		throwE(e);
	}

	input = in->prev;
	return result;
}


/*
 * pushing new input sources
 */


struct FD_input : public Input {
	int fill() {
		if (unget_fill) return ungetfill(this);
		else if (fd == EOF_FD) return EOF;
		else return fdfill(this);
	}
	~FD_input() {
		unregisterfd(&fd);
		if (fd >= 0)
			close(fd);
		efree(bufbegin);
	}
};

/* runfd -- run commands from a file descriptor */
extern List *runfd(int fd, const char *name, int flags) {
	FD_input in;
	List *result;

	in.lineno = 1;
	in.fd = fd;
	registerfd(&in.fd, true);
	in.buflen = BUFSIZE;
	in.bufbegin = in.buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen));
	in.bufend = in.bufbegin;
	in.name = (name == NULL) ? str("fd %d", fd) : name;

	result = runinput(&in, flags);

	return result;
}

struct String_input : public Input {
	int fill() {
		if (unget_fill) return ungetfill(this);
		else {
			fd = EOF_FD;
			return EOF;
		}
	}
	~String_input() {
		efree(bufbegin);
	}
};

/* runstring -- run commands from a string */
extern List *runstring(const char *str, const char *name, int flags) {
	String_input in;
	List *result;
	unsigned char *buf;

	assert(str != NULL);

	in.fd = -2;
	in.lineno = 1;
	in.name = (name == NULL) ? str : name;
	in.buflen = strlen(str);
	buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen + 1));
	memcpy(buf, str, in.buflen);
	in.bufbegin = in.buf = buf;
	in.bufend = in.buf + in.buflen;

	result = runinput(&in, flags);
	return result;
}

/* parseinput -- turn an input source into a tree */
extern Tree *parseinput(Input *in) {
	Tree * volatile result;

	in->prev = input;
	in->runflags = 0;
	input = in;

	try {
		result = parse(NULL, NULL);
		if (in->get() != EOF)
			fail("$&parse", "more than one value in term");
	} catch (List *e) {
		input = input->prev;
		throwE(e);
	}

	input = in->prev;
	return result;
}



/* parsestring -- turn a string into a tree; must be exactly one tree */
extern Tree *parsestring(const char *str) {
	String_input in;
	Tree *result;
	unsigned char *buf;

	assert(str != NULL);

	/* TODO: abstract out common code with runstring */

	in.fd = -2;
	in.lineno = 1;
	in.name = str;
	in.buflen = strlen(str);
	buf = reinterpret_cast<unsigned char*>(ealloc(in.buflen + 1));
	memcpy(buf, str, in.buflen);
	in.bufbegin = in.buf = buf;
	in.bufend = in.buf + in.buflen;

	result = parseinput(&in);
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
	yylloc.first_line = yylloc.last_line = 1;
	yylloc.first_column = yylloc.last_column = 0;

	/* mark the historyfd as a file descriptor to hold back from forked children */
	registerfd(&historyfd, true);

#if READLINE
	rl_meta_chars = 0;
	/* = basically works here for := */
	rl_basic_word_break_characters = " \t\n\\'`><=;|&{()}";
	rl_completer_quote_characters = "'";
	/* Either = or : has to be here to safeguard := */
	rl_filename_quote_characters = " \t\n\\'`=$><;|&{()}";
	default_quote_function = rl_filename_quoting_function;
	rl_filename_quoting_function = quote_func;
	rl_attempted_completion_function = command_completion;
#endif
}
