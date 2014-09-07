;======================================;
; Asimov Hackathon Example Set         ;
; Example 3 - Show off Inheritence     ;
;======================================;

[extern puts]

%class [Pet] : [ASObject]   ; Pets!
; Related Data
.poopString: db "I pooped",10, 0
.eatString: db "omnomnom",10, 0
.sleepString: db "zZzZzZz",10, 0
%functions
    eat
    poop
    sleep
%variables
    name
    weight
%endclass

%class [Dog] : [Pet]        ; Woof!
; Related Data
.barkString: db "Bark",10, 0
.growlString: db "Grrrrr",10, 0
%functions
    bark
    growl
%variables
%endclass

%class [Cat] : [Pet]        ; Kitty!
.purrString: db "Purrr",10, 0
.meowString: db "Meow",10, 0
%functions
    purr
    meow
%variables
%endclass

CommonCall:
    push esi    ; push string
    call puts   ; Call Puts
    pop esi     ; pop string to fix stack
    ret         ; Return

Cat.purr:
    mov esi, Cat.purrString
    jmp CommonCall

Cat.meow:
    mov esi, Cat.meowString
    jmp CommonCall

Dog.bark:
    mov esi, Dog.barkString
    jmp CommonCall
Dog.growl:
    mov esi, Dog.growlString
    jmp CommonCall

Pet.sleep:
    mov esi, Pet.sleepString
    jmp CommonCall
Pet.poop
    mov esi, Pet.poopString
    jmp CommonCall
Pet.eat
    mov esi, Pet.eatString
    jmp CommonCall

;========[ Start ]=======;
Snowball:   dq ?
Rocky:      dq ?

[Global start]
start:
    new Rocky, Dog      ; Rocky is born
    new Snowball, Cat   ; Snowball is a little kitty
    mov ebp, Snowball   ; we're gonna tell snowball to do things
    ccr meow            ; Snowball meow
    ccr sleep           ; Snowball sleep
    ccr poop            ; Snowball poop 
    mov ebp, Rocky      ; Set up rocky
    ccr bark            ; Rocky Bark
    ccr sleep           ; Rocky Sleep
    ccr eat             ; Rocky Eat
    del Rocky           ; Clean Up!
    del Snowball        ;
    ret                 ; All done!

