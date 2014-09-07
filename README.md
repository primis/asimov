Asimov is a new object oriented language designed on top of x86 Assembly.
=========================================================================

This is a hack project for MHacks.

Greets to:
UB Hacking!
vLK
All The Organizers (We <3 you guys)
Class Creation:

%class [name] : Parent

.staticmember: member

%functions

functiona

functionb

%variables

variable1

variable2

%endclass

Syntax:
* new - create new object from class. Usage:
	new [object], class
* del - Deallocate object from memory. Usage:
	del [object]
* lor - Load register with a variable from an object where EDI = object pointer. Usage:
	lor eax, Variable
* str - Store register into a variable in an object where EDI = object pointer. Usage:
	str Variable, eax
* ccr - Call Class Routine. Run a routine that exists within a class where EDI = object pointer. Usage:
	ccr Function
