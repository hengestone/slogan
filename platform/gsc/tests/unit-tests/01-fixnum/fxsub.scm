(include "#.scm")

(check-eqv? (##fx- 44 11)   33)
(check-eqv? (##fx- 11 -11)  22)
(check-eqv? (##fx- -33 11) -44)
(check-eqv? (##fx- 33 11)   22)

(check-eqv? (##fx- 0) 0)
(check-eqv? (##fx- 22) -22)
(check-eqv? (##fx- 33 11) 22)
(check-eqv? (##fx- -11 -22 -33) 44)
(check-eqv? (##fx- 11 22 33 44) -88)

(check-eqv? (fx- 44 11)   33)
(check-eqv? (fx- 11 -11)  22)
(check-eqv? (fx- -33 11) -44)
(check-eqv? (fx- 33 11)   22)

(check-eqv? (fx- 0) 0)
(check-eqv? (fx- 22) -22)
(check-eqv? (fx- 33 11) 22)
(check-eqv? (fx- -11 -22 -33) 44)
(check-eqv? (fx- 11 22 33 44) -88)

(check-tail-exn fixnum-overflow-exception? (lambda () (fx- ##min-fixnum 1)))
(check-tail-exn fixnum-overflow-exception? (lambda () (fx- 0 ##min-fixnum 1 0)))
(check-tail-exn fixnum-overflow-exception? (lambda () (fx- ##min-fixnum)))
(check-tail-exn fixnum-overflow-exception? (lambda () (fx- 0 ##min-fixnum 1 0)))

(check-tail-exn type-exception? (lambda () (fx- 0.0)))
(check-tail-exn type-exception? (lambda () (fx- 0.5)))
(check-tail-exn type-exception? (lambda () (fx- 0.5 9)))
(check-tail-exn type-exception? (lambda () (fx- 9 0.5)))
(check-tail-exn type-exception? (lambda () (fx- 0.5 3 9)))
(check-tail-exn type-exception? (lambda () (fx- 3 0.5 9)))
(check-tail-exn type-exception? (lambda () (fx- 3 9 0.5)))
