#ifndef lint
static const char yysccsid[] = "@(#)yaccpar	1.9 (Berkeley) 02/21/93";
#endif

#include <stdlib.h>
#include <string.h>

#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYPATCH 20090221

#define YYEMPTY        (-1)
#define yyclearin      (yychar = YYEMPTY)
#define yyerrok        (yyerrflag = 0)
#define YYRECOVERING() (yyerrflag != 0)

/* compatibility with bison */
#ifdef YYPARSE_PARAM
/* compatibility with FreeBSD */
#ifdef YYPARSE_PARAM_TYPE
#define YYPARSE_DECL() yyparse(YYPARSE_PARAM_TYPE YYPARSE_PARAM)
#else
#define YYPARSE_DECL() yyparse(void *YYPARSE_PARAM)
#endif
#else
#define YYPARSE_DECL() yyparse(void)
#endif /* YYPARSE_PARAM */

extern int YYPARSE_DECL();

static int yygrowstack(void);
#define YYPREFIX "yy"
#line 4 "./parse.y"
/* Some yaccs insist on including stdlib.h */
#define _STDLIB_H
#include "es.h"
#include "input.h"
#include "syntax.h"
#line 23 "./parse.y"
typedef union {
	Tree *tree;
	char *str;
	NodeKind kind;
} YYSTYPE;
#line 46 "y.tab.c"
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
#define YYERRCODE 256
static const short yylhs[] = {                           -1,
    0,    0,   22,   22,    9,    9,    2,    2,    4,    4,
    5,    5,    3,    3,    3,    3,    3,    3,    3,    3,
    3,    3,    3,    3,   18,   18,   18,   19,   19,   14,
   14,   14,   13,   13,   13,   12,    8,    8,    7,    7,
   20,   20,   10,   10,    6,    6,    6,    6,    6,    6,
    6,    6,    6,    6,    6,    6,   11,   11,   15,   15,
   17,   17,   16,   16,   16,   23,   23,   24,   24,   21,
   21,   21,   21,    1,    1,    1,    1,    1,    1,    1,
    1,
};
static const short yylen[] = {                            2,
    2,    2,    1,    1,    1,    2,    1,    2,    2,    2,
    1,    2,    0,    1,    2,    2,    1,    7,    4,    4,
    4,    3,    3,    3,    1,    2,    2,    1,    2,    1,
    3,    3,    0,    1,    2,    4,    6,    2,    1,    3,
    1,    1,    1,    3,    1,    3,    3,    5,    2,    5,
    2,    2,    2,    2,    2,    3,    1,    1,    0,    2,
    0,    2,    0,    2,    2,    0,    2,    0,    1,    1,
    1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
    1,
};
static const short yydefred[] = {                         0,
    0,   57,   58,   70,   71,   72,   73,    0,    0,    0,
    0,    0,   28,    0,    0,    0,    0,    0,   63,    0,
    0,   59,    0,    0,    0,    0,   39,    0,   17,    0,
   45,    0,    0,   66,    3,    4,    2,   77,   78,   79,
   81,   80,   76,   74,   75,   42,   41,    0,   43,    0,
    0,   51,   52,   53,   54,    0,   69,    0,    0,    0,
    0,    0,    0,   11,    0,    0,   55,   66,   66,   66,
    9,   10,    6,    0,   16,    0,    1,    0,   27,    0,
    0,    0,    0,   56,    0,    0,   61,   65,   46,    0,
    0,   47,   12,    8,    0,   60,    0,    0,    0,   40,
    0,   67,    0,   44,    0,    0,    0,    0,    0,    0,
   21,   61,    0,   34,    0,   30,    0,    0,   50,   48,
    0,    0,   35,    0,   66,    0,   37,   32,    0,   31,
    0,
};
static const short yydgoto[] = {                         24,
   46,   62,   63,   64,   65,   47,   28,   29,   30,  106,
   31,   75,  116,  117,   66,   60,   85,   32,   33,   49,
   34,   37,   81,   76,
};
static const short yysindex[] = {                       438,
 -252,    0,    0,    0,    0,    0,    0,  745,  745,  745,
  745,  745,    0,  745, -247,  745,  -81,  745,    0,  745,
  623,    0,  745,    0,  126,  623,    0,  -61,    0, -252,
    0,  676,  623,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,  -51,    0,  702,
  -51,    0,    0,    0,    0,  -51,    0,  623, -237,  385,
  -51,  -84,  113,    0,  623, -112,    0,    0,    0,    0,
    0,    0,    0,  745,    0,  -16,    0,  -51,    0, -224,
  -34,  745, -102,    0,  745, -224,    0,    0,    0,  -51,
  745,    0,    0,    0,  623,    0,  365,  365,  365,    0,
  -81,    0,  780,    0,  623,  -51,  719,  -67, -224, -224,
    0,    0,  745,    0,  -35,    0,   38,  -65,    0,    0,
  745,  745,    0,  780,    0,  780,    0,    0,  365,    0,
 -232,
};
static const short yyrindex[] = {                       111,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   11,    0,    0,    0,
  504,    0,    0,    0, -219,  111,    0,  -11,    0,    0,
    0,  160,  394,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,  516,    0,    0,
  343,    0,    0,    0,    0,   36,    0,  394,  -33,    0,
  343,    0,  -63,    0,  504,    0,    0,    0,    0,    0,
    0,    0,    0,    3,    0,    0,    0,   58,    0,  752,
    0,    0,    0,    0,  451,  789,    0,    0,    0,  418,
  487,    0,    0,    0,  504,    0,  536,  536,  536,    0,
   80,    0,   60,    0,  504,  321,    0,    0,  791,  797,
    0,    0,  -60,    0,    4,    0,    0,    0,    0,    0,
   89,    3,    0,   60,    0,   60,    0,    0,  536,    0,
   93,
};
static const short yygindex[] = {                         0,
    0,  -53,  419,    9,    0,  993,    0,  -86,   40,  447,
  -47,  -48, -106,    0,   20,    0,  -57,    0,   41,  849,
    0,   47,  -54,  -15,
};
#define YYTABLESIZE 1122
static const short yytable[] = {                         49,
   80,   58,   49,   91,   49,  103,   49,   49,   26,   55,
   95,   94,   57,   97,   98,   99,  114,  128,   96,  130,
  105,   25,   35,   36,   25,   49,   25,   49,   25,  107,
   49,   68,   74,   80,   26,   96,   87,  114,   69,  114,
   92,  108,   82,   68,  101,   70,   68,   25,   68,   68,
   68,  118,   25,   70,  121,    5,    5,  120,  122,  127,
   49,    7,   49,   69,   68,   73,  123,   83,   29,   68,
  129,   29,   79,   29,   68,   29,   77,    0,  125,    0,
    0,    0,    0,    0,   25,  112,    0,    0,    0,   49,
   26,   49,   49,   26,   29,   26,  126,   26,    0,   29,
   33,    0,    0,    0,    0,    0,   68,    0,    0,    0,
    0,   25,   68,   25,   25,   68,   26,   68,   33,   68,
   68,   26,    0,    0,    0,    0,   36,    0,    0,   36,
   18,   29,    0,   68,    0,   68,   68,    0,   68,    0,
    0,    0,    0,   68,    2,    3,    0,   36,   13,    0,
   72,   18,    0,   26,    2,    3,    0,    0,   29,    0,
   29,   29,    0,   72,    0,    0,    0,    0,    0,   13,
    0,   71,    0,    0,    0,   68,    0,    0,    0,    0,
   26,    0,   26,   26,   71,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   14,    0,    0,
    0,    0,   68,    0,   68,   68,    0,    0,    0,    0,
    0,    0,    0,   36,    0,    0,    0,   18,   14,    0,
    0,    0,    0,   49,   49,   49,   49,   49,   49,   49,
   49,   49,   49,   49,   49,   49,   49,   49,   49,   49,
  102,   49,   49,    0,   49,   25,   25,   25,   25,   25,
   25,   25,   25,   25,   25,   25,   25,   25,   25,   25,
   25,   25,    0,   25,   25,    0,   25,   68,   68,   68,
   68,   68,   68,   68,   68,   68,   68,   68,   68,   68,
   68,   68,   68,   68,   14,   68,   68,    0,   68,    0,
    0,    0,   29,   29,   29,   29,   29,   29,   29,   29,
   29,   29,   29,   29,   29,   29,   29,   29,   29,    0,
   29,   29,  124,   29,   26,   26,   26,   26,   26,   26,
   26,   26,   26,   26,   26,   26,   26,   26,   26,   26,
   26,    0,   26,   26,   33,   26,   68,   68,   68,   68,
   68,   68,   68,   68,   68,   68,   68,   68,    0,   68,
   68,   68,   36,   62,   68,   68,   62,   68,   62,   36,
   62,   62,    0,   36,   36,    0,   36,   18,   18,    0,
    0,    0,    0,    0,   13,   61,   68,    0,   61,   62,
   61,   13,   61,   69,   62,   13,   13,   93,   13,   68,
   70,    0,    0,    0,    0,    0,   69,   17,    0,    0,
   18,   61,    0,   70,   19,    0,   61,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   62,   44,   25,    0,
   18,    0,    0,   14,   19,   89,    0,    0,   22,    0,
   14,   13,    0,    0,   14,   14,    0,   14,   61,    0,
    0,    0,    0,   62,   25,   62,   62,    0,   22,    0,
   64,   80,   13,   64,   48,   50,   51,   64,   64,    0,
   23,    0,   56,    0,    0,   61,   61,   61,   61,    0,
   17,    0,    0,   18,    0,    0,   86,   19,   78,    0,
   23,   64,    0,    0,    0,    0,    0,   21,   24,    0,
   20,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,   22,    0,    0,    0,    0,   90,   21,    0,   24,
   45,    0,    0,   64,    0,  109,  110,  111,   13,    0,
    0,    0,    0,    0,   23,    0,    0,    0,    0,    0,
    0,    0,    0,   23,    0,    0,    0,    0,    0,    0,
   64,   13,    0,   64,    0,   23,    0,  131,    0,  115,
    0,    0,    0,   38,    0,    0,   38,    0,    0,   48,
   21,    0,   13,   20,    0,    0,    0,    0,    0,    0,
  115,    0,  115,   13,   38,   24,    0,   62,   62,   62,
   62,   62,   62,   62,   62,   62,   62,   62,   62,    0,
   62,   62,   62,    0,   13,   62,   62,    0,   62,   61,
   61,   61,   61,   61,   61,   61,   61,   61,   61,   61,
   61,   23,   61,   61,   61,    0,    0,   61,   61,    0,
   61,    2,    3,    4,    5,    6,    7,    8,   13,    9,
   10,   11,   12,   13,   14,    0,   15,   16,   59,  102,
   38,    2,    3,   38,   39,   40,   41,   42,    0,    9,
   43,   11,   12,    0,   14,   17,   15,   13,   18,   88,
   13,    0,   19,    0,   13,    0,    0,    0,   13,   13,
    0,   13,    0,    0,   64,   64,   64,   64,   64,   64,
   64,    0,   64,   64,   64,   64,   22,   64,    0,   64,
    0,    0,   64,    1,    2,    3,    4,    5,    6,    7,
    8,    0,    9,   10,   11,   12,   13,   14,   44,   15,
   16,   18,    0,    0,   24,   19,    0,    0,   23,    0,
    0,   24,    0,    0,    0,   24,   24,    0,   24,    0,
    0,    0,    0,    0,   44,    0,    0,   18,    0,   22,
    0,   19,    0,    0,    0,   21,    0,    0,   20,    0,
   23,   44,    0,    0,   18,    0,    0,   23,   19,  119,
    0,   23,   23,    0,   23,   22,    0,   13,    0,    0,
    0,   23,   59,   59,   13,    0,    0,   44,   13,   38,
   18,   13,   22,    0,   19,    0,   38,    0,    0,   15,
   38,   38,    0,   38,    0,   82,    0,   23,   21,   13,
    0,   45,    0,    0,    0,    0,   13,    0,   22,    0,
   15,   13,   44,   13,   23,   18,    0,    0,    0,   19,
    0,    0,    0,    0,   21,    0,   22,   45,   19,    0,
    0,    0,    0,    0,   20,    0,    0,    0,    0,    0,
   23,   21,    0,   22,   45,    0,    0,   22,    0,   19,
    0,    0,    0,    0,    0,   20,    0,    0,    0,   52,
   53,    0,   54,    0,    0,    0,   59,   21,    0,    0,
   45,   67,    0,    0,    0,   23,   15,    0,    0,    2,
    3,    4,    5,    6,    7,    8,    0,    9,   10,   11,
   12,   13,   14,    0,   15,   16,    0,    0,   84,    0,
    0,    0,   21,    0,    0,   45,    0,    0,    0,    0,
    0,    0,    0,   22,    0,   19,    0,    0,    0,    0,
    0,   20,  100,    0,    0,    0,    0,    0,    0,    0,
  104,    0,    2,    3,   38,   39,   40,   41,   42,    0,
    9,   43,   11,   12,   13,   14,    0,   15,   16,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    2,    3,
   38,   39,   40,   41,   42,    0,    9,   43,   11,   12,
  104,   14,    0,   15,    0,    2,    3,   38,   39,   40,
   41,   42,    0,    9,   43,   11,   12,    0,   14,    0,
   15,    0,   27,    0,    0,    0,    0,    0,    0,    0,
    0,    2,    3,   38,   39,   40,   41,   42,    0,    9,
   43,   11,   12,   27,   14,   15,   15,    0,   27,    0,
    0,    0,   15,    0,    0,   27,   15,   15,    0,    0,
    0,    0,    0,    0,    0,    0,    2,    3,   38,   39,
   40,   41,  113,    0,    9,   43,   11,   12,    0,   14,
   27,   15,   22,    0,   19,    0,    0,   27,    0,   22,
   20,   19,    0,   22,   22,   19,   19,   20,    0,    0,
    0,   20,   20,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   27,    0,   27,
   27,   27,    0,    0,    0,    0,    0,   27,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,   27,
};
static const short yycheck[] = {                         33,
   61,   17,   36,   61,   38,   40,   40,   41,    0,  257,
  123,   65,   94,   68,   69,   70,  103,  124,   66,  126,
  123,   33,  275,  276,   36,   59,   38,   61,   40,   87,
   64,  264,   94,   94,   26,   83,  274,  124,  271,  126,
  125,   95,   94,   33,   61,  278,   36,   59,   38,   61,
   40,  105,   64,  278,  112,  275,  276,  125,   94,  125,
   94,  125,   96,   61,   61,   26,  115,   48,   33,   59,
  125,   36,   32,   38,   64,   40,   30,   -1,   41,   -1,
   -1,   -1,   -1,   -1,   96,  101,   -1,   -1,   -1,  123,
   33,  125,  126,   36,   59,   38,   59,   40,   -1,   64,
   41,   -1,   -1,   -1,   -1,   -1,   96,   -1,   -1,   -1,
   -1,  123,   33,  125,  126,   36,   59,   38,   59,   40,
   41,   64,   -1,   -1,   -1,   -1,   38,   -1,   -1,   41,
   38,   96,   -1,  123,   -1,  125,  126,   -1,   59,   -1,
   -1,   -1,   -1,   64,  257,  258,   -1,   59,   38,   -1,
   38,   59,   -1,   96,  257,  258,   -1,   -1,  123,   -1,
  125,  126,   -1,   38,   -1,   -1,   -1,   -1,   -1,   59,
   -1,   59,   -1,   -1,   -1,   96,   -1,   -1,   -1,   -1,
  123,   -1,  125,  126,   59,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   38,   -1,   -1,
   -1,   -1,  123,   -1,  125,  126,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,  125,   -1,   -1,   -1,  125,   59,   -1,
   -1,   -1,   -1,  257,  258,  259,  260,  261,  262,  263,
  264,  265,  266,  267,  268,  269,  270,  271,  272,  273,
  275,  275,  276,   -1,  278,  257,  258,  259,  260,  261,
  262,  263,  264,  265,  266,  267,  268,  269,  270,  271,
  272,  273,   -1,  275,  276,   -1,  278,  257,  258,  259,
  260,  261,  262,  263,  264,  265,  266,  267,  268,  269,
  270,  271,  272,  273,  125,  275,  276,   -1,  278,   -1,
   -1,   -1,  257,  258,  259,  260,  261,  262,  263,  264,
  265,  266,  267,  268,  269,  270,  271,  272,  273,   -1,
  275,  276,  275,  278,  257,  258,  259,  260,  261,  262,
  263,  264,  265,  266,  267,  268,  269,  270,  271,  272,
  273,   -1,  275,  276,  275,  278,  257,  258,  259,  260,
  261,  262,  263,  264,  265,  266,  267,  268,   -1,  270,
  271,  272,  264,   33,  275,  276,   36,  278,   38,  271,
   40,   41,   -1,  275,  276,   -1,  278,  275,  276,   -1,
   -1,   -1,   -1,   -1,  264,   33,  264,   -1,   36,   59,
   38,  271,   40,  271,   64,  275,  276,  275,  278,  264,
  278,   -1,   -1,   -1,   -1,   -1,  271,   33,   -1,   -1,
   36,   59,   -1,  278,   40,   -1,   64,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   96,   33,    0,   -1,
   36,   -1,   -1,  264,   40,   41,   -1,   -1,   64,   -1,
  271,   38,   -1,   -1,  275,  276,   -1,  278,   96,   -1,
   -1,   -1,   -1,  123,   26,  125,  126,   -1,   64,   -1,
   33,   33,   59,   36,    8,    9,   10,   40,   41,   -1,
   96,   -1,   16,   -1,   -1,  123,   20,  125,  126,   -1,
   33,   -1,   -1,   36,   -1,   -1,   58,   40,   32,   -1,
   96,   64,   -1,   -1,   -1,   -1,   -1,  123,   38,   -1,
  126,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   64,   -1,   -1,   -1,   -1,   60,  123,   -1,   59,
  126,   -1,   -1,   96,   -1,   97,   98,   99,  125,   -1,
   -1,   -1,   -1,   -1,   38,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   96,   -1,   -1,   -1,   -1,   -1,   -1,
  123,   38,   -1,  126,   -1,   59,   -1,  129,   -1,  103,
   -1,   -1,   -1,   38,   -1,   -1,   41,   -1,   -1,  113,
  123,   -1,   59,  126,   -1,   -1,   -1,   -1,   -1,   -1,
  124,   -1,  126,   38,   59,  125,   -1,  257,  258,  259,
  260,  261,  262,  263,  264,  265,  266,  267,  268,   -1,
  270,  271,  272,   -1,   59,  275,  276,   -1,  278,  257,
  258,  259,  260,  261,  262,  263,  264,  265,  266,  267,
  268,  125,  270,  271,  272,   -1,   -1,  275,  276,   -1,
  278,  257,  258,  259,  260,  261,  262,  263,  125,  265,
  266,  267,  268,  269,  270,   -1,  272,  273,  123,  275,
  125,  257,  258,  259,  260,  261,  262,  263,   -1,  265,
  266,  267,  268,   -1,  270,   33,  272,  264,   36,  275,
  125,   -1,   40,   -1,  271,   -1,   -1,   -1,  275,  276,
   -1,  278,   -1,   -1,  257,  258,  259,  260,  261,  262,
  263,   -1,  265,  266,  267,  268,   64,  270,   -1,  272,
   -1,   -1,  275,  256,  257,  258,  259,  260,  261,  262,
  263,   -1,  265,  266,  267,  268,  269,  270,   33,  272,
  273,   36,   -1,   -1,  264,   40,   -1,   -1,   96,   -1,
   -1,  271,   -1,   -1,   -1,  275,  276,   -1,  278,   -1,
   -1,   -1,   -1,   -1,   33,   -1,   -1,   36,   -1,   64,
   -1,   40,   -1,   -1,   -1,  123,   -1,   -1,  126,   -1,
  264,   33,   -1,   -1,   36,   -1,   -1,  271,   40,   41,
   -1,  275,  276,   -1,  278,   64,   -1,  264,   -1,   -1,
   -1,   96,  257,  258,  271,   -1,   -1,   33,  275,  264,
   36,  278,   64,   -1,   40,   -1,  271,   -1,   -1,   38,
  275,  276,   -1,  278,   -1,   94,   -1,   96,  123,  264,
   -1,  126,   -1,   -1,   -1,   -1,  271,   -1,   64,   -1,
   59,  276,   33,  278,   96,   36,   -1,   -1,   -1,   40,
   -1,   -1,   -1,   -1,  123,   -1,   38,  126,   38,   -1,
   -1,   -1,   -1,   -1,   38,   -1,   -1,   -1,   -1,   -1,
   96,  123,   -1,   64,  126,   -1,   -1,   59,   -1,   59,
   -1,   -1,   -1,   -1,   -1,   59,   -1,   -1,   -1,   11,
   12,   -1,   14,   -1,   -1,   -1,   18,  123,   -1,   -1,
  126,   23,   -1,   -1,   -1,   96,  125,   -1,   -1,  257,
  258,  259,  260,  261,  262,  263,   -1,  265,  266,  267,
  268,  269,  270,   -1,  272,  273,   -1,   -1,   50,   -1,
   -1,   -1,  123,   -1,   -1,  126,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,  125,   -1,  125,   -1,   -1,   -1,   -1,
   -1,  125,   74,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   82,   -1,  257,  258,  259,  260,  261,  262,  263,   -1,
  265,  266,  267,  268,  269,  270,   -1,  272,  273,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,
  259,  260,  261,  262,  263,   -1,  265,  266,  267,  268,
  122,  270,   -1,  272,   -1,  257,  258,  259,  260,  261,
  262,  263,   -1,  265,  266,  267,  268,   -1,  270,   -1,
  272,   -1,    0,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,  257,  258,  259,  260,  261,  262,  263,   -1,  265,
  266,  267,  268,   21,  270,  264,  272,   -1,   26,   -1,
   -1,   -1,  271,   -1,   -1,   33,  275,  276,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,  259,  260,
  261,  262,  263,   -1,  265,  266,  267,  268,   -1,  270,
   58,  272,  264,   -1,  264,   -1,   -1,   65,   -1,  271,
  264,  271,   -1,  275,  276,  275,  276,  271,   -1,   -1,
   -1,  275,  276,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   95,   -1,   97,
   98,   99,   -1,   -1,   -1,   -1,   -1,  105,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,  129,
};
#define YYFINAL 24
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 278
#if YYDEBUG
static const char *yyname[] = {

"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
"'!'",0,0,"'$'",0,"'&'",0,"'('","')'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"';'",0,
"'='",0,0,"'@'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'^'",
0,"'`'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'{'",0,"'}'","'~'",
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,"WORD","QWORD","LOCAL","LET","FOR","CLOSURE","FN","ANDAND",
"BACKBACK","EXTRACT","CALL","COUNT","DUP","FLAT","OROR","PRIM","REDIR","SUB",
"NL","ENDFILE","ERROR","PIPE",
};
static const char *yyrule[] = {
"$accept : es",
"es : line end",
"es : error end",
"end : NL",
"end : ENDFILE",
"line : cmd",
"line : cmdsa line",
"body : cmd",
"body : cmdsan body",
"cmdsa : cmd ';'",
"cmdsa : cmd '&'",
"cmdsan : cmdsa",
"cmdsan : cmd NL",
"cmd :",
"cmd : simple",
"cmd : redir cmd",
"cmd : first assign",
"cmd : fn",
"cmd : binder nl '(' bindings ')' nl cmd",
"cmd : cmd ANDAND nl cmd",
"cmd : cmd OROR nl cmd",
"cmd : cmd PIPE nl cmd",
"cmd : '!' caret cmd",
"cmd : '~' word words",
"cmd : EXTRACT word words",
"simple : first",
"simple : simple word",
"simple : simple redir",
"redir : DUP",
"redir : REDIR word",
"bindings : binding",
"bindings : bindings ';' binding",
"bindings : bindings NL binding",
"binding :",
"binding : fn",
"binding : word assign",
"assign : caret '=' caret words",
"fn : FN word params '{' body '}'",
"fn : FN word",
"first : comword",
"first : first '^' sword",
"sword : comword",
"sword : keyword",
"word : sword",
"word : word '^' sword",
"comword : param",
"comword : '(' nlwords ')'",
"comword : '{' body '}'",
"comword : '@' params '{' body '}'",
"comword : '$' sword",
"comword : '$' sword SUB words ')'",
"comword : CALL sword",
"comword : COUNT sword",
"comword : FLAT sword",
"comword : PRIM WORD",
"comword : '`' sword",
"comword : BACKBACK word sword",
"param : WORD",
"param : QWORD",
"params :",
"params : params param",
"words :",
"words : words word",
"nlwords :",
"nlwords : nlwords word",
"nlwords : nlwords NL",
"nl :",
"nl : nl NL",
"caret :",
"caret : '^'",
"binder : LOCAL",
"binder : LET",
"binder : FOR",
"binder : CLOSURE",
"keyword : '!'",
"keyword : '~'",
"keyword : EXTRACT",
"keyword : LOCAL",
"keyword : LET",
"keyword : FOR",
"keyword : FN",
"keyword : CLOSURE",

};
#endif
#if YYDEBUG
#include <stdio.h>
#endif

