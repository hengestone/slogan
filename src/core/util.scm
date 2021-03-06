;; Copyright (c) 2013-2017 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define (scm-repr->slgn-repr val)
  (if (or (number? val) 
          (string? val)
          (char? val)) 
      val
      (repr-convert val *scheme-reprs*)))

(define (slgn-repr->scm-repr val)
  (repr-convert val *slogan-reprs*))

(define (slgn-directive->scm-directive s)
  (case s
    ((@optional) '#!optional)
    ((@key) '#!key)
    ((@rest) '#!rest)
    (else s)))

(define (slgn-variable->scm-keyword var)
  (string->keyword (symbol->string var)))

(define (slgn-symbol->scm-sym/kw s convfn)
  (let ((str (symbol->string s)))
    (convfn
     (string_replace_all 
      str
      #\_ #\-))))

(define (scm-symbol->slgn-sym s)
  (let ((str (symbol->string s)))
    (string->symbol
     (string_replace_all 
      str
      #\- #\_))))

(define (slgn-symbol->scm-keyword s)
  (slgn-symbol->scm-sym/kw s string->keyword))

(define (slgn-symbol-quote? s)
  (and (list? s) (scm-not (null? s))
       (scm-eq? (scm-car s) 'quote)))

(define (slgn-path/settings->scm-path/settings path-or-settings)
  (if (string? path-or-settings)
      path-or-settings
      (let loop ((settings path-or-settings)
                 (result '()))
        (if (null? settings)
            result
            (loop (scm-cdr settings)
                  (scm-append (scm-list (slgn-symbol->scm-keyword (scm-car (scm-car settings)))
                                (scm-cdr (scm-car settings)))
                          result))))))

(define (repr-convert val reprs)
  (let ((r (scm-assq val reprs)))
    (if r (scm-cdr r) val)))

(define (void? val) (scm-eq? *void* val))

(define (unicode-literals->qmarks str)
  (let ((len (string-length str)))
    (let loop ((i 0) (start #f) (chars '()))
      (if (scm->= i len)
          (list->string (scm-reverse chars))
          (let ((c (string-ref str i)))
            (if (scm-> (char->integer c) 255)
                (loop (scm-+ i 1) #t (scm-cons #\? chars))
                (loop (scm-+ i 1) start (if start (scm-cons c chars) chars))))))))

(define (safe-display-string str quotes port)
  (with-exception-catcher
   (lambda (e)
     (if (os-exception? e)
         (begin
           (if quotes (scm-display #\" port))
           (scm-display (unicode-literals->qmarks str) port)
           (if quotes (scm-display #\" port)))
         (scm-raise e)))
   (lambda ()
     (if quotes (scm-display #\" port))
     (scm-display str port)
     (if quotes (scm-display #\" port)))))

(define (slgn-display val #!key (port (current-output-port)) (quotes #f))
  (if (scm-not (void? val))
      (cond
       ((number? val)
        (scm-display val port))
       ((symbol? val)
        (if quotes
            (scm-display #\' port))
        (scm-display (scm-repr->slgn-repr val) port))
       ((string? val)
        (safe-display-string val quotes port))
       ((char? val)
        (slgn-display-char val port))
       ((set-type? val)
        (slgn-display-set val quotes port))
       ((namespace? val)
        (slgn-display-namespace val port))
       ((task_group? val)
        (slgn-display-task-group port))
       ((list? val)
        (slgn-display-list val quotes port))
       ((pair? val)
        (slgn-display-pair val quotes port))
       ((vector? val)
        (slgn-display-array val quotes port "#" vector->list))
       ((hashtable? val)
        (slgn-display-hashtable val quotes port))
       ((u8vector? val)
        (slgn-display-array val quotes port "#u8" u8vector->list))
       ((s8vector? val)
        (slgn-display-array val quotes port "#s8" s8vector->list))
       ((procedure? val)
        (slgn-display-function port))       
       ((s16vector? val)
        (slgn-display-array val quotes port "#s16" s16vector->list))
       ((u16vector? val)
        (slgn-display-array val quotes port "#u16" u16vector->list))
       ((s32vector? val)
        (slgn-display-array val quotes port "#s32" s32vector->list))
       ((u32vector? val)
        (slgn-display-array val quotes port "#u32" u32vector->list))
       ((s64vector? val)
        (slgn-display-array val quotes port "#s64" s64vector->list))
       ((u64vector? val)
        (slgn-display-array val quotes port "#u64" u64vector->list))
       ((f32vector? val)
        (slgn-display-array val quotes port "#f32" f32vector->list))
       ((f64vector? val)
        (slgn-display-array val quotes port "#f64" f64vector->list))
       ((%bitvector? val)
        (slgn-display-array val quotes port "#b" bitvector->list))
       ((thread? val)
        (slgn-display-task port))
       ((error-exception? val)
        (display-exception val port))
       ((eof-object? val)
        (scm-display '<eof> port))
       ((reactive-var? val)
        (slgn-display-rvar port))
       ((##promise? val)
        (slgn-display-promise port))
       ((s-yield? val)
        (slgn-display-special-obj "iterator" port))
       ((condition-variable? val)
        (slgn-display-special-obj "monitor" port))
       (else
        (scm-display (scm-repr->slgn-repr val) port)))))

(define (slgn-display-namespace obj port)
  (let ((str (string-append
              "<namespace "
              (symbol->string (namespace-name obj))
              ">")))
  (scm-display str port)))

(define (slgn-display-hashtable ht quotes port)
  (scm-display "#{" port)
  (let ((t (hashtable-table ht)))
    (let ((len (scm-- (table-length t) 1))
          (i 0))
      (table-for-each (lambda (k v)
                        (slgn-display k port: port quotes: quotes)
                        (scm-display ": " port)
                        (slgn-display v port: port quotes: quotes)
                        (set! i (scm-+ 1 i))
                        (if (scm-not (scm-> i len))
                            (begin
                              (if *sep-char* (scm-display *sep-char* port))
                              (scm-display #\space port))))
                      t)))
  (scm-display #\} port))

(define (slgn-display-set s quotes port)
  (scm-display "#(" port)
  (let loop ((xs (scm-reverse (set->list s))))
    (if (scm-not (null? xs))
        (begin (slgn-display (scm-car xs) port: port quotes: quotes)
               (if (scm-not (null? (scm-cdr xs)))
                   (scm-display ", " port))
               (loop (scm-cdr xs)))))
  (scm-display #\) port))
    
(define (slgn-display-special-obj tag port)
  (scm-display "<" port) (scm-display tag port)
  (scm-display ">" port))
  
(define (slgn-display-rvar port) 
  (slgn-display-special-obj "rvar" port))

(define (slgn-display-function port)
  (slgn-display-special-obj "function" port))

(define (slgn-display-promise port)
  (slgn-display-special-obj "promise" port))

(define *sep-char* #\,)

(define (show_comma_separator flag) 
  (if flag
      (set! *sep-char* #\,)
      (set! *sep-char* #f)))

(define (slgn-display-list lst quotes port)
  (scm-display "[" port)
  (let loop ((lst lst))
    (cond ((null? lst)
           (scm-display "]" port))
          (else
           (slgn-display (scm-car lst) port: port quotes: quotes)
           (if (scm-not (null? (scm-cdr lst)))
               (begin (if *sep-char* (scm-display *sep-char* port))
                      (scm-display #\space port)))
           (loop (scm-cdr lst))))))

(define (slgn-display-pair p quotes port)
  (slgn-display (scm-car p) port: port quotes: quotes)
  (scm-display ":" port)
  (slgn-display (scm-cdr p) port: port quotes: quotes))

(define (slgn-display-array a quotes port
                            prefix tolist)
  (scm-display prefix port)
  (slgn-display-list (tolist a) quotes port))

(define *special-chars* '(#\newline #\space #\tab #\return
                          #\backspace #\alarm #\vtab #\esc
                          #\delete #\nul))

(define (slgn-display-char c port)
  (scm-display #\\ port)  
  (with-exception-catcher
   (lambda (ex)
     (let* ((s (with-output-to-string
                '()
                (lambda () (scm-write c))))
            (len (string-length s))
            (subsi (if (scm-> len 2)
                       (if (char=? #\# (string-ref s 0))
                           (if (char=? #\\ (string-ref s 1))
                               2
                               1)
                           #f)
                       #f)))
       (if subsi
           (scm-display (scm-substring s subsi len) port)
           (scm-display s port))))
   (lambda ()
     (if (scm-member c *special-chars*)
         (scm-display (let ((s (with-output-to-string '() (lambda () (scm-write c)))))
                        (scm-substring s 2 (string-length s)))
                      port)
         (scm-display (scm-string c) port)))))

(define (slgn-display-task port)
  (slgn-display-special-obj "task" port))

(define (slgn-display-task-group port)
  (slgn-display-special-obj "task_group" port))

(define (generic-map1! f result vec len reff setf)
  (let loop ((i 0))
    (if (scm->= i len)
        (if result result *void*)
        (let ((res (f (reff vec i))))
          (if result (setf result i res))
          (loop (scm-+ i 1))))))

(define (generic-map2+! f result vecs len reff setf)
  (let loop ((i 0))
    (if (scm->= i len)
        (if result result *void*)
        (let ((res (scm-apply f (reff vecs i)))) 
          (if result (setf result i res))
          (loop (scm-+ i 1))))))

(define (assert-equal-lengths seq rest #!optional (lenf length))
  (let ((len (lenf seq)))
    (let loop ((rest rest))
      (if (scm-not (null? rest))
          (begin (if (scm-not (scm-eq? (lenf (scm-car rest)) len))
                     (scm-error (with-output-to-string 
                                  "object is not of proper length: "
                                  (lambda () (slgn-display (scm-car rest))))))
                 (loop (scm-cdr rest)))))))

(define (has-envvars? path)
  (let ((len (string-length path)))
    (let loop ((i 0))
      (if (scm-< i len)
          (if (char=? (string-ref path i) #\$)
              #t
              (loop (scm-+ i 1)))
          #f))))

(define (extract-envvar path offset len)
  (let ((buff (open-output-string)))
    (let loop ((i offset))
      (if (scm-< i len)
          (let ((c (string-ref path i)))
            (if (scm-not (or (char=? c #\/) (char=? c #\\)))
                (begin (write-char c buff)
                       (loop (scm-+ i 1)))))))
    (get-output-string buff)))
                
(define (expand_envvars path)
  (let ((len (string-length path))
        (buff (open-output-string)))
    (let loop ((i 0))
      (if (scm-< i len)
          (let ((c (string-ref path i)))
            (if (char=? c #\$)
                (let ((evar (extract-envvar path (scm-+ i 1) len)))
                  (if evar
                      (begin (scm-display (getenv evar) buff)
                             (loop (scm-+ i 1 (string-length evar))))
                      (loop (scm-+ i 1))))
                (begin (write-char c buff)
                       (loop (scm-+ i 1)))))
          (get-output-string buff)))))

(define (add-slgn-extn file-name)
  (if (string=? (path-extension file-name) *slgn-extn*)
      file-name
      (string-append file-name *slgn-extn*)))

(define (load script #!optional force-compile)
  (if force-compile
      (with-exception-catcher
       (lambda (e)
         (if (scm-not (no-such-file-or-directory-exception? e))
             (scm-raise e)))
       (lambda ()
         (delete-file (string-append script *scm-extn*)))))
  (with-exception-catcher
   (lambda (e)
     (if (file-exists? (add-slgn-extn script))
         (if (slgn-compile script assemble: #f)
             (scm-load (string-append script *scm-extn*))
             (scm-error "failed to compile script" script))
         (scm-error "file not found" script)))
   (lambda () (scm-load script))))

(define slgn-load load)

(define (reload script) (slgn-load script #t))

(define (link script)
  (with-exception-catcher
   (lambda (e)
     (cond ((no-such-file-or-directory-exception? e)
            (if (file-exists? (add-slgn-extn script))
                (if (scm-not (slgn-compile script assemble: #t))
                    (scm-error "failed to compile script" script)))
            (scm-load script))
           (else (scm-raise e))))
   (lambda () (scm-load script))))

(define slgn-link link)

(define (check-for-? name tokenizer)
  (let ((name (if (pair? name) (scm-cadr name) name)))
    (if (scm->= (string-indexof (symbol->string name) #\?) 0)
        (parser-error tokenizer "Invalid character `?` in variable name."))))

(define (sanitize-expression tokenizer expr)
  (if (and (list? expr) (scm-not (null? expr)))
      (let ((f (scm-car expr)))
        (cond ((or (eq? f 'define)
                   (eq? f 'set!))
               (check-for-? (scm-cadr expr) tokenizer))
              ((or (eq? f 'let)
                   (eq? f 'let*)
                   (eq? f 'letrec))
               (let ((e (if (symbol? (scm-cadr expr)) (scm-caddr expr) (scm-cadr expr))))
                 (scm-map (lambda (d) (check-for-? (scm-car d) tokenizer)) e))))))
  expr)

(define (display-all x . xs)
  (scm-display x)
  (let loop ((xs xs))
    (if (scm-not (null? xs))
        (begin
          (scm-display (scm-car xs))
          (loop (scm-cdr xs))))))
