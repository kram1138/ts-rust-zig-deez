(load "../src/utils.rkt")
(loader "lexer")
(loader "ast")
(loader "parser")
(loader "eval")
(loader "object")
(loader "environment")

(define (test-eval input)
  (let* ((lexer (new-lexer input))
         (parser (new-parser lexer))
         (p (parse-programme parser))
         (env (new-environment)))
    (monkey-eval p env)))

(define (test-integer-obj evaulated expected)
  (if (not (obj-int? evaulated)) (error (format "Object is not an interger, but was: " (obj-type evaulated))))
  (if (not (= (obj-value evaulated) expected)) (error (format "Object had wrong value, got:" (obj-value evaulated) ", but want:" expected))))

(define (test-boolean-obj obj expected)
  (if (not (obj-bool? obj)) (error (format "Object is not an bool, but was: " (obj-type obj))))
  (if (not (eq? (obj-value obj) expected)) (error (format "Object had wrong value, got:" (obj-value obj) ", but want:" expected))))

(define (test-null-obj obj)
  (if (not (obj-null? obj)) (error (format "Object is not an NULL, but was: " (obj-type obj)))))


(define (test-eval-integer)
  (define tests (list
                 (list "5" 5)
                 (list "10" 10)
                 (list "-5" -5)
                 (list "-10" -10)
                 (list "5 + 5 + 5 + 5 - 10" 10)
                 (list "2 * 2 * 2 * 2 * 2" 32)
                 (list "-50 + 100 + -50" 0)
                 (list "5 * 2 + 10" 20)
                 (list "5 + 2 * 10" 25)
                 (list "20 + 2 * -10" 0)
                 (list "50 / 2 * 2 + 10" 60)
                 (list "2 * (5 + 10)" 30)
                 (list "3 * 3 * 3 + 10" 37)
                 (list "3 * (3 * 3) + 10" 37)
                 (list "(5 + 10 * 2 + 15 / 3) * 2 + -10" 50)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-integer-obj evaluated (cadr t))) tests))

(define (test-eval-bool)
  (define tests (list
                 (list "true" #t)
                 (list "false" #f)
                 (list "1 < 2" #t)
                 (list "1 > 2" #f)
                 (list "1 < 1" #f)
                 (list "1 > 1" #f)
                 (list "1 == 1" #t)
                 (list "1 != 1" #f)
                 (list "1 == 2" #f)
                 (list "1 != 2" #t)
                 (list "true == true" #t)
                 (list "false == false" #t)
                 (list "true == false" #f)
                 (list "true != false" #t)
                 (list "false != true" #t)
                 (list "(1 < 2) == true" #t)
                 (list "(1 < 2) == false" #f)
                 (list "(1 > 2) == true" #f)
                 (list "(1 > 2) == false" #t)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-boolean-obj evaluated (cadr t))) tests))

(define (test-bang-operator)
  (define tests (list (list "!true" #f) (list "!false" #t) (list "!5" #f) (list "!!true" #t) (list "!!false" #f) (list "!!5" #t)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-boolean-obj evaluated (cadr t))) tests))

(define (test-if-else-expressions)
  (define tests (list
                 (list "if (true) { 10 }" 10)
                 (list "if (false) { 10 }" '())
                 (list "if (1) { 10 }" 10)
                 (list "if (1 < 2) { 10 }" 10)
                 (list "if (1 > 2) { 10 }" '())
                 (list "if (1 > 2) { 10 } else { 20 }" 20)
                 (list "if (1 < 2) { 10 } else { 20 }" 10)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (if (number? (cadr t)) (test-integer-obj evaluated (cadr t)) (test-null-obj evaluated))) tests))

(define (test-return-statements)
  (define tests (list
                 (list "return 10;" 10)
                 (list "return 10; 9" 10)
                 (list "return 2 * 5; 9" 10)
                 (list "9; return 2 * 5; 9;" 10)
                 (list "if (10 > 1) { if (10 > 1) { return 10; } return 1; }" 10)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-integer-obj evaluated (cadr t))) tests))

(define (test-error-handling)
  (define tests (list
                 (list "5 + true;" "type mismatch: INTEGER + BOOLEAN")
                 (list "5 + true; 5;" "type mismatch: INTEGER + BOOLEAN")
                 (list "-true" "unknown operator: -BOOLEAN")
                 (list "true + false" "unknown operator: BOOLEAN + BOOLEAN")
                 (list "5; true + false; 5" "unknown operator: BOOLEAN + BOOLEAN")
                 (list "if (10 > 1) { true + false; }" "unknown operator: BOOLEAN + BOOLEAN")
                 (list "foobar" "identifier not found: foobar")))
  (for-each (lambda (t)
              (define evaluated (test-eval (car t)))             
              (if (not (obj-error? evaluated)) (error (format "no error object returned, got: " evaluated)))
              (if (not (string=? (obj-value evaluated) (cadr t))) (error (format "wrong error message, expected='" (cadr t) "' but got='" (obj-value evaluated) "'")))
              ) tests))

(define (test-let-statements)
  (define tests (list (list "let a = 5; a;" 5) (list "let a = 5 * 5; a;" 25) (list "let a = 5; let b = a; b;" 5) (list "let a = 5; let b = a; let c = a + b + 5; c;" 15)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-integer-obj evaluated (cadr t))) tests))

(define (test-function-object)
  (define evaluated (test-eval "fn(x) { x + 2; };"))

  (if (not (obj-fn? evaluated))
      (error (format "object is not a function, got" evaluated)))

  (if (not (= (length (obj-fn-params evaluated)) 1))
      (error (format "function has wrong parameters. Parameters= " (car (obj-fn-params evaluated))))))

(define (test-function-applications)
  (define tests (list
                 (list "let identity = fn(x) { x; }; identity(5)" 5)
                 (list "let identity = fn(x) { return x; }; identity(5);" 5)
                 (list "let double = fn(x) { x * 2; }; double(5);" 10)
                 (list "let add = fn(x, y) { x + y; }; add(5, 5);" 10)
                 (list "let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));" 20)
                 (list "fn(x) { x; }(5)" 5)))
  (for-each (lambda (t) (define evaluated (test-eval (car t))) (test-integer-obj evaluated (cadr t))) tests))

(display-nl "Starting eval tests...")
(test-eval-integer)
(test-eval-bool)
(test-bang-operator)
(test-if-else-expressions)
(test-return-statements)
(test-error-handling)
(test-let-statements)
(test-function-object)
(test-function-applications)
(display-nl "\tEval tests have passed without errros")