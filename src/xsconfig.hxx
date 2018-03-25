/* xsconfig.hxx -- xs(1) configuration parameters */

/*
 * Compile time options
 *
 *	ASSERTIONS
 *		if this is on, asserts will be checked, raising errors on
 *		actual assertion failure.
 */

/* Version number of package */
#define VERSION "1.2"

#ifndef	ASSERTIONS
#define	ASSERTIONS		0
#endif

#define	DEVFD_PATH		"/dev/fd/%d"

#define	INITIAL_PATH		"/usr/bin", "/bin", ""

/* why is this here? */
#define REF_ASSERTIONS		0

/* Define to the type of elements in the array set by `getgroups'. Usually
   this is either `int' or `gid_t'. */
#define GETGROUPS_T gid_t

/* Define to 1 if you have the <tr1/unordered_map> header file. */
#define HAVE_TR1_UNORDERED_MAP 1

/* Type of data in structure from getrlimit */
#define LIMIT_T rlim_t 
