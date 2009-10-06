/* heredoc.c -- in-line files (here documents) ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "input.hxx"
#include "syntax.hxx"
#include <sstream>

using std::stringstream;

typedef struct Here Here;
struct Here {
	Here *next;
	Tree *marker;
};

static Here *hereq;

/* getherevar -- read a variable from a here doc */
extern Tree *getherevar(void) {
	int c;
	char *s;
	stringstream buf;
	while (!dnw[c = GETC()])
		buf.put(c);
	if (buf.str() == "") {
		yyerror("null variable name in here document");
		return NULL;
	}
	s = gcdup(buf.str().c_str());
	if (c != '^')
		UNGETC(c);
	return flatten(mk(nVar, mk(nWord, s)), " ");
}

/* snarfheredoc -- read a heredoc until the eof marker */
extern Tree *snarfheredoc(const char *eof, bool quoted) {
	Tree *tree, **tailp;
	stringstream buf;
	unsigned char *s;

	assert(quoted || strchr(eof, '$') == NULL);	/* can never be typed (whew!) */
	if (strchr(eof, '\n') != NULL) {
		yyerror("here document eof-marker contains a newline");
		return NULL;
	}
	disablehistory = true;

	for (tree = NULL, tailp = &tree;;) {
		int c;
		print_prompt2();
		for (s = (unsigned char *) eof; (c = GETC()) == *s; s++)
			;
		if (*s == '\0' && (c == '\n' || c == EOF)) {
			if (!(buf.tellp() == 0 && tree != NULL))
				*tailp = treecons(mk(nQword, gcdup(buf.str().c_str())), NULL);
			break;
		}
		if (s != (unsigned char *) eof)
			buf.write(eof, s - (unsigned char *) eof);
		for (;; c = GETC()) {
			if (c == EOF) {
				yyerror("incomplete here document");
				disablehistory = false;
				return NULL;
			}
			if (c == '$' && !quoted && (c = GETC()) != '$') {
				Tree *var;
				UNGETC(c);
				if (buf.str() != "") {
					*tailp = treecons(mk(nQword, gcdup(buf.str().c_str())), NULL);
					tailp = &(*tailp)->CDR;
				}
				var = getherevar();
				if (var == NULL) {
					disablehistory = false;
					return NULL;
				}
				*tailp = treecons(var, NULL);
				tailp = &(*tailp)->CDR;
				buf.str("");
				continue;
			}
			buf.put(c);
			if (c == '\n')
				break;
		}
	}

	disablehistory = false;
	return tree->CDR == NULL ? tree->CAR : tree;
}

/* readheredocs -- read all the heredocs at the end of a line (or fail if at end of file) */
extern bool readheredocs(bool endfile) {
	for (; hereq != NULL; hereq = hereq->next) {
		Tree *marker, *eof;
		if (endfile) {
			yyerror("end of file with pending here documents");
			return false;
		}
		marker = hereq->marker;
		eof = marker->CAR;
		marker->CAR = snarfheredoc(eof->u[0].s, eof->kind == nQword);
		if (marker->CAR == NULL)
			return false;
	}
	return true;
}

/* queueheredoc -- add a heredoc to the queue to process at the end of the line */
extern bool queueheredoc(Tree *t) {
	Tree *eof;
	Here *here;

	assert(hereq == NULL || hereq->marker->kind == nList);
	assert(t->kind == nList);
	assert(t->CAR->kind == nWord);
	assert(streq(t->CAR->u[0].s, "%heredoc"));
	t->CAR->u[0].s = "%here";
	assert(t->CDR->kind == nList);
	eof = t->CDR->CDR;
	assert(eof->kind == nList);
	if (eof->CAR->kind != nWord && eof->CAR->kind != nQword) {
		yyerror("here document eof-marker not a single literal word");
		return false;
	}

	here = reinterpret_cast<Here*>(galloc(sizeof(Here)));
	here->next = hereq;
	here->marker = eof;
	hereq = here;
	return true;
}

extern void emptyherequeue(void) {
	hereq = NULL;
	disablehistory = false;
}
