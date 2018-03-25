/* xsconfig.hxx -- xs(1) configuration parameters */

/* Version number of package */
#define VERSION "1.2"

#ifndef	ASSERTIONS
#define	ASSERTIONS		0
#endif

#define	DEVFD_PATH		"/dev/fd/%d"

#define	INITIAL_PATH		"/usr/bin", "/bin", ""
