#include <stdio.h>

/* Trivial prettyprinter for canonical-form xs programs */
#define INDENT 4
int main(int argc, char *argv[]) {
	unsigned ch, depth = 0;
	while ((ch = getchar()) != EOF) {
		if (ch == '{') {
			putchar('\n');
			int i;
			for (i = 0; i < INDENT*depth; ++i)
				putchar(' ');
			++depth;
		}
		if (ch == '}') {
			--depth;
		}
		putchar(ch);
	}
}
