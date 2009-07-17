#include "es.hxx"
template <class T>
class SRef {
	public:
		SRef(const SRef& orig) {
			ref = orig.ref;
			root.p = &ref;
			root.next = rootlist;
			rootlist = root;
		}
		~SRef() {
			refassert(rootlist == &root); \
			refassert(rootlist->p == (void **) &ref); \
			rootlist = rootlist->next;
		}
		T& operator*() {
			return *ref;
		}
		T* operator->() {
			return ref;
		}
	private:
		Root root;
		T *ref;
};
