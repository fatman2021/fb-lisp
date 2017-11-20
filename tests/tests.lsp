;; tests.lsp
;;
;;
;; from the parent directory, run from the command line
;; using the 'runlisp' example program
;;
;;    examples/runlisp tests/tests.lsp
;;
;; main file to load all other tests
;; assert.lsp must be first file loaded

(princ "fb-lisp tests - started\n" )

(load "tests/assert.lsp")
(load "tests/bool_op.lsp")
(load "tests/branch.lsp")
(load "tests/eq.lsp")
(load "tests/list.lsp")
(load "tests/mathcomp.lsp")
(load "tests/mathops.lsp")
(load "tests/progn.lsp")
(load "tests/types.lsp")

(princ "fb-lisp tests - complete\n" )
