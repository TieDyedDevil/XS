#include "cgreen/cgreen.h"
char *utoa(unsigned long u, char *t, unsigned int radix, const char *digit);

void test_utoa() {
    typedef struct {
        int num, radix;
        const char *expected;
    } test;
    const static test TESTS[] = { 
        { 0, 1, "0" },
        { 1, 2, "1" },
        { 2, 2, "10"},
        { 3, 2, "11"},
        { 7, 6, "11"},
        { 9, 6, "13"},
        { 9, 9, "10"},
        { 9, 10,"9" },
        { 135, 10, "135"},
        { 80, 16, "50" },
        { 255, 16, "FF" },
    };
    const static int NUM_TESTS = sizeof(TESTS) / sizeof(test);
    const char* digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    char t1[128] = {0,};

    for (int i = 0; i < NUM_TESTS; ++i)
    {
        char *z = utoa(TESTS[i].num, t1, TESTS[i].radix, digits);
        *z = '\0';
        assert_string_equal(t1,TESTS[i].expected);
    }
}

TestSuite *words_tests() {
    TestSuite *suite = create_test_suite();
    add_test(suite, test_utoa);
    return suite;
}
