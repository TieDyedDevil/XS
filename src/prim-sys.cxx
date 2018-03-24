/* prim-sys.cxx -- system call primitives */

#define	REQUIRE_IOCTL	1

#include <time.h>
#include "xs.hxx"
#include "prim.hxx"

# define BSD_LIMITS 1

#if BSD_LIMITS || BUILTIN_TIME
#include <sys/time.h>
#include <sys/resource.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>

PRIM(newpgrp) {
	(void)binding;
	(void)evalflags;
	int pid;
	if (list != NULL)
		fail("$&newpgrp", "usage: newpgrp");
	pid = getpid();
	setpgrp(pid, pid);
#ifdef TIOCSPGRP
	{
		Sigeffect sigtstp = esignal(SIGTSTP, sig_ignore);
		Sigeffect sigttin = esignal(SIGTTIN, sig_ignore);
		Sigeffect sigttou = esignal(SIGTTOU, sig_ignore);
		ioctl(2, TIOCSPGRP, &pid);
		esignal(SIGTSTP, sigtstp);
		esignal(SIGTTIN, sigttin);
		esignal(SIGTTOU, sigttou);
	}
#endif
	return ltrue;
}

PRIM(background) {
	(void)binding;
	int pid = efork(true, true);
	if (pid == 0) {
#if JOB_PROTECT
		/* job control safe version: put it in a new pgroup. */
		setpgrp(0, getpid());
#endif
		mvfd(eopen("/dev/null", oOpen), 0);
		exit(exitstatus(eval(list, NULL, evalflags | eval_inchild)));
	}
	return mklist(mkstr(str("%d", pid)), NULL);
}

PRIM(fork) {
	(void)binding;
	int pid, status;
	pid = efork(true, false);
	if (pid == 0)
		exit(exitstatus(eval(list, NULL, evalflags | eval_inchild)));
	status = ewaitfor(pid);
	SIGCHK();
	printstatus(0, status);
	return mklist(mkstr(mkstatus(status)), NULL);
}

PRIM(run) {
	(void)binding;
	if (list == NULL)
		fail("$&run", "usage: %%run file argv0 argv1 ...");
	const char *file = getstr(list->term);
	list = forkexec(file, list->next, (evalflags & eval_inchild) != 0);
	return list;
}

PRIM(umask) {
	(void)binding;
	(void)evalflags;
	if (list == NULL) {
		int mask = umask(0);
		umask(mask);
		print("%04o\n", mask);
		return ltrue;
	}
	if (list->next == NULL) {
		int mask;
		char *t;
		const char *s = getstr(list->term);
		mask = strtol(s, &t, 8);
		if ((t != NULL && *t != '\0') || ((unsigned) mask) > 07777)
			fail("$&umask", "bad umask: %s", s);
		umask(mask);
		return ltrue;
	}
	fail("$&umask", "usage: umask [mask]");
	NOTREACHED;
}

PRIM(cd) {
	(void)binding;
	(void)evalflags;
	if (list == NULL || list->next != NULL)
		fail("$&cd", "usage: $&cd directory");
	const char *dir = getstr(list->term);
	if (chdir(dir) == -1)
		fail("$&cd", "chdir %s: %s", dir, esstrerror(errno));
	return ltrue;
}

PRIM(setsignals) {
	(void)binding;
	(void)evalflags;
	int i;
	Sigeffect effects[NSIG];
	for (i = 0; i < NSIG; i++)
		effects[i] = sig_default;
	iterate (list) {
		int sig;
		const char *s = getstr(list->term);
		Sigeffect effect = sig_catch;
		switch (*s) {
		case '-':	effect = sig_ignore;	s++; break;
		case '/':	effect = sig_noop;	s++; break;
		case '.':	effect = sig_special;	s++; break;
		}
		sig = signumber(s);
		if (sig < 0)
			fail("$&setsignals", "unknown signal: %s", s);
		effects[sig] = effect;
	}
	blocksignals();
	setsigeffects(effects);
	unblocksignals();
	return mksiglist();
}

/*
 * limit builtin -- this is too much code for what it gives you
 */

#if BSD_LIMITS
typedef struct Suffix Suffix;
struct Suffix {
	const char *name;
	long amount;
	const Suffix *next;
};

static const Suffix sizesuf[] = {
	{ "g",	1024*1024*1024,	sizesuf + 1 },
	{ "m",	1024*1024,	sizesuf + 2 },
	{ "k",	1024,		NULL },
};

static const Suffix timesuf[] = {
	{ "h",	60 * 60,	timesuf + 1 },
	{ "m",	60,		timesuf + 2 },
	{ "s",	1,		NULL },
};

typedef struct {
	const char *name;
	int flag;
	const Suffix *suffix;
} Limit;

