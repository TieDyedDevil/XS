/* prim.hxx -- definitions for xs primitives */
#include <string>

#define	PRIM(name)	static const List* CONCAT(prim_,name)( \
				List* __attribute__((unused)) list, \
				Binding* __attribute__((unused)) binding, \
				int __attribute__((unused)) evalflags \
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

extern void initprims_controlflow(Prim_dict& primdict);	/* prim-ctl.cxx */
extern void initprims_io(Prim_dict& primdict);		/* prim-io.cxx */
extern void initprims_etc(Prim_dict& primdict);		/* prim-etc.cxx */
extern void initprims_sys(Prim_dict& primdict);		/* prim-sys.cxx */
extern void initprims_rel(Prim_dict& primdict);		/* prim-rel.cxx */
extern void initprims_proc(Prim_dict& primdict);	/* proc.cxx */
extern void initprims_access(Prim_dict& primdict);	/* access.cxx */

