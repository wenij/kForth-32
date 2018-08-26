\ serial-comm.4th
\
\ Module for serial port communication functions.
\

Module: serial-comm

ALSO serial  \ depends on module serial

Begin-Module

variable com			
create buf 64 allot

Public:

struct
   int:   port
   int:   baud
   4 buf: params
end-struct serial-config%

create config serial-config% %allot drop

\ Default values for comm port configuration
COM1    config port !
B9600   config baud !
s" 8N1" config params swap move

\ Open and configure the comm port
\ port baud ^str_param
: open ( aconfig -- )
	dup port @ ∋ serial open com !
	dup params com @ swap ∋ serial set-params
	    baud @ com @ swap ∋ serial set-baud
;

\ Get available byte from the comm port
: get ( -- c )  com @ buf 1 ∋ serial read drop buf c@ ;

\ Put a byte to the comm port
: put ( c -- ) buf c! com @ buf 1 ∋ serial write drop ;

\ Length of receive queue
: Rx-len ( -- u )  com @ ∋ serial lenrx ;

\ Write a byte stream to the comm port
: write ( a u -- )  com @ -rot ∋ serial write drop ;

\ Close the comm port
: close ( -- )  com @ ∋ serial close drop ;

End-Module

