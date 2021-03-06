;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Asimov Runtime. 2014 Primis          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Runtime that allows objects to       ;
; actually run.                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definitions                                                   ;
%define CLASS_HEADER db 'BEGIN_CLASS',   0xDE,0xAD,0xBE,0xEF, 0 ; Class Header
%define FUNC_HEADER db 'BEGIN_FUNCTIONS',0xDE,0xAD,0xBE,0xEF, 0 ; Functions
%define VAR_HEADER db 'BEGIN_VARIABLES', 0xDE,0xAD,0xBE,0xEF, 0 ; Variables
%define CLASS_FOOTER db 'END_CLASS',     0xDE,0xAD,0xBE,0xEF, 0 ; Class
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;
Class_Header:                          ;
    db 'BEGIN_CLASS'                   ;
    db 0xDE,0xAD,0xBE,0xEF,0           ; Magic!
Function_Header:                       ; Where Functions are
    db 'BEGIN_FUNCTIONS'               ; Functions start here
    db 0xDE,0xAD,0xBE,0xEF,0           ; Magic numbers help identify
Variable_Header:                       ; Where Variables are
    db 'BEGIN_VARIABLES'               ; :/
    db 0xDE, 0xAD,0xBE,0xEF,0          ; :)
Class_Footer:                          ; End of Class
    db 'END_CLASS'                     ; :D
    db 0xDE,0xAD,0xBE,0xEF,0           ; Magic variable
INIT_LABEL:                            ;
    db 'init',0                        ; Init!
DeInit:                                ;
    db 'uninit',0                      ; Disassemble an object
;--------------------------------------;
       
[global _call_class_routine]
[global _find_variable]
[global _set_variable]
[extern malloc]
[extern free]
[global main]
[extern start]


;-----[ Entry Point ]---;
main:                   ; C Runtime requires a main
call start              ; Call The start of the program
ret                     ; Return to OS
;=======================;


;-----[ strcmp ]--------;
strcmp:                 ; Compare Two Strings.
push esi                ; Source String
push edi                ; String To compare against
push eax                ; Scrap register
dec edi                 ; Loop has to take into account the null pointer
.loop:                  ; Loop label
inc edi                 ; Increment edi 
lodsb                   ; Load al with the next char from string 1
cmp [edi], al           ; Compare the two charecters.
jne .NotEqual           ; if not the same, quit early.
cmp al, 0               ; End of string?
jne .loop               ; if not, repeat until we hit end.
cmp al, al              ; Set zero flag, They're the same
pop eax                 ; pop eax
pop edi                 ; pop strings
pop esi                 ;
ret                     ; Return!
.NotEqual:              ; Strings not equal?
mov ah, 6               ; Random number, Determined by fair die roll
cmp ah, 1               ; Garunteed to never equal
pop eax                 ; pop
pop edi                 ; 
pop esi                 ; 
ret                     ; return
;-----------------------;

;-----[ strlen ]--------;
strlen:                 ; String Length
push esi                ; save esi
push eax                ; save eax
mov ecx, 0              ; make count 0
.loop:                  ; loopback
lodsb                   ; esi -> eax
inc ecx                 ; increment count
cmp al, 0               ; compare to null terminator
jne .loop               ; jump back to loop
pop eax                 ; restore eax
pop esi                 ; restore esi
ret                     ; return
;-----------------------;

;---[ memcpy ]----------; 
memcpy:                ; copy specified amount of bytes from esi to edi
pusha                   ; Store all registers. We use quite a few
.loop:                  ; loop until out of bytes
lodsb                   ; esi -> al
stosb                   ; al  -> edi
loop .loop              ; loop
popa                    ; restore
ret                     ; return
;-----------------------;

