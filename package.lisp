;;;; package.lisp -*- Mode: Lisp;-*- 
(cl:in-package "COMMON-LISP-USER")


(defpackage "https://github.com/g000001/slotted-objects"
  (:nicknames slotted-objects)
  (:use)
  (:export 
   slotted-class
   slotted-object
   make-unbound-marker
   allocate-slotted-instance
   class-wrapper
   instance-wrapper
   instance-slots
   initialize-slot-from-initarg
   initialize-slot-from-initfunction)
  ;; syntax
  (:export slotted-objects-syntax))


(defpackage "https://github.com/g000001/slotted-objects#internals"
  (:use "https://github.com/g000001/slotted-objects"
        "C2CL"))


;;; *EOF*
