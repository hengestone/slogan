;; Copyright (c) 2013-2014 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define-structure port-pos port line col)

(define (port-pos-read-char! port)
  (let ((c (read-char (port-pos-port port))))
    (cond ((and (char? c) (char=? c #\newline))
           (port-pos-line-set! port (+ 1 (port-pos-line port)))
           (port-pos-col-set! port 0))
          (else
           (port-pos-col-set! port (+ 1 (port-pos-col port)))))
    c))

(define (port-pos-peek-char port) (peek-char (port-pos-port port)))

(define (make-tokenizer port program-text 
                        #!key (compile-mode #f))
  (let ((current-token #f)
        (program-text (if (string? program-text)
                          (string_split program-text #\newline #t)
                          '()))
        (port (make-port-pos port 1 0))
        (pattern-mode #f)
	(quote-mode #f)
        (lookahead-stack '()))
    (lambda (msg . args)
      (case msg
        ((peek) 
         (if (not current-token)
             (if (= 0 (length lookahead-stack))
                 (set! current-token (next-token port))
                 (begin (set! current-token (car lookahead-stack))
                        (set! lookahead-stack (cdr lookahead-stack)))))
         current-token)
        ((next)
         (if (not current-token)
             (if (= 0 (length lookahead-stack))
                 (next-token port)
                 (let ((tmp (car lookahead-stack)))
                   (set! lookahead-stack (cdr lookahead-stack))
                   tmp))
             (let ((tmp current-token))
               (set! current-token #f)
               tmp)))
        ((put)
         (if current-token
             (begin (set! lookahead-stack (cons current-token lookahead-stack))
                    (set! current-token #f)))
         (set! lookahead-stack (cons (car args) lookahead-stack)))
        ((has-more?)
         (char-ready? (port-pos-port port)))
	((get-port)
	 (port-pos-port port))
        ((line)
         (port-pos-line port))
        ((column)
         (port-pos-col port))
        ((compile-mode?) compile-mode)
        ((pattern-mode-on) (set! pattern-mode #t))
        ((pattern-mode-off) (set! pattern-mode #f))
        ((pattern-mode?) pattern-mode)
	((quote-mode-on) (set! quote-mode #t))
	((quote-mode-off) (set! quote-mode #f))
	((quote-mode?) quote-mode)
        ((program-text) program-text)
        (else (error "tokenizer received unknown message: " msg))))))

(define (next-token port)
  (let ((c (port-pos-peek-char port)))
    (if (eof-object? c)
        c
        (let ((opr (single-char-operator? c)))
          (if opr
              (begin (port-pos-read-char! port)
                     (if (and (char-comment-start? c) 
                              (char-comment-part? (port-pos-peek-char port)))
                         (begin (skip-comment port)
                                (next-token port))
                         (cdr opr)))
              (cond ((char-whitespace? c)
                     (skip-whitespace port)
                     (next-token port))
                    ((char-numeric? c)
                     (if (char=? c #\0)
                         (begin (port-pos-read-char! port)
                                (read-number-with-radix-prefix port))
                         (read-number port #f)))
                    ((multi-char-operator? c)
                     (read-multi-char-operator port))
                    ((char=? c #\")
                     (read-string port))
		    ((char=? c #\')
		     (port-pos-read-character port))
                    ((char=? c #\.)
                     (port-pos-read-char! port)
                     (if (char-numeric? (port-pos-peek-char port))
                         (read-number port #\.)
                         '*period*))
                    (else (read-name port))))))))

(define *single-char-operators* (list (cons #\+ '*plus*)
                                      (cons #\- '*minus*)
                                      (cons #\/ '*backslash*)
                                      (cons #\* '*asterisk*)
                                      (cons #\( '*open-paren*)
                                      (cons #\) '*close-paren*)
                                      (cons #\{ '*open-brace*)
                                      (cons #\} '*close-brace*)
                                      (cons #\[ '*open-bracket*)
                                      (cons #\] '*close-bracket*)
                                      (cons #\# '*hash*)
                                      (cons #\, '*comma*)
                                      (cons #\: '*colon*)                                      
                                      (cons #\! '*bang*)
                                      (cons #\; '*semicolon*)))

(define *single-char-operators-strings* (list (cons "+" '*plus*)
                                              (cons "-" '*minus*)
                                              (cons "/" '*backslash*)
                                              (cons "*" '*asterisk*)
                                              (cons "(" '*open-paren*)
                                              (cons ")" '*close-paren*)
                                              (cons "{" '*open-brace*)
                                              (cons "}" '*close-brace*)
                                              (cons "[" '*open-bracket*)
                                              (cons "]" '*close-bracket*)
                                              (cons "#" '*hash*)
                                              (cons "," '*comma*)
                                              (cons ":" '*colon*)                                      
                                              (cons "!" '*bang*)
                                              (cons ";" '*semicolon*)))

(define *multi-char-operators-strings* (list (cons "==" '*equals*)
                                             (cons ">" '*greater-than*)
                                             (cons "<" '*less-than*)
                                             (cons ">=" '*greater-than-equals*)
                                             (cons "<=" '*less-than-equals*)
                                             (cons "&&" '*and*)
                                             (cons "||" '*or*)))

(define (math-operator? sym)
  (or (eq? sym '*plus*)
      (eq? sym '*minus*)
      (eq? sym '*backslash*)
      (eq? sym '*asterisk*)))

(define (single-char-operator? c)
  (and (char? c) (assoc c *single-char-operators*)))

(define (multi-char-operator? c)
  (and (char? c)
       (or (char=? c #\=)
           (char=? c #\<)
           (char=? c #\>)
           (char=? c #\&)
           (char=? c #\|))))

(define (fetch-operator-string token strs)
  (let loop ((oprs strs))
    (cond ((null? oprs)
           #f)
          ((eq? token (cdar oprs))
           (caar oprs))
          (else (loop (cdr oprs))))))

(define (fetch-single-char-operator-string token)
  (fetch-operator-string token *single-char-operators-strings*))

(define (fetch-multi-char-operator-string token)
  (fetch-operator-string *multi-char-operators-strings*))

(define (fetch-operator port 
                        suffix
                        suffix-opr
                        opr)
  (port-pos-read-char! port)
  (if (char=? (port-pos-peek-char port) suffix)
      (begin (port-pos-read-char! port)
             suffix-opr)
      opr))

(define (tokenizer-error msg #!rest args)
  (error (with-output-to-string 
           '()
           (lambda ()
             (slgn-display msg display-string: #t)
             (let loop ((args args))
               (if (not (null? args))
                   (begin (slgn-display (car args) display-string: #t)
                          (display " ")
                          (loop (cdr args)))))))))

(define (fetch-same-operator port c opr)
  (port-pos-read-char! port)
  (if (char=? (port-pos-peek-char port) c)
      (begin (port-pos-read-char! port)
	     opr)
      (tokenizer-error "invalid character in operator. " (port-pos-read-char! port))))

(define (read-multi-char-operator port)
  (let ((c (port-pos-peek-char port)))
    (cond ((char=? c #\=)
           (fetch-operator port #\= '*equals* '*assignment*))
          ((char=? c #\<)
           (fetch-operator port #\= '*less-than-equals* '*less-than*))
          ((char=? c #\>)
           (fetch-operator port #\= '*greater-than-equals* '*greater-than*))
	  ((or (char=? c #\&)
	       (char=? c #\|))
	   (fetch-same-operator port c (if (char=? c #\&) '*and* '*or*)))
          (else
           (tokenizer-error "expected a valid operator. unexpected character: " (port-pos-read-char! port))))))

(define (read-number port prefix)
  (let loop ((c (port-pos-peek-char port))
             (result (if prefix (list prefix) '())))
    (if (char-valid-in-number? c)
        (begin (port-pos-read-char! port)
               (loop (port-pos-peek-char port)
                     (cons c result)))
	(if (and (not (eof-object? c))
                 (char=? c #\#))
	    (begin (port-pos-read-char! port)
		   (read-complex-number port result))
	    (let ((n (string->number (list->string (reverse result)))))
	      (if (not n)
		  (tokenizer-error "read-number failed. invalid number format.")
		  n))))))

(define (read-complex-number port prefix)
  (let loop ((c (port-pos-peek-char port))
	     (result (cons #\+ prefix)))
    (if (char-valid-in-number? c)
	(begin (port-pos-read-char! port)
	       (loop (port-pos-peek-char port)
		     (cons c result)))
	(let ((n (string->number (list->string (reverse (cons #\i result))))))
	  (if (not n)
	      (tokenizer-error "read-complex-number failed. invalid number format.")
	      n)))))
    
(define (read-number-with-radix-prefix port)
  (let ((radix-prefix 
         (let ((c (char-downcase (port-pos-peek-char port))))
           (cond ((char=? c #\x) "#x")
                 ((char=? c #\b) "#b")
                 ((char=? c #\o) "#o")
                 ((char=? c #\d) "#d")
                 ((char=? c #\e) "#e")
		 ((char=? c #\i) "#i")
                 (else #f)))))
    (if (not radix-prefix)
	(read-number port #\0)
	(begin (port-pos-read-char! port)
	       (let loop ((c (port-pos-peek-char port))
			  (result '()))
		 (if (or (char-valid-in-number? c)
			 (char-hex-alpha? c))
		     (begin (port-pos-read-char! port)
			    (loop (port-pos-peek-char port)
				  (cons c result)))
		     (let ((n (string->number (string-append radix-prefix (list->string (reverse result))))))
		       (if (not n)
			   (tokenizer-error "read-number-with-radix-prefix failed. invalid number format.")
			   n))))))))

(define (char-valid-in-number? c)
  (and (char? c)
       (or (char-numeric? c)
           (char=? #\e c)
           (char=? #\E c)
           (char=? #\. c))))

(define (char-hex-alpha? c)
  (if (char? c)
      (let ((c (char-downcase c)))
        (or (char=? c #\a)
            (char=? c #\b)
            (char=? c #\c)
            (char=? c #\d)
            (char=? c #\e)
            (char=? c #\f)))
      #f))

(define (skip-whitespace port)
  (let loop ((c (port-pos-peek-char port)))
    (if (eof-object? c)
        c
        (if (char-whitespace? c)
            (begin (port-pos-read-char! port)
                   (loop (port-pos-peek-char port)))))))

(define (char-valid-name-start? c)
  (and (char? c) 
       (or (char-alphabetic? c)
           (char=? c #\_)
           (char=? c #\$)
           (char=? c #\?)
           (char=? c #\!)
           (char=? c #\~)
           (char=? c #\@))))

(define (char-valid-in-name? c)
  (and (char? c) 
       (or (char-valid-name-start? c)
           (char-numeric? c))))

(define (read-name port)
  (if (char-valid-name-start? (port-pos-peek-char port))
      (let loop ((c (port-pos-peek-char port))
                 (result '()))
        (if (char-valid-in-name? c)
            (begin (port-pos-read-char! port)
                   (loop (port-pos-peek-char port)
                         (cons c result)))
            (string->symbol (list->string (reverse result)))))
      (tokenizer-error "read-name failed at " (port-pos-read-char! port))))

(define (read-string port)
  (let ((c (port-pos-read-char! port)))
    (if (char=? c #\")
        (let loop ((c (port-pos-peek-char port))
                   (result '()))
          (if (char? c)
              (cond ((char=? c #\")
                     (port-pos-read-char! port)
                     (list->string (reverse result)))
                    ((char=? c #\\)
                     (port-pos-read-char! port)
                     (set! c (char->special (port-pos-read-char! port)))
                     (loop (port-pos-peek-char port) (cons c result)))
                    (else 
                     (set! c (port-pos-read-char! port))
                     (loop (port-pos-peek-char port) (cons c result))))
              (tokenizer-error "string not terminated.")))
        (tokenizer-error "read-string failed at " c))))

(define (char-comment-start? c) (and (char? c) (char=? c #\/)))
(define (char-comment-part? c) (and (char? c)
                                    (or (char-comment-start? c) 
                                        (char=? c #\*))))

(define (skip-comment port)
  (let ((c (port-pos-read-char! port)))
    (if (char-comment-start? c)
        (skip-line-comment port)
        (skip-block-comment port))))

(define (skip-line-comment port)
  (let loop ((c (port-pos-peek-char port)))
    (if (and (char? c)
             (not (char=? c #\newline)))
        (begin (port-pos-read-char! port)
               (loop (port-pos-peek-char port))))))

(define (skip-block-comment port)
  (let loop ((c (port-pos-peek-char port)))
    (if (not (eof-object? c))
        (begin (port-pos-read-char! port)
               (if (char=? c #\*)
                   (if (not (char=? (port-pos-read-char! port) #\/))
                       (loop (port-pos-peek-char port)))
                   (loop (port-pos-peek-char port)))))))

(define (port-pos-read-character port)
  (if (char=? (port-pos-read-char! port) #\')
      (let ((c (if (char=? (port-pos-peek-char port) #\\)
                   (read-special-character port)
                   (port-pos-read-char! port))))
        (if (not (char=? (port-pos-peek-char port) #\'))
            (if (char=? c #\') 
                #\nul
                (tokenizer-error "character constant not terminated. " c))
            (begin (port-pos-read-char! port)
                   c)))
      (tokenizer-error "not a character literal.")))

(define (read-special-character port)
  (port-pos-read-char! port)
  (let ((c (port-pos-read-char! port)))
    (if (char=? c #\u)
        (read-unicode-literal port)
        (char->special c))))

(define (read-unicode-literal port)
  (let loop ((result '())
             (c (port-pos-peek-char port)))
    (if (char=? c #\')
        (eval-unicode-literal (string-append (hexchar-prefix (length result)) (list->string (reverse result))))
        (loop (cons (port-pos-read-char! port) result) (port-pos-peek-char port)))))

(define (eval-unicode-literal s)
  (eval (with-input-from-string s read)))

(define (hexchar-prefix len)
  (cond ((= len 2)
         "#\\x")
        ((= len 4)
         "#\\u")
        ((= len 8)
         "#\\U")
        (else (tokenizer-error "invalid hex encoded character length. " len))))

(define (char->special c)
  (cond ((char=? c #\n)
         #\newline)
        ((char=? c #\")
         #\")
        ((char=? c #\t)
         #\tab)
        ((char=? c #\r)
         #\return)
        ((char=? c #\\)
         #\\)
        ((char=? c #\b)
         #\backspace)
        ((char=? c #\a)
         #\alarm)
        ((char=? c #\v)
         #\vtab)
        ((char=? c #\e)
         #\esc)
        ((char=? c #\d)
         #\delete)
        (else (tokenizer-error "invalid escaped character " c))))

(define (is_operator_token token)
  (or (single-char-operator? token)
      (multi-char-operator? token)))

(define (operator_token_to_string token)
  (cond ((single-char-operator? token)
         (fetch-single-char-operator-string token))
        ((multi-char-operator? token)
         (fetch-multi-char-operator-string token))
        (else #f)))

(define is_keyword_token reserved-name?)
