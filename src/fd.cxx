/* fd.cxx -- file descriptor manipulations */

#include "xs.hxx"
#include <vector>
using std::vector;

/* mvfd -- duplicate a fd and close the old */
extern void mvfd(int old, int newFd) {
	if (old != newFd) {
		int fd = dup2(old, newFd);
		if (fd == -1)
			fail("xs:mvfd", "dup2: %s", esstrerror(errno));
		assert(fd == newFd);
		close(old);
	}
}


/*
 * deferred file descriptor operations
 *	we maintain a stack of file descriptor operations as they occur,
 *	if we're operating in the context of a parent shell.  (if we're
 *	already in a forked process, we just do them.)  the operations
 *	are actually done at closefds() time.
 */

struct Defer {
	Defer(int _realfd, int _userfd) : realfd(_realfd), userfd(_userfd) {
		registerfd(&realfd, true);
	}
	Defer(const Defer& old) : realfd(old.realfd), userfd(old.userfd) {
		registerfd(&realfd, true);
	}
	~Defer() {
		unregisterfd(&realfd);
	}
	int realfd, userfd;
};

static vector<Defer> deftab;

static void dodeferred(int realfd, int userfd) {
	assert(userfd >= 0);
	releasefd(userfd);

	if (realfd == -1)
		close(userfd);
	else {
		assert(realfd >= 0);
		mvfd(realfd, userfd);
	}
}

static int pushdefer(bool parent, int realfd, int userfd) {
	if (parent) {
		Defer d(realfd, userfd);
		deftab.push_back(d);
		return deftab.size() - 1;
	} else {
		dodeferred(realfd, userfd);
		return UNREGISTERED;
	}
}

extern int defer_mvfd(bool parent, int old, int newFd) {
	assert(old >= 0);
	assert(newFd >= 0);
	return pushdefer(parent, old, newFd);
}

extern int defer_close(bool parent, int fd) {
	assert(fd >= 0);
	return pushdefer(parent, -1, fd);
}

extern void undefer(int ticket) {
	if (ticket != UNREGISTERED) {
		assert(ticket >= 0);
		assert (not deftab.empty());
		assert(ticket == deftab.size() - 1);
		if (deftab.rbegin()->realfd != -1)
			close(deftab.rbegin()->realfd);
		deftab.pop_back();
	}
}

/* fdmap -- turn a deferred (user) fd into a real fd */
extern int fdmap(int fd) {
	for(vector<Defer>::reverse_iterator defer = deftab.rbegin(); 
	    defer != deftab.rend();
	    ++defer) 
	{
		if (fd == defer->userfd) {
			fd = defer->realfd;
			if (fd == -1)
				return -1;
		}
	}
	return fd;
}

/* remapfds -- apply the fd map to the current file descriptor table */
static void remapfds(void) {
	foreach (Defer& defer, deftab)
		dodeferred(defer.realfd, defer.userfd);
	deftab.clear();
}


/*
 * the registered file descriptor list
 *	this is actually a list of pointers to file descriptors.
 *	when we start to work with a user-defined fd, we scan
 *	this list (releasefds) and it an entry matches the user
 *	defined one, we dup it to a different number.  when we fork,
 *	we close all the descriptors on this list.
 */

typedef struct {
	int *fdp;
	bool closeonfork;
} Reserve;

static Reserve *reserved = NULL;
static int rescount = 0, resmax = 0;

/* registerfd -- reserve a file descriptor for xs */
extern void registerfd(int *fdp, bool closeonfork) {
#if ASSERTIONS
	int i;
	for (i = 0; i < rescount; i++)
		assert(fdp != reserved[i].fdp);
#endif
	if (rescount >= resmax) {
		resmax += 10;
		reserved = reinterpret_cast<Reserve*>(erealloc(reserved,
                                                      resmax*sizeof (Reserve)));
	}
	reserved[rescount].fdp = fdp;
	reserved[rescount].closeonfork = closeonfork;
	rescount++;
}

/* unregisterfd -- give up our hold on a file descriptor */
extern void unregisterfd(int *fdp) {
	int i;
	assert(reserved != NULL);
	assert(rescount > 0);
	for (i = 0; i < rescount; i++)
		if (reserved[i].fdp == fdp) {
			reserved[i] = reserved[--rescount];
			return;
		}
	panic("%x not on file descriptor reserved list", fdp);
}

/* closefds -- close file descriptors after a fork() */
extern void closefds(void) {
	int i;
	remapfds();
	for (i = 0; i < rescount; i++) {
		Reserve *r = &reserved[i];
		if (r->closeonfork) {
			int fd = *r->fdp;
			if (fd >= 3)
				close(fd);
			*r->fdp = -1;
		}
	}
}

/* releasefd -- release a specific file descriptor from its xs uses */
extern void releasefd(int n) {
	int i;
	assert(n >= 0);
	for (i = 0; i < rescount; i++) {
		int *fdp = reserved[i].fdp;
		int fd = *fdp;
		if (fd == n) {
			*fdp = dup(fd);
			if (*fdp == -1) {
				assert(errno != EBADF);
				fail("xs:releasefd", "%s", esstrerror(errno));
			}
			close(fd);
		}
	}
}

/* isdeferred -- is this file descriptor on the deferral list */
static bool isdeferred(int fd) {
	foreach (Defer& defer, deftab)
		if (defer.userfd == fd)
			return true;
	return false;
}

/* newfd -- return a new, free file descriptor */
extern int newfd(void) {
	int i;
	for (i = 3;; i++)
		if (!isdeferred(i)) {
			int fd = dup(i);
			if (fd == -1) {
				if (errno != EBADF)
					fail("$&newfd", "%s",
                                             esstrerror(errno));
				return i;
			} else if (isdeferred(fd)) {
				int n = newfd();
				close(fd);
				return n;
			} else {
				close(fd);
				return fd;
			}
		}
}
