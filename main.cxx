/* main.c -- initialization for es ($Revision: 1.3 $) */

#include "es.hxx"

#if GCVERBOSE
bool gcverbose	= false;	/* -G */
#endif
#if GCINFO
bool gcinfo		= false;	/* -I */
#endif

extern int optind;
extern char *optarg;

extern char **environ;


/* checkfd -- open /dev/null on an fd if it is closed */
static void checkfd(int fd, OpenKind r) {
	int newFD;
	newFD = dup(fd);
	if (newFD != -1)
		close(newFD);
	else if (errno == EBADF && (newFD = eopen("/dev/null", r)) != -1)
		mvfd(newFD, fd);
}

/* initpath -- set $path based on the configuration default */
static void initpath(void) {
	int i;
	static const char * const path[] = { INITIAL_PATH };

	Ref(List *, list, NULL);
	for (i = arraysize(path); i-- > 0;) {
		Term *t = mkstr((char *) path[i]);
		list = mklist(t, list);
	}
	vardef("path", NULL, list);
	RefEnd(list);
}

/* initpid -- set $pid for this shell */
static void initpid(void) {
	vardef("pid", NULL, mklist(mkstr(str("%d", getpid())), NULL));
}

/* runxsrc -- run the user's profile, if it exists */
static void runxsrc(void) {
	char *xsrc = str("%L/.xsrc", varlookup("home", NULL), "\001");
	int fd = eopen(xsrc, oOpen);
	if (fd != -1) {
		ExceptionHandler
			runfd(fd, xsrc, 0);
		CatchException (e)
			if (termeq(e->term, "exit"))
				exit(exitstatus(e->next));
			else if (termeq(e->term, "error"))
				eprint("%L\n",
				       e->next == NULL ? NULL : e->next->next,
				       " ");
			else if (!issilentsignal(e))
				eprint("uncaught exception: %L\n", e, " ");
			return;
		EndExceptionHandler
	}
}

/* usage -- print usage message and die */
static void usage(void) NORETURN;
static void usage(void) {
	eprint(
		"usage: xs [-c command] [-silevxnpo] [file [args ...]]\n"
		"	-c cmd	execute argument\n"
		"	-s	read commands from standard input; stop option parsing\n"
		"	-i	interactive shell\n"
		"	-l	login shell\n"
		"	-e	exit if any command exits with false status\n"
		"	-v	print input to standard error\n"
		"	-x	print commands to standard error before executing\n"
		"	-n	just parse; don't execute\n"
		"	-p	don't load functions from the environment\n"
		"	-o	don't open stdin, stdout, and stderr if they were closed\n"
		"	-d	don't ignore SIGQUIT or SIGTERM\n"
#if GCINFO
		"	-I	print garbage collector information\n"
#endif
#if GCVERBOSE
		"	-G	print verbose garbage collector information\n"
#endif
#if LISPTREES
		"	-L	print parser results in LISP format\n"
#endif
	);
	exit(1);
}


/* main -- initialize, parse command arguments, and start running */
int main(int argc, char **argv) {
	int c;
	volatile int ac;
	char **volatile av;

	volatile int runflags = 0;		/* -[einvxL] */
	volatile bool isprotected = false;	/* -p */
	volatile bool allowquit = false;	/* -d */
	volatile bool cmd_stdin = false;		/* -s */
	volatile bool loginshell = false;	/* -l or $0[0] == '-' */
	bool keepclosed = false;		/* -o */
	const char *volatile cmd = NULL;	/* -c */

	initgc();
	initconv();

	if (argc == 0) {
		argc = 1;
		argv = reinterpret_cast<char**>(ealloc(2 * sizeof (char *)));
		argv[0] = strdup("es");
		argv[1] = NULL;
	}
	if (argv[0][0] == '-')
		loginshell = true;

	while ((c = getopt(argc, argv, "eilxvnpodsc:?GIL")) != EOF)
		switch (c) {
		case 'c':	cmd = optarg;			break;
		case 'e':	runflags |= eval_exitonfalse;	break;
		case 'i':	runflags |= run_interactive;	break;
		case 'n':	runflags |= run_noexec;		break;
		case 'v':	runflags |= run_echoinput;	break;
		case 'x':	runflags |= run_printcmds;	break;
#if LISPTREES
		case 'L':	runflags |= run_lisptrees;	break;
#endif
		case 'l':	loginshell = true;		break;
		case 'p':	isprotected = true;		break;
		case 'o':	keepclosed = true;		break;
		case 'd':	allowquit = true;		break;
		case 's':	cmd_stdin = true;			goto getopt_done;
#if GCVERBOSE
		case 'G':	gcverbose = true;		break;
#endif
#if GCINFO
		case 'I':	gcinfo = true;			break;
#endif
		default:
			usage();
		}

getopt_done:
	if (cmd_stdin && cmd != NULL) {
		eprint("es: -s and -c are incompatible\n");
		exit(1);
	}

	if (!keepclosed) {
		checkfd(0, oOpen);
		checkfd(1, oCreate);
		checkfd(2, oCreate);
	}

	if (
		cmd == NULL
	     && (optind == argc || cmd_stdin)
	     && (runflags & run_interactive) == 0
	     && isatty(0)
	)
		runflags |= run_interactive;

	ac = argc;
	av = argv;

	ExceptionHandler
		roothandler = &_localhandler;	/* unhygeinic */

		initinput();
		initprims();
		initvars();

		runinitial();

		initpath();
		initpid();
		initsignals(runflags & run_interactive, allowquit);
		hidevariables();
		initenv(environ, isprotected);

		if (loginshell)
			runxsrc();

		if (cmd == NULL && !cmd_stdin && optind < ac) {
			int fd;
			char *file = av[optind++];
			if ((fd = eopen(file, oOpen)) == -1) {
				eprint("%s: %s\n", file, esstrerror(errno));
				return 1;
			}
			vardef("*", NULL, listify(ac - optind, av + optind));
			vardef("0", NULL, mklist(mkstr(file), NULL));
			return exitstatus(runfd(fd, file, runflags));
		}

		vardef("*", NULL, listify(ac - optind, av + optind));
		vardef("0", NULL, mklist(mkstr(av[0]), NULL));
		if (cmd != NULL)
			return exitstatus(runstring(cmd, NULL, runflags));
		return exitstatus(runfd(0, "stdin", runflags));

	CatchException (e)

		if (termeq(e->term, "exit"))
			return exitstatus(e->next);
		else if (termeq(e->term, "error"))
			eprint("%L\n",
			       e->next == NULL ? NULL : e->next->next,
			       " ");
		else if (!issilentsignal(e))
			eprint("uncaught exception: %L\n", e, " ");
		return 1;

	EndExceptionHandler
}
