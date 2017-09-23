/* proc.cxx -- process control system calls */

#include "xs.hxx"
#include <list>
using std::list;

/* TODO: the rusage code for the time builtin really needs to be cleaned up */

#if HAVE_WAIT3
#include <sys/time.h>
#include <sys/resource.h>
#endif

bool hasforked = false;

struct Proc {
	int pid;
	int status;
#if HAVE_WAIT3
	struct rusage rusage;
#endif
	bool alive, background;
};
list<Proc> proclist;

/* mkproc -- create a Proc structure */
extern Proc *mkproc(int pid, bool background) {
	Proc proc;
	proc.pid = pid;
	proc.alive = true;
	proc.background = background;
	proclist.push_front(proc);
	return &*proclist.begin();
}

/* efork -- fork (if necessary) and clean up as appropriate */
extern int efork(bool parent, bool background) {
	if (parent) {
		int pid = fork();
		switch (pid) {
		default:	/* parent */
			mkproc(pid, background);
			return pid;
		case 0:		/* child */
			proclist.clear();
			hasforked = true;
			break;
		case -1:
			fail("xs:efork", "fork: %s", esstrerror(errno));
		}
	}
	closefds();
	setsigdefaults();
	return 0;
}

#if HAVE_WAIT3
static struct rusage wait_rusage;
#endif

/* dowait -- a wait wrapper that interfaces with signals */
static int dowait(int *statusp) {
	int n;
	interrupted = false;
	if (!xs_setjmp(slowlabel)) {
		slow = true;
		n = interrupted ? -2 :
#if HAVE_WAIT3
			wait3((int *) statusp, 0, &wait_rusage);
#else
			wait((int *) statusp);
#endif
	} else
		n = -2;
	slow = false;
	if (n == -2) {
		errno = EINTR;
		n = -1;
	}
	return n;
}

/* reap -- mark a process as dead and attach its exit status */
static void reap(int pid, int status) {
	foreach (Proc &proc, proclist)
		if (proc.pid == pid) {
			assert(proc.alive);
			proc.alive = false;
			proc.status = status;
#if HAVE_WAIT3
			proc.rusage = wait_rusage;
#endif
			return;
		}
}

/* ewait -- wait for a specific process to die, or any process if pid == 0 */
extern int ewait(int pid, bool interruptible, void *rusage) {
top:
	for (list<Proc>::iterator proc = proclist.begin();
             proc != proclist.end(); ++proc)
		if (proc->pid == pid || (pid == 0 && !proc->alive)) {
			int status;
			if (proc->alive) {
				int deadpid;
				while ((deadpid = dowait(&proc->status)) != pid)
					if (deadpid != -1)
						reap(deadpid, proc->status);
					else if (errno != EINTR) {
						fail("xs:ewait", "wait: %s",
                                                     esstrerror(errno));
					}
					else if (interruptible)
						SIGCHK();
				proc->alive = false;
#if HAVE_WAIT3
				proc->rusage = wait_rusage;
#endif
			}
			status = proc->status;
			if (proc->background)
				printstatus(proc->pid, status);
#if HAVE_WAIT3
			if (rusage != NULL)
				memcpy(rusage, &proc->rusage,
                                       sizeof(struct rusage));
#else
			assert(rusage == NULL);
#endif
			proclist.erase(proc);
			return status;
		}
	if (pid == 0) {
		int status;
		while ((pid = dowait(&status)) == -1) {
			if (errno != EINTR) {
				fail("xs:ewait", "wait: %s", esstrerror(errno));
			}
			if (interruptible)
				SIGCHK();
		}
		goto top;
	}
	fail("xs:ewait", "wait: %d is not a child of this shell", pid);
	NOTREACHED;
}

#include "prim.hxx"

PRIM(apids) {
	(void)list;
	(void)binding;
	(void)evalflags;
	List* lp = NULL;
	foreach (Proc &p, proclist)
		if (p.background && p.alive) {
			Term* t = mkstr(str("%d", p.pid));
			lp = mklist(t, lp);
		}
	/* TODO: sort the return value, but by number? */
	return lp;
}

PRIM(wait) {
	(void)binding;
	(void)evalflags;
	int pid;
	if (list == NULL)
		pid = 0;
	else if (list->next == NULL) {
		pid = atoi(getstr(list->term));
		if (pid <= 0) {
			fail("$&wait", "wait: %d: bad pid", pid);
			NOTREACHED;
		}
	} else {
		fail("$&wait", "usage: wait [pid]");
		NOTREACHED;
	}
	return mklist(mkstr(mkstatus(ewait(pid, true, NULL))), NULL);
}

extern void initprims_proc(Prim_dict& primdict) {
	X(apids);
	X(wait);
}
