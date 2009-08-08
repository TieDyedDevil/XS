/* dict.c -- hash-table based dictionaries ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

static const int INIT_DICT_SIZE = 2;
inline static int remain(int n)	{
	return n * 2 / 3;
}
inline static int grow(int n) {
	return n * 2;
}

/*
 * hashing
 */

/* strhash2 -- the (probably too slow) haahr hash function */
static unsigned long strhash2(const char *str1, const char *str2) {

#define	ADVANCE() { \
		if ((c = *s++) == '\0') { \
			if (str2 == NULL) \
				break; \
			else { \
				s = (unsigned char *) str2; \
				str2 = NULL; \
				if ((c = *s++) == '\0') \
					break; \
			} \
		} \
	}

	int c;
	unsigned long n = 0;
	unsigned char *s = (unsigned char *) str1;
	assert(str1 != NULL);
	while (1) {
		ADVANCE();
		n += (c << 17) ^ (c << 11) ^ (c << 5) ^ (c >> 1);
		ADVANCE();
		n ^= (c << 14) + (c << 7) + (c << 4) + c;
		ADVANCE();
		n ^= (~c << 11) | ((c << 3) ^ (c >> 1));
		ADVANCE();
		n -= (c << 16) | (c << 9) | (c << 2) | (c & 3);
	}
	return n;
}

/* strhash -- hash a single string */
static unsigned long strhash(const char *str) {
	return strhash2(str, NULL);
}


/*
 * data structures and garbage collection
 */

DefineTag(Dict, static);

typedef struct {
	const char *name;
	void *value;
} Assoc;

struct Dict {
	int size, remain;
	Assoc table[1];		/* variable length */
};


static Dict *mkdict0(int size) {
	size_t len = offsetof(Dict, table[0]) + size * sizeof(Assoc);
	Dict *dict = reinterpret_cast<Dict*>(gcalloc(len, &DictTag));
	memzero(dict, len);
	dict->size = size;
	dict->remain = remain(size);
	return dict;
}

static void *DictCopy(void *op) {
	Dict *dict = reinterpret_cast<Dict*>(op);
	size_t len = offsetof(Dict, table[0]) + dict->size * sizeof(Assoc);
	void *np = gcalloc(len, &DictTag);
	memcpy(np, op, len);
	return np;
}

static size_t DictScan(void *p) {
	Dict *dict = reinterpret_cast<Dict*>(p);
	int i;
	for (i = 0; i < dict->size; i++) {
		Assoc *ap = &dict->table[i];
		ap->name  = forward(const_cast<char*>(ap->name));
		ap->value = forward(ap->value);
	}
	return offsetof(Dict, table[0]) + sizeof(Assoc) * dict->size;
}


/*
 * private operations
 */

static char DEAD[] = "DEAD";

static Assoc *get(Dict *dict, const char *name) {
	unsigned long n = strhash(name), mask = dict->size - 1;
	for (Assoc *ap; (ap = &dict->table[n & mask])->name != NULL; n++)
		if (ap->name != DEAD && streq(name, ap->name))
			return ap;
	return NULL;
}

static Dict *put(Ref<Dict> dict, Ref<const char> name, Ref<void> value);
static void putForAll(void *dict, const char *name, void *value) {
	put(reinterpret_cast<Dict*>(dict), name, value);
}

static Dict *put(Ref<Dict> dict, Ref<const char> name, Ref<void> value) {
	unsigned long n, mask;
	Assoc *ap;
	assert(get(dict.uget(), name.uget()) == NULL);
	assert(value != NULL);

	if (dict->remain <= 1) {
		Ref<Dict> newDict;
		newDict = mkdict0(grow(dict->size));
		dictforall(dict.uget(), putForAll, newDict.uget());
		dict = newDict;
	}

	n = strhash(name.uget());
	mask = dict->size - 1;
	for (; (ap = &dict->table[n & mask])->name != DEAD; n++)
		if (ap->name == NULL) {
			--dict->remain;
			break;
		}

	ap->name = name.uget();
	ap->value = value.uget();
	return dict.release();
}

static void rm(Dict *dict, Assoc *ap) {
	unsigned long n, mask;
	assert(dict->table <= ap && ap < &dict->table[dict->size]);

	ap->name = DEAD;
	ap->value = NULL;
	n = ap - dict->table;
	mask = dict->size - 1;
	for (n++; (ap = &dict->table[n & mask])->name == DEAD; n++)
		;
	if (ap->name != NULL)
		return;
	for (n--; (ap = &dict->table[n & mask])->name == DEAD; n--) {
		ap->name = NULL;
		++dict->remain;
	}
}



/*
 * exported functions
 */

extern Dict *mkdict(void) {
	return mkdict0(INIT_DICT_SIZE);
}

extern void *dictget(Dict *dict, const char *name) {
	Assoc *ap = get(dict, name);
	return ap == NULL ? NULL : ap->value;
}

extern Dict *dictput(Dict *dict, const char *name, void *value) {
	Assoc *ap = get(dict, name);
	if (value != NULL)
		if (ap == NULL)
			dict = put(dict, name, value);
		else
			ap->value = value;
	else if (ap != NULL)
		rm(dict, ap);
	return dict;
}

extern void dictforall(Ref<Dict> dict, void (*proc)(void *, const char *, void *), Ref<void> argp) {
	int i;
	for (i = 0; i < dict->size; i++) {
		Assoc *ap = &dict->table[i];
		if (ap->name != NULL && ap->name != DEAD)
			(*proc)(argp.uget(), ap->name, ap->value);
	}
}

/* dictget2 -- look up the catenation of two names (such a hack!) */
extern void *dictget2(Dict *dict, const char *name1, const char *name2) {
	Assoc *ap;
	unsigned long n = strhash2(name1, name2), mask = dict->size - 1;
	for (; (ap = &dict->table[n & mask])->name != NULL; n++)
		if (ap->name != DEAD && streq2(ap->name, name1, name2))
			return ap->value;
	return NULL;
}
