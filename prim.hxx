/* prim.hxx -- definitions for xs primitives */
#include <string>

#define	PRIM(name)	static const List* CONCAT(prim_,name)( \
				List* list, Binding* binding, int evalflags \
			)
#define	X(name)		primdict[STRING(name)] = CONCAT(prim_,name)

typedef const List* (*Prim)(List*, Binding*, int);
#ifdef HAVE_TR1_UNORDERED_MAP
#include <tr1/unordered_map>
typedef std::tr1::unordered_map<std::string, Prim> Prim_dict;
#else
#include <map>
typedef std::map<std::string, Prim> Prim_dict;
#endif

extern void initprims_controlflow(Prim_dict& primdict);	/* prim-ctl.c */
extern void initprims_io(Prim_dict& primdict);		/* prim-io.c */
extern void initprims_etc(Prim_dict& primdict);		/* prim-etc.c */
extern void initprims_sys(Prim_dict& primdict);		/* prim-sys.c */
extern void initprims_proc(Prim_dict& primdict);	/* proc.c */
extern void initprims_access(Prim_dict& primdict);	/* access.c */

