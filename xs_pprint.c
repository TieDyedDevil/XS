#include <stdio.h>

/* Trivial prettyprinter for canonical-form xs programs */
#define INDENT 4
int main(int argc, char *argv[]) {
	int i;
	for (i = 1; i < argc; ++i) {
		fputs(argv[i], stdout);
		putchar(' ');
	}
	unsigned ch, depth = argc == 1 ? 0 : 1;
	while ((ch = getchar()) != EOF) {
		if (ch == '{') {
			if (depth) putchar('\\');
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
