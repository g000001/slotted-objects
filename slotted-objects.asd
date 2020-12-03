;;;; slotted-objects.asd -*- Mode: Lisp;-*- 

(cl:in-package :asdf)


(defsystem :slotted-objects
  :serial T
  :depends-on (:closer-mop)
  :components ((:file "package")
               (:file "slotted-objects")))


;;; *EOF*
