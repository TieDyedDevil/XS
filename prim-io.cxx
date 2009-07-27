/* prim-io.c -- input/output and redirection primitives ($Revision: 1.2 $) */

#include "es.hxx"
#include "gc.hxx"
#include "prim.hxx"
#include <stdio.h>

static const char *caller;

static int getnumber(const char *s) {
	char *end;
	int result = strtol(s, &end, 0);

	if (*end != '\0' || result < 0)
		fail(caller, "bad number: %s", s);
	return result;
}

static SRef<List> redir(SRef<List> (*rop)(int *fd, SRef<List> list), SRef<List> list, int evalflags) {
	int destfd, srcfd;
	volatile int inparent = (evalflags & eval_inchild) == 0;
	volatile int ticket = UNREGISTERED;

	assert(list != NULL);
	destfd = getnumber(getstr(list->term));
	list = (*rop)(&srcfd, list->next);

	try {
		ticket = (srcfd == -1)
			   ? defer_close(inparent, destfd)
			   : defer_mvfd(inparent, srcfd, destfd);
		list = eval(list, NULL, evalflags);
		undefer(ticket);
	} catch (List *e) {
		undefer(ticket);
		throwE(e);
	}

	return list;
}

#define	REDIR(name)	static SRef<List> CONCAT(redir_,name)(int *srcfdp, SRef<List> list)

static void argcount(const char *s) NORETURN;
static void argcount(const char *s) {
	fail(caller, "argument count: usage: %s", s);
}

REDIR(openfile) {
	int i, fd;
	OpenKind kind;
	static const struct {
		const char *name;
		OpenKind kind;
	} modes[] = {
		{ "r",	oOpen },
		{ "w",	oCreate },
		{ "a",	oAppend },
		{ "r+",	oReadWrite },
		{ "w+",	oReadCreate },
		{ "a+",	oReadAppend },
		{ NULL, }
	};

	assert(length(list) == 3);

	const char *mode = getstr(list->term);
	list = list->next;
	for (i = 0;; i++) {
		if (modes[i].name == NULL)
			fail("$&openfile", "bad %%openfile mode: %s", mode);
		if (streq(mode, modes[i].name)) {
			kind = modes[i].kind;
			break;
		}
	}

	const char *name = getstr(list->term);
	list = list->next;
	fd = eopen(name, kind);
	if (fd == -1)
		fail("$&openfile", "%s: %s", name, esstrerror(errno));
	*srcfdp = fd;
	return list;
}

PRIM(openfile) {
	caller = "$&openfile";
	if (length(list) != 4)
		argcount("%openfile mode fd file cmd");
	/* transpose the first two elements */
	SRef<List> lp = list->next;
	list->next = lp->next;
	lp->next = list.release();
	return redir(redir_openfile, lp.release(), evalflags);
}

REDIR(dup) {
	int fd;
	assert(length(list) == 2);
	fd = dup(fdmap(getnumber(getstr(list->term))));
	if (fd == -1)
		fail("$&dup", "dup: %s", esstrerror(errno));
	*srcfdp = fd;
	return list->next;
}

PRIM(dup) {
	caller = "$&dup";
	if (length(list) != 3)
		argcount("%dup newfd oldfd cmd");
	return redir(redir_dup, list.release(), evalflags);
}

REDIR(close) {
	*srcfdp = -1;
	return list;
}

PRIM(close) {
	caller = "$&close";
	if (length(list) != 2)
		argcount("%close fd cmd");
	return redir(redir_close, list.release(), evalflags);
}


/* pipefork -- create a pipe and fork */
static int pipefork(int p[2], int *extra) {
	volatile int pid = 0;

	if (pipe(p) == -1)
		fail(caller, "pipe: %s", esstrerror(errno));

	registerfd(&p[0], false);
	registerfd(&p[1], false);
	if (extra != NULL)
		registerfd(extra, false);

	try {
		pid = efork(true, false);
	} catch (List *e) {
		unregisterfd(&p[0]);
		unregisterfd(&p[1]);
		if (extra != NULL)
			unregisterfd(extra);
		throwE(e);
	}

	unregisterfd(&p[0]);
	unregisterfd(&p[1]);
	if (extra != NULL)
		unregisterfd(extra);
	return pid;
}

