;;;;  Copyright (c) 1992, Giuseppe Attardi.
;;;;
;;;;    This program is free software; you can redistribute it and/or
;;;;    modify it under the terms of the GNU Library General Public
;;;;    License as published by the Free Software Foundation; either
;;;;    version 2 of the License, or (at your option) any later version.
;;;;
;;;;    See file '../Copyright' for full details.

(in-package "CLOS")

;;; ----------------------------------------------------------------------
;;; Methods

;;; ======================================================================
;;; Built-in classes
;;; ----------------------------------------------------------------------
;;;
;;; IMPORTANT!
;;; This class did not exist until now. This was no problem, because it is
;;; not used anywhere in ECL. However, we have to define and we have to
;;; ensure that "T" becomes an instance of BUILT-IN-CLASS.

;;; We have to build the class manually, because
;;;	(ENSURE-CLASS-USING-CLASS NIL ...)
;;; does not work yet, since the class NULL does not exist.
;;;
(setf (find-class 'built-in-class)
      (make-instance (find-class 'class)
		     :name 'built-in-class
		     :direct-superclasses (list (find-class 'class))
		     :direct-slots nil))

(si:instance-class-set (find-class 't) (find-class 'built-in-class))

(defun create-built-in-class (options)
  (let* ((name (first options))
	 (direct-superclasses (mapcar #'find-class (or (rest options)
						       '(t)))))
    (setf (find-class name)
	  (make-instance (find-class 'built-in-class)
			 :name name
			 :direct-superclasses direct-superclasses
			 :direct-slots nil))))

(defmethod make-instance ((class built-in-class) &rest initargs)
  (declare (ignore initargs))
  (error "The built-in class (~A) cannot be instantiated" class))

(mapcar #'create-built-in-class
	  '(;(t object)
	    (sequence)
	      (list sequence)
	        (cons list)
	    (array)
	      (vector array sequence)
	        (string vector)
	        (bit-vector vector)
	    (stream)
	      (file-stream stream)
	      (echo-stream stream)
	      (string-stream stream)
	      (two-way-stream stream)
	      (synonym-stream stream)
	      (broadcast-stream stream)
	      (concatenated-stream stream)
	    (character)
	    (number)
	      (real number)
	        (rational real)
		  (integer rational)
		  (ratio rational)
	        (float real)
	      (complex number)
	    (symbol)
	      (null symbol list)
	      (keyword symbol)
	    (method-combination)
	    (package)
	    (function)
	    (pathname)
	      (logical-pathname pathname)
	    (hash-table)
	    (random-state)
	    (readtable)
	    #+threads (mp::process)
	    #+threads (mp::lock)))

(defmethod ensure-class-using-class ((class null) name &rest rest)
  (multiple-value-bind (metaclass direct-superclasses options)
      (apply #'help-ensure-class rest)
    (apply #'make-instance metaclass :name name options)))

(defmethod change-class ((instance t) (new-class symbol) &rest initargs)
  (apply #'change-class instance (find-class new-class) initargs))

(defmethod make-instances-obsolete ((class symbol))
  (make-instances-obsolete (find-class class))
  class)

(defmethod make-instance ((class-name symbol) &rest initargs)
  (apply #'make-instance (find-class class-name) initargs))

(defmethod slot-makunbound-using-class ((class built-in-class) self slot-name)
  (error "SLOT-MAKUNBOUND-USING-CLASS cannot be applied on built-in objects"))

(defmethod slot-boundp-using-class ((class built-in-class) self slot-name)
  (error "SLOT-BOUNDP-USING-CLASS cannot be applied on built-in objects"))

(defmethod slot-value-using-class ((class built-in-class) self slot-name)
  (error "SLOT-VALUE-USING-CLASS cannot be applied on built-in objects"))

(defmethod (setf slot-value-using-class) (val (class built-in-class) self slot-name)
  (error "SLOT-VALUE-USING-CLASS cannot be applied on built-in objects"))

(defmethod slot-exists-p-using-class ((class built-in-class) self slot-name)
  nil)

;;; ======================================================================
;;; STRUCTURES
;;;

(defclass structure-class (class)
  (slot-descriptions initial-offset defstruct-form constructors documentation
		     copier predicate print-function))

;;; structure-classes cannot be instantiated
(defmethod make-instance ((class structure-class) &rest initargs)
  (declare (ignore initargs))
  (error "The structure-class (~A) cannot be instantiated" class))

(defmethod finalize-inheritance ((class structure-class))
  (call-next-method)
  (dolist (slot (class-slots class))
    (unless (eq :INSTANCE (slotd-allocation slot))
      (error "The structure class ~S can't have shared slots" (class-name class)))))

;;; ----------------------------------------------------------------------
;;; Structure-object
;;;

;;; Structure-object has no slots and inherits only from t:
;;; (defclass structure-object (t) ())

(defclass structure-object (t) ()
  (:metaclass structure-class))

(defmethod make-load-form ((object structure-object) &optional environment)
  (make-load-form-saving-slots object))

(defmethod print-object ((obj structure-object) stream)
  (let* ((class (si:instance-class obj))
	 (slotds (class-slots class)))
    (when (and slotds
	       *print-level*
	       ;; *p-readably* effectively disables *p-level*
	       (not *print-readably*)
	       (zerop *print-level*))
      (write-string "#" stream)
      (return-from print-object obj))
    (write-string "#S(" stream)
    (prin1 (class-name class) stream)
    (do ((scan slotds (cdr scan))
	 (i 0 (1+ i))
	 (limit (or *print-length* most-positive-fixnum))
	 (sv))
	((null scan))
      (declare (fixnum i))
      (when (>= i limit)
	(write-string " ..." stream)
	(return))
      (setq sv (si:instance-ref obj i))
      (write-string " :" stream)
      (prin1 (slotd-name (car scan)) stream)
      (write-string " " stream)
      (prin1 sv stream))
    (write-string ")" stream)
    obj))
