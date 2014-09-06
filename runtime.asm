;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Asimov Runtime. 2014 Primis          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Runtime that allows objects to       ;
; actually run.                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DATA                                 ;
Class_Header:                          ; Is this really a class?
    db 'BEGIN_CLASS',0xDEADBEEF,0      ; Magic!
Function_Header:                       ; Where Functions are
    db 'BEGIN_FUNCTIONS',0xDEADBEEF,0  ; Magic numbers help identify
Variable_Header:                       ; Where Variables are
    db 'BEGIN_VARIABLES',0xDEADBEEF,0  ;
Class_Footer:                          ; End of Class
    db 'END_CLASS',0xDEADBEEF,0        ; Magic variable
;--------------------------------------;
       
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
pop eax                 ; save eax
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
mov esi, edx            ; Pointer for parent, Save for later
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

;-------[ LOR ]---------;
; esi - Variable name   ;
; ebp - Object Location ;
;-----------------------;
_find_variable:         ; Find a variable
mov eax, esi            ; Save Variable name
mov ebp, esi            ; Store object in esi
.retry:                 ; Loopback recurse
add esi, 4              ; Skip class pointer
mov edx, [esi]          ;  
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



;"Science isn't about WHY. It's about WHY NOT. Why is so much of our science 
; dangerous? Why not marry safe science if you love it so much. In fact, 
; why not invent a special safety door that won't hit you on the butt 
; on the way out, because you are fired."   

                     
