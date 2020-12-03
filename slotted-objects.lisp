;;;; slotted-objects.lisp -*- Mode: Lisp;-*- 
(cl:in-package "https://github.com/g000001/slotted-objects#internals")


(defclass slotted-class (standard-class)
  ())


(defmethod validate-superclass ((class slotted-class) (super standard-class))
  T)


(defclass slotted-object (standard-object)
  ()
  (:metaclass slotted-class))


(defmacro make-unbound-marker ()
  #+lispworks 'clos::*slot-unbound*
  #+sbcl '(sb-kernel:make-unbound-marker))


(defun allocate-instance-data (wrapper instance-slots)
  #+allegro
  (excl::.primcall 'sys::new-standard-instance
                   wrapper
                   instance-slots)
  #+lispworks
  (sys:alloc-fix-instance wrapper instance-slots)
  #+sbcl
  (let* ((instance (sb-pcl::%make-instance (1+ sb-vm:instance-data-start))))
    (setf (sb-kernel::%instance-layout instance) wrapper)
    (setf (sb-pcl::std-instance-slots instance) instance-slots)
    instance)
  #+ccl
  (let ((instance (ccl::gvector :instance 0 wrapper nil)))
    (setf (ccl::instance.hash instance) (ccl::strip-tag-to-fixnum instance)
	  (ccl::instance.slots instance) instance-slots)
    instance))


(defun class-wrapper (class)
  #+allegro (excl::class-wrapper class)
  #+lispworks (clos::class-wrapper class)
  #+sbcl (sb-pcl::class-wrapper class)
  #+ccl (ccl::instance-class-wrapper class))


(defun instance-wrapper (ins)
  #+allegro (excl::std-instance-wrapper ins)
  #+lispworks (clos::standard-instance-wrapper ins)
  #+sbcl (sb-kernel::%instance-layout ins)
  #+ccl (ccl::instance.class-wrapper ins))


(defun instance-slots (ins)
  #+allegro (excl::std-instance-slots ins)
  #+lispworks (clos::standard-instance-static-slots ins)
  #+sbcl (sb-pcl::std-instance-slots ins)
  #+ccl (ccl::instance.slots ins))


(defun (setf instance-slots) (value ins)
  (setf 
   #+allegro (excl::std-instance-slots ins)
   #+lispworks (clos::standard-instance-static-slots ins)
   #+sbcl (sb-pcl::std-instance-slots ins)
   #+ccl (ccl::instance.slots ins)
   value))


(defmethod allocate-instance ((class slotted-class) &rest initargs)
  (allocate-instance-data (class-wrapper class)
                          (make-sequence 'vector
                                         (length (class-slots class))
                                         :initial-element (make-unbound-marker))))


(defmethod slot-value-using-class ((class slotted-class) instance (slotd slot-definition))
  (elt (instance-slots instance)
       (slot-definition-location slotd)))


(defmethod (setf slot-value-using-class)
           (value (class slotted-class) instance (slotd slot-definition))
  (setf (elt (instance-slots instance)
             (slot-definition-location slotd))
        value))


(defgeneric initialize-slot-from-initarg (class instance slotd initargs))


(defmethod initialize-slot-from-initarg (class instance slotd initargs)
  (let ((slot-initargs (slot-definition-initargs slotd)))
    (loop :for (initarg value) :on initargs :by #'cddr
          :do (when (member initarg slot-initargs)
                (setf (slot-value-using-class class instance slotd)
                      value)
                (return T)))))


(defgeneric initialize-slot-from-initfunction (class instance slotd))


(defmethod initialize-slot-from-initfunction (class instance slotd)
  (let ((initfun (slot-definition-initfunction slotd)))
    (unless (not initfun)
      (setf (slot-value-using-class class instance slotd)
            (funcall initfun)))))


(defmethod shared-initialize 
           ((instance slotted-object) slot-names &rest initargs)
  (let ((class (class-of instance)))
    (dolist (slotd (class-slots class))
      (unless (initialize-slot-from-initarg class instance slotd initargs)
        (when (or (eq t slot-names)
                  (member (slot-definition-name slotd) slot-names))
          (initialize-slot-from-initfunction class instance slotd)))))
  instance)


;;; *EOF*
