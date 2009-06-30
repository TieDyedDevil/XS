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

void test_streq2() {
#define TRUE(y, x1, x2) assert_true(streq2(y, x1, x2))
#define FALSE(y, x1, x2) assert_false(streq2(y, x1, x2))
	TRUE("", "", "");
	TRUE(" ", " ", "");
	TRUE("test_true", "test", "_true");
	TRUE("test_true", "test_true", "");
	FALSE("", " ", "");
	FALSE("test_false", "test", "_fals");
	FALSE("test_false", "test", "_falsee");
	FALSE("test_false", "test", "_falsx");
#undef TRUE
#undef FALSE
}

TestSuite *util_tests() {
    TestSuite *suite = create_test_suite();
    add_test(suite, test_isabsolute);
    add_test(suite, test_streq2);
    return suite;
}