;-----[ ccr ]-----------;
; esi = Function name   ;
; ebp = Object          ;
;-----------------------;
_call_class_routine:    ;
mov eax, esi            ; Move function name for later
mov esi, [ebp]          ; Get Class pointer from object
.retry:                 ; For parent checking
mov edi, Class_Header   ; Check Class header
call strcmp             ; Call String Compare to check
jne .error              ; Uhoh!
call strlen             ; Get length of object name
add esi, ecx            ; Add string length.
mov edx, [esi]          ; Pointer for parent, Save for later
add esi, 4              ; Get to the Function Header.
mov edi, Function_Header; Function header. For sanity.
call strcmp             ; Check to see if we have functions here.
jne .parent             ; Go To parent class to check
call strlen             ; Length of header %OPTIMIZE%: Manually Write this in
add esi, ecx            ; Skip that and go to functions!
mov edi, eax            ; Function Name
;;;;;;;;;;;;;;;;;;;;;;;;;
mov ebx, Variable_Header; Move Var Header into ebx for testing
.loop:                  ; Loop through the functions till we hit something
xchg ebx, edi           ; swap real quick
call strcmp             ; Make sure this isnt the last function.
je .parent              ; That was the last function, check parent.
xchg ebx, edi           ; swap back
call strcmp             ; Do the function names match?
je .done                ; YAY! :D
call strlen             ; Stringlen of name we skipped
add esi, ecx            ; add that to source
add esi, 4              ; skip pointer
jmp .loop               ; Go back up to top of loop 
;;;;;;;;;;;;;;;;;;;;;;;;;
.error:                 ; Deal with an error
ret                     ; %TODO% implement error catching
;;;;;;;;;;;;;;;;;;;;;;;;;
.parent:                ; Go to parent Class
cmp edx, 0              ; Make sure that it's not an orphan class
je .error               ; Well Shit.
mov esi, [edx]          ; Move parent into source
jmp .retry              ; all set to try again
;;;;;;;;;;;;;;;;;;;;;;;;;
.done:                  ; Holy shit! it worked! :D
call strlen             ; Get length of name
add esi, ecx            ; Get to pointer
call [esi]              ; Call function!
ret                     ; All Done, return
;-----------------------;


[global _find_variable]
;-------[ LOR ]---------;
; esi - Variable name   ;
; ebp - Object Location ;
;-----------------------;
_find_variable:         ; Find a variable
mov eax, esi            ; Save Variable name
mov ebp, esi            ; Store object in esi
.retry:                 ; Loopback recurse
add esi, 4              ; Skip class pointer
mov edx, [esi]          ; add parent to edx for later
add esi, 4              ; Skip that now.
mov edi, Variable_Header; look for Variable header
call strcmp             ; This *should* be right after pointer
jne .error              ; Somthing went wrong, error out.
call strlen             ; get length of string
add esi, ecx            ; offset source to after string.
mov edi, eax            ; restore variable name
mov ebx, Class_Footer   ; Know when to end.
.loop:                  ; Loop!
xchg ebx, edi           ; Swap in the footer
call strcmp             ; Check to see if we hit it
je .parent              ; If we did, go up to parent
xchg ebx, edi           ; Swap back
call strcmp             ; Did we hit the right variable?
je .done                ; YAY :D
call strlen             ; What's the length again?
add esi, ecx            ; add that to the source
add esi, 4              ; Skip Variable
jmp .loop               ; Try again
;;;;;;;;;;;;;;;;;;;;;;;;;
.error:                 ; Uhoh
ret                     ; %TODO% implement error handling
;;;;;;;;;;;;;;;;;;;;;;;;;
.parent:                ; Couldn't find variable here, look at parent
cmp edx, 0              ; Check to see if we're an orphan
je .error               ; If we are, the variable doesn't exist
mov esi, [edx]          ; move parent pointer into source
jmp .retry              ; Try again
;;;;;;;;;;;;;;;;;;;;;;;;;
.done:                  ; Found the variable name
call strlen             ; Add length!
add esi, ecx            ; This is fun! (ha.)
mov eax, [esi]          ; Move the value of the register into eax
mov ebx, esp            ; Get stack pointer
add ebx, 40             ; 8 GPR's + Call to this function
mov [ebx], eax          ; Store eax in the stack.
ret                     ; Cave Johnson, We're Done here.
;-----------------------;


[global _store_variable]
;-------[ STR ]---------;
; esi - Variable name   ;
; ebp - Object Location ;
;-----------------------;
_store_variable:        ; Store a variable
mov eax, esi            ; Save Variable name
mov ebp, esi            ; Store object in esi
.retry:                 ; Loopback recurse
add esi, 4              ; Skip class pointer
mov edx, [esi]          ; Put parent in edx for later
add esi, 4              ; Skip Parent
mov edi, Variable_Header; look for Variable header
call strcmp             ; This *should* be right after pointer
jne .error              ; Somthing went wrong, error out.
call strlen             ; get length of string
add esi, ecx            ; offset source to after string.
mov edi, eax            ; restore variable name
mov ebx, Class_Footer   ; Know when to end.
.loop:                  ; Loop!
xchg ebx, edi           ; Swap in the footer
call strcmp             ; Check to see if we hit it
je .parent              ; If we did, go up to parent
xchg ebx, edi           ; Swap back
call strcmp             ; Did we hit the right variable?
je .done                ; YAY :D
call strlen             ; What's the length again?
add esi, ecx            ; add that to the source
add esi, 4              ; Skip Variable
jmp .loop               ; Try again
;;;;;;;;;;;;;;;;;;;;;;;;;
.error:                 ; Uhoh
ret                     ; %TODO% implement error handling
;;;;;;;;;;;;;;;;;;;;;;;;;
.parent:                ; Couldn't find variable here, look at parent
cmp edx, 0              ; Check to see if we're an orphan
je .error               ; If we are, the variable doesn't exist
mov esi, [edx]          ; move parent pointer into source
jmp .retry              ; Try again
;;;;;;;;;;;;;;;;;;;;;;;;;
.done:                  ; We're Done!
call strlen             ; String Length for offset
add esi, ecx            ; add for actual datum
pop eax                 ; pop the value off stack
mov [esi], eax          ; store into the variable
ret                     ; Cave Johnson, We're done here.
;=======================;

