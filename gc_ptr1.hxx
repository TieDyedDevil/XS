	public: 
		SRef() : ref(NULL) {
			addroot();
		}
		SRef(const SRef<T>& orig) : ref(orig.ref) {
			addroot();
		}
		SRef(T* x) : ref(x) {
			addroot();
		}
		SRef& operator=(const SRef<T>& x) {
			ref = x.ref;
			return *this;
		}
		SRef& operator=(T* p) {
			ref = p;
			return *this;
		}
		operator bool() const {
			return ref != NULL;
		}
		bool operator==(T *x) const {
			return ref == x;
		}
		bool operator==(SRef<T> x) const {
			return ref == x.ref;
		}
		bool operator!=(T *x) const {
			return ref != x;
		}
		bool operator!=(SRef<T> x) const {
			return ref != x.ref;
		}

		~SRef() {
			if (&root == rootlist) {
				/* MUST use c-cast here because we don't
				 * know if we should const_cast or not
				 */
				refassert(root.p == (void **) &ref);
				rootlist = rootlist->next;
			} else {
				Root *x = rootlist;
				while (x->next != &root) x = x->next;
				refassert(x->next->p == (void **) &ref);
				x->next = x->next->next;
			}
		}
		T* get() const {
			assert(gcisblocked());
			return ref;
		}
		/* unchecked version of get. Ocasionally there are valid reasons
		 * that the gc would be enabled, for example if assigning
		 * into a scanned type
		 */
		T* uget() const {
			return ref;
		}
		/* Object should NOT be used after a release() without reassignment - this will
		 * probably lead to a NULL pointer dereference
		 */
		T* release() {
			T* t = ref;
			ref = NULL;
			return t;
		}
		T* operator->() const {
			assert(ref != NULL);
			return ref;
		}
	private:
		void addroot() {
			root.p = (void **) &ref;
			root.next = rootlist;
			rootlist = &root;
		}
		T *ref;
		Root root;
