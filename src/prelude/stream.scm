;; Copyright (c) 2013-2014 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define (stream type path-or-settings)
  (case type
    ((!file) (open_file path-or-settings))
    ((!process) (open_process path-or-settings))
    ((!tcpclient) (open_tcp_client path-or-settings))
    ((!tcpserver) (open_tcp_server path-or-settings))
    ((!directory) (open_directory path-or-settings))
    ((!array) (open_array path-or-settings))
    ((!u8array) (open_u8array path-or-settings))
    ((!string) (open_string path-or-settings))
    (else (error "not a supported stream type. " type))))

(define (slgn-path/settings->scm-path/settings path-or-settings)
  (if (list? path-or-settings)
      (let loop ((settings path-or-settings)
                 (result '()))
        (if (null? settings)
            (reverse result)
            (loop (cddr settings)
                  (cons (list (slogan-symbol->scheme-keyword (car settings))
                              (slgn-setting->scm-setting (cadr settings)))
                        result))))
      path-or-settings))

(define (slgn-setting->scm-setting s)
  (if (symbol? s)
      (slogan-symbol->scheme-symbol s)
      s))

(define (open_file path-or-settings) 
  (open-file (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_input_file path-or-settings) 
  (open-input-file (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_output_file path-or-settings) 
  (open-output-file (slgn-path/settings->scm-path/settings path-or-settings)))

(define (call_with_input_file path-or-settings fn) 
  (call-with-input-file (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (call_with_output_file path-or-settings fn) 
  (call-with-output-file (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (with_input_from_file path-or-settings fn) 
  (with-input-from-file (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (with_output_to_file path-or-settings fn) 
  (with-output-to-file (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (open_process path-or-settings) 
  (open-process (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_input_process path-or-settings) 
  (open-input-process (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_output_process path-or-settings) 
  (open-output-process (slgn-path/settings->scm-path/settings path-or-settings)))

(define (call_with_input_process path-or-settings fn) 
  (call-with-input-process (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (call_with_output_process path-or-settings fn) 
  (call-with-output-process (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (with_input_from_process path-or-settings fn) 
  (with-input-from-process (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (with_output_to_process path-or-settings fn) 
  (with-output-to-process (slgn-path/settings->scm-path/settings path-or-settings) fn))
  
(define process_pid process-pid)
(define process_status process-status)

(define (open_tcp_client path-or-settings) 
  (open-tcp-client (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_tcp_server path-or-settings) 
  (open-tcp-server (slgn-path/settings->scm-path/settings path-or-settings)))

(define (tcp_service_register path-or-settings fn) 
  (tcp-service-register! (slgn-path/settings->scm-path/settings path-or-settings) fn))

(define (tcp_service_unregister path-or-settings)
  (tcp-service-unregister! (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_directory path-or-settings)
  (open-directory (slgn-path/settings->scm-path/settings path-or-settings)))

(define (open_array array-or-settings)
  (open-vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (open_input_array array-or-settings)
  (open-input-vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (open_output_array array-or-settings)
  (open-output-vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (call_with_input_array array-or-settings fn)
  (call-with-input-vector (slgn-path/settings->scm-path/settings array-or-settings) fn))

(define (call_with_output_array array-or-settings fn)
  (call-with-output-vector (slgn-path/settings->scm-path/settings array-or-settings) fn))

(define (open_u8array array-or-settings)
  (open-u8vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (open_input_u8array array-or-settings)
  (open-input-u8vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (open_output_u8array array-or-settings)
  (open-output-u8vector (slgn-path/settings->scm-path/settings array-or-settings)))

(define (call_with_input_u8array array-or-settings fn)
  (call-with-input-u8vector (slgn-path/settings->scm-path/settings array-or-settings) fn))

(define (call_with_output_u8array array-or-settings fn)
  (call-with-output-u8vector (slgn-path/settings->scm-path/settings array-or-settings) fn))

(define (open_string string-or-settings)
  (open-string (slgn-path/settings->scm-path/settings string-or-settings)))

(define (open_input_string string-or-settings)
  (open-input-string (slgn-path/settings->scm-path/settings string-or-settings)))

(define (open_output_string string-or-settings)
  (open-output-string (slgn-path/settings->scm-path/settings string-or-settings)))

(define (call_with_input_string string-or-settings fn)
  (call-with-input-string (slgn-path/settings->scm-path/settings string-or-settings) fn))

(define input_stream? input-port?)
(define output_stream? output-port?)
(define stream? port?)
(define current_input_stream current-input-port)
(define current_output_stream current-output-port)
(define close_input_stream close-input-port)
(define close_output_stream close-output-port)
(define close_stream close-port)
(define read_char read-char)
(define peek_char peek-char)
(define char_ready? char-ready?)
(define write_char write-char)
(define read_line read-line)
(define read_substring read-substring)
(define write_substring write-substring)
(define read_u8 read-u8)
(define write_u8 write-u8)
(define read_u8array read-subu8vector)
(define write_u8array write-subu8vector)
(define force_output force-output)
(define eof? eof-object?)

