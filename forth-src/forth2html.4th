\ forth2html.4th
\ 
\ Forth --> HTML Converter, by Brad Eckert, et. al.  June 2004
\ 
\ This is the kForth version, adapted to kForth by K. Myneni, 6/17/2004
\ ( see kForth requirements section below )
\ Further revisions: 6/18/2004  km, 6/20/04, 9/24/05, 11/22/09 km
\
\ Revision history
\ 0. 1st release to guinea pigs via comp.lang.forth
\ 1. (BNE) Added multi-line comment 0 [IF]. Colored CHAR outside definitions.
\ 2. (EJB) Added missing definitions for common but nonstandard words
\    and cleaned up to account for case sensitivity.
\ 3. (EJB) Fixed up to create conforming XHTML 1.0 Strict
\ 4. (BNE) File check before nesting, moved file names to the hyperlink table,
\    added some option flags, cleared hyperlink list for each run. Added more
\    multiline comment words. Expands tabs to spaces. Title uses %20 for blanks.
\ 5. (BNE) Added multiline { comment. Replaced -1 WORD with [CHAR] |.
\    Put hyperlinks that should not be overridden in a separate wordlist.
\ 6. (BNE) Limited this text to 80 columns, cleaned up comments a bit. Added
\    option for different color schemes.
\ 7. (DBU) Added dpanspath to configure the path to the dpans-files. Added
\    linksource to output a hyperlink to the original source file. Added
\    some words used in Win32Forth. Added copyright to output a copyright text
\    at the bottom of the HTML-file.
\ 8. (BNE) Put in Dirk's link to source file in header. Changed ['] to be
\    simple colored link. Added Forth2HTML link at bottom.
\ 9. (BNE) Added index creation, fixed UPC & minor file nesting bug.
\ 10. (BNE) Fixed glass jaw in SKIP". S" etc crashed if nothing else was on the
\    line. Fixed link generation bug in multi-file HTML.
\ 11. (KM) Fixed isnumber? to handle negative numbers.
\ 12. (KM) Added definition of >FLOAT suitable for use with Forths
\          which provide floating point but do not provide >FLOAT,
\          e.g. kForth.
\ 13. (KM) Must preserve base to handle fp constant detection
\          (see changes to "fontcolor", "<idx>", and "make-index"),
\          and change in order of integer/fp detection required 
\          (see changes to "hint").
\ 14. (KM) Revised for kForth 1.5.x.
\ ================== Required for kForth =====================
include ans-words
include strings
include files 
include utils

CREATE dummy-space 8192 32 * CELLS ALLOT

\ The definitions of HERE  ","  "C," are NOT equivalent
\   to the corresponding ANS Forth defs. Their use is
\   restricted to the scope of this program only.
\
dummy-space ptr HERE
: ,  ( u|a -- ) HERE  ! HERE CELL+ TO HERE ;
: C, ( u -- )   HERE C! HERE    1+ TO HERE ;
: acreate ( <name> -- | like ANS CREATE ) HERE ptr ;

: orig-create CREATE ;
: orig-hex HEX ;
: orig-decimal DECIMAL ;


\ Utility
: $!+  ( a len adest --- a' | a' = adest+len+1; copy to dest as counted string)
    OVER OVER + 1+ >R pack R> ;
\ ================== end of kForth defs ==================

0 [IF]
   Forth to HTML converter

   Main contributors:
      Brad Eckert       brad1NO@SPAMtinyboot.com            Original author
      Ed Beroset      berosetNO@SPAMmindspring.com          Fixed HTML bugs
      Dirk Busch         dirkNO@SPAMschneider-busch.de      Added some features

   Revision 10. See bottom for revision history.

   This ANS Forth program is public domain. It translates ANS Forth to colorized
   HTML. Hyperlinks to the ANS Forth draft standard are inserted for all ANS
   standard words. Hyperlinks to user definitions are included.

   Usage: HTML FileName    Generates HTML file from Forth source.
                           Output file is Filename with .HTM extension.
          Q [forth code]   Outputs HTML for 1 line to screen

   Keep in mind that whatever path you use for the input filename will be in the
   output files, so don't use a drive letter etc. if the HTML is intended for
   distribution on CD or a web site.

   A framed version of the output file has a "_f.htm" extension. The left frame
   is an index of words and the words that use them. The right frame is source.
   If you open the index file (_i.htm extension) and click on links, source will
   be in a separate window. Still usable but frames are easier.

   Q is for debugging. You can use "linenum ?" to show the line number if an
   ABORT occurs. The HTML is about 8 times as big as the Forth source because of
   all the links, color changes and whitespace.

   INCLUDEd files produce corresponding HTML pages. If a file can't be found,
   it is skipped. Otherwise it is nested.

   When you INCLUDE this file some redefinition complaints may occur. That's
   okay since you won't be loading an application on top of this. You can make
   a text version of this file by cut-and-paste to a text editor. The browser's
   save-as-text function will work too. This file is only 80 columns wide. Note
   that the browser may wrap after 80 columns when saving as a text file.

   Users of specific Forths can extend the hyperlink table to point to anchors
   in a glossary for that particular Forth.

   This code has been tested under Win32forth, SwiftForth, VFX and Gforth.

   You can change the following bold/italic/nestable options:
[THEN]

ONLY FORTH ALSO DEFINITIONS
\ ------------------------------------------------------------------------------
\ Configuration - You can change the options:
0 VALUE bold                                      \ T if bold text
0 VALUE italic                                    \ T if italic comments
1 VALUE nestable                                  \ T if INCLUDE nested files
1 VALUE linksource                                \ T link to the org. file /7/
1 VALUE frames                                    \ T if using frames /9/
: dpanspath S" .\" ;                              \ path to the ANS-Files   /7/
: copyright S" "   ;                              \ copyright to output at  /7/
                                                  \ the bottom of the HTML-file
0 CONSTANT scheme ( Color scheme )                \ 0 = light background, 1=dark
\ ------------------------------------------------------------------------------

[undefined] NOOP   [IF] : NOOP ;                                            [THEN]
[undefined] BOUNDS [IF] : BOUNDS OVER + SWAP ;                              [THEN]
[undefined] /STRING [IF] : /STRING TUCK - >R CHARS + R> ;                   [THEN]
[undefined] C+!    [IF] : C+! SWAP OVER C@ + SWAP C! ;                      [THEN]
[undefined] FDROP  [IF] : FDROP ;         ( no floating point? fake it )    [THEN]
[undefined] SCAN   [IF] : SCAN            ( addr len char -- addr' len' )
   >R BEGIN DUP WHILE OVER C@ R@ <> WHILE 1 /STRING REPEAT THEN R> DROP ; [THEN]
[undefined] SKIP   [IF] : SKIP            ( addr len char -- addr' len' )
   >R BEGIN DUP WHILE OVER C@ R@ = WHILE 1 /STRING REPEAT THEN R> DROP ;  [THEN]

: +PLACE        ( addr len a -- ) 2DUP 2>R COUNT CHARS + SWAP MOVE 2R> C+! ;
: PLACE         ( addr len a -- ) 0 OVER C! +PLACE ;
: UPC           ( c -- C )  DUP [CHAR] a [CHAR] z 1+ WITHIN IF 32 - THEN ;

0 VALUE outf                                    \ output to file
1 VALUE screen-only                             \ screen is for testing
: werr  ABORT" Error writing file" ;
: out   screen-only IF TYPE    ELSE outf WRITE-FILE 0< werr THEN ;
: outln screen-only IF TYPE CR ELSE outf WRITE-LINE 0< werr THEN ;

WORDLIST ptr hyperlinks                    \ list of hyperlinks
WORDLIST ptr superlinks                    \ hyperlinks that can't change

