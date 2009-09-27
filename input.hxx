/* input.h -- definitions for es lexical analyzer ($Revision: 1.1.1.1 $) */
#ifndef INPUT_HXX
#define INPUT_HXX

#define	MAXUNGET	2		/* maximum 2 character pushback */

typedef struct Input Input;
struct Input {
	int (*get)(Input *self);
	int (*fill)(Input *self), (*rfill)(Input *self);
	void (*cleanup)(Input *self);
	Input *prev;
	const char *name;
	unsigned char *buf, *bufend, *bufbegin, *rbuf;
	size_t buflen;
	int unget[MAXUNGET];
	int ungot;
	int lineno;
	int fd;
	int runflags;
};
extern Input *input;

inline int RGETC() {
	return (*input->get)(input);
}

int GETC();
#define	UNGETC(c)	unget(input, c)


/* input.c */

extern void unget(Input *in, int c);
extern bool disablehistory;
extern void yyerror(const char *s);


/* token.c */

extern char dnw[];
extern int yylex(void);
extern void inityy(void);
extern void print_prompt2(void);
extern int passign;


/* parse.y */

extern Tree *parsetree;
extern int yyparse(void);


/* heredoc.c */

extern void emptyherequeue(void);
#endif
