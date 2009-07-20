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