VARIABLE attrib
: /a      ( -- )         attrib @ IF S" </a>" out THEN 0 attrib ! ;
: ,$      ( a len -- )   DUP C, BOUNDS ?DO I C@ C, LOOP ; \ text to dictionary
: ,|      ( <text> -- )  [CHAR] | WORD COUNT -TRAILING ,$ ;
: line    ( a line# -- ) 0 ?DO COUNT + LOOP COUNT out ;   \ output one string
: boiler  ( addr -- )    BEGIN COUNT DUP WHILE 2DUP + >R outln R> REPEAT 2DROP ;
: ital(   ( -- )         italic IF S" <i>" out THEN ;
: )ital   ( -- )         italic IF S" </i>" out THEN ;
: newline ( -- )         S" <br />" outln ;
: xcr     ( -- )         S" " outln ;           \ /9/

acreate misctext                                 \ various attribute strings
   ,| <a href="                                                         | \ 0
   ,| <a name="x                                                        |
   ,| ">                                                                |
   ,| <a href="#x                                                       |
   ,| "                                                                 |
   ,| <span style="color:#                                              |
   ,| <hr /><h1>                                                        |
   ,| </h1><hr />                                                       |
   ,| </span>                                                           |
   ,| </a>                                                              |
   ,| <HEAD><TITLE>                                                     | \ 10
   ,| </TITLE></HEAD>                                                   |
   ,| <FRAMESET cols="25%,75%">                                         |
   ,| <FRAME SRC="                                                      |
   ,| " name="idx"  target="_self">                                     |
   ,| " name="main" target="_self">                                     |
   ,| </FRAMESET>                                                       |
   ,| " target="main">                                                  | \ 17
   ,| " target="idx">                                                   |
   0 C,

VARIABLE color                                  \ current color
VARIABLE infont                                 \ within <font> tag

: <href="       misctext 0 line ;
: ">            misctext 2 line ;

: fontcolor ( color -- )                        \ change font color
   BASE @ >R 1 infont !
   misctext 5 line 0 HEX <# # # # # # # #> out  "> R> BASE ! ;

: col ( color <name> -- )                       \ define a font color
    CREATE 1 CELLS ?allot ! DOES> @ color ! ;

HEX
scheme 0 = [IF]                                 \ light background
   808080 col unknown
   008000 col commentary
   990000 col numeric
   FF0000 col errors
   990080 col values
   000000 col userwords
   009999 col userdefiner
   CC00CC col variables
   0000FF col core_ws                           \ core is slightly lighter blue
   0000FF col core_ext_ws
   0000FF col block_ws
   0000FF col double_ws
   0000FF col exception_ws
   0000FF col facilities_ws
   0000FF col file_ws
   0000FF col fp_ws
   0000FF col local_ws
   0000FF col malloc_ws
   0000FF col progtools_ws
   0000FF col searchord_ws
   0000FF col string_ws
[ELSE]                                          \ black background
   808080 col unknown
   00FF00 col commentary
   FF8080 col numeric
   FF0000 col errors
   FF00FF col values
   FFFFFF col userwords
   00FFFF col userdefiner
   FF80FF col variables
   8080FF col core_ws
   8080FF col core_ext_ws
   0000FF col block_ws
   0000FF col double_ws
   0000FF col exception_ws
   0000FF col facilities_ws
   0000FF col file_ws
   0000FF col fp_ws
   0000FF col local_ws
   0000FF col malloc_ws
   0000FF col progtools_ws
   0000FF col searchord_ws
   0000FF col string_ws
[THEN]
DECIMAL

acreate begin_header                             \ begin of HTML file part 1
   ,| <?xml version="1.0"?>                                                    |
   ,| <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"                 |
   ,|     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">                 |
   ,| <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">      |
   ,| <head>                                                                   |
   ,| <meta http-equiv="Content-Type" content="text/xml; charset=iso-8859-1" />|
   ,| <meta name="GENERATOR" content="Forth2HTML ver 10" />                    |
   ,| <style type="text/css">                                                  |
scheme 0 = [IF] ,| body {background: #FFFFEE;}  | [THEN]  \ light background
scheme 1 = [IF] ,| body {background: #000000;}  | [THEN]  \ black background
scheme 0 = [IF] ,| h1 {color: #000000;}         | [THEN]
scheme 1 = [IF] ,| h1 {color: #FFFFFF;}         | [THEN]
   ,| p {font-family: monospace;}                                              |
   ,| a {text-decoration:none;}                                                |
   ,| </style>                                                                 |
   ,| <title>                                                                  |
   0 C,

acreate mid_header                               \ begin of HTML file part 2
   ,| </title></head>                                                          |
   ,| <body>                                                                   |
   0 C,

acreate end_header_part1                         \ end of HTML file part 1 /7/
   ,| </p><hr />                                                               |
   ,| <h4 style="color:black">                                                 |
   0 C,

acreate end_header_part2                         \ end of HTML file part 2 /8/
   ,| <p><a href="http://www.tinyboot.com/ANS/color.htm"><font color="#C0C0C0">|
   ,| HTMLized by <u>Forth2HTML</u> ver 10</font></a></p>                      |
   ,| </h4>                                                                    |
   ,| </body></html>                                                           |
   0 C,

: setcolor ( -- )                               \ select next color
   color @ fontcolor ;

: closefont ( -- )
   infont @ IF
   misctext 8 line 0 infont ! THEN ;

\ In order to represent all ASCII chars as text, some puncuation needs to be
\ changed to make it HTML compatible.

VARIABLE bltally
: outh    ( a n -- )                            \ HTMLized text output
   999 bltally !
   BOUNDS ?DO I C@ CASE
      [CHAR] & OF S" &amp;"     out ENDOF
      [CHAR] < OF S" &lt;"      out ENDOF
      [CHAR] > OF S" &gt;"      out ENDOF
      [CHAR] " OF S" &quot;"    out ENDOF
      [CHAR] � OF S" &copy;"    out ENDOF       \ /7/
      BL       OF bltally @ 0= IF S"  " ELSE S" &nbsp;" THEN out
                1 bltally +!     ENDOF
      I 1 out   0 bltally !
   ENDCASE LOOP ;

: outhattr  ( a n -- )                          \ HTMLized text output
   BOUNDS ?DO I C@ CASE
      [CHAR] & OF S" amp"       out ENDOF
      [CHAR] < OF S" lt"        out ENDOF
      [CHAR] > OF S" gt"        out ENDOF
      [CHAR] " OF S" quot"      out ENDOF
      [CHAR] + OF S" plus"      out ENDOF
      [CHAR] ! OF S" bang"      out ENDOF
      [CHAR] / OF S" slash"     out ENDOF
      [CHAR] \ OF S" backslash" out ENDOF
      [CHAR] ' OF S" apos"      out ENDOF
      [CHAR] = OF S" equal"     out ENDOF
      [CHAR] - OF S" dash"      out ENDOF
      [CHAR] @ OF S" at"        out ENDOF
      [CHAR] ; OF S" semi"      out ENDOF
      [CHAR] * OF S" star"      out ENDOF
      [CHAR] ? OF S" question"  out ENDOF
      [CHAR] ~ OF S" tilde"     out ENDOF
      [CHAR] # OF S" pound"     out ENDOF
      [CHAR] , OF S" comma"     out ENDOF
      [CHAR] $ OF S" dollar"    out ENDOF
      [CHAR] | OF S" bar"       out ENDOF
      [CHAR] [ OF S" ltbracket" out ENDOF
      [CHAR] ( OF S" ltparen"   out ENDOF
      [CHAR] { OF S" ltbrace"   out ENDOF
      [CHAR] ] OF S" rtbracket" out ENDOF
      [CHAR] ) OF S" rtparen"   out ENDOF
      [CHAR] } OF S" rtbrace"   out ENDOF
      BL       OF S" _"         out ENDOF
      I 1 out
   ENDCASE LOOP ;

: end_header ( -- )                             \ output end of HTML file /7/
   end_header_part1 boiler
   copyright ?DUP IF outh ELSE drop THEN
   end_header_part2 boiler ;

: label ( addr len -- ) /a                      \ associate a label with a word
   misctext 1 line outhattr
   "> 1 attrib ! ;

\ Assuming this is running on a PC, we allocate enough storage that crashes from
\ string overflows can't happen.

CREATE inbuf 260 CHARS ALLOT                    \ current line from file
CREATE token 260 CHARS ALLOT                    \ last blank delimited string
CREATE XPAD  260 CHARS ALLOT                    \ temporary pad for word storage
CREATE EPAD  260 CHARS ALLOT                    \ temporary pad for evaluation
CREATE fn    260 CHARS ALLOT                    \ file name
CREATE fn1   260 CHARS ALLOT                    \ file name backup
CREATE fn2   260 CHARS ALLOT                    \ global file name
CREATE fn3   260 CHARS ALLOT                    \ index file name
CREATE "str" 260 CHARS ALLOT                    \ parsed string storage
CREATE uname 260 CHARS ALLOT                    \ : definition name
0 VALUE inf
VARIABLE nufile                                 \ T if nesting a file
VARIABLE utype                                  \ type of defined word
VARIABLE hstate
VARIABLE linenum
VARIABLE special                                \ special action, 0=none

\ Defining word for hyperlinks to words in HTML standards files.

: std    ( word 2nd_fn color filename label -- )
   \ CREATE ' , ' , BL WORD COUNT ,$ BL WORD COUNT ,$
   CREATE 512 ?ALLOT ' OVER ! CELL+ ' OVER ! CELL+
   BL WORD COUNT ROT $!+
   BL WORD COUNT ROT pack  
 
   DOES> /a DUP >R  2 CELLS +
   <href="                                      \ begin hyperlink
   dpanspath out                                \ output path to ANS files /7/
   COUNT 2DUP + >R  out S" #" out               \ output file name
   R> COUNT out ">                              \ and anchor name
   1 attrib !
   R> 2@ SWAP EXECUTE EXECUTE ;                 \ extra attributes

: genHTML ( -- )                                \ generate pending HTML
   token COUNT DUP IF setcolor THEN outh closefont /a  0 token ! ;

: isnumber? ( addr len -- f )                   \ string converts to number?
   OVER C@ [CHAR] - = IF 1 /STRING THEN 
   0 0 2SWAP >NUMBER NIP NIP NIP 0= ;
   
: hparse ( a len char -- a' len' )
   >R 2DUP R@ SKIP R> SCAN BL SCAN
   2SWAP 2 PICK - token +PLACE ;

: >XPAD ( -- ) token COUNT BL SKIP XPAD PLACE ; \ move to temporary pad

: hint  ( addr len -- )                         \ interpret one line...
   BEGIN
      0 token !  BL hparse token C@
   WHILE unknown                                \ default color
      >XPAD XPAD COUNT superlinks SEARCH-WORDLIST 0=  \ fixed hyperlink?
      IF    XPAD COUNT hyperlinks SEARCH-WORDLIST \ got a hyperlink for this?
      ELSE  TRUE
      THEN
      IF DEPTH >R EXECUTE
         R> DEPTH <> ABORT" stack depth change in HTML generator"
      ELSE
         XPAD COUNT isnumber?   \ valid number?
	 IF numeric ELSE BASE @ 10 = 
	   IF XPAD COUNT >FLOAT IF numeric FDROP THEN THEN        \ valid float? 
         THEN
      THEN genHTML
   REPEAT 2DROP newline ;

: shortname   ( -- )
   fn COUNT 2DUP [CHAR] . SCAN NIP - EPAD PLACE ;

: ofn    ( -- addr len )                        \ output file name
   shortname S" .htm" EPAD +PLACE  EPAD COUNT ;

: mfn    ( -- addr len )                        \ main file name
   shortname S" _f.htm" EPAD +PLACE  EPAD COUNT ;

: hcreate ( addr len -- )
   DUP 0= IF 2DROP S" fakename" THEN            \ in case the name is missing
   S" orig-create " EPAD PLACE  EPAD +PLACE
   GET-CURRENT >R hyperlinks SET-CURRENT
   EPAD COUNT EVALUATE    R> SET-CURRENT ;      \ create a hyperlink generator

\ The user defined words use the following data structure:
\ CELL   xt of coloring word
\ CELL   pointer to index                       \ /9/
\ STRING name of reference word
\ STRING name of file

\ An index is a list of all of the words that call a defined word. The master
\ index is a list of indexes.

variable index  0 index !                       \ index is a SLL of SLLs.
variable ulast  0 ulast !                       \ last compiled definition name
variable tally  0 tally !                       \ tally of defined words

\ Each index entry consists of a pointer to the previous index entry and a SLL.
\ The SLL (single linked list) starts out empty so upon creation it is 0.

\ index --> link_to_next
\           link_to_usedby_list <-- 'index
\           link to defined name structure
\           tally

: <idx>     ( n -- )                            \ create link to index n
   frames if                                    \ links undesirable if no frames
   1 attrib !                                   \ or for W3C HTML validation
   <href=" fn3 count out S" #x" out             \ <a href="index.htm#x
   BASE @ >R HEX 0 <# #S #> out R> BASE ! misctext 18 line          \ ..." target="idx">
   else drop then ;

: newindex ( -- 'index )                        \ add an index to the list
   HERE index @ , HERE SWAP 0 , index ! 0 ,     \ /9/
   1 tally +!  tally @ , ;

\ 'index -> link_to_next
\           link to usedby name structure

: newlink  ( 'index -- 'index )                 \ add a name to the index /9/
   dup a@ a@ ?dup if                              \ non-empty sublist?
      cell+ @ ulast @ = if exit then            \ duplicate entry
   then
   HERE OVER a@ @ , ulast @ , OVER a@ ! ;

variable indexing

: deflink ( addr -- )                           \ defined word makes hyperlink
   DUP @ EXECUTE CELL+                          \ set color
   ulast a@ IF newlink THEN CELL+               \ /9/ optional addition to index
   DUP COUNT + COUNT ofn COMPARE                \ in an external file?
   IF   <href=" DUP COUNT + COUNT out           \ yes, put the file name
        S" #x" out COUNT outhattr
   ELSE misctext 3 line COUNT outhattr          \ no, just the label name
        misctext 4 line
   THEN
   misctext indexing @ if 17 else 2 then line   \ an index link needs a target
   1 attrib ! ;

: showlink ( addr bold? -- )                    \ output hyperlink for index
   >R dup deflink
   R@ if S" <b>" out then
   2 cells + count outh
   R> if S" </b>" out then
   /a    S"  " out ;

: outdex ( sll -- )                             \ output list of client words
   0 ulast !
   begin ?dup while  dup cell+ a@ 0 showlink  a@ repeat ;

: iname ( a -- )                                \ display index root name
   a@ 1 showlink ;

: defx  ( a len xt -- a' len' )
   newindex >R
   >R genHTML BL hparse >XPAD                   \ output defining word
   \ XPAD COUNT 2DUP hcreate R> HERE SWAP ,
   \ R@ CELL+ !                                   \ resolve link to definition name
   \ R> , ,$ ofn ,$                               \ rest of structure
   XPAD COUNT 2DUP hcreate 512 ?allot R> OVER !
   DUP R@ CELL+ ! CELL+ R> OVER ! CELL+  $!+  ofn ROT pack
   DOES> deflink ;

: labelnow   XPAD COUNT label /a tally @ <idx> genHTML /a ;
: defdat ['] numeric   defx numeric   labelnow ;
: defvar ['] variables defx variables labelnow ;
: defusr ['] userwords defx userwords labelnow ;
: defval ['] values    defx values    labelnow ;
: defdef ['] userdefiner defx userdefiner labelnow ;

: hstate=0 ( -- )             0 hstate ! ;
: hstate=1 ( -- )             1 hstate ! ;
: spec=zero ( -- )            1 special ! ;
: NONE     ( -- )             0 special ! ;     \ plain word
: skip)  ( a len -- a' len' ) [CHAR] ) hparse ;
: skip}  ( a len -- a' len' ) [CHAR] } hparse ; \ /7/
: skipw  ( a len -- a' len' ) BL hparse ;
: skipc  ( a len -- a len )   hstate @ 0= IF numeric skipw THEN ;
: skip"  ( a len -- a' len' )                   \ copy string to "str"
   genHTML [CHAR] " hparse token COUNT 1- 0 MAX "str" PLACE ;  \ /10/

\ ------------------------------------------------------------------------------
\ ":" definitions might be defining words, so they can't be assumed to be defusr
\ types. ":" makes a label and saves the name for later use by ";" which makes
\ a hyperlink or a hyperlink defining word.

: NONAME                                         \ normal : definition
   ulast @ if                                   \ ending a : definition?
      uname COUNT ['] userwords defx 2DROP  0 token !
   then
; ( CONSTANT normal_def ) ' NONAME ptr normal_def

: NONAME
   newindex >R
   uname COUNT 2DUP hcreate 
   \ HERE ['] userwords , R@ CELL+ ! R> , ,$ ofn ,$
   512 ?allot ['] userwords OVER ! DUP R@ CELL+ ! CELL+ R> OVER ! CELL+ $!+
   ofn ROT pack
   DOES> deflink defdef
; ( CONSTANT defining_def )  ' NONAME ptr defining_def

\ ULAST points to a data structure containing the hyperlink to the word being
\ defined. It is used when building the index because it can't wait until ;
\ resolves the definition before requiring the hyperlink.

: defunk ( a len -- a' len' )                   \ starting unknown definition
   hstate=1  normal_def utype !                 \ save name of : definition
   genHTML skipw userwords token COUNT BL SKIP
   2DUP label /a tally @ 1+ <idx>               \ link to index
   2DUP HERE ulast ! ['] NOOP , PAD , ,$ ofn ,$ \ save name of definition /9/
   uname PLACE ;

: resunk ( -- )                                 \ resolve unknown defined word
   genHTML ( utype @ EXECUTE) hstate=0
   0 ulast ! ;                                  \ indexing off

: created ( -- ) hstate @
   IF   defining_def utype !                    \ make ; create a defining word
   ELSE defdat                                  \ not compiling
   THEN ;

\ ------------------------------------------------------------------------------

: header  ( -- )                                \ output big header text /8/9/
   fn count
   misctext 6 line
   linksource
   IF   <href="
        2dup out ">
        outln  misctext 9 line
   ELSE outln
   THEN misctext 7 line ;

: _incfil ( addr -- )                           \ trigger file nesting  /4/
   nestable 0= IF DROP EXIT THEN                \ don't nest files if disabled
   COUNT BL SKIP  2DUP R/O OPEN-FILE            \ can the file be opened?
   IF   DROP 2DROP                              \ no
   ELSE CLOSE-FILE DROP                         \ yes
        fn COUNT fn1 PLACE  fn PLACE 1 nufile !
   THEN ;

: incfile ( a len -- a' len' )                  \ include a file
   genHTML skipw token _incfil ;

: "incfil ( a len -- a' len' )                  \ include file from S" filename"
   skipw "str" _incfil ;

: hfill  ( -- len ior )                         \ read next line of file
   inbuf 256 BL FILL
   XPAD 256 inf READ-LINE ( ABORT" Error reading file" ) 
   IF EXIT THEN
   >R >R 0 XPAD R> BOUNDS                       ( idx . . )
   ?DO  I C@ 9 = IF 3 RSHIFT 1+ 3 LSHIFT        \ tab
        ELSE I C@ OVER 255 AND CHARS inbuf + C!
           1+ DUP 256 = IF CR ." Input line too long" THEN
        THEN
   LOOP R>
   1 linenum +! ;

\ OPEN and CLOSE input files

: open-inf  ( -- ) CR ." Reading " fn COUNT TYPE ."  at line " linenum @ decimal .
   0 linenum !
   fn COUNT R/O OPEN-FILE ABORT" Error opening source file" TO inf ;

: close-inf  ( -- ) CR ." closing " fn COUNT TYPE
   inf CLOSE-FILE ABORT" Error closing file" ;

: .title  ( addr len -- )                       \ output as title string
   BOUNDS ?DO I C@ BL = IF S" %20" out ELSE I 1 out THEN LOOP ;

\ OPEN and CLOSE output files

: ocreate ( addr len -- )
   W/O CREATE-FILE ABORT" Error creating file" TO outf ;

: oopen  ( -- )                                 \ create new output file
   ofn ocreate begin_header boiler              \ begin boilerplate
   fn COUNT .title  mid_header boiler           \ title and end boilerplate
   bold IF S" <b>" out THEN ;

: fclose  ( -- )
   outf CLOSE-FILE ABORT" Error closing file" ;

: new-output  ( -- )                            \ start a new output file /9/
   open-inf oopen header S" <p>" out ;

\ Create index and frame files

: make-index  ( -- )                            \ make index /9/
   cr ." building index "
   1 indexing !
   fn2 count fn place
   cr ." Framed version: " mfn type
   mfn ocreate                                  \ create the main file
   misctext 10 line fn count .title
   ofn xpad place
   fn3 COUNT fn PLACE                           \ filename for index
   misctext 11 line xcr misctext 12 line xcr    \    <FRAMESET>
   misctext 13 line ofn out        misctext 14 line xcr \ <FRAME SRC= ...
   misctext 13 line xpad count out misctext 15 line xcr \ <FRAME SRC= ...
   misctext 16 line xcr                         \    </FRAMESET>
   fclose
   cr ." Index file " ofn type
   oopen S" <p>" out                            \ start the menu frame file
   index a@ begin ?dup while                    \ for all index entries:
      dup cell+  dup cell+  dup cell+ @
      misctext 1 line  BASE @ >R HEX 0 <# #S #> out R> BASE !       \ <a name="x
      ">  misctext 9 line          \ a></a>
      iname                \ root name
      a@ outdex newline                         \ list of client words
   a@ repeat
   S" </p></body></html>" outln                 \ end index
   fclose ;

\ Convert Forth source file(s) to HTML

: HTML  ( <infile> -- )
   S" /basic-links/" hyperlinks SEARCH-WORDLIST
   IF   EXECUTE  THEN                           \ remove user hyperlinks
   GET-CURRENT >R hyperlinks SET-CURRENT        \ replace the fence
   \ S" MARKER /basic-links/" EVALUATE
   R> SET-CURRENT
   0 TO outf                                    \ no output file yet
   0 TO screen-only  0 nufile !  1 linenum !    \ force usage of file
   0 ulast ! 0 index ! 0 tally !                \ clear index
   0 indexing !
   BL WORD COUNT  2dup fn2 place                \ save global filename /9/
   fn PLACE shortname S" _i.htm" epad +place epad count fn3 place \ index name
   new-output                                   \ open input and output files
   -1 DUP >R outf >R                            \ file nest uses stacks
   hstate=0
   BEGIN
      BEGIN 0 special !                         \ process line
         nufile @                               \ nest a file?
         IF   inf outf
              new-output outf >R                \ open new files
              0 nufile !
         THEN hfill
      WHILE inbuf SWAP hint
      REPEAT DROP
      close-inf fn1 COUNT fn PLACE                  \ restore file name
      DUP -1 <>
      IF   TO outf TO inf FALSE                 \ unnest files
      ELSE TRUE
      THEN
   UNTIL DROP
   BEGIN R> DUP -1 <>                           \ close all output files
   WHILE TO outf
         bold IF S" </b>" out THEN end_header
         fclose
   REPEAT DROP
   make-index 
   ( CR BYE) ;

: test TRUE TO screen-only 
     -1 WORD COUNT inbuf PLACE inbuf COUNT 
     BEGIN
       0 token ! BL hparse token C@ 
     WHILE
       token count type CR
       unknown
       >XPAD
       XPAD COUNT
       superlinks SEARCH-WORDLIST 0=
       IF XPAD COUNT hyperlinks SEARCH-WORDLIST
       ELSE TRUE  
       THEN
       IF DEPTH >R
         EXECUTE
         R> DEPTH <> ABORT" stack depth change..."
       THEN
      REPEAT 2DROP
;

: q  ( -- ) 1 TO screen-only                    \ single line test
   -1 WORD COUNT inbuf PLACE inbuf COUNT hint ;

\ 0 [IF] is often used as a comment. If it is used as a comment, scan the file
\ for a [THEN]. [THEN] must be on the next line or beyond.

CREATE terminator 16 CHARS ALLOT                \ multiline comment terminator

: multicomment ( a len searchstring -- a' len' )
   terminator PLACE
   genHTML commentary ital( setcolor outh       \ finish up this line
   BEGIN hfill newline
   WHILE >R inbuf EPAD R@ MOVE
      EPAD R@ BOUNDS ?DO I C@ UPC I C! LOOP     \ uppercase for search
      EPAD R@ terminator COUNT SEARCH
      IF   DROP EPAD - inbuf OVER token PLACE   \ before [THEN] is comment
           genHTML
           inbuf R> ROT /STRING
           )ital closefont EXIT
      ELSE 2DROP inbuf R> outh                  \ whole line is comment
      THEN
   REPEAT inbuf SWAP )ital closefont ;          \ EOF found

: bigif  ( a len -- a len )  ( special @ 1 = ) 1
   IF S" [THEN]" multicomment THEN ;

\ =============================================================================

: _DEFINITIONS DEFINITIONS ;
: _order order ;  
: _words words ; 
\ : _see see ;

superlinks SET-CURRENT \ These hyperlinks cannot be overridden.

\ The following words are not in the ANS standard but are very common.
: VOCABULARY    defusr ;
: DEFER         defusr ;
: INCLUDE       hstate @ 0= IF incfile THEN ;
\ : FLOAD         hstate @ 0= IF incfile THEN ;
\ : SYS-FLOAD     hstate @ 0= IF incfile THEN ;
\ : BINARY        2 BASE ! ;
\ : OCTAL         8 BASE ! ;
\ : 0             numeric spec=zero ;
\ : 1             numeric  ;
\ : -1            numeric  ;
\ : COMMENT:      S" COMMENT;" multicomment ;
\ : ((            S" ))"       multicomment ;

\ The following words are not in the ANS standard but are used in Win32Forth
\ : ANEW          skipw ;                    \ /7/
\ : CallBack:     defunk ;                   \ /7/
\ : :M            defunk ;                   \ /7/
\ : ;M            resunk ;                   \ /7/
\ : z"            numeric skip" ;

\ Forth Inc uses { for comment while others use it for locals. } on the same
\ line indicates locals, which are grayed. Otherwise a multiline comment.

: {             2DUP [CHAR] } SCAN NIP 0=
                IF S" }" multicomment ELSE genHTML skip} THEN ;

\ Not ANS standard, but used in kForth

: ?allot  resunk ;
: a@      resunk ;


hyperlinks SET-CURRENT \ These hyperlinks can be overridden.
 
\ The rest is ANS Forth standard

: \             commentary genHTML ital( token PLACE genHTML )ital token 0 ;

( Some user-help )

CR CR .( USAGE:  html filename -- Converts file and exits Forth ) CR CR

(   NAME                ACTION  COLOR           FILENAME        REFERENCE )
(   ------------------  ------  --------------  -----------     --------- )
std (                   skip)   commentary      dpans6.htm      6.1.0080
std ."                  skip"   numeric         dpans6.htm      6.1.0190
std :                   defunk  core_ws         dpans6.htm      6.1.0450
std ;                   resunk  core_ws         dpans6.htm      6.1.0460
std ABORT"              skip"   errors          dpans6.htm      6.1.0680
std CHAR                skipc   core_ws         dpans6.htm      6.1.0895
std CONSTANT            defdat  core_ws         dpans6.htm      6.1.0950
std CREATE              created core_ws         dpans6.htm      6.1.1000
std DECIMAL        orig-DECIMAL core_ws         dpans6.htm      6.1.1170
std S"                  skip"   numeric         dpans6.htm      6.1.2165
std VARIABLE            defvar  core_ws         dpans6.htm      6.1.2410
std [                  hstate=0 core_ws         dpans6.htm      6.1.2500
std [CHAR]              skipw   numeric         dpans6.htm      6.1.2520
std ]                  hstate=1 core_ws         dpans6.htm      6.1.2540
std .(                  skip)   commentary      dpans6.htm      6.2.0200
std C"                  skip"   numeric         dpans6.htm      6.2.0855
std FALSE             spec=zero numeric         dpans6.htm      6.2.1485
std HEX            orig-HEX     core_ext_ws     dpans6.htm      6.2.1660
std MARKER              defusr  core_ext_ws     dpans6.htm      6.2.1850
std VALUE               defval  core_ext_ws     dpans6.htm      6.2.2405
std 2CONSTANT           defdat  double_ws       dpans8.htm      8.6.1.0360
std 2VARIABLE           defvar  double_ws       dpans8.htm      8.6.1.0440
std INCLUDED            "incfil file_ws         dpans11.htm     11.6.1.1718
std FCONSTANT           defdat  fp_ws           dpans12.htm     12.6.1.1492
std FVARIABLE           defvar  fp_ws           dpans12.htm     12.6.1.1630
std ;CODE               resunk  progtools_ws    dpans15.htm     15.6.2.0470
std CODE                defusr  progtools_ws    dpans15.htm     15.6.2.0930
std [IF]                bigif   progtools_ws    dpans15.htm     15.6.2.2532


std [']                 NONE    numeric         dpans6.htm      6.1.2510
std !                   NONE    core_ws         dpans6.htm      6.1.0010
std #                   NONE    core_ws         dpans6.htm      6.1.0030
std #>                  NONE    core_ws         dpans6.htm      6.1.0040
std #S                  NONE    core_ws         dpans6.htm      6.1.0050
std '                   NONE    core_ws         dpans6.htm      6.1.0070
std *                   NONE    core_ws         dpans6.htm      6.1.0090
std */                  NONE    core_ws         dpans6.htm      6.1.0100
std */MOD               NONE    core_ws         dpans6.htm      6.1.0110
std +                   NONE    core_ws         dpans6.htm      6.1.0120
std +!                  NONE    core_ws         dpans6.htm      6.1.0130
std +LOOP               NONE    core_ws         dpans6.htm      6.1.0140
std ,                   NONE    core_ws         dpans6.htm      6.1.0150
std -                   NONE    core_ws         dpans6.htm      6.1.0160
std .                   NONE    core_ws         dpans6.htm      6.1.0180
std /                   NONE    core_ws         dpans6.htm      6.1.0230
std /MOD                NONE    core_ws         dpans6.htm      6.1.0240
std 0<                  NONE    core_ws         dpans6.htm      6.1.0250
std 0=                  NONE    core_ws         dpans6.htm      6.1.0270
std 1+                  NONE    core_ws         dpans6.htm      6.1.0290
std 1-                  NONE    core_ws         dpans6.htm      6.1.0300
std 2!                  NONE    core_ws         dpans6.htm      6.1.0310
std 2*                  NONE    core_ws         dpans6.htm      6.1.0320
std 2/                  NONE    core_ws         dpans6.htm      6.1.0330
std 2@                  NONE    core_ws         dpans6.htm      6.1.0350
std 2DROP               NONE    core_ws         dpans6.htm      6.1.0370
std 2DUP                NONE    core_ws         dpans6.htm      6.1.0380
std 2OVER               NONE    core_ws         dpans6.htm      6.1.0400
std 2SWAP               NONE    core_ws         dpans6.htm      6.1.0430
std <                   NONE    core_ws         dpans6.htm      6.1.0480
std <#                  NONE    core_ws         dpans6.htm      6.1.0490
std =                   NONE    core_ws         dpans6.htm      6.1.0530
std >                   NONE    core_ws         dpans6.htm      6.1.0540
std >BODY               NONE    core_ws         dpans6.htm      6.1.0550
std >IN                 NONE    core_ws         dpans6.htm      6.1.0560
std >NUMBER             NONE    core_ws         dpans6.htm      6.1.0570
std >R                  NONE    core_ws         dpans6.htm      6.1.0580
std ?DUP                NONE    core_ws         dpans6.htm      6.1.0630
std @                   NONE    core_ws         dpans6.htm      6.1.0650
std ABORT               NONE    core_ws         dpans6.htm      6.1.0670
std ABS                 NONE    core_ws         dpans6.htm      6.1.0690
std ACCEPT              NONE    core_ws         dpans6.htm      6.1.0695
std ALIGN               NONE    core_ws         dpans6.htm      6.1.0705
std ALIGNED             NONE    core_ws         dpans6.htm      6.1.0706
std ALLOT               NONE    core_ws         dpans6.htm      6.1.0710
std AND                 NONE    core_ws         dpans6.htm      6.1.0720
std BASE                NONE    core_ws         dpans6.htm      6.1.0750
std BEGIN               NONE    core_ws         dpans6.htm      6.1.0760
std BL                  NONE    numeric         dpans6.htm      6.1.0770
std C!                  NONE    core_ws         dpans6.htm      6.1.0850
std C,                  NONE    core_ws         dpans6.htm      6.1.0860
std C@                  NONE    core_ws         dpans6.htm      6.1.0870
std CELL+               NONE    core_ws         dpans6.htm      6.1.0880
std CELLS               NONE    core_ws         dpans6.htm      6.1.0890
std CHAR+               NONE    core_ws         dpans6.htm      6.1.0897
std CHARS               NONE    core_ws         dpans6.htm      6.1.0898
std COUNT               NONE    core_ws         dpans6.htm      6.1.0980
std CR                  NONE    core_ws         dpans6.htm      6.1.0990
std DEPTH               NONE    core_ws         dpans6.htm      6.1.1200
std DO                  NONE    core_ws         dpans6.htm      6.1.1240
std DOES>               NONE    core_ws         dpans6.htm      6.1.1250
std DROP                NONE    core_ws         dpans6.htm      6.1.1260
std DUP                 NONE    core_ws         dpans6.htm      6.1.1290
std ELSE                NONE    core_ws         dpans6.htm      6.1.1310
std EMIT                NONE    core_ws         dpans6.htm      6.1.1320
std ENVIRONMENT?        NONE    core_ws         dpans6.htm      6.1.1345
std EVALUATE            NONE    core_ws         dpans6.htm      6.1.1360
std EXECUTE             NONE    core_ws         dpans6.htm      6.1.1370
std EXIT                NONE    core_ws         dpans6.htm      6.1.1380
std FILL                NONE    core_ws         dpans6.htm      6.1.1540
std FIND                NONE    core_ws         dpans6.htm      6.1.1550
std FM/MOD              NONE    core_ws         dpans6.htm      6.1.1561
std HERE                NONE    core_ws         dpans6.htm      6.1.1650
std HOLD                NONE    core_ws         dpans6.htm      6.1.1670
std I                   NONE    core_ws         dpans6.htm      6.1.1680
std IF                  NONE    core_ws         dpans6.htm      6.1.1700
std IMMEDIATE           NONE    core_ws         dpans6.htm      6.1.1710
std INVERT              NONE    core_ws         dpans6.htm      6.1.1720
std J                   NONE    core_ws         dpans6.htm      6.1.1730
std KEY                 NONE    core_ws         dpans6.htm      6.1.1750
std LEAVE               NONE    core_ws         dpans6.htm      6.1.1760
std LITERAL             NONE    core_ws         dpans6.htm      6.1.1780
std LOOP                NONE    core_ws         dpans6.htm      6.1.1800
std LSHIFT              NONE    core_ws         dpans6.htm      6.1.1805
std M*                  NONE    core_ws         dpans6.htm      6.1.1810
std MAX                 NONE    core_ws         dpans6.htm      6.1.1870
std MIN                 NONE    core_ws         dpans6.htm      6.1.1880
std MOD                 NONE    core_ws         dpans6.htm      6.1.1890
std MOVE                NONE    core_ws         dpans6.htm      6.1.1900
std NEGATE              NONE    core_ws         dpans6.htm      6.1.1910
std OR                  NONE    core_ws         dpans6.htm      6.1.1980
std OVER                NONE    core_ws         dpans6.htm      6.1.1990
std POSTPONE            NONE    core_ws         dpans6.htm      6.1.2033
std QUIT                NONE    core_ws         dpans6.htm      6.1.2050
std R>                  NONE    core_ws         dpans6.htm      6.1.2060
std R@                  NONE    core_ws         dpans6.htm      6.1.2070
std RECURSE             NONE    core_ws         dpans6.htm      6.1.2120
std REPEAT              NONE    core_ws         dpans6.htm      6.1.2140
std ROT                 NONE    core_ws         dpans6.htm      6.1.2160
std RSHIFT              NONE    core_ws         dpans6.htm      6.1.2162
std S>D                 NONE    core_ws         dpans6.htm      6.1.2170
std SIGN                NONE    core_ws         dpans6.htm      6.1.2210
std SM/REM              NONE    core_ws         dpans6.htm      6.1.2214
std SOURCE              NONE    core_ws         dpans6.htm      6.1.2216
std SPACE               NONE    core_ws         dpans6.htm      6.1.2220
std SPACES              NONE    core_ws         dpans6.htm      6.1.2230
std STATE               NONE    core_ws         dpans6.htm      6.1.2250
std SWAP                NONE    core_ws         dpans6.htm      6.1.2260
std THEN                NONE    core_ws         dpans6.htm      6.1.2270
std TYPE                NONE    core_ws         dpans6.htm      6.1.2310
std U.                  NONE    core_ws         dpans6.htm      6.1.2320
std U<                  NONE    core_ws         dpans6.htm      6.1.2340
std UM*                 NONE    core_ws         dpans6.htm      6.1.2360
std UM/MOD              NONE    core_ws         dpans6.htm      6.1.2370
std UNLOOP              NONE    core_ws         dpans6.htm      6.1.2380
std UNTIL               NONE    core_ws         dpans6.htm      6.1.2390
std WHILE               NONE    core_ws         dpans6.htm      6.1.2430
std WORD                NONE    core_ws         dpans6.htm      6.1.2450
std XOR                 NONE    core_ws         dpans6.htm      6.1.2490
std #TIB                NONE    core_ext_ws     dpans6.htm      6.2.0060
std .R                  NONE    core_ext_ws     dpans6.htm      6.2.0210
std 0<>                 NONE    core_ext_ws     dpans6.htm      6.2.0260
std 0>                  NONE    core_ext_ws     dpans6.htm      6.2.0280
std 2>R                 NONE    core_ext_ws     dpans6.htm      6.2.0340
std 2R>                 NONE    core_ext_ws     dpans6.htm      6.2.0410
std 2R@                 NONE    core_ext_ws     dpans6.htm      6.2.0415
std :NONAME             NONE    core_ext_ws     dpans6.htm      6.2.0455
std <>                  NONE    core_ext_ws     dpans6.htm      6.2.0500
std ?DO                 NONE    core_ext_ws     dpans6.htm      6.2.0620
std AGAIN               NONE    core_ext_ws     dpans6.htm      6.2.0700
std CASE                NONE    core_ext_ws     dpans6.htm      6.2.0873
std COMPILE,            NONE    core_ext_ws     dpans6.htm      6.2.0945
std CONVERT             NONE    core_ext_ws     dpans6.htm      6.2.0970
std ENDCASE             NONE    core_ext_ws     dpans6.htm      6.2.1342
std ENDOF               NONE    core_ext_ws     dpans6.htm      6.2.1343
std ERASE               NONE    core_ext_ws     dpans6.htm      6.2.1350
std EXPECT              NONE    core_ext_ws     dpans6.htm      6.2.1390
std NIP                 NONE    core_ext_ws     dpans6.htm      6.2.1930
std OF                  NONE    core_ext_ws     dpans6.htm      6.2.1950
std PAD                 NONE    core_ext_ws     dpans6.htm      6.2.2000
std PARSE               NONE    core_ext_ws     dpans6.htm      6.2.2008
std PICK                NONE    core_ext_ws     dpans6.htm      6.2.2030
std QUERY               NONE    core_ext_ws     dpans6.htm      6.2.2040
std REFILL              NONE    core_ext_ws     dpans6.htm      6.2.2125
std RESTORE-INPUT       NONE    core_ext_ws     dpans6.htm      6.2.2148
std ROLL                NONE    core_ext_ws     dpans6.htm      6.2.2150
std SAVE-INPUT          NONE    core_ext_ws     dpans6.htm      6.2.2182
std SOURCE-ID           NONE    core_ext_ws     dpans6.htm      6.2.2218
std SPAN                NONE    core_ext_ws     dpans6.htm      6.2.2240
std TIB                 NONE    core_ext_ws     dpans6.htm      6.2.2290
std TO                  NONE    core_ext_ws     dpans6.htm      6.2.2295
std TRUE                NONE    numeric         dpans6.htm      6.2.2298
std TUCK                NONE    core_ext_ws     dpans6.htm      6.2.2300
std U.R                 NONE    core_ext_ws     dpans6.htm      6.2.2330
std U>                  NONE    core_ext_ws     dpans6.htm      6.2.2350
std UNUSED              NONE    core_ext_ws     dpans6.htm      6.2.2395
std WITHIN              NONE    core_ext_ws     dpans6.htm      6.2.2440
std [COMPILE]           NONE    core_ext_ws     dpans6.htm      6.2.2530
std BLK                 NONE    block_ws        dpans7.htm      7.6.1.0790
std BLOCK               NONE    block_ws        dpans7.htm      7.6.1.0800
std BUFFER              NONE    block_ws        dpans7.htm      7.6.1.0820
std FLUSH               NONE    block_ws        dpans7.htm      7.6.1.1559
std LOAD                NONE    block_ws        dpans7.htm      7.6.1.1790
std SAVE-BUFFERS        NONE    block_ws        dpans7.htm      7.6.1.2180
std UPDATE              NONE    block_ws        dpans7.htm      7.6.1.2400
std EMPTY-BUFFERS       NONE    block_ws        dpans7.htm      7.6.2.1330
std LIST                NONE    block_ws        dpans7.htm      7.6.2.1770
std SCR                 NONE    block_ws        dpans7.htm      7.6.2.2190
std THRU                NONE    block_ws        dpans7.htm      7.6.2.2280
std 2LITERAL            NONE    double_ws       dpans8.htm      8.6.1.0390
std D+                  NONE    double_ws       dpans8.htm      8.6.1.1040
std D-                  NONE    double_ws       dpans8.htm      8.6.1.1050
std D.                  NONE    double_ws       dpans8.htm      8.6.1.1060
std D.R                 NONE    double_ws       dpans8.htm      8.6.1.1070
std D0<                 NONE    double_ws       dpans8.htm      8.6.1.1075
std D0=                 NONE    double_ws       dpans8.htm      8.6.1.1080
std D2*                 NONE    double_ws       dpans8.htm      8.6.1.1090
std D2/                 NONE    double_ws       dpans8.htm      8.6.1.1100
std D<                  NONE    double_ws       dpans8.htm      8.6.1.1110
std D=                  NONE    double_ws       dpans8.htm      8.6.1.1120
std D>S                 NONE    double_ws       dpans8.htm      8.6.1.1140
std DABS                NONE    double_ws       dpans8.htm      8.6.1.1160
std DMAX                NONE    double_ws       dpans8.htm      8.6.1.1210
std DMIN                NONE    double_ws       dpans8.htm      8.6.1.1220
std DNEGATE             NONE    double_ws       dpans8.htm      8.6.1.1230
std M*/                 NONE    double_ws       dpans8.htm      8.6.1.1820
std M+                  NONE    double_ws       dpans8.htm      8.6.1.1830
std 2ROT                NONE    double_ws       dpans8.htm      8.6.2.0420
std DU<                 NONE    double_ws       dpans8.htm      8.6.2.1270
std CATCH               NONE    exception_ws    dpans9.htm      9.6.1.0875
std THROW               NONE    exception_ws    dpans9.htm      9.6.1.2275
std AT-XY               NONE    facilities_ws   dpans10.htm     10.6.1.0742
std KEY?                NONE    facilities_ws   dpans10.htm     10.6.1.1755
std PAGE                NONE    facilities_ws   dpans10.htm     10.6.1.2005
std EKEY                NONE    facilities_ws   dpans10.htm     10.6.2.1305
std EKEY<CHAR           NONE    facilities_ws   dpans10.htm     10.6.2.1306
std EKEY?               NONE    facilities_ws   dpans10.htm     10.6.2.1307
std EMIT?               NONE    facilities_ws   dpans10.htm     10.6.2.1325
std MS                  NONE    facilities_ws   dpans10.htm     10.6.2.1905
std TIME&DATE           NONE    facilities_ws   dpans10.htm     10.6.2.2292
std BIN                 NONE    file_ws         dpans11.htm     11.6.1.0765
std CLOSE-FILE          NONE    file_ws         dpans11.htm     11.6.1.0900
std CREATE-FILE         NONE    file_ws         dpans11.htm     11.6.1.1010
std DELETE-FILE         NONE    file_ws         dpans11.htm     11.6.1.1190
std FILE-POSITION       NONE    file_ws         dpans11.htm     11.6.1.1520
std FILE-SIZE           NONE    file_ws         dpans11.htm     11.6.1.1522
std INCLUDE-FILE        NONE    file_ws         dpans11.htm     11.6.1.1717
std OPEN-FILE           NONE    file_ws         dpans11.htm     11.6.1.1970
std R/O                 NONE    file_ws         dpans11.htm     11.6.1.2054
std R/W                 NONE    file_ws         dpans11.htm     11.6.1.2056
std READ-FILE           NONE    file_ws         dpans11.htm     11.6.1.2080
std READ-LINE           NONE    file_ws         dpans11.htm     11.6.1.2090
std REPOSITION-FILE     NONE    file_ws         dpans11.htm     11.6.1.2142
std RESIZE-FILE         NONE    file_ws         dpans11.htm     11.6.1.2147
std W/O                 NONE    file_ws         dpans11.htm     11.6.1.2425
std WRITE-FILE          NONE    file_ws         dpans11.htm     11.6.1.2480
std WRITE-LINE          NONE    file_ws         dpans11.htm     11.6.1.2485
std FILE-STATUS         NONE    file_ws         dpans11.htm     11.6.2.1524
std FLUSH-FILE          NONE    file_ws         dpans11.htm     11.6.2.1560
std RENAME-FILE         NONE    file_ws         dpans11.htm     11.6.2.2130
std >FLOAT              NONE    fp_ws           dpans12.htm     12.6.1.0558
std D>F                 NONE    fp_ws           dpans12.htm     12.6.1.1130
std F!                  NONE    fp_ws           dpans12.htm     12.6.1.1400
std F*                  NONE    fp_ws           dpans12.htm     12.6.1.1410
std F+                  NONE    fp_ws           dpans12.htm     12.6.1.1420
std F-                  NONE    fp_ws           dpans12.htm     12.6.1.1425
std F/                  NONE    fp_ws           dpans12.htm     12.6.1.1430
std F0<                 NONE    fp_ws           dpans12.htm     12.6.1.1440
std F0=                 NONE    fp_ws           dpans12.htm     12.6.1.1450
std F<                  NONE    fp_ws           dpans12.htm     12.6.1.1460
std F>D                 NONE    fp_ws           dpans12.htm     12.6.1.1460
std F@                  NONE    fp_ws           dpans12.htm     12.6.1.1472
std FALIGN              NONE    fp_ws           dpans12.htm     12.6.1.1479
std FALIGNED            NONE    fp_ws           dpans12.htm     12.6.1.1483
std FDEPTH              NONE    fp_ws           dpans12.htm     12.6.1.1497
std FDROP               NONE    fp_ws           dpans12.htm     12.6.1.1500
std FDUP                NONE    fp_ws           dpans12.htm     12.6.1.1510
std FLITERAL            NONE    fp_ws           dpans12.htm     12.6.1.1552
std FLOAT+              NONE    fp_ws           dpans12.htm     12.6.1.1555
std FLOATS              NONE    fp_ws           dpans12.htm     12.6.1.1556
std FLOOR               NONE    fp_ws           dpans12.htm     12.6.1.1558
std FMAX                NONE    fp_ws           dpans12.htm     12.6.1.1562
std FMIN                NONE    fp_ws           dpans12.htm     12.6.1.1565
std FNEGATE             NONE    fp_ws           dpans12.htm     12.6.1.1567
std FOVER               NONE    fp_ws           dpans12.htm     12.6.1.1600
std FROT                NONE    fp_ws           dpans12.htm     12.6.1.1610
std FROUND              NONE    fp_ws           dpans12.htm     12.6.1.1612
std FSWAP               NONE    fp_ws           dpans12.htm     12.6.1.1620
std REPRESENT           NONE    fp_ws           dpans12.htm     12.6.1.2143
std DF!                 NONE    fp_ws           dpans12.htm     12.6.2.1203
std DF@                 NONE    fp_ws           dpans12.htm     12.6.2.1204
std DFALIGN             NONE    fp_ws           dpans12.htm     12.6.2.1205
std DFALIGNED           NONE    fp_ws           dpans12.htm     12.6.2.1207
std DFLOAT+             NONE    fp_ws           dpans12.htm     12.6.2.1208
std DFLOATS             NONE    fp_ws           dpans12.htm     12.6.2.1209
std F**                 NONE    fp_ws           dpans12.htm     12.6.2.1415
std F.                  NONE    fp_ws           dpans12.htm     12.6.2.1427
std FABS                NONE    fp_ws           dpans12.htm     12.6.2.1474
std FACOS               NONE    fp_ws           dpans12.htm     12.6.2.1476
std FACOSH              NONE    fp_ws           dpans12.htm     12.6.2.1477
std FALOG               NONE    fp_ws           dpans12.htm     12.6.2.1484
std FASIN               NONE    fp_ws           dpans12.htm     12.6.2.1486
std FASINH              NONE    fp_ws           dpans12.htm     12.6.2.1487
std FATAN               NONE    fp_ws           dpans12.htm     12.6.2.1488
std FATAN2              NONE    fp_ws           dpans12.htm     12.6.2.1489
std FATANH              NONE    fp_ws           dpans12.htm     12.6.2.1491
std FCOS                NONE    fp_ws           dpans12.htm     12.6.2.1493
std FCOSH               NONE    fp_ws           dpans12.htm     12.6.2.1494
std FE.                 NONE    fp_ws           dpans12.htm     12.6.2.1513
std FEXP                NONE    fp_ws           dpans12.htm     12.6.2.1515
std FEXPM1              NONE    fp_ws           dpans12.htm     12.6.2.1516
std FLN                 NONE    fp_ws           dpans12.htm     12.6.2.1553
std FLNP1               NONE    fp_ws           dpans12.htm     12.6.2.1554
std FLOG                NONE    fp_ws           dpans12.htm     12.6.2.1557
std FS.                 NONE    fp_ws           dpans12.htm     12.6.2.1613
std FSIN                NONE    fp_ws           dpans12.htm     12.6.2.1614
std FSINCOS             NONE    fp_ws           dpans12.htm     12.6.2.1616
std FSINH               NONE    fp_ws           dpans12.htm     12.6.2.1617
std FSQRT               NONE    fp_ws           dpans12.htm     12.6.2.1618
std FTAN                NONE    fp_ws           dpans12.htm     12.6.2.1625
std FTANH               NONE    fp_ws           dpans12.htm     12.6.2.1626
std F~                  NONE    fp_ws           dpans12.htm     12.6.2.1640
std PRECISION           NONE    fp_ws           dpans12.htm     12.6.2.2035
std SET-PRECISION       NONE    fp_ws           dpans12.htm     12.6.2.2200
std SF!                 NONE    fp_ws           dpans12.htm     12.6.2.2202
std SF@                 NONE    fp_ws           dpans12.htm     12.6.2.2203
std SFALIGN             NONE    fp_ws           dpans12.htm     12.6.2.2204
std SFALIGNED           NONE    fp_ws           dpans12.htm     12.6.2.2206
std SFLOAT+             NONE    fp_ws           dpans12.htm     12.6.2.2207
std SFLOATS             NONE    fp_ws           dpans12.htm     12.6.2.2208
std (LOCAL)             NONE    local_ws        dpans13.htm     13.6.1.0086
std LOCALS|             NONE    local_ws        dpans13.htm     13.6.2.1795
std ALLOCATE            NONE    malloc_ws       dpans14.htm     14.6.1.0707
std FREE                NONE    malloc_ws       dpans14.htm     14.6.1.1605
std RESIZE              NONE    malloc_ws       dpans14.htm     14.6.1.2145
std .S                  NONE    progtools_ws    dpans15.htm     15.6.1.0220
std ?                   NONE    progtools_ws    dpans15.htm     15.6.1.0600
std DUMP                NONE    progtools_ws    dpans15.htm     15.6.1.1280
std SEE                 NONE    progtools_ws    dpans15.htm     15.6.1.2194
std WORDS               NONE    progtools_ws    dpans15.htm     15.6.1.2465
std AHEAD               NONE    progtools_ws    dpans15.htm     15.6.2.0702
std ASSEMBLER           NONE    progtools_ws    dpans15.htm     15.6.2.0740
std BYE                 NONE    progtools_ws    dpans15.htm     15.6.2.0830
std CS-PICK             NONE    progtools_ws    dpans15.htm     15.6.2.1015
std CS-ROLL             NONE    progtools_ws    dpans15.htm     15.6.2.1020
std EDITOR              NONE    progtools_ws    dpans15.htm     15.6.2.1300
std FORGET              NONE    progtools_ws    dpans15.htm     15.6.2.1580
std [ELSE]              NONE    progtools_ws    dpans15.htm     15.6.2.2531
std [THEN]              NONE    progtools_ws    dpans15.htm     15.6.2.2533
std DEFINITIONS         NONE    searchord_ws    dpans16.htm     16.6.1.1180
std FORTH-WORDLIST      NONE    searchord_ws    dpans16.htm     16.6.1.1595
std GET-CURRENT         NONE    searchord_ws    dpans16.htm     16.6.1.1643
std GET-ORDER           NONE    searchord_ws    dpans16.htm     16.6.1.1647
std SEARCH-WORDLIST     NONE    searchord_ws    dpans16.htm     16.6.1.2192
std SET-CURRENT         NONE    searchord_ws    dpans16.htm     16.6.1.2195
std SET-ORDER           NONE    searchord_ws    dpans16.htm     16.6.1.2197
std WORDLIST            NONE    searchord_ws    dpans16.htm     16.6.1.2460
std ALSO                NONE    searchord_ws    dpans16.htm     16.6.2.0715
std FORTH               NONE    searchord_ws    dpans16.htm     16.6.2.1590
std ONLY                NONE    searchord_ws    dpans16.htm     16.6.2.1965
std ORDER               NONE    searchord_ws    dpans16.htm     16.6.2.1985
std PREVIOUS            NONE    searchord_ws    dpans16.htm     16.6.2.2037
std -TRAILING           NONE    string_ws       dpans17.htm     17.6.1.0170
std /STRING             NONE    string_ws       dpans17.htm     17.6.1.0245
std BLANK               NONE    string_ws       dpans17.htm     17.6.1.0780
std CMOVE               NONE    string_ws       dpans17.htm     17.6.1.0910
std CMOVE>              NONE    string_ws       dpans17.htm     17.6.1.0920
std COMPARE             NONE    string_ws       dpans17.htm     17.6.1.0935
std SEARCH              NONE    string_ws       dpans17.htm     17.6.1.2191
std SLITERAL            NONE    string_ws       dpans17.htm     17.6.1.2212



