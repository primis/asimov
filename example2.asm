; Create an object that says "Hello World!"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HelloObject: dq ?                          ; 
hello: db 'Hello, World. This is Asimov', 0; Hello String
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[extern puts]

%class [HelloSayer] : [ASObject]
%functions
init
say_hello
%variables
%endclass

HelloSayer.init:
ret ; no init

HelloSayer.say_hello:
mov esi, hello      ; get string
push esi            ; push to stack for C
call puts           ; Call putString
pop esi             ; fix stack
ret                 ; return

;==========[ Start ]============;
[Global start]                  ; Let runtime know where start is
start:                          ;
    new HelloObject, HelloSayer ; Allocate an instance of HelloSayer
    mov ebp, [HelloObject]      ; Set up object for use
    ccr say_hello               ; Tell the object to say hello!
    del HelloObject             ; Deallocate Object
    ret                         ; All Done!
;===============================;