REDIR(here) {
	int pid, p[2];
	List *doc, *tail, **tailp;

	assert(list != NULL);
	for (tailp = list.rget(); (tail = *tailp)->next != NULL; tailp = &tail->next)
		;
	doc = (list == tail) ? NULL : list.uget();
	*tailp = NULL;

	if ((pid = pipefork(p, NULL)) == 0) {		/* child that writes to pipe */
		try {
			close(p[0]);
			fprint(p[1], "%L", doc, "");
			exit(0);
		} catch (List *e) {
			eprint("Received error in here redirection child:\n");
			print_exception(e);
			exit(9);
		}
	}

	close(p[1]);
	*srcfdp = p[0];
	return tail;
}

PRIM(here) {
	caller = "$&here";
	if (length(list) < 2)
		argcount("%here fd [word ...] cmd");
	return redir(redir_here, list.release(), evalflags);
}

PRIM(pipe) {
	int n, infd, inpipe;
	static int *pids = NULL, pidmax = 0;

	caller = "$&pipe";
	n = length(list);
	if ((n % 3) != 1)
		fail("$&pipe", "usage: pipe cmd [ outfd infd cmd ] ...");
	n = (n + 2) / 3;
	if (n > pidmax) {
		pids = reinterpret_cast<int*>(erealloc(pids, n * sizeof *pids));
		pidmax = n;
	}
	n = 0;

	infd = inpipe = -1;

	for (;; list = list->next) {
		int p[2], pid;
		
		pid = (list->next == NULL) ? efork(true, false) : pipefork(p, &inpipe);

		if (pid == 0) {		/* child */
			try {
				if (inpipe != -1) {
					assert(infd != -1);
					releasefd(infd);
					mvfd(inpipe, infd);
				}
				if (list->next != NULL) {
					int fd = getnumber(getstr(list->next->term));
					releasefd(fd);
					mvfd(p[1], fd);
					close(p[0]);
				}
				exit(exitstatus(eval1(list->term, evalflags | eval_inchild)));
			} catch (List *e) {
				eprint("Received error in %%pipe child process:\n");
				print_exception(e);
				exit(9);
			}
		}
		pids[n++] = pid;
		close(inpipe);
		if (list->next == NULL)
			break;
		list = list->next->next;
		infd = getnumber(getstr(list->term));
		inpipe = p[0];
		close(p[1]);
	}

	SRef<List> result;
	do {
		int status = ewaitfor(pids[--n]);
		printstatus(0, status);
		SRef<Term> t = mkstr(mkstatus(status));
		result = mklist(t, result);
	} while (0 < n);
	if (evalflags & eval_inchild)
		exit(exitstatus(result.uget()));
	return result;
}

#ifdef HAVE_DEV_FD
PRIM(readfrom) {
	int pid, p[2], status;
	caller = "$&readfrom";
	if (length(list) != 3)
		argcount("%readfrom var input cmd");
	SRef<const char> var = getstr(list->term);
	list = list->next;
	SRef<Term> input = list->term;
	list = list->next;
	SRef<Term> cmd = list->term;

	if ((pid = pipefork(p, NULL)) == 0) {
		try {
			close(p[0]);
			mvfd(p[1], 1);
			exit(exitstatus(eval1(input.uget(), evalflags &~ eval_inchild)));
		} catch (List *e) {
			eprint("Received exception in %%readfrom (<{}) child process:\n");
			print_exception(e);
			exit(9);
		}
	}

	close(p[1]);
	list = mklist(mkstr(str(DEVFD_PATH, p[0])), NULL);

	try {
		Push push(var.release(), list.uget());
		list = eval1(cmd.uget(), evalflags);
	} catch (List *e) {
		close(p[0]);
		ewaitfor(pid);
		throwE(e);
	}

	close(p[0]);
	status = ewaitfor(pid);
	printstatus(0, status);
	return list;
}

