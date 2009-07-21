/* Stack/Paramater/Return type/etc. reference
   Should be used for gc references which cannot be auto-forwarded
   otherwise (i.e. are not pointers contained within another reference),
   otherwise the reference may either
   		* be considered unused and deleted
		* or be forwarded without updating your pointer
	both leading to bad things
   Works fine with non-gc pointers too (although it doesn't auto-free them)

   You should NOT, as an exception, form an SRef to an object with a custom scanner/copier
   while that scanner/copier would not operate correctly, if the object you are creating
   will not be setup properly by the next possible gc run (gc(), gcenable(), or any gc allocation)
*/
template <class T>
class SRef {
#include "gc_ptr1.hxx"
	public:
		T& operator*() const {
			assert(ref != NULL);
			return *ref;
		}
		T& operator[](int n) const {
			assert(ref != NULL);
			return ref[n];
		}
};

template<>
class SRef<void> {
	typedef void T;
#include "gc_ptr1.hxx"
};
