#define WORD 257
#define QWORD 258
#define LOCAL 259
#define LET 260
#define FOR 261
#define CLOSURE 262
#define FN 263
#define ANDAND 264
#define BACKBACK 265
#define EXTRACT 266
#define CALL 267
#define COUNT 268
#define DUP 269
#define FLAT 270
#define OROR 271
#define PRIM 272
#define REDIR 273
#define SUB 274
#define NL 275
#define ENDFILE 276
#define ERROR 277
#define PIPE 278
typedef union {
	Tree *tree;
	char *str;
	NodeKind kind;
} YYSTYPE;
extern YYSTYPE yylval;
