\ pentomino.4th
\
\ Here follows an explanation of the Pentomino solutions code


\                 The Twelve Pentominoes

\  ff  i  l   n   pp  ttt  u u  v    w     x    y  zz
\ ff   i  l   nn  pp   t   uuu  v    ww   xxx  yy   z
\  f   i  l    n  p             vvv   ww   x    y   zz
\      i  ll   n                                y
\      i

\ These are all twelve planar shapes consisting of 5 adjacent
\ squares. They can be fit into a 6x10 rectangle in exactly 2339
\ way not counting rotations and mirror images.


\ First two solutions found by PENTOM

\ uuxppp  uuxppp
\ uxxxpp  uxxxpp
\ uuxttt  uuxttt
\ yyyytn  yyyytn
\ lywwtn  iywwtn
\ lwwfnn  iwwfnn
\ lwffnv  iwffnv
\ llzffv  izzffv
\ zzzvvv  izlvvv
\ aiiiii  zzllll


\ PENTOM does an exhaustive search for all solutions of the
\ pentomino puzzle for the given board. The method is to find the
\ first empty square (called lead square) and then place
\ recursively all available pieces in all possible orientations.
\ When the last square on the board is reached, a solution has
\ been found and the solution is printed on the screen.

\ The excellence of this algorithm is in method of testing whether
\ pieces and their orientations fit at a given location. A simple
\ but slow method is to list all pieces in all orientations (there
\ are 63 possibilities) and go through the full list each time.
\ This method is slow since all pieces will be tried even though
\ none will fit (for example in a one-square hole bounded on all
\ sides).

\ My method is to test squares increasingly far from the lead
\ square. Thus a hole too small for any pieces to fit will be
\ found quickly. Branching out to the right and below yields all
\ 63 possible orientations. This branching is encoded as a binary
\ tree. Traversing the tree is the means by which all pieces in
\ all their orientations are tried starting at the lead square.

\ Rather than traverse the tree by observation and then test the
\ squares on the board to see if they are empty, I have hard-coded
\ the testing of the squares on the board using postpone. This is
\ done by two forth macros which compile the necessary code:
\ 'leaf-test' and 'testsq'. The tricky bit (tricky to understand
\ what is happening) is the postponing of if and then in the
\ recursive macro testsq. But it works! The two macros generate
\ over 6000 cells of code of threaded code.

\ Another not so obvious speed up in the code is to traverse the
\ board across the shorter side, i.e. across rows of 6 squares
\ rather than across rows of 10 squares. To understand why this is
\ so consider what happens when a too-small hole occurs below the
\ piece being placed. It won't be found as quickly if the board is
\ oriented the long way.

\ A further speed up is to manually place the 'x' in all possible
\ positions in the upper left quadrant of the board. This has the
\ additional side effect of eliminating mirror images and
\ rotations from the solutions.

\ Of course a great speed improvement can be had by coding the
\ guts in assembly -- about 50 times on my 16 bit DTC forth.


\ The pentomino shapes can all be placed in an 8x5 rectangle (see
\ below) using position A as lead square. There are 63
\ orientations which are encoded as a character string.

\      ...ABCDE
\      FGHIJKL.
\      .OPQRS..
\      ..XYZ...
\      ...a....

\ Posn  piece   orientation
\ ABCDE   i       ABCDE
\     I   l       ABCDI
\     J   y       ABCDJ
\     K   y       ABCDK
\     L   l       ABCDL
\    IH   n       ABCIH
\     J   p       ABCIJ
\     etc.  coded in string 'orients'

\ \ The broken lines below should be connected
\ create orients
\ ," ABCDEiIlJyKyLl.IHnJpKuQv.JKpRt.KLnSv..IHGnJpPwQf.
\    JKpQpRp.QPzRuYl..JKLnRfSw.RQuSzZl...IHGFlJyOzPfQt.
\    JKyPfRf.POwQpXn.QRfYy..JKCuLlQtRfSz.QPfRpYy.RSwZn..
\    QPOvRtXnYy.RSvYyZn.YXlZlai....."

\ In the string 'orients' the letters 'A-Z' and 'a' are positions
\ in the above 8x5 rectangle. The lower case letters
\ 'filnptuvwxyz' are names of the 12 pentomino pieces.

\ The recursive routines 'testsq' and 'leaf-test' use the string
\ 'orients' to direct the generation of code which tests the
\ squares on the board to see if a piece will fit. Each position
\ letter (A-Z,a) causes the generation of code to check a square
\ on the board. Each piece name (filnptuvwxyz) generates code to
\ test piece availability. The '.' characters signal an unrecurse.


\ What use is it? Dunno! But it's fun. Could use it as an addition
\ to Hanoi for a benchmark. It does test simple code generated by
\ postpone.


\ Bruce Hoyt


