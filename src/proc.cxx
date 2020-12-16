/* proc.cxx -- process control system calls */

#include "xs.hxx"
#include "prim.hxx"
#include <list>
using std::list;
#include <sys/resource.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>

bool hasforked = false;

struct Proc {
	int pid;
	int status;
	struct termios tmodes;
	struct rusage rusage;
	bool alive, background;
};
list<Proc> proclist;

/* isforeground -- True when we have control of the terminal */
extern bool isforeground(void) {
	int tcpgrp = tcgetpgrp(0);
	return tcpgrp > 0 && tcpgrp == getpgrp();
}

/* proc_tmodes -- Get a pointer to tmodes */
extern struct termios* proc_tmodes(int pid) {
	foreach (Proc &proc, proclist)
		if (proc.pid == pid && proc.alive)
			return &proc.tmodes;
	return NULL;
}

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
			if (isinteractive()) {
				if (setpgid(pid, pid))
					fail("xs:efork", "setpgid: %s",
						xsstrerror(errno));
				if (isforeground()) {
					if (tcsetpgrp(0, pid))
						fail("xs:efork",
							"tcsetpgrp: %s",
							xsstrerror(errno));
				}
			}
			mkproc(pid, background);
			return pid;
		case 0:		/* child */
			if (isinteractive()) {
				if (setpgid(0, 0))
					fail("xs:efork", "setpgid: %s",
						xsstrerror(errno));
				if (isforeground()) {
					if (tcsetpgrp(0, getpgrp()))
						fail("xs:efork",
							"tcsetpgrp: %s",
							xsstrerror(errno));
				}
			}
			proclist.clear();
			hasforked = true;
			break;
		case -1:
			fail("xs:efork", "fork: %s", xsstrerror(errno));
		}
	}
	closefds();
	setsigdefaults();
	return 0;
}

static struct rusage wait_rusage;

/* dowait -- a wait wrapper that interfaces with signals */
static int dowait(int *statusp) {
	int n;
	interrupted = false;
	if (!xs_setjmp(slowlabel)) {
		slow = true;
		n = interrupted ? -2 :
			wait3((int *) statusp, WUNTRACED, &wait_rusage);
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
			proc.rusage = wait_rusage;
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
                                                     xsstrerror(errno));
					}
					else if (interruptible)
						SIGCHK();
				proc->alive = false;
				proc->rusage = wait_rusage;
			}
			status = proc->status;
			if (proc->background)
				printstatus(proc->pid, status);
			if (rusage != NULL)
				memcpy(rusage, &proc->rusage,
                                       sizeof(struct rusage));
			proclist.erase(proc);
			return status;
		}
	if (pid == 0) {
		int status;
		while ((pid = dowait(&status)) == -1) {
			if (errno != EINTR) {
				fail("xs:ewait", "wait: %s", xsstrerror(errno));
			}
			if (interruptible)
				SIGCHK();
		}
		goto top;
	}
	fail("xs:ewait", "%d is not a child of this shell", pid);
	NOTREACHED;
}

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
			fail("$&wait", "%d: bad pid", pid);
			NOTREACHED;
		}
	} else {
		fail("$&wait", "usage: $&wait [pid]");
		NOTREACHED;
	}
	return mklist(mkstr(mkstatus(ewait(pid, true, NULL))), NULL);
}

extern void initprims_proc(Prim_dict& primdict) {
	X(apids);
	X(wait);
}
