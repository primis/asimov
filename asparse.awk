#!/usr/bin/awk -f
BEGIN{
    state = 0;
}

/^%class/ {
    state = 1;
    parent = $4;
    name = $2;
    sub(/\[/,"",name);
    sub(/\]/,"",name);
    sub(/\[/,"",parent);
    sub(/\]/,"",parent);
    printf ";====CLASS HEADER====\n";
    printf "%s: CLASS_HEADER\n", name;
}
/^%endclass/ {
    printf ";=====END HEADER=====\n";
    printf "CLASS_FOOTER\n";
    state = 0;
}

/^%functions/ {
    state = 2;
    printf ";====FUNCTIONS====\n";
    printf "FUNC_HEADER\n";
}
/^%variables/ {
    state = 3;
    printf ";====VARIABLES====\n";
    printf "VAR_HEADER\n";
}



# Stateless Declarations

/^new/ {
    sub(/,/,"",$2);
    sub(/,/,"",$1);
    print "pusha";
    printf "mov esi, [%s]\n",$2;
    printf "mov ebp, %s\n", $1;
    print "call _new_object";
    print "popa";
}

/^del/ {
    sub(/,/,"",$1);
    print "pusha";
    printf "mov ebp, %s\n", $1;
    print "call _del_object";
    print "popa";
}

/^lor/ {
    sub(/,/,"",$2);
    sub(/,/,"",$1);
    print "push eax";
    print "pusha";
    printf "%%ifndef %s\n", $2;
    printf "%%define %s\n", $2;
    printf "%s: db '%s',0\n", $2, $2;
    printf "%%endif\n";
    printf "mov esi, %s\n",$2;
    print "call _find_variables";
    print "popa";
    printf "pop %s\n", $1;
}

/^str/ {
    sub(/,/,"",$2);
    sub(/,/,"",$1);
    print "pusha";
    printf "push %s\n",$2;
    printf "%%ifndef %s\n", $1;
    printf "%%define %s\n", $1;
    printf "%s: db '%s',0\n", $1, $1;
    printf "%%endif\n";
    printf "mov esi, %s\n", $1;
    print "call _save_variable";
    print "popa";
}
/^ccr/ {
    sub(/,/,"",$1);
    print "pusha";
    printf "%%ifndef %s\n", $1;
    printf "%%define %s\n", $1;
    printf "%s: dv '%s',0\n", $1;
    printf "%%endif\n";
    printf "mov esi, %s\n", $1;
    print "call _call_class_routine";
    print "popa";
}

# Extremely Stateful Declarations

!/^new|^del|^str|^lor|^ccr|^%endclass/{ 
    if(state==0) 
        print; 
    if(state==1) # Static Functions
        if($1 != "%class")
            printf "'%s',0,.%s\n",$1,$1;
    if(state==2)
        if ($1 != "%functions")
            printf "db '%s',0,.%s\n",$1,$1; # Functions
    if(state==3)
        if($1 != "%variables")
            printf "db '%s',0,1,1,1,1\n",$1; # Variables
}