static const Limit limits[] = {

	{ "cputime",		RLIMIT_CPU,	timesuf },
	{ "filesize",		RLIMIT_FSIZE,	sizesuf },
	{ "datasize",		RLIMIT_DATA,	sizesuf },
	{ "stacksize",		RLIMIT_STACK,	sizesuf },
	{ "coredumpsize",	RLIMIT_CORE,	sizesuf },

#ifdef RLIMIT_RSS	/* SysVr4 does not have this */
	{ "memoryuse",		RLIMIT_RSS,	sizesuf },
#endif
#ifdef RLIMIT_VMEM	/* instead, they have this! */
	{ "memorysize",		RLIMIT_VMEM,	sizesuf },
#endif

#ifdef RLIMIT_MEMLOCK	/* 4.4bsd adds an unimplemented limit
			   on non-pageable memory */
	{ "lockedmemory",	RLIMIT_CORE,	sizesuf },
#endif

#ifdef RLIMIT_NOFILE	/* SunOS 4.1 adds a limit on file descriptors */
	{ "descriptors",	RLIMIT_NOFILE,	NULL },
#elif defined(RLIMIT_OFILE) /* but 4.4bsd uses this name for it */
	{ "descriptors",	RLIMIT_OFILE,	NULL },
#endif

#ifdef RLIMIT_NPROC	/* 4.4bsd adds a limit on child processes */
	{ "processes",		RLIMIT_NPROC,	NULL },
#endif

	{ NULL, 0, NULL }
};

static void printlimit(const Limit *limit, bool hard) {
	struct rlimit rlim;
	LIMIT_T lim;
	getrlimit(limit->flag, &rlim);
	if (hard)
		lim = rlim.rlim_max;
	else
		lim = rlim.rlim_cur;
	if (lim == (LIMIT_T) RLIM_INFINITY)
		print("%-8s\tunlimited\n", limit->name);
	else {
		const Suffix *suf = limit->suffix;

		iterate (suf)
			if (lim % suf->amount == 0
                            && (lim != 0 || suf->amount > 1)) {
				lim /= suf->amount;
				break;
			}
		print("%-8s\t%d%s\n", limit->name, lim,
                      (suf == NULL || lim == 0) ? "" : suf->name);
	}
}

static LIMIT_T parselimit(const Limit *limit, const char *s) {
	LIMIT_T lim;
	const Suffix *suf = limit->suffix;
	if (streq(s, "unlimited"))
		return RLIM_INFINITY;
	if (!isdigit(*s))
		fail("$&limit", "%s: bad limit value", s);

	const char *t;
	if (suf == timesuf && 
	    (t = strchr(s, ':')) != NULL) {
		char *u;
		lim = strtol(s, &u, 0) * 60;
		if (u != t)
			fail("$&limit", "%s %s: bad limit value",
				limit->name, s);
		char *x;
		lim += strtol(u + 1, &x, 0);
		if (x != NULL && *x == ':')
			lim = lim * 60 + strtol(x + 1, &x, 0);
		if (x != NULL && *x != '\0')
			fail("$&limit", "%s %s: bad limit value",
				limit->name, s);
	} else {
		char *x;
		lim = strtol(s, &x, 0);
		if (x != NULL && *x != '\0')
			for (;; suf = suf->next) {
				if (suf == NULL)
					fail("$&limit",
						"%s %s: bad limit value",
						limit->name, s);
				if (streq(suf->name, x)) {
					lim *= suf->amount;
					break;
				}
			}
	}
	return lim;
}

PRIM(limit) {
	(void)binding;
	(void)evalflags;
	const Limit *lim = limits;
	bool hard = false;

	if (list != NULL && streq(getstr(list->term), "-h")) {
		hard = true;
		list = list->next;
	}

	if (!list)
		for (; lim->name != NULL; lim++)
			printlimit(lim, hard);
	else {
		const char *name = getstr(list->term);
		for (;; lim++) {
			if (lim->name == NULL)
				fail("$&limit", "%s: no such limit", name);
			if (streq(name, lim->name))
				break;
		}
		list = list->next;
		if (list == NULL)
			printlimit(lim, hard);
		else {
			LIMIT_T n;
			struct rlimit rlim;
			getrlimit(lim->flag, &rlim);
			n = parselimit(lim, getstr(list->term));
			if (hard)
				rlim.rlim_max = n;
			else
				rlim.rlim_cur = n;
			if (setrlimit(lim->flag, &rlim) == -1)
				fail("$&limit", "setrlimit: %s",
					esstrerror(errno));
		}
	}
	return ltrue;
}
#endif	/* BSD_LIMITS */

#if BUILTIN_TIME
PRIM(time) {
	(void)binding;

	int pid, status;
	time_t t0, t1;
	struct rusage r;

        /* do a garbage collection first to ensure reproducible results */
	GC_gcollect();
	t0 = time(NULL);
	pid = efork(true, false);
	if (pid == 0)
		exit(exitstatus(eval(list, NULL, evalflags | eval_inchild)));
	status = ewait(pid, false, &r);
	t1 = time(NULL);
	SIGCHK();
	printstatus(0, status);

	eprint(
		"%6ldr %5ld.%ldu %5ld.%lds\t%L\n",
		(long long) t1 - t0,
		(long long) r.ru_utime.tv_sec,
                (long long) (r.ru_utime.tv_usec / 100000),
		(long long) r.ru_stime.tv_sec,
                (long long) (r.ru_stime.tv_usec / 100000),
		list, " "
	);

	return mklist(mkstr(mkstatus(status)), NULL);
}
#endif	/* BUILTIN_TIME */

extern void initprims_sys(Prim_dict& primdict) {
	X(newpgrp);
	X(background);
	X(umask);
	X(cd);
	X(fork);
	X(run);
	X(setsignals);
#if BSD_LIMITS
	X(limit);
#endif
#if BUILTIN_TIME
	X(time);
#endif
}
