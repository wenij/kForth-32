\ mpfr_gr.4th
\
\ Compute and print the Golden Ratio [1] to 77 significant digits,
\   using the GNU MPFR library and four different methods.
\
\ K. Myneni, 2011-07-07
\
\ 1. http://en.wikipedia.org/wiki/Golden_ratio

\ Load library bindings and open the library

1                \ change to 0 if not using kForth
[IF]
include asm
include strings
include lib-interface
[THEN]

include libmpfr.4th

DECIMAL

\ 1. Soln. of quadratic eqn: phi = (1 + sqrt(5))/2
: phi-qu ( amp -- )
    dup
    dup  5    GMP_RNDN  mpfr_set_ui  drop
    2dup      GMP_RNDN  mpfr_sqrt    drop
    2dup 1    GMP_RNDN  mpfr_add_ui  drop
    2dup 2    GMP_RNDN  mpfr_div_ui  drop
    2drop ;


\ 2. Trigonometric eqn: phi = 2*cos(pi/5)
: phi-tr ( amp -- )
   dup
   dup       GMP_RNDN  mpfr_const_pi  drop
   2dup 5    GMP_RNDN  mpfr_div_ui    drop
   2dup      GMP_RNDN  mpfr_cos       drop
   2dup 2    GMP_RNDN  mpfr_mul_ui    drop
   2drop ;


\ 3. Continued square root: phi = sqrt(1 + sqrt(1 + sqrt(1 + ...
: phi-cs ( amp nterms -- )
    >r dup
    dup 2 GMP_RNDN mpfr_set_ui drop
    2dup GMP_RNDN mpfr_sqrt drop
    r> 0 ?do
      2dup 1 GMP_RNDN mpfr_add_ui drop
      2dup GMP_RNDN mpfr_sqrt drop
    loop 
    2drop ;


\ 4. Continued fraction: phi = 1 + 1/(1 + 1/(1 + 1/... 
: phi-cf ( amp nterms -- )
    >r dup
    dup 3 GMP_RNDN mpfr_set_ui drop
    2dup 2 GMP_RNDN mpfr_div_ui drop
    r> 0 ?do
      2dup 1 swap GMP_RNDN mpfr_ui_div drop
      2dup 1 GMP_RNDN mpfr_add_ui drop
    loop
    2drop ;

\ Utilities
: mpfr. ( amp u -- )  swap 0 10 2swap GMP_RNDN mpfr_out_str drop ;
[undefined] mpfr_t [IF] : mpfr_t create /MPFR allot ; [THEN]


256 mpfr_set_default_prec  \ provides 77 sig. decimal digits
mpfr_t gr
gr  mpfr_init

cr gr     phi-qu  gr 77 mpfr.
cr gr     phi-tr  gr 77 mpfr.
cr gr 150 phi-cs  gr 77 mpfr.
cr gr 182 phi-cf  gr 77 mpfr.