\ --------------------------------------------------------------------

\ PENTOM  --  All 2339 solutions to the 6x10 pentomino puzzle
\ Bruce Hoyt 04-MAR-00 17:04:41

\ Adapted for kForth by Krishna Myneni, 28-OCT-03; 
\ Revised for kForth 1.2.x, 2004/04/09 (removed workaround for POSTPONE of variable)

\ ========= kForth requires ==================
include ans-words
include strings
include utils
include ansi
: set-colour background ;
\ ========= end of kForth requires ===========

\ Compiling options
FALSE constant mute                     \ disable printing for benchmark
TRUE  constant has-colour               \ all colour display
TRUE  constant 6X10                     \ do 6x10 board, if false do 4x15 board

11 constant Wtot                        \ total width of board
create Bd  500 allot                    \ allow 11 X 30 board
create Pa  12 allot                     \ pieces available
variable Level                          \ recursion level, = # pieces on board
0 value Width                           \ board width actually used
0 value Height                          \ board height actually used
0 ptr Bstart                            \ pointer to starting square on board
0 ptr Bend                              \ pointer to ending square on board
variable Soln                           \ # of this solution
variable Tries                          \ count of pieces tried

: pentom-init ( wd ht - )               \ initialise the board & pieces
    to Height  to Width
    Width 1+ Wtot > abort"  Total width too small"
    Wtot Bd + to Bstart                 \ set pointer to start of board
    Wtot Height * Width + Bd + to Bend  \ set pointer to end of board
    0 Bd + Wtot Height 2 + * 1+ -1 fill \ set unused squares to -1
    12 0 do                             \ mark all pieces available
        -1 i Pa + c!
    loop
    0 9 Pa + c!                         \ except the X
    Height 1+ 1 do
        Width 1+ 1 do
            0 j Wtot * i + Bd + c!      \ set unoccupied squares to 0
        loop
    loop ;

(
create pats
    bl c, bl c,                         \ -1 is boundary, 0 is empty
    char f c, char i c, char l c, char n c,
    char p c, char t c, char u c, char v c,
    char w c, char x c, char y c, char z c,
    char x c,                           \ 13 is manually placed 'x'
)

: ctable ( ... n -- ) dup >r create ?allot dup r> + 1-
    ?do	 i c! -1 +loop ;
  
bl  bl                          \ -1 is boundary, 0 is empty
char f  char i  char l  char n 
char p  char t  char u  char v 
char w  char x  char y  char z 
char x
15 ctable pats

: printbd
    mute if exit then
    0 2 at-xy
    Height 1+ 1 do                      \ for each row
        Width 1+ 1 do                   \ and each col
            j Wtot * i +  Bd + c@       \ # in square
            has-colour if
              ( 4 lshift) 
	      dup 8 mod set-colour \ use coloured spaces to 'prettyify'
	      1+ pats + c@ dup emit emit
              \ 2 spaces
              7 set-colour
	    else
              1+ pats +                 \ piece name
              c@ emit                   \ plain jane emit piece names
	    then
        loop cr
    loop
    text_normal
    ." Solution " Soln @ .
    ."  Pieces tried = " Tries @ . cr cr
    key? if
        key 27 = abort"  User aborted "
        key drop
    then ;

\ ************** Start of Guts ****************************

\ I hope you can handle long strings; the following should be
\  one long string of 181 characters ending with 'ai.....'
\ create orients ," ABCDEiIlJyKyLl.IHnJpKuQv.JKpRt.KLnSv..IHGnJpPwQf.JKpQpRp.QPzRuYl..JKLnRfSw.RQuSzZl...IHGFlJyOzPfQt.JKyPfRf.POwQpXn.QRfYy..JKCuLlQtRfSz.QPfRpYy.RSwZn..QPOvRtXnYy.RSvYyZn.YXlZlai....."
\ 'x' omitted by replacing 'JKyPfQxRf.' with 'JKyPfRf.'

c" ABCDEiIlJyKyLl.IHnJpKuQv.JKpRt.KLnSv..IHGnJpPwQf.JKpQpRp.QPzRuYl..JKLnRfSw.RQuSzZl...IHGFlJyOzPfQt.JKyPfRf.POwQpXn.QRfYy..JKCuLlQtRfSz.QPfRpYy.RSwZn..QPOvRtXnYy.RSvYyZn.YXlZlai....."
ptr orients

create pos-stack 5 allot                \ stack to hold rel positions
variable posptr  pos-stack posptr !

: push-relpos ( relpos -- )
    posptr a@ c!  1 posptr +! ;
: pop-relpos
    -1 posptr +! ;

