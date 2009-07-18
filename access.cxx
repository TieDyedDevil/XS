/* access.c -- access testing and path searching ($Revision: 1.2 $) */

#define	REQUIRE_STAT	1
#include <sys/param.h>

#include "es.hxx"
#include "prim.hxx"

#define	READ	4
#define	WRITE	2
#define	EXEC	1

#define	USER	6
#define	GROUP	3
#define	OTHER	0

/* ingroupset -- determine whether gid lies in the user's set of groups */
static bool ingroupset(gidset_t gid) {
#ifdef NGROUPS
	static int ngroups = -2;
	static gidset_t gidset[NGROUPS];
	if (ngroups == -2)
		ngroups = getgroups(NGROUPS, gidset);

	for (int i = 0; i < ngroups; i++)
		if (gid == gidset[i])
			return true;
#endif
	return false;
}

static uid_t tperm_uid;
static uid_t tperm_gid;
static int testperm_init(struct stat*, int);
static int testperm_real(struct stat*, int);
static int (*testperm)(struct stat*, int) = testperm_init;

static int testperm_init(struct stat *stat, int perm) {
    tperm_uid = geteuid();
    tperm_gid = getegid();
    testperm = testperm_real;
    return testperm_real(stat, perm);
}

static int testperm_real(struct stat *stat, int perm) {
	int mask;
	if (perm == 0)
		return 0;
	mask = (tperm_uid == 0)
		? (perm << USER) | (perm << GROUP) | (perm << OTHER)
		: (perm <<
			((tperm_uid == stat->st_uid)
				? USER
				: ((tperm_gid == stat->st_gid  || ingroupset(stat->st_gid))
					? GROUP
					: OTHER)));
	return (stat->st_mode & mask) ? 0 : EACCES;
}

static int testfile(const char *path, int perm, mode_t type) {
	struct stat st;
#ifdef S_IFLNK
	if (type == S_IFLNK) {
		if (lstat(path, &st) == -1)
			return errno;
	} else
#endif
		if (stat(path, &st) == -1)
			return errno;
	if (type != 0 && (st.st_mode & S_IFMT) != type)
		return EACCES;		/* what is an appropriate return value? */
	return testperm(&st, perm);
}

static const char *pathcat(const char *prefix, const char *suffix) {
	char *s;
	size_t plen, slen, len;
	static char *pathbuf = NULL;
	static size_t pathlen = 0;

	if (*prefix == '\0')
		return suffix;
	if (*suffix == '\0')
		return prefix;

	plen = strlen(prefix);
	slen = strlen(suffix);
	len = plen + slen + 2;		/* one for '/', one for '\0' */
	if (pathlen < len) {
		pathlen = len;
		pathbuf = reinterpret_cast<char*>(erealloc(pathbuf, pathlen));
	}

	memcpy(pathbuf, prefix, plen);
	s = pathbuf + plen;
	if (s[-1] != '/')
		*s++ = '/';
	memcpy(s, suffix, slen + 1);
	return pathbuf;
}

PRIM(access) {
	int c, perm = 0, type = 0, estatus = ENOENT;
	bool first = false, exception = false;
	const char *suffix = NULL;
	List *lp;
	const char * const usage = "access [-n name] [-1e] [-rwx] [-fdcblsp] path ...";

	gcdisable();
	esoptbegin(list, "$&access", usage);
	while ((c = esopt("bcdefln:prswx1")) != EOF)
		switch (c) {
		case 'n':	suffix = getstr(esoptarg());	break;
		case '1':	first = true;			break;
		case 'e':	exception = true;		break;
		case 'r':	perm |= READ;			break;
		case 'w':	perm |= WRITE;			break;
		case 'x':	perm |= EXEC;			break;
		case 'f':	type = S_IFREG;			break;
		case 'd':	type = S_IFDIR;			break;
		case 'c':	type = S_IFCHR;			break;
		case 'b':	type = S_IFBLK;			break;
#ifdef S_IFLNK
		case 'l':	type = S_IFLNK;			break;
#endif
#ifdef S_IFSOCK
		case 's':	type = S_IFSOCK;		break;
#endif
#ifdef S_IFIFO
		case 'p':	type = S_IFIFO;			break;
#endif
		default:
			esoptend();
			fail("$&access", "access -%c is not supported on this system", c);
		}
	list = esoptend();

	for (lp = NULL; list != NULL; list = list->next) {
		const char *name = strdup(getstr(list->term));
		if (suffix != NULL)
			name = pathcat(name, suffix);
		int error = testfile(name, perm, type);

		if (first) {
			if (error == 0) {
				SRef<List> result = 
					mklist(mkstr(suffix == NULL
							? name
							: gcdup(name)),
					       NULL);
				gcenable();
				return result.release();
			} else if (error != ENOENT)
				estatus = error;
		} else
			lp = mklist(mkstr(error == 0 ? "0" : esstrerror(error)),
				    lp);
	}

	if (first && exception) {
		gcenable();
		if (suffix)
			fail("$&access", "%s: %s", suffix, esstrerror(estatus));
		else
			fail("$&access", "%s", esstrerror(estatus));
	}

	SRef<List> result = reverse(lp);
	gcenable();
	return result.release();
}

extern Dict *initprims_access(Dict *primdict) {
	X(access);
	return primdict;
}

extern char *checkexecutable(const char *file) {
	int err = testfile(file, EXEC, S_IFREG);
	return err == 0 ? NULL : esstrerror(err);
}
