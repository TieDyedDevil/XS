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
		operator bool() {
			return ref != NULL;
		}
		bool operator==(T *x) {
			return ref == x;
		}
		bool operator==(SRef<T> x) {
			return ref == x;
		}
		bool operator!=(T *x) {
			return ref != x;
		}
		bool operator!=(SRef<T> x) {
			return ref != x;
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
			T *t = ref;
			unroot();
			return t;
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
