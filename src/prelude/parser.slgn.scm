;; Copyright (c) 2013-2014 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define (slogan tokenizer)
  (expression/statement tokenizer))

(define (import tokenizer script-name)
  (if (compile (if (symbol? script-name) 
                   (symbol->string script-name) 
                   script-name) 
               assemble: (tokenizer 'compile-mode?))
      (if (tokenizer 'compile-mode?)
          `(load ,script-name)
          `(load ,(string-append script-name *scm-extn*)))
      (error "failed to compile " script-name)))

(define (expression/statement tokenizer)
  (if (eof-object? (tokenizer 'peek))
      (tokenizer 'next)
      (let ((v (statement tokenizer)))
        (if (not v)
            (set! v (expression tokenizer)))
        (assert-semicolon tokenizer v)
        v)))

(define (statement tokenizer)
  (if (eq? (tokenizer 'peek) '*semicolon*)
      *void*
      (import-stmt tokenizer)))

(define (highligted-line colno)
  (with-output-to-string
    '()
    (lambda ()
      (let loop ((n 1))
        (if (= n colno)
            (display #\^)
            (begin (display #\space)
                   (loop (+ n 1))))))))

(define (highligted-error-line tokenizer)
  (let loop ((line-no (tokenizer 'line))
             (n 1)
             (program-text (tokenizer 'program-text)))
    (if (not (null? program-text))
        (if (= n line-no)
            (cons (car program-text) (highligted-line (tokenizer 'column)))
            (loop line-no (+ n 1) (cdr program-text)))
        #f)))

(define (parser-error tokenizer msg)
  (error (with-output-to-string 
           '()
           (lambda ()
             (if tokenizer
                 (println "at [line: "(tokenizer 'line) 
                          ", column: " (tokenizer 'column) "]. " 
                          msg))
             (let ((hl (highligted-error-line tokenizer)))
               (if hl
                   (begin (println (car hl))
                          (println (cdr hl)))))))))

(define (assert-semicolon tokenizer expr)
  (let ((token (tokenizer 'peek)))
    (if (or (eq? token '*semicolon*)
            (eq? token '*close-brace*)
            (eof-object? token))
        (if (eq? token '*semicolon*)
            (tokenizer 'next))
        (parser-error tokenizer
                      "Statement or expression not properly terminated."))))

(define (import-stmt tokenizer)
  (cond ((eq? (tokenizer 'peek) 'import)
         (tokenizer 'next)
         (import tokenizer (tokenizer 'next)))
        (else
         (func-def-stmt tokenizer))))

(define (func-def-stmt tokenizer)
  (cond ((eq? (tokenizer 'peek) 'fn)
         (tokenizer 'next)
         (let ((name (tokenizer 'peek)))
           (if (not (variable? name))
               (merge-lambda (list 'lambda (func-params-expr tokenizer)) 
                             (func-body-expr tokenizer))
               (begin (tokenizer 'next)
                      (list 'define name (merge-lambda (list 'lambda (func-params-expr tokenizer)) 
                                                       (func-body-expr tokenizer)))))))
        (else (record-def-stmt tokenizer))))
         
(define (assignment-stmt tokenizer)
  (if (name? (tokenizer 'peek))
      (let ((sym (tokenizer 'next)))
        (if (eq? sym 'var)
            (define-stmt tokenizer)
            (cond ((reserved-name? sym)
                   (tokenizer 'put sym)
                   #f)
                  ((eq? (tokenizer 'peek) '*assignment*)
                   (set-stmt sym tokenizer))
                  (else (tokenizer 'put sym) 
                        #f))))
      #f))

(define (macro-def-stmt tokenizer)
  (if (eq? (tokenizer 'peek) 'macro)
      (begin (tokenizer 'next)
             (mk-macro-def (tokenizer 'next) tokenizer))
      (assignment-stmt tokenizer)))

(define (mk-macro-def macro-name tokenizer)
  (if (not (name? macro-name))
      (parser-error tokenizer
                    (with-output-to-string 
                      '() 
                      (lambda () 
                        (display "Invalid macro name: ") 
                        (display macro-name)))))
  (def-macro macro-name (make-+macro (macro-params tokenizer) (macro-body-expr tokenizer))))

(define (macro-body-expr tokenizer)
  (func-body-expr tokenizer #t))

(define (macro-params tokenizer)
  (let ((nxt (tokenizer 'next)))
    (if (eq? '*open-paren* nxt)
        (let loop ((p (tokenizer 'peek))
                   (params '()))
          (cond ((name? p)
                 (check-if-reserved-name p tokenizer)
                 (tokenizer 'next)
                 (assert-comma-separator tokenizer '*close-paren*)
                 (loop (tokenizer 'peek) (append params (list p))))
                (else 
                 (if (eq? '*close-paren* (tokenizer 'peek))
                     (begin (tokenizer 'next)
                            params)
                     (parser-error tokenizer "Expected closing parenthesis after macro parameters.")))))
        (if (variable? nxt)
            (check-if-reserved-name nxt tokenizer)
            (parser-error tokenizer "Invalid macro parameter specification.")))))

(define (enter-scope)
  (set! *macros* (cons (make-table) *macros*)))

(define (leave-scope)
  (set! *macros* (cdr *macros*)))

(define (define-stmt tokenizer)
  (if (variable? (tokenizer 'peek))
      (if (reserved-name? (tokenizer 'peek))
          (parser-error tokenizer "Reserved name cannot be used as identifier.")
          (var-def-set (tokenizer 'next) tokenizer #t))
      (parser-error tokenizer "Invalid variable name.")))

(define (set-stmt sym tokenizer)
  (var-def-set sym tokenizer #f))

(define (normalize-rvar sym)
  (let ((s (symbol->string sym)))
    (string->symbol (substring s 1 (string-length s)))))

(define (rvar? sym)
  (and (symbol? sym) (char=? #\? (string-ref (symbol->string sym) 0))))

(define (var-def-set sym tokenizer def)
  (if (get-macro-def sym)
      (parser-error tokenizer (with-output-to-string 
                                '()
                                (lambda ()
                                  (display "Macro name can't be used as a variable: ")
                                  (display sym) 
                                  (display ".")
                                  (display " (See `undef_macro' in the documentation.)")))))
  (if (eq? (tokenizer 'peek) '*assignment*)
      (begin (tokenizer 'next)
             (if (rvar? sym)
                 (if def
                     (parser-error tokenizer (with-output-to-string 
                                               '()
                                               (lambda ()
                                                 (display "Invalid character in variable name: ")
                                                 (display sym))))
                     (list 'rbind (normalize-rvar sym) (expression tokenizer)))
                 (list (if def 'define 'set!) sym (expression tokenizer))))
      (parser-error tokenizer "Expected assignment.")))

(define (expression tokenizer)
  (let ((expr (binary-expr tokenizer)))
    (let loop ((expr expr)) 
      (if (eq? (tokenizer 'peek) '*open-paren*)
          (loop (func-call-expr expr tokenizer))
          expr))))

(define (then-expr tokenizer)
  (if (not (eq? (tokenizer 'next) 'then))
      (parser-error tokenizer "Expected keyword: then"))
  (func-body-expr tokenizer #t))

(define (if-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) 'if)
         (tokenizer 'next)
         (let ((expr (cons 'if (list (expression tokenizer)
                                     (then-expr tokenizer)))))
           (if (eq? (tokenizer 'peek) 'else)
               (begin (tokenizer 'next)
                      (if (eq? (tokenizer 'peek) 'if)
                          (append expr (list (if-expr tokenizer)))
                          (append expr (list (expression tokenizer)))))
               expr)))
        (else (case-expr tokenizer))))

(define (case-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) 'case)
         (tokenizer 'next)
         (let ((value (expression tokenizer)))
           (if (not (eq? (tokenizer 'peek) '*open-brace*))
               (parser-error tokenizer "Missing opening brace before case expressions.")
               (tokenizer 'next))
           (let loop ((token (tokenizer 'peek))
                      (body '()))
             (if (eq? token '*close-brace*)
                 (begin (tokenizer 'next)
                        (append `(case ,value) (reverse body)))
                 (let ((expr (normalize-sym (expression tokenizer))))
                   (if (not (eq? (tokenizer 'peek) '*colon*))
                       (parser-error tokenizer "Missing colon after case expression.")
                       (tokenizer 'next))
                   (let ((result (func-body-expr tokenizer #t)))
                     (loop (tokenizer 'peek)
                           (cons (list (if (or (list? expr) (eq? expr 'else)) expr (cons expr '()))
                                       result) body))))))))
        (else (match-expr tokenizer))))

(define (pattern-expression tokenizer)
  (tokenizer 'pattern-mode-on)
  (let ((expr (expression tokenizer)))
    (tokenizer 'pattern-mode-off)
    expr))

(define (unbound? r) (eq? r '*unbound*))

(define (match-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) 'match)
         (tokenizer 'next)
         (let ((value (expression tokenizer)))
           (if (not (eq? (tokenizer 'peek) '*open-brace*))
               (parser-error tokenizer "Missing opening brace before match expressions.")
               (tokenizer 'next))
           (let loop ((token (tokenizer 'peek))
                      (body '()))
             (if (eq? token '*close-brace*)
                 (begin (tokenizer 'next)
                        `(let ((*match-expr* ,value))
                           (let ((*value* *match-expr*)
                                 (*orig-value* *match-expr*)
                                 (*match-found* #f)
                                 (*result* '*unbound*))
                             ,@(reverse body)
                             (if (unbound? *result*)
                                 (error "No match found.")
                                 *result*))))
                 (let ((pattern (pattern-expression tokenizer))
                       (guard #t))
                   (if (eq? (tokenizer 'peek) 'where)
                       (begin (tokenizer 'next)
                              (set! guard (expression tokenizer))))
                   (if (not (eq? (tokenizer 'peek) '*colon*))
                       (parser-error tokenizer "Missing colon after pattern.")
                       (tokenizer 'next))
                   (let ((consequent (func-body-expr tokenizer #t)))
                     (if (not (eq? guard #t))
                         (set! consequent `(if ,guard 
                                               ,consequent 
                                               (begin (set! *match-found* #f) 
                                                      (set! *value* *orig-value*)
                                                      '*unbound*))))
                     (loop (tokenizer 'peek)
                           (cons (match-pattern pattern consequent) body))))))))
        (else (try-catch-expr tokenizer))))

(define (try-catch-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) 'try)
         (tokenizer 'next)
         (let ((try-expr (expression tokenizer)))
           (case (tokenizer 'peek)
             ((catch)
              (make-try-catch-expr try-expr (catch-args tokenizer) 
                                   (expression tokenizer) 
                                   (finally-expr tokenizer)))
             ((finally)
              (make-try-catch-expr try-expr '(*e*) '(raise *e*)
                                   (finally-expr tokenizer)))
             (else
              (parser-error tokenizer "Expected catch or finally clauses.")))))
        (else #f)))

(define (catch-args tokenizer)
  (tokenizer 'next)
  (if (not (eq? (tokenizer 'peek) '*open-paren*))
      (parser-error tokenizer "Missing opening parenthesis."))
  (tokenizer 'next)
  (let ((result (tokenizer 'next)))
    (if (not (variable? result))
        (parser-error tokenizer "Missing exception identifier."))
    (if (not (eq? (tokenizer 'peek) '*close-paren*))
        (parser-error tokenizer "Missing closing parenthesis."))
    (tokenizer 'next)
    (list result)))

(define (finally-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) 'finally)
         (tokenizer 'next)
         (expression tokenizer))
        (else *void*)))
      
(define (make-try-catch-expr try-expr catch-args catch-expr finally-expr)
  (if (void? finally-expr)
      (list 'with-exception-catcher 
            (list 'lambda catch-args catch-expr)
            (list 'lambda (list) try-expr))
      (list 'let (list (list '*finally* (list 'lambda (list) finally-expr)))
            (list 'with-exception-catcher 
                  (list 'lambda catch-args (list 'begin '(*finally*) catch-expr))
                  (list 'lambda (list) (list 'begin try-expr '(*finally*)))))))
                   
(define (normalize-sym s)
  (if (and (list? s)
           (eq? (car s) 'quote))
      (cadr s)
      s))

(define (expression-with-semicolon tokenizer)
  (let ((expr (expression tokenizer)))
    (if (eq? (tokenizer 'peek) '*semicolon*)
        (tokenizer 'next))
    expr))

(define (block-expr tokenizer #!optional (use-let #f))
  (if (not (eq? (tokenizer 'peek) '*open-brace*))
      (parser-error tokenizer "Missing block start.")
      (begin (enter-scope)
             (tokenizer 'next)
             (let loop ((expr (if use-let (cons 'let (cons '() '())) (cons 'begin '())))
                        (count 0))
               (let ((token (tokenizer 'peek)))
                 (cond ((eq? token '*close-brace*)
                        (leave-scope)
                        (tokenizer 'next)
                        (if (zero? count) (append expr (list *void*)) expr))
                       ((eof-object? token)
                        (parser-error tokenizer "Unexpected end of input. Missing closing brace?"))
                       (else
                        (loop (append expr (list (expression/statement tokenizer)))
                              (+ 1 count)))))))))

(define (binary-expr tokenizer)
  (let loop ((expr (cmpr-expr tokenizer)))
    (if (and-or-opr? (tokenizer 'peek))
        (case (tokenizer 'next)
          ((*and*) (loop (swap-operands (append (and-expr tokenizer) (list expr)))))
          ((*or*) (loop (swap-operands (append (or-expr tokenizer) (list expr))))))
        expr)))
  
(define (cmpr-expr tokenizer)
  (let loop ((expr (addsub-expr tokenizer)))
    (if (cmpr-opr? (tokenizer 'peek))
        (case (tokenizer 'next)
          ((*equals*) (loop (swap-operands (append (eq-expr tokenizer) (list expr)))))
          ((*less-than*) (loop (swap-operands (append (lt-expr tokenizer) (list expr)))))
          ((*greater-than*) (loop (swap-operands (append (gt-expr tokenizer) (list expr)))))
          ((*less-than-equals*) (loop (swap-operands (append (lteq-expr tokenizer) (list expr)))))
          ((*greater-than-equals*) (loop (swap-operands (append (gteq-expr tokenizer) (list expr))))))
        expr)))

(define (addsub-expr tokenizer)
  (let loop ((expr (term-expr tokenizer)))
    (if (add-sub-opr? (tokenizer 'peek))
        (case (tokenizer 'next)
          ((*plus*) (loop (swap-operands (append (add-expr tokenizer) (list expr)))))
          ((*minus*) (loop (swap-operands (append (sub-expr tokenizer) (list expr))))))
        expr)))

(define (factor-expr tokenizer)
  (let ((token (tokenizer 'peek)))
    (if (eq? token '*open-paren*)
        (begin (tokenizer 'next)
               (let ((expr (expression tokenizer)))
                 (if (not (eq? (tokenizer 'peek) '*close-paren*))
                     (begin (parser-error tokenizer "Missing closing parenthesis.")
                            #f)
                     (begin (tokenizer 'next)
                            (member-access/funcall-expr expr tokenizer)))))
        (let ((expr (if-expr tokenizer)))
          (if expr
              expr
              (let-expr tokenizer))))))

(define (handle-rvar-access sym)
  (if (rvar? sym)
      (list 'rget (normalize-rvar sym))
      sym))

(define (literal-expr tokenizer)
  (let ((expr (func-def-expr tokenizer)))
    (if expr
        (member-access/funcall-expr expr tokenizer)
        (let ((token (tokenizer 'peek)))
          (cond ((or (number? token)
                     (string? token)
		     (char? token))
                 (slgn-repr->scm-repr (tokenizer 'next)))
                ((add-sub-opr? token)
                 (tokenizer 'next)
                 (let ((sub (eq? token '*minus*))
                       (expr (literal-expr tokenizer)))
                   (if sub (list '- expr) expr)))
                ((variable? token)
		 (cond ((eq? token '?)
			(tokenizer 'next)
			(list 'rvar))
		       (else
			(let ((var (tokenizer 'next)))
			  (if (eq? (tokenizer 'peek) '*period*)
			      (begin (tokenizer 'next)
				     (closure-member-access var tokenizer))
			      (handle-rvar-access (slgn-repr->scm-repr var)))))))
                ((eq? token '*open-bracket*)
                 (list-literal tokenizer))
                ((eq? token '*open-brace*)
                 (block-expr tokenizer #t))
                ((eq? token '*hash*)
                 (array-literal tokenizer))
                ((eq? token '*bang*)
                 (tokenizer 'next)
		 (tokenizer 'quote-mode-on)
                 (let ((qe `(quote ,(expression tokenizer))))
		   (tokenizer 'quote-mode-off)
		   qe))
                (else (parser-error tokenizer "Invalid literal expression.")))))))

(define (member-access/funcall-expr expr tokenizer)
  (cond ((eq? (tokenizer 'peek) '*period*)
         (begin (tokenizer 'next)
                (closure-member-access expr tokenizer)))
        ((eq? (tokenizer 'peek) '*open-paren*)
         (func-call-expr expr tokenizer))
        (else expr)))

(define (list-literal tokenizer)
  (tokenizer 'next)
  (let loop ((result (if (tokenizer 'quote-mode?) (list) (list 'list)))
             (first #t))
    (let ((token (tokenizer 'peek)))
      (if (eq? token '*close-bracket*)
          (begin (tokenizer 'next)
                 (reverse result))
          (let ((expr (expression tokenizer)))
            (let ((pl (if first (let ((t (tokenizer 'peek)))
                                  (not (or (eq? t '*comma*)
                                           (eq? t '*close-bracket*))))
                          #f)))
              (if pl (pair-literal expr tokenizer)
                  (begin (assert-comma-separator tokenizer '*close-bracket*)
                         (loop (cons expr result) #f)))))))))

(define (pair-literal expr tokenizer)
  (let ((result (if (tokenizer 'quote-mode?) 
		    (cons expr (expression tokenizer))
		    (list 'cons expr (expression tokenizer)))))
    (if (not (eq? (tokenizer 'peek) '*close-bracket*))
        (parser-error tokenizer "Pair not terminated.")
        (begin (tokenizer 'next)
               result))))

(define (array-literal tokenizer)
  (tokenizer 'next)
  (let ((is-byte-array (eq? (tokenizer 'peek) 'b)))
    (if is-byte-array (tokenizer 'next))
    (if (eq? (tokenizer 'peek) '*open-bracket*)
        (begin (tokenizer 'next)
               (let loop ((expr (list (if is-byte-array 'u8vector 'vector)))
                          (token (tokenizer 'peek)))
                 (cond ((eq? token '*close-bracket*)
                        (tokenizer 'next)
                        (reverse expr))
                       (else (let ((e (expression tokenizer)))
                               (assert-comma-separator tokenizer '*close-bracket*)
                               (loop (cons e expr) (tokenizer 'peek)))))))
        (parser-error tokenizer "Invalid start of array literal."))))

(define (let-body-expr tokenizer)
  (if (not (eq? (tokenizer 'next) 'in))
      (parser-error tokenizer "Expected keyword: in"))
  (func-body-expr tokenizer))

(define (let-expr tokenizer)
  (let ((letkw (letkw? (tokenizer 'peek))))
    (cond (letkw
	   (tokenizer 'next)
	   (let loop ((result '()))
	     (let ((sym (tokenizer 'next)))
	       (if (not (name? sym))
		   (parser-error tokenizer (with-output-to-string 
                                             '()
                                             (lambda ()
                                               (display "Expected name instead of ")
                                               (display sym) 
                                               (display ".")))))
	       (if (reserved-name? sym)
		   (parser-error tokenizer (with-output-to-string
                                             '()
                                             (lambda ()
                                               (display "Invalid variable name: ")
                                               (display sym) 
                                               (display ".")))))
	       (if (eq? (tokenizer 'peek) '*assignment*)
		   (tokenizer 'next)
		   (parser-error tokenizer "Expected assignment."))
	       (let ((expr (expression tokenizer)))
		 (cond ((eq? (tokenizer 'peek) '*comma*)
			(tokenizer 'next)
			(loop (append result (list (list sym expr)))))
		       (else (append (list letkw) 
				     (cons (append result (list (list sym expr))) 
					   (list (let-body-expr tokenizer))))))))))
	  (else (func-call-expr (literal-expr tokenizer) tokenizer)))))

(define (letkw? sym)
  (if (and (symbol? sym)
	   (or (eq? sym 'let)
	       (eq? sym 'letseq)
	       (eq? sym 'letrec)))
      (cond ((eq? sym 'letseq)
             'let*)
            (else sym))
      #f))

(define (func-def-expr tokenizer)
  (if (eq? (tokenizer 'peek) 'fn)
      (begin (tokenizer 'next)
             (merge-lambda (list 'lambda (func-params-expr tokenizer)) 
                           (func-body-expr tokenizer)))
      #f))

(define (merge-lambda lambda-expr lambda-body)
  (if (not (list? lambda-body))
      (merge-lambda lambda-expr (list 'begin lambda-body))
      (if (<= 1 (length lambda-body))
          (append lambda-expr (list lambda-body))
          (let loop ((lambda-expr lambda-expr)
                     (lambda-body (if (eq? (car lambda-body) 'begin)
                                      (cdr lambda-body)
                                      lambda-body)))
            (if (null? lambda-body)
                lambda-expr
                (loop (append lambda-expr (list (car lambda-body)))
                      (cdr lambda-body)))))))

(define (func-body-expr tokenizer #!optional (use-let #f))
  (enter-scope)
  (let ((expr (if (eq? (tokenizer 'peek) '*open-brace*)
                  (block-expr tokenizer use-let)
                  (let ((expr (statement tokenizer)))
                    (if (not expr)
                        (expression tokenizer)
                        expr)))))
    (leave-scope)
    expr))

(define (func-call-expr func-val tokenizer)
  (if (and (name? func-val)
           (get-macro-def func-val)
           (not (tokenizer 'pattern-mode?)))
      (macro-call-expr func-val tokenizer)
      (cond ((eq? (tokenizer 'peek) '*open-paren*)
             (if (and (name? func-val)
                      (tokenizer 'pattern-mode?))
                 (let ((s (symbol->string func-val)))
                   (set! func-val (string->symbol (string-append "+" s)))))
             (tokenizer 'next)
             (let ((expr (cons func-val (func-args-expr tokenizer))))
               (if (eq? (tokenizer 'peek) '*close-paren*)
                   (begin (tokenizer 'next) 
                          expr)
                   (parser-error tokenizer "Missing closing parenthesis after function argument list."))))
            (else func-val))))

(define (macro-args-list tokenizer)
  (let loop ((args '()))
    (let ((token (tokenizer 'peek)))
      (if (not (eq? token '*close-paren*))
          (let ((expr (func-body-expr tokenizer #t)))
            (assert-comma-separator tokenizer '*close-paren*)
            (loop (append args (list expr))))
          args))))

(define (macro-call-expr macro-name tokenizer)
  (if (not (eq? (tokenizer 'peek) '*open-paren*))
      (parser-error tokenizer "Missing macro argument list.")
      (tokenizer 'next))
  (let ((m (get-macro-def macro-name))
        (args (macro-args-list tokenizer)))
    (if (eq? (tokenizer 'peek) '*close-paren*)
        (tokenizer 'next)
        (parser-error tokenizer "Missing closing parenthesis after macro arguments."))
    (expand-macro macro-name m args tokenizer)))

(define (expand-macro macro-name m args tokenizer)
  (if (and (list? (+macro-params m))
           (not (= (length (+macro-params m)) (length args))))
      (parser-error tokenizer (with-output-to-string 
                                '()
                                (lambda ()
                                  (display "macro ")
                                  (display macro-name)
                                  (display " expects exactly ")
                                  (display (length (+macro-params m)))
                                  (display " arguments.")))))
  (let ((body (+macro-body m))
        (mparams (+macro-params m)))
    (if (symbol? mparams)
        (begin (set! args (list `(list ,@args)))
               (set! mparams (list mparams))))
    (if (list? body)
	(replace-macro-args mparams args body)
        (if (variable? body)
            (replace-macro-var body mparams args)
            body))))

(define (mk-eval-macro-params params)
  (let loop ((params params)
             (result '()))
    (cond ((null? params)
           (reverse result))
          (else (loop (cdr params) (cons (string->symbol (string-append "~" (symbol->string (car params)))) 
                                         result))))))

(define (record-def-stmt tokenizer)
  (if (eq? (tokenizer 'peek) 'record)
      (begin (tokenizer 'next)
	     (let ((token (tokenizer 'peek)))
	       (if (not (variable? token))
		   (parser-error tokenizer "Missing record name."))
	       (mk-record-expr (tokenizer 'next) tokenizer)))
      (macro-def-stmt tokenizer)))

(define (mk-record-expr name tokenizer)
  (if (eq? (tokenizer 'peek) '*open-paren*)
      (begin (tokenizer 'next)
	     (let loop ((token (tokenizer 'peek))
			(members '())
                        (default-values '()))
	       (cond ((variable? token)
		      (set! token (tokenizer 'next))
                      (cond ((eq? (tokenizer 'peek) '*assignment*)
                             (tokenizer 'next)
                             (let ((val (tokenizer 'next)))
                               (assert-comma-separator tokenizer '*close-paren*)
                               (loop (tokenizer 'peek) (cons token members)
                                     (cons val default-values))))
                            (else
                             (assert-comma-separator tokenizer '*close-paren*)
                             (loop (tokenizer 'peek) (cons token members) (cons #f default-values)))))
		     ((eq? token '*close-paren*)
		      (tokenizer 'next)
		      (def-struct-expr name (reverse members) (reverse default-values)))
		     (else (parser-error tokenizer "Invalid record specification.")))))
      (parser-error tokenizer "Expected record member specification.")))

(define (def-struct-expr name members default-values)
  (append (list 'begin (append (list 'define-structure name) members))
	  (mk-struct-accessors/modifiers name members default-values)))

(define (mk-record-constructor recname members default-values)
  (list 'lambda (append (list '#!key) (mk-record-constructor-params members default-values))
        (cons (string->symbol (string-append "make-" recname)) members)))

(define (mk-record-constructor-params members default-values)
  (let loop ((members members)
             (default-values default-values)
             (params '()))
    (cond ((null? members)
           (reverse params))
          (else (loop (cdr members) (cdr default-values)
                      (cons (list (car members) (car default-values)) params))))))

(define (mk-struct-accessors/modifiers name members default-values)
  (let ((sname (symbol->string name)))
    (let loop ((members members)
               (expr (list (list 'define (string->symbol sname) 
                                 (mk-record-constructor sname members default-values))
                           (list 'define 
                                 (string->symbol (string-append "is_" sname))
                                 (string->symbol (string-append sname "?"))))))
      (if (null? members)
          (reverse expr)
          (begin (loop (cdr members)
                       (append expr (member-accessor/modifier name (car members)))))))))

(define (member-accessor/modifier name mem)
  (let ((sname (symbol->string name))
	(smem (symbol->string mem)))
    (let ((scm-accessor (string->symbol (string-append sname "-" smem)))
	  (scm-modifier (string->symbol (string-append sname "-" smem "-set!")))
	  (slgn-accessor (string->symbol (string-append sname "_" smem)))
	  (slgn-modifier (string->symbol (string-append sname "_set_" smem))))
      (list (list 'define slgn-accessor scm-accessor)
	    (list 'define slgn-modifier scm-modifier)))))

(define (assert-comma-separator tokenizer end-seq-char)
  (let ((token (tokenizer 'peek)))
    (if (or (eq? token '*comma*)
            (eq? token end-seq-char))
        (if (eq? token '*comma*) (tokenizer 'next))
        (parser-error tokenizer (with-output-to-string
                                  '()
                                  (lambda ()
                                    (display "Missing comma or ") 
                                    (display end-seq-char) 
                                    (display ".")))))))

(define (func-args-expr tokenizer)
  (let loop ((args '()))
    (let ((token (tokenizer 'peek)))
      (if (not (eq? token '*close-paren*))
          (cond ((variable? token)
                 (let ((sym (tokenizer 'next)))
                   (if (eq? (tokenizer 'peek) '*assignment*)
                       (begin (tokenizer 'next)
                              (let ((expr (expression tokenizer)))
                                (assert-comma-separator tokenizer '*close-paren*)
                                (loop (append args (list (slgn-variable->scm-keyword sym) expr)))))
                       (begin (tokenizer 'put sym)
                              (let ((expr (expression tokenizer)))
                                (assert-comma-separator tokenizer '*close-paren*)
                                (loop (append args (list expr))))))))
                (else
                 (let ((expr (expression tokenizer)))
                   (assert-comma-separator tokenizer '*close-paren*)
                   (loop (append args (list expr))))))
          args))))

(define (check-if-reserved-name sym tokenizer)
  (if (reserved-name? sym)
      (parser-error tokenizer (with-output-to-string 
                                '()
                                (lambda ()
                                  (display "Invalid use of reserved name: ") 
                                  (display sym) 
                                  (display "."))))
      sym))
  
(define (check-func-param tokenizer) 
  (check-if-reserved-name (tokenizer 'next) tokenizer))

(define (func-params-expr tokenizer)
  (cond ((eq? (tokenizer 'peek) '*open-paren*)
         (tokenizer 'next)
         (let loop ((params '())
                    (directives-found #f))
           (let ((token (tokenizer 'peek)))
             (cond ((variable? token)
                    (let ((sym (check-func-param tokenizer)))
                      (cond ((param-directive? sym)
                             (loop (cons (slgn-directive->scm-directive sym) params) #t))
                            ((eq? (tokenizer 'peek) '*assignment*)
                             (tokenizer 'next)
                             (let ((expr (expression tokenizer)))
                               (assert-comma-separator tokenizer '*close-paren*)
                               (if directives-found
                                   (loop (cons (list sym expr) params) directives-found)
                                       (loop (cons (list sym expr) (cons (slgn-directive->scm-directive '@optional) params)) #t))))
                            (else 
                             (assert-comma-separator tokenizer '*close-paren*)
                             (loop (cons sym params) directives-found)))))
                   (else 
                    (if (eq? token '*close-paren*)
                        (begin (tokenizer 'next)
                               (reverse params))
                        (parser-error tokenizer "Missing closing parenthesis after parameter list.")))))))
        ((variable? (tokenizer 'peek))
         (check-func-param tokenizer))
        (else 
         (parser-error tokenizer "Missing opening parenthesis at the start of parameter list."))))

(define (param-directive? sym)
  (memq sym '(@optional @key @rest)))

(define (closure-member-access var tokenizer)
  (if (variable? (tokenizer 'peek))
      (let loop ((expr `(,var ',(tokenizer 'next))))
	(if (eq? (tokenizer 'peek) '*period*)
	    (begin (tokenizer 'next)
		   (if (variable? (tokenizer 'peek))
		       (loop (cons expr `(',(tokenizer 'next))))
		       (parser-error tokenizer "Expected name.")))
	    expr))
      (parser-error tokenizer "Expected name.")))

(define (add-expr tokenizer)
  (swap-operands (cons '+ (list (term-expr tokenizer)))))

(define (sub-expr tokenizer)
  (swap-operands (cons '- (list (term-expr tokenizer)))))

(define (mult-expr tokenizer)
  (swap-operands (cons '* (list (factor-expr tokenizer)))))

(define (div-expr tokenizer)
  (swap-operands (cons '/ (list (factor-expr tokenizer)))))

(define (eq-expr tokenizer)
  (swap-operands (cons 'equal? (list (addsub-expr tokenizer)))))

(define (lt-expr tokenizer)
  (swap-operands (cons '< (list (addsub-expr tokenizer)))))

(define (lteq-expr tokenizer)
  (swap-operands (cons '<= (list (addsub-expr tokenizer)))))

(define (gt-expr tokenizer)
  (swap-operands (cons '> (list (addsub-expr tokenizer)))))

(define (gteq-expr tokenizer)
  (swap-operands (cons '>= (list (addsub-expr tokenizer)))))

(define (and-expr tokenizer)
  (swap-operands (cons 'and (list (cmpr-expr tokenizer)))))

(define (or-expr tokenizer)
  (swap-operands (cons 'or (list (cmpr-expr tokenizer)))))

(define (term-expr tokenizer)
  (let loop ((expr (factor-expr tokenizer)))
    (if (mult-div-opr? (tokenizer 'peek))
        (case (tokenizer 'next)
          ((*asterisk*) (loop (swap-operands (append (mult-expr tokenizer) (list expr)))))
          ((*backslash*) (loop (swap-operands (append (div-expr tokenizer) (list expr))))))
        expr)))

(define (add-sub-opr? token)
  (or (eq? token '*plus*)
      (eq? token '*minus*)))

(define (mult-div-opr? token)
  (or (eq? token '*asterisk*)
      (eq? token '*backslash*)))

(define (cmpr-opr? token)
  (or (eq? token '*equals*)
      (eq? token '*less-than*)
      (eq? token '*greater-than*)
      (eq? token '*less-than-equals*)
      (eq? token '*greater-than-equals*)))

(define (and-or-opr? token)
  (or (eq? token '*and*)
      (eq? token '*or*)))

(define (swap-operands expr)
  (if (= 3 (length expr))
      (list (car expr) (caddr expr) (cadr expr))
      expr))

(define (variable? sym)
  (and (symbol? sym)
       (char-valid-name-start? (string-ref (symbol->string sym) 0))))

(define *reserved-names* '(var record fn 
                               if then else 
                               case match where
                               try catch finally
                               let letseq letrec in
                               macro import))

(define (reserved-name? sym)
  (and (symbol? sym)
       (memq sym *reserved-names*)))

(define (name? sym) 
  (or (variable? sym)
      (reserved-name? sym)))