;"Science isn't about WHY. It's about WHY NOT. Why is so much of our science 
; dangerous? Why not marry safe science if you love it so much. In fact, 
; why not invent a special safety door that won't hit you on the butt 
; on the way out, because you are fired."   

[global _new_object]
;-----[ New ]-----------;
; esi - Class           ;
; ebp - Object pointer  ;
;-----------------------;
_new_object:            ; Allocate Space for a new object, then initialize it.
pusha                   ; Save all Registers
mov ebx, esi            ; Save class for later 
mov eax, 0              ; Clear eax. We're gonna use it to store var count.
mov edi, Class_Header   ; Make sure that it's really a class.
call strcmp             ; Compare the two strings
jne .error              ; This isn't a Class definition, fail!
call strlen             ; Get length of header
add esi, ecx            ; Add that to source to skip to parent
mov edx, [esi]          ; Save Superclass for later. We're gonna need it.
add esi, 4              ; Move to the next section
mov edi, Variable_Header; We're gonna skip over the functions, we don't need em
;;;;;;;;;;;;;;;;;;;;;;;;;
.loopa:                 ; First loop, Skip to the variables by skipping over strings
call strlen             ; Get Lenght of string to null pointer.
add esi, ecx            ; Skip string
call strcmp             ; Check to see if we hit variables yet
jne .loopa              ; if not, keep going till we do
mov edi, Class_Footer   ; Class footer string so we know when we've hit the end.
;;;;;;;;;;;;;;;;;;;;;;;;;
.loopb:                 ; At this point we've hit variables, now we have to count how many we have
call strcmp             ; Compare to footer, if so, no variables
je .next                ; On to next step
call strlen             ; Get length of var name
add ecx, 4              ; Add on the var itself.
add esi, ecx            ; Move on to the next one
add eax, ecx            ; Add it to running count of bytes to allocate
jmp .loopb              ; Jump back to loop
;;;;;;;;;;;;;;;;;;;;;;;;;
.next:                  ; At this point, we've hit the object footer.
call strlen             ; Call String length on Class_Footer
add eax, ecx            ; Add Footer to length
add esi, ecx            ; Advance esi to account for this.
mov edi, Variable_Header; Need length
call strlen             ; :)
add eax, ecx            ; Add header to length to malloc
add eax, 8              ; Class Pointer & Parent Pointer
push eax                ; Push the amount of bytes to allocate for malloc
call malloc             ; Oh noes, C code! (There was really no other way)
mov [ebp], eax          ; Store the object proper.
mov ebp, eax            ; Move to pointed address
pop eax                 ; Restore count
mov [ebp], ebx          ; Store the class pointer
add ebp, 8              ; go to the next section
sub eax, 8              ; ok, 8 less bytes to memcopy.
sub esi, eax            ; Rewind source for copy
mov ecx, eax            ; Set up count
mov edi, ebp            ; put object in destination
call memcpy             ; Call Memory Copy over eax bytes
sub ebp, 4              ; Back up to where the parent pointer should be
cmp edx, 0              ; Check to see if we have a parent
je .done                ; All done! :D
mov esi, edx            ; Put parent in source register
call _new_object        ; Recurse!
jmp .donewithparent     ;
.done:
mov eax, 0              ;
mov [ebp], eax          ; No parent left
.donewithparent:        ;
sub ebp, 8              ; hop back up to top of object
mov esi, INIT_LABEL     ; Init label (Literally "init")
call _call_class_routine; Run the init
popa                    ; Restore Registers
ret                     ; Return
;;;;;;;;;;;;;;;;;;;;;;;;;
.error:                 ; uhoh
ret                     ; todo: errror handling
;-----------------------;


[global _delete_object]
;----[ Del ]------------;
; ebp - Object          ;
;-----------------------;
_delete_object:         ; Deallocates object
mov eax, ebp            ; make a copy
add eax, 4              ; Get to parent
mov esi, DeInit         ; DeInit Things
call _call_class_routine; Call UnInit
push ebp                ;
call free               ; Call Free
mov ebp, eax            ; store parent in base object register
mov ebx, [eax]
cmp ebx, 0            ; Are we an orphan?
je .done                ;
call _delete_object     ; recurse!
.done:                  ;
ret                     ; done here
;=======================;
