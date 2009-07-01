#include "cgreen/cgreen.h"
#include <string.h>
#include "es.h"

void *test_glob() {
	const char **dirnames = {
		"abc",
		"bbc",
		".abc",
		"2222",
		"3333",
	};
	char *fn = strdup("/dev/shm/xstestdirXXXXXX");
	mkdtemp(fn);
	char *dtmp = malloc(100);

	for(int i = 0; i < arraysize(dirnames); ++i) {
		strcpy(dtmp, fn);
		strcat(dtmp, "/");
		strcat(dtmp, dirnames[i]);
		mkdir(dtmp);
	}
	free(dtmp);

	char *command = malloc(110);
	const char *cmd_base = "rm -r ";
	strcpy(command, cmd_base);
	strcpy(command + strlen(cmd_base), fn);
	system(command);
	free(fn);
}

TestSuite *glob_tests() {
    TestSuite *suite = create_test_suite();
    add_test(suite, test_glob);
    return suite;
}