\ factors for leaf-test
: place-piece ( p# -- )                 \ code to put piece on board
    pos-stack 5 over + swap do
        dup postpone literal
        postpone over i c@ postpone literal postpone +
        postpone c!
    loop drop ;

: lift-piece                            \ code to remove piece from board
    pos-stack 5 over + swap do
        0 postpone literal
        postpone over i c@ postpone literal postpone +
        postpone c!
    loop ;

\ defer is non-ans but everybody has it
defer next-piece                        \ forward reference

\ macro to generate code to recursively test availability of a piece
\  and mark the board and the piece availability accordingly
: leaf-test ( pc# -- )
    Pa + >r        ( R: pc-addr )
    r@ postpone literal postpone c@ postpone if \ is piece available?
        0 postpone literal r@ postpone literal postpone c! \ mark unavailable
        1 postpone literal 
        postpone Tries   
	postpone +!	    \ inc Tries
        r@ Pa - 1+ place-piece
        postpone dup postpone next-piece
        lift-piece
        -1 postpone literal r> postpone literal postpone c! \ mark available
    postpone then ;

\ factor for testsq
: sq@0= ( relpos -- )                   \ current square empty?
    postpone dup postpone literal postpone +
    postpone c@ postpone 0= ;

\ create piece#                           \ convert piece names to numbers
\      f..i..l.n.p...tuvwxyz
\    ," 0xx1xx2x3x4xxx56789:;"

c" 0xx1xx2x3x4xxx56789:;" ptr piece#

variable optr                           \ pointer into orients
    orients count drop 1- optr !

\ macro to generate code to recursively find a piece that fits at lead square
\  traverses the string orients to generate code
: testsq
    begin                               \ repeat
        1 optr +!                       \  for each char in orients
        optr a@ c@ [char] . = if         \  until recursion is done
            exit
        then
        optr a@ c@ [char] a > if         \ at a piece name?
            optr a@ c@                   \ yes
            [char] e - piece# + c@ [char] 0 - \ so convert to a number 0-11
            leaf-test exit              \ at leaf so test piece availability
        then
        optr a@ c@ [char] A - 3 +
        8 /mod Wtot * swap 3 - + >r  ( R: relpos ) \ posn rel to lead
        r@
	sq@0= postpone if            \ square empty?
            r@ push-relpos              \ push to rel posn stack
            recurse
            pop-relpos                  \ pop rel posn stack
        postpone then
        r> drop
    again ; immediate

: soln-print
    1 Soln +!  printbd ;

\ find next piece that fits lead square
: noname ( lead-sq -- )
    1 Level +!                          \ next level, i.e. place a piece
    begin                               \ loop back here
        dup 1+ Bend > if                \ at end of board yet?
            soln-print                  \ yes, so print solution
            -1 Level +!                 \ previous level, i.e. lift up piece
            drop exit                   \ exit when at end of board
        then
        1+                              \ next square
        testsq                          \ place all pieces at lead square
    dup c@ 0= until                     \ loop until lead square is empty
    drop  -1 Level +!
; 

' noname is next-piece

: solve
    0 Level !                           \ no pieces on board
    Bstart next-piece ;

\ ************** End of Guts ****************************

: placex ( x y val -- )                 \ place or lift the X pattern
    >r              ( x y R: val )
    2dup Wtot * + Bd + r@ swap c!
    2dup 1+ Wtot * + 1- Bd + r@ swap c!
    2dup 1+ Wtot * + Bd + r@ swap c!
    2dup 1+ Wtot * + 1+ Bd + r@ swap c!
    2 + Wtot * + Bd + r> swap c! ;

: x-at ( x y - )                        \ place the X; solve; then lift the X
    2dup 13 placex
    solve
    0 placex ;

: p6*10                                 \ 6 X 10 puzzle 2339 solutions
    6 10 pentom-init                    \ other boards may be constructed
    3 1 x-at                            \ 'x' in upper left quadrant
    2 2 x-at
    3 2 x-at
    2 3 x-at
    3 3 x-at
    2 4 x-at
    3 4 x-at ;

: p4*15                                 \ 4 X 15 puzzle 402 solutions
    4 15 pentom-init
    2 2 x-at
    2 3 x-at
    2 4 x-at
    2 5 x-at
    2 6 x-at
    2 7 x-at ;

variable starttime
: read-secs
    time&date drop 2drop 3600 * swap 60 * + + ;
: start-timing
    read-secs starttime ! ;
: elapsed-time ( -- secs )
    read-secs starttime @ - ;

: pentom
    page
    ." Solutions to the Pentomino Puzzle by Exhaustive Search" cr
    ." Press any key to pause, Esc to abort " cr
    0 Soln !   0 Tries !
    start-timing
    6X10 if
      p6*10
    else
      p4*15
    then
    elapsed-time
    cr cr
    ." Total solutions = " Soln @ .
    ."  Total pieces tried = " Tries @ . cr
    ." Elapsed time in secs = " .
;

pentom
