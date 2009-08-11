/* prim.hxx -- definitions for es primitives ($Revision: 1.1.1.1 $) */
#include <map>
#include <string>

#define	PRIM(name)	static Ref<List> CONCAT(prim_,name)( \
				Ref<List> list, Ref<Binding> binding, int evalflags \
			)
#define	X(name)		primdict[STRING(name)] = CONCAT(prim_,name)

typedef Ref<List> (*Prim)(Ref<List>, Ref<Binding>, int);
typedef std::map<std::string, Prim> Prim_dict;

extern void initprims_controlflow(Prim_dict& primdict);	/* prim-ctl.c */
extern void initprims_io(Prim_dict& primdict);		/* prim-io.c */
extern void initprims_etc(Prim_dict& primdict);		/* prim-etc.c */
extern void initprims_sys(Prim_dict& primdict);		/* prim-sys.c */
extern void initprims_proc(Prim_dict& primdict);	/* proc.c */
extern void initprims_access(Prim_dict& primdict);	/* access.c */

