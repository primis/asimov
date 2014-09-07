
%class [ASTest] : [ASObject]
%functions
shout
kill
whisper
init
%variables
runtime
patience
%endclass

ASTest.shout:
lor eax, runtime
inc eax
str runtime, eax

AsmTester: dq ?
start:
new AsmTester, ASTest
ret
