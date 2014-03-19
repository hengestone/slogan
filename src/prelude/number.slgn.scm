;; Copyright (c) 2013-2014 by Vijay Mathew Pandyalakal, All Rights Reserved.

(define is_number number?)
(define is_integer integer?)
(define is_real real?)
(define is_rational rational?)
(define is_complex complex?)
(define is_zero zero?)
(define is_even even?)
(define is_odd odd?)
(define is_positive positive?)
(define is_negative negative?)
(define is_nan nan?)
(define is_fixnum fixnum?)
(define is_flonum flonum?)
(define is_fxnegative fxnegative?)
(define is_fxpositive fxpositive?)
(define is_fxzero fxzero?)
(define is_fxeven fxeven?)
(define is_fxodd fxodd?)
(define is_flfinite flfinite?)
(define is_flinfinite flinfinite?)
(define is_fleven fleven?)
(define is_flodd flodd?)
(define is_flinteger flinteger?)
(define is_flnan flnan?)
(define is_flzero flzero?)
(define is_flnegative flnegative?)
(define is_flpositive flpositive?)

(define (is_positive_infinity n)
  (if (not (real? n))
      (##fail-check-real 1 is_positive_infinity n))
  (eq? *pos-inf-sym* (string->symbol (number->string n))))

(define (is_negative_infinity n)
  (if (not (real? n))
      (##fail-check-real 1 is_negative_infinity n))
  (eq? *neg-inf-sym* (string->symbol (number->string n))))

(define integer_to_char integer->char)
(define rational_to_real exact->inexact)
(define real_to_rational inexact->exact)
(define number_to_string number->string)

(define (real_to_integer n)
  (inexact->exact (round n)))

(define (integer_to_real n)
  (exact->inexact n))

(define fixnum_to_flonum fixnum->flonum)

(define rectangular make-rectangular)
(define polar make-polar)
(define real_part real-part)
(define imag_part imag-part)

(define add +)
(define sub -)
(define mult *)
(define div /)

(define (safe_div a b)
  (if (zero? b) +inf.0 (/ a b)))

(define fxadd fx+)
(define fxsub fx-)
(define fxmult fx*)
(define fxwrap_add fxwrap+)
(define fxwrap_sub fxwrap-)
(define fxwrap_mult fxwrap*)

(define fladd fl+)
(define flsub fl-)
(define flmult fl*)
(define fldiv fl/)

(define arithmetic_shift arithmetic-shift)
(define bitwise_merge bitwise-merge)
(define bitwise_and bitwise-and)
(define bitwise_ior bitwise-ior)
(define bitwise_xor bitwise-xor)
(define bitwise_not bitwise-not)
(define bit_count bit-count)
(define integer_length integer-length)
(define is_bit_set bit-set?)
(define is_any_bits_set any-bits-set?)
(define is_all_bits_set all-bits-set?)
(define first_bit_set first-bit-set)
(define extract_bit_field extract-bit-field)
(define is_bit_field_set test-bit-field?)
(define clear_bit_field clear-bit-field)
(define replace_bit_field replace-bit-field)
(define copy_bit_field copy-bit-field)

(define is_fxbit_set fxbit-set?)
(define fxarithmetic_shift fxarithmetic-shift)
(define fxarithmetic_shift_left fxarithmetic-shift-left)
(define fxarithmetic_shift_right fxarithmetic-shift-right)
(define fxbit_count)
(define fxfirst_bit_set fxfirst-bit-set)
(define fxwraparithmetic_shift fxwraparithmetic-shift)
(define fxwraparithmetic_shift_left fxwraparithmetic-shift-left)
(define fxwraparithmetic_shift_right fxwraplogical-shift-right)
(define fxwraplogical_shift_right fxwraplogical-shift-right)

(define number_is_eq =)
(define number_is_lt <)
(define number_is_gt >)
(define number_is_lteq <=)
(define number_is_gteq >=)

(define fx_is_eq fx=)
(define fx_is_lt fx<)
(define fx_is_gt fx>)
(define fx_is_lteq fx<=)
(define fx_is_gteq fx>=)

(define fl_is_eq fl=)
(define fl_is_lt fl<)
(define fl_is_gt fl>)
(define fl_is_lteq fl<=)
(define fl_is_gteq fl>=)

(define integer_sqrt integer-sqrt)
(define integer_nth_root integer-nth-root)

(define random_integer random-integer)
(define random_real random-real)
(define random_byte_array random-u8vector)

(define (default_random_source) default-random-source)
(define (set_default_random_source s) (set! default-random-source s))
(define random_source make-random-source)
(define is_random_source random-source?)
(define random_source_state random-source-state-ref)
(define random_source_set_state random-source-state-set!)
(define random_source_randomize random-source-randomize!)
(define random_source_pseudo_randomize random-source-pseudo-randomize!)
(define random_source_for_integers random-source-make-integers)
(define random_source_for_reals random-source-make-reals)
(define random_source_for_byte_arrays random-source-make-u8vectors)

