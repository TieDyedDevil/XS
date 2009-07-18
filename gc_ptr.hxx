/* Reference on Stack */
template <class T>
class SRef {
	public: 
		SRef() : ref(NULL) {}
		SRef(const SRef<T>& orig) : ref(orig.ref) {
			addroot();
		}
		SRef(T* x) : ref(x) {
			addroot();
		}
		SRef& operator=(const SRef& orig) {
			unroot();
			ref = orig.ref;
			addroot();
		}
		SRef& operator=(T* x) {
			unroot();
			ref = x;
			addroot();
		}
		~SRef() {
			unroot();
		}
		T* get() {
			assert(gcisblocked());
			return ref;
		}
		/* unchecked version of get. Ocasionally there are valid reasons
		 * that the gc would be enabled, for example if assigning
		 * into a scanned type
		 */
		T* uget() {
			return ref;
		}
		T* release() {
			unroot();
			return ref;
		}
		T& operator*() {
			assert (ref != NULL);
			return *ref;
		}
		T* operator->() {
			assert (ref != NULL);
			return ref;
		}
	private:
		void addroot() {
			root.p = reinterpret_cast<void**>(&ref);
			root.next = rootlist;
			rootlist = &root;
		}
		void unroot() {
			if (ref == NULL) return;
			refassert(rootlist == &root); \
			refassert(rootlist->p == reinterpret_cast<void **>(&ref)); \
			rootlist = rootlist->next;
			ref = NULL;
		}
		Root root;
		T *ref;
};
