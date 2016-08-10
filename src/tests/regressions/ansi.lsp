;;;; -*- Mode: Lisp; Syntax: Common-Lisp; indent-tabs-mode: nil -*-
;;;; vim: set filetype=lisp tabstop=8 shiftwidth=2 expandtab:

(in-package :cl-test)

(suite 'regressions/ansi+)


;; HyperSpec – 3.*

;;;;;;;;;;;;;;;;;;;
;; Deftype tests ;;
;;;;;;;;;;;;;;;;;;;

(ext:with-clean-symbols (ordinary1 ordinary2)
  (test ansi.0001.ordinary
    (deftype ordinary1 ()
      `(member nil t))

    (deftype ordinary2 (a b)
      (if a 'CONS `(INTEGER 0 ,b)))

    (is-true  (typep T  'ordinary1))
    (is-false (typep :a 'ordinary1))
    (is-false (typep T '(ordinary2 nil 3)))
    (is-true  (typep 3 '(ordinary2 nil 4)))
    (is-false (typep T '(ordinary2 T nil)))
    (is-true  (typep '(1 . 2) '(ordinary2 T nil)))))

(ext:with-clean-symbols (opt)
  (test ansi.0002.optional
    (deftype opt (a &optional b)
      (if a 'CONS `(INTEGER 0 ,b)))

    (is-true (typep 5 '(opt nil)))
    (is-false (typep 5 '(opt nil 4)))))

(ext:with-clean-symbols (nest)
  (test ansi.0003.nested
    (deftype nest ((a &optional b) c . d)
      (assert (listp d))
      `(member ,a ,b ,c))
    (is-true  (typep  1 '(nest (1 2) 3 4 5 6)))
    (is-false (typep  1 '(nest (2 2) 3 4 5 6)))
    (is-true  (typep '* '(nest (3) 3)))
    (is-true  (typep  3 '(nest (2) 3)))))



;;;;;;;;;;;;;;;;;;;;;;;;;
;; 19.* Pathname tests ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;; Issue #103 ;; logical-pathname-translations not translating
;; https://gitlab.com/embeddable-common-lisp/ecl/issues/103
(test ansi.0004.wildcards
  (setf (logical-pathname-translations "prog")
        '(("CODE;*.*.*" "/tmp/prog/")))
  (is (equal
       (namestring (translate-logical-pathname "prog:code;documentation.lisp"))
       "/tmp/prog/documentation.lisp")))



;;;;;;;;;;;;;;;;;;;;;;;
;; 23.* Reader tests ;;
;;;;;;;;;;;;;;;;;;;;;;;
(progn
  (defstruct example-struct a)
  (test ansi.0005.sharp-s-reader
    (finishes
      (read-from-string
       "(#1=\"Hello\" #S(cl-test::example-struct :A #1#))"))))

