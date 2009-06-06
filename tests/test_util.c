#include "cgreen/cgreen.h"

void test_isabsolute() {
	const char *test_true[] = {
		"/",
		"./",
		"../",
		"/usr",
		"/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"./././../t",
		"../.././a"
	};
	const char *test_false[] = {
		"a",
		"a/",
		"abc/",
		"x/",
		"\\/ls",
		".a/",
		"..b/",
		"a/.././"
	};
	for (const char **t = test_true;
	     t != test_true + sizeof(test_true) / sizeof(const char *);
	     ++t) assert_true(isabsolute(*t));
	for (const char **t = test_false;
	     t != test_false + sizeof(test_false) / sizeof(const char *);
	     ++t) assert_false(isabsolute(*t));
}

TestSuite *util_tests() {
    TestSuite *suite = create_test_suite();
    add_test(suite, test_isabsolute);
    return suite;
}
