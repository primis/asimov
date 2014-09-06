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
mov ecx, 0              ; make count 0
.loop:                  ; loopback
lodsb                   ; esi -> eax
inc ecx                 ; increment count
cmp al, 0               ; compare to null terminator
jne .loop               ; jump back to loop
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