/* define the initial stack-sizes */
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH  YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 500
#define YYMAXDEPTH  500
#endif
#endif

#define YYINITSTACKSIZE 500

int      yydebug;
int      yynerrs;
int      yyerrflag;
int      yychar;
short   *yyssp;
YYSTYPE *yyvsp;
YYSTYPE  yyval;
YYSTYPE  yylval;

/* variables for the parser stack */
static short   *yyss;
static short   *yysslim;
static YYSTYPE *yyvs;
static unsigned yystacksize;
/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack(void)
{
    int i;
    unsigned newsize;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = yystacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;

    i = yyssp - yyss;
    newss = (yyss != 0)
          ? (short *)realloc(yyss, newsize * sizeof(*newss))
          : (short *)malloc(newsize * sizeof(*newss));
    if (newss == 0)
        return -1;

    yyss  = newss;
    yyssp = newss + i;
    newvs = (yyvs != 0)
          ? (YYSTYPE *)realloc(yyvs, newsize * sizeof(*newvs))
          : (YYSTYPE *)malloc(newsize * sizeof(*newvs));
    if (newvs == 0)
        return -1;

    yyvs = newvs;
    yyvsp = newvs + i;
    yystacksize = newsize;
    yysslim = yyss + newsize - 1;
    return 0;
}

