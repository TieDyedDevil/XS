	public: 
		Ref() : ref(NULL) {
			addroot();
		}
		Ref(const Ref<T>& orig) : ref(orig.ref) {
			addroot();
		}
		Ref(T* x) : ref(x) {
			addroot();
		}
		Ref& operator=(const Ref<T>& x) {
			ref = x.ref;
			return *this;
		}
		Ref& operator=(T* p) {
			ref = p;
			return *this;
		}
		operator bool() const {
			return ref != NULL;
		}
		bool operator==(T *x) const {
			return ref == x;
		}
		/* ONLY for comparisons to NULL */
		bool operator==(int x) const {
			/* Cast in assert is to quiet warnings about
			 * NULL in arithmetic
			 */
			assert (reinterpret_cast<void*>(x) == NULL);
			return ref == reinterpret_cast<T*>(x);
		}
		bool operator==(Ref<T> x) const {
			return ref == x.ref;
		}
		bool operator!=(T *x) const {
			return ref != x;
		}
		bool operator!=(Ref<T> x) const {
			return ref != x.ref;
		}
		bool operator!=(int x) const {
			assert (reinterpret_cast<void*>(x) == NULL);
			return ref != reinterpret_cast<T*>(x);
		}

		~Ref() {
			if (&root == rootlist) {
				/* MUST use c-cast here because we don't
				 * know if we should const_cast or not
				 */
				refassert(root.p == (void **) &ref);
				rootlist = rootlist->next;
			} else {
				Root *x = rootlist;
				/* x needs to be predecessor in order
				 * to properly set ->next
				 */
				while (x->next != &root) {
					refassert(x->next); /* If this fails, the root is somehow not in the list */
					x = x->next;
				}
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
		T** rget() {
			return &ref;
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