PRIM(writeto) {
	int pid, p[2], status;

	caller = "$&writeto";
	if (length(list) != 3)
		argcount("%writeto var output cmd");
	SRef<const char> var = getstr(list->term);
	list = list->next;
	SRef<Term> output = list->term;
	list = list->next;
	SRef<Term> cmd = list->term;

	if ((pid = pipefork(p, NULL)) == 0) {
		try {
			close(p[1]);
			mvfd(p[0], 0);
			exit(exitstatus(eval1(output.uget(), evalflags &~ eval_inchild)));
		} catch (List *e) {
			eprint("Received error in %%writeto (>{}) child process:\n");
			print_exception(e);
			exit(9);
		}
	}

	close(p[0]);
	list = mklist(mkstr(str(DEVFD_PATH, p[1])), NULL);

	try {
		Push push(var.uget(), list.uget());
		list = eval1(cmd.uget(), evalflags);
	} catch (List *e) {
		close(p[1]);
		ewaitfor(pid);
		throwE(e);
	}

	close(p[1]);
	status = ewaitfor(pid);
	printstatus(0, status);
	return list;
}
#endif

#define	BUFSIZE	4096

static List *bqinput(const char *sep, int fd) {
	long n;
	char in[BUFSIZE];
	startsplit(sep, true);

restart:
	while ((n = eread(fd, in, sizeof in)) > 0)
		splitstring(in, n, false);
	SIGCHK();
	if (n == -1) {
		if (errno == EINTR)
			goto restart;
		close(fd);
		fail("$&backquote", "backquote read: %s", esstrerror(errno));
	}
	return endsplit().release();
}

PRIM(backquote) {
	int pid, p[2], status;
	
	caller = "$&backquote";
	if (list == NULL)
		fail(caller, "usage: backquote separator command [args ...]");

	SRef<const char> sep = getstr(list->term);
	list = list->next;

	if ((pid = pipefork(p, NULL)) == 0) {
		try {
			mvfd(p[1], 1);
			close(p[0]);
			exit(exitstatus(eval(list, NULL, evalflags | eval_inchild)));
		} catch (List *e) {
			eprint("%%backquote received exception from child process: ");
			print_exception(e);
			exit(9);
		}
	}

	close(p[1]);
	gcdisable();
	list = bqinput(sep.uget(), p[0]);
	close(p[0]);
	status = ewaitfor(pid);
	printstatus(0, status);
	list = mklist(mkstr(mkstatus(status)), list);
	gcenable();
	SIGCHK();
	return list;
}

PRIM(newfd) {
	if (list != NULL)
		fail("$&newfd", "usage: $&newfd");
	return mklist(mkstr(str("%d", newfd())), NULL);
}

/* read1 -- read one byte */
static int read1(int fd) {
	int nread;
	unsigned char buf;
	do {
		nread = eread(fd, (char *) &buf, 1);
		SIGCHK();
	} while (nread == -1 && errno == EINTR);
	if (nread == -1)
		fail("$&read", esstrerror(errno));
	return nread == 0 ? EOF : buf;
}

PRIM(read) {
	int c;
	int fd = fdmap(0);

	static Buffer *buffer = NULL;
	if (buffer != NULL)
		freebuffer(buffer);
	buffer = openbuffer(0);

	while ((c = read1(fd)) != EOF && c != '\n')
		buffer = bufputc(buffer, c);

	if (c == EOF && buffer->current == 0) {
		freebuffer(buffer);
		buffer = NULL;
		return NULL;
	} else {
		List *result = mklist(mkstr(sealcountedbuffer(buffer)), NULL);
		buffer = NULL;
		return result;
	}
}

extern Dict *initprims_io(Dict *primdict) {
	X(openfile);
	X(close);
	X(dup);
	X(pipe);
	X(backquote);
	X(newfd);
	X(here);
#ifdef HAVE_DEV_FD
	X(readfrom);
	X(writeto);
#endif
	X(read);
	return primdict;
}