#define YYABORT  goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR  goto yyerrlab

int
YYPARSE_DECL()
{
    int yym, yyn, yystate;
#if YYDEBUG
    const char *yys;

    if ((yys = getenv("YYDEBUG")) != 0)
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = YYEMPTY;
    yystate = 0;

    if (yyss == NULL && yygrowstack()) goto yyoverflow;
    yyssp = yyss;
    yyvsp = yyvs;
    yystate = 0;
    *yyssp = 0;

yyloop:
    if ((yyn = yydefred[yystate]) != 0) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yysslim && yygrowstack())
        {
            goto yyoverflow;
        }
        yystate = yytable[yyn];
        *++yyssp = yytable[yyn];
        *++yyvsp = yylval;
        yychar = YYEMPTY;
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;

    yyerror("syntax error");

    goto yyerrlab;

yyerrlab:
    ++yynerrs;

yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yysslim && yygrowstack())
                {
                    goto yyoverflow;
                }
                yystate = yytable[yyn];
                *++yyssp = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = YYEMPTY;
        goto yyloop;
    }

yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    if (yym)
        yyval = yyvsp[1-yym];
    else
        memset(&yyval, 0, sizeof yyval);
    switch (yyn)
    {
case 1:
#line 39 "./parse.y"
	{ parsetree = yyvsp[-1].tree; YYACCEPT; }
break;
case 2:
#line 40 "./parse.y"
	{ yyerrok; parsetree = NULL; YYABORT; }
break;
case 3:
#line 42 "./parse.y"
	{ if (!readheredocs(FALSE)) YYABORT; }
break;
case 4:
#line 43 "./parse.y"
	{ if (!readheredocs(TRUE)) YYABORT; }
break;
case 5:
#line 45 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 6:
#line 46 "./parse.y"
	{ yyval.tree = mkseq("%seq", yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 7:
#line 48 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 8:
#line 49 "./parse.y"
	{ yyval.tree = mkseq("%seq", yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 9:
#line 51 "./parse.y"
	{ yyval.tree = yyvsp[-1].tree; }
break;
case 10:
#line 52 "./parse.y"
	{ yyval.tree = prefix("%background", mk(nList, thunkify(yyvsp[-1].tree), NULL)); }
break;
case 11:
#line 54 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 12:
#line 55 "./parse.y"
	{ yyval.tree = yyvsp[-1].tree; if (!readheredocs(FALSE)) YYABORT; }
break;
case 13:
#line 57 "./parse.y"
	{ yyval.tree = NULL; }
break;
case 14:
#line 58 "./parse.y"
	{ yyval.tree = redirect(yyvsp[0].tree); if (yyval.tree == &errornode) YYABORT; }
break;
case 15:
#line 59 "./parse.y"
	{ yyval.tree = redirect(mk(nRedir, yyvsp[-1].tree, yyvsp[0].tree)); if (yyval.tree == &errornode) YYABORT; }
break;
case 16:
#line 60 "./parse.y"
	{ yyval.tree = mk(nAssign, yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 17:
#line 61 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 18:
#line 62 "./parse.y"
	{ yyval.tree = mk(yyvsp[-6].kind, yyvsp[-3].tree, yyvsp[0].tree); }
break;
case 19:
#line 63 "./parse.y"
	{ yyval.tree = mkseq("%and", yyvsp[-3].tree, yyvsp[0].tree); }
break;
case 20:
#line 64 "./parse.y"
	{ yyval.tree = mkseq("%or", yyvsp[-3].tree, yyvsp[0].tree); }
break;
case 21:
#line 65 "./parse.y"
	{ yyval.tree = mkpipe(yyvsp[-3].tree, yyvsp[-2].tree->u[0].i, yyvsp[-2].tree->u[1].i, yyvsp[0].tree); }
break;
case 22:
#line 66 "./parse.y"
	{ yyval.tree = prefix("%not", mk(nList, thunkify(yyvsp[0].tree), NULL)); }
break;
case 23:
#line 67 "./parse.y"
	{ yyval.tree = mk(nMatch, yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 24:
#line 68 "./parse.y"
	{ yyval.tree = mk(nExtract, yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 25:
#line 70 "./parse.y"
	{ yyval.tree = treecons2(yyvsp[0].tree, NULL); }
break;
case 26:
#line 71 "./parse.y"
	{ yyval.tree = treeconsend2(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 27:
#line 72 "./parse.y"
	{ yyval.tree = redirappend(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 28:
#line 74 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 29:
#line 75 "./parse.y"
	{ yyval.tree = mkredir(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 30:
#line 77 "./parse.y"
	{ yyval.tree = treecons2(yyvsp[0].tree, NULL); }
break;
case 31:
#line 78 "./parse.y"
	{ yyval.tree = treeconsend2(yyvsp[-2].tree, yyvsp[0].tree); }
break;
case 32:
#line 79 "./parse.y"
	{ yyval.tree = treeconsend2(yyvsp[-2].tree, yyvsp[0].tree); }
break;
case 33:
#line 81 "./parse.y"
	{ yyval.tree = NULL; }
break;
case 34:
#line 82 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 35:
#line 83 "./parse.y"
	{ yyval.tree = mk(nAssign, yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 36:
#line 85 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 37:
#line 87 "./parse.y"
	{ yyval.tree = fnassign(yyvsp[-4].tree, mklambda(yyvsp[-3].tree, yyvsp[-1].tree)); }
break;
case 38:
#line 88 "./parse.y"
	{ yyval.tree = fnassign(yyvsp[0].tree, NULL); }
break;
case 39:
#line 90 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 40:
#line 91 "./parse.y"
	{ yyval.tree = mk(nConcat, yyvsp[-2].tree, yyvsp[0].tree); }
break;
case 41:
#line 93 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 42:
#line 94 "./parse.y"
	{ yyval.tree = mk(nWord, yyvsp[0].str); }
break;
case 43:
#line 96 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 44:
#line 97 "./parse.y"
	{ yyval.tree = mk(nConcat, yyvsp[-2].tree, yyvsp[0].tree); }
break;
case 45:
#line 99 "./parse.y"
	{ yyval.tree = yyvsp[0].tree; }
break;
case 46:
#line 100 "./parse.y"
	{ yyval.tree = yyvsp[-1].tree; }
break;
case 47:
#line 101 "./parse.y"
	{ yyval.tree = thunkify(yyvsp[-1].tree); }
break;
case 48:
#line 102 "./parse.y"
	{ yyval.tree = mklambda(yyvsp[-3].tree, yyvsp[-1].tree); }
break;
case 49:
#line 103 "./parse.y"
	{ yyval.tree = mk(nVar, yyvsp[0].tree); }
break;
case 50:
#line 104 "./parse.y"
	{ yyval.tree = mk(nVarsub, yyvsp[-3].tree, yyvsp[-1].tree); }
break;
case 51:
#line 105 "./parse.y"
	{ yyval.tree = mk(nCall, yyvsp[0].tree); }
break;
case 52:
#line 106 "./parse.y"
	{ yyval.tree = mk(nCall, prefix("%count", treecons(mk(nVar, yyvsp[0].tree), NULL))); }
break;
case 53:
#line 107 "./parse.y"
	{ yyval.tree = flatten(mk(nVar, yyvsp[0].tree), " "); }
break;
case 54:
#line 108 "./parse.y"
	{ yyval.tree = mk(nPrim, yyvsp[0].str); }
break;
case 55:
#line 109 "./parse.y"
	{ yyval.tree = backquote(mk(nVar, mk(nWord, "ifs")), yyvsp[0].tree); }
break;
case 56:
#line 110 "./parse.y"
	{ yyval.tree = backquote(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 57:
#line 112 "./parse.y"
	{ yyval.tree = mk(nWord, yyvsp[0].str); }
break;
case 58:
#line 113 "./parse.y"
	{ yyval.tree = mk(nQword, yyvsp[0].str); }
break;
case 59:
#line 115 "./parse.y"
	{ yyval.tree = NULL; }
break;
case 60:
#line 116 "./parse.y"
	{ yyval.tree = treeconsend(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 61:
#line 118 "./parse.y"
	{ yyval.tree = NULL; }
break;
case 62:
#line 119 "./parse.y"
	{ yyval.tree = treeconsend(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 63:
#line 121 "./parse.y"
	{ yyval.tree = NULL; }
break;
case 64:
#line 122 "./parse.y"
	{ yyval.tree = treeconsend(yyvsp[-1].tree, yyvsp[0].tree); }
break;
case 65:
#line 123 "./parse.y"
	{ yyval.tree = yyvsp[-1].tree; }
break;
case 70:
#line 131 "./parse.y"
	{ yyval.kind = nLocal; }
break;
case 71:
#line 132 "./parse.y"
	{ yyval.kind = nLet; }
break;
case 72:
#line 133 "./parse.y"
	{ yyval.kind = nFor; }
break;
case 73:
#line 134 "./parse.y"
	{ yyval.kind = nClosure; }
break;
case 74:
#line 136 "./parse.y"
	{ yyval.str = "!"; }
break;
case 75:
#line 137 "./parse.y"
	{ yyval.str = "~"; }
break;
case 76:
#line 138 "./parse.y"
	{ yyval.str = "~~"; }
break;
case 77:
#line 139 "./parse.y"
	{ yyval.str = "local"; }
break;
case 78:
#line 140 "./parse.y"
	{ yyval.str = "let"; }
break;
case 79:
#line 141 "./parse.y"
	{ yyval.str = "for"; }
break;
case 80:
#line 142 "./parse.y"
	{ yyval.str = "fn"; }
break;
case 81:
#line 143 "./parse.y"
	{ yyval.str = "%closure"; }
break;
#line 1011 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yysslim && yygrowstack())
    {
        goto yyoverflow;
    }
    *++yyssp = (short) yystate;
    *++yyvsp = yyval;
    goto yyloop;

yyoverflow:
    yyerror("yacc stack overflow");

yyabort:
    return (1);

yyaccept:
    return (0);
}
