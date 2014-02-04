;; Copyright (c) 2013-2014 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define is_eq eq?)
(define is_equal equal?)
(define is_boolean boolean?)

(define (current_exception_handler) 
  (current-exception-handler))

(define (set_current_exception_handler handler)
  (current-exception-handler handler))

(define (try thunk #!key (catch (current-exception-handler))
             finally)
  (let ((result (with-exception-catcher catch thunk)))
    (if finally
        (finally)
        result)))

(define is_error error-exception?)
(define error_message error-exception-message)
(define error_args error-exception-parameters)

;; Extensions specific to this implementation of Slogan.
(define callcc call/cc)
