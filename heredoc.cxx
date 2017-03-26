/* heredoc.cxx -- in-line files (here documents) */

#include "xs.hxx"
#include "input.hxx"
#include "syntax.hxx"
#include <sstream>
#include <stack>

using std::stringstream;
using std::stack;

static stack<Tree*> hereq;

/* getherevar -- read a variable from a here doc */
extern Tree *getherevar(void) {
	int c;
	stringstream buf;
	while (!dnw[c = GETC()])
		buf.put(c);
	if (buf.tellp() == 0) {
		yyerror("null variable name in here document");
		return NULL;
	}
	char *s = gcdup(buf.str().c_str());
	if (c != '^')
		UNGETC(c);
	return flatten(mk(nVar, mk(nWord, s)), " ");
}

/* snarfheredoc -- read a heredoc until the eof marker */
extern Tree *snarfheredoc(const char *eof, bool quoted) {
	Tree *tree, **tailp;
	stringstream buf;

	assert(quoted || strchr(eof, '$') == NULL);	/* can never be typed (whew!) */
	if (strchr(eof, '\n') != NULL) {
		yyerror("here document eof-marker contains a newline");
		return NULL;
	}
	disablehistory = true;

	for (tree = NULL, tailp = &tree;;) {
		print_prompt2();
		unsigned char *s;
		int c;
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
				if (buf.tellp() > 0) {
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
	while (!hereq.empty()) {
		Tree *marker = hereq.top();
		hereq.pop();
		if (endfile) {
			yyerror("end of file with pending here documents");
			return false;
		}
		Tree *eof = marker->CAR;
		marker->CAR = snarfheredoc(eof->u[0].s, eof->kind == nQword);
		if (marker->CAR == NULL)
			return false;
	}
	return true;
}

/* queueheredoc -- add a heredoc to the queue to process at the end of the line */
extern bool queueheredoc(Tree *t) {
	assert(hereq.empty() || hereq.top()->kind == nList);
	assert(t->kind == nList);
	assert(t->CAR->kind == nWord);
	assert(streq(t->CAR->u[0].s, "%heredoc"));
	t->CAR->u[0].s = "%here";
	
	assert(t->CDR->kind == nList);
	
	Tree *eof = t->CDR->CDR;
	assert(eof->kind == nList);
	if (eof->CAR->kind != nWord && eof->CAR->kind != nQword) {
		yyerror("here document eof-marker not a single literal word");
		return false;
	}
	
	hereq.push(eof);
	return true;
}

extern void emptyherequeue(void) {
	while (not hereq.empty()) hereq.pop();
	disablehistory = false;
}
