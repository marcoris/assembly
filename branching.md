[< Back](README.md)

## Flow Control in Assembly
With the exception of JMP, all of the assembly we have seen so far has been completely linear: the processor reads a 
byte from the next memory address and processes it, moving from the start of our ROM file to the end. Flow control 
refers to the ability to write code that can evaluate certain conditions and change which code will be executed next 
based on the result. For the 6502, there are two forms of flow control. JMP is an "unconditional" jump to a different 
point in the ROM (it does not perform any kind of test or evaluation). The other form of flow control is called 
"branching", because it performs a test and then moves to one of two different "branches" of code based on the result.

## The Processor Status Register
The key to branching is a part of the 6502 called the processor status register, often referred to as `P`. The status 
register, like all other 6502 registers, is eight bits in size. Unlike the other registers, the status register is 
not directly accessible to the programmer. Each time the processor performs an operation, the status register changes 
to reflect the results of that operation. Each bit in the status register gives information about a particular aspect 
of the last operation.

![img_11.png](img_11.png)

For our purposes, the two most important bits (or "flags") of the processor status register are the Z ("zero") and C 
("carry") bits. The zero flag is set (1) if the result of the last operation was zero. The zero flag is cleared (0) 
if the result of the last operation was anything but zero. Similarly, the carry flag is set if the result of the last
operation caused a "carry", and cleared otherwise.

## Carrying
While the zero flag is straightforward, the carry flag requires some additional explanation. Consider what happens when 
we add the decimal numbers 13 and 29. If we were to perform this addition by hand, we would first add the "3" from 13 to
the "9" from 29. The result is 12, which is too large to fit into a single decimal digit. So, we write down a "2" and 
carry over the "1" into the next column to the left. Here, we add together the "1" from 13, the "2" from 29, and the "1"
that we carried over. The result is 4, which we write down under that column, for a total of 42.

The carry flag on the 6502 performs the same function, but for bytes. An addition operation will result in the carry 
flag being set if the result of the addition is larger than what can fit in one byte (i.e. if the result is greater 
than 255). We will generally use an opcode that force-clears the carry flag before performing an addition, to avoid 
having a carry set by a previous operation persist to the current addition.

Subtraction works similarly to addition, except that we will generally set the carry flag before performing a 
subtraction. A subtraction operation results in the carry flag being cleared if the number being subtracted is larger 
than the number it is being subtracted from. As an example, if we subtract 17 from 15, the result is -2. This number is 
less than zero, so in order to carry out the subtraction we need to "borrow" from the next-lowest column, using up the 
carry flag that we set before starting the subtraction.

It is important to note here that much like single-digit decimal numbers, bytes "wrap around" when adding beyond 255 or 
subtracting beyond zero. If a byte (or register, or memory value) is currently at 253 and you add 7, the result is not 
260 — it is 4, with the carry flag set. Similarly, if a byte's value is 4 and you subtract 7, the result is 253 with a 
cleared carry flag, not -3.

We will cover how to actually perform addition and subtraction in a later chapter; for now, all you need to know is that
the instructions the processor executes will change the values of the zero and carry flags in the processor status 
register.

## Branching
Now that you know about the processor status register, we can use the results of operations to branch to different parts
of our code. The simplest way to use branching is to build a loop that does something 256 times. In its most basic form,
it looks like this:

````asm
LDX #$00
LoopStart:
    ; do something
    INX
    BNE LoopStart
    ; end of loop
````

The loop begins by loading the immediate value ``$00`` into the X register. Next, we have a label (``LoopStart``), which 
will be used by our branching instruction at the end of the loop. After the label, we do whatever it is that we want our
loop to perform, then we increment the X register. Like all math-related operations, this will update the flags in the 
processor status register. The final line of the loop checks the value of the zero flag. If the zero flag is set, 
nothing special happens — the program just keeps on running, with whatever comes after ``; end of loop`` being executed 
next. If the zero flag is cleared, then ``BNE LoopStart`` tells the processor to find the ``LoopStart`` label and 
execute whatever is located there next instead — in other words, running the next iteration of the loop.

In actual operation, this loop will run 256 times. On the first iteration of the loop, the value of the X register is 
zero. After ``INX``, the value of the X register is one. Since the result of ``INX`` was not a zero, the zero flag will 
be cleared. When we get to ``BNE LoopStart``, because the zero flag is cleared, the processor will go back to the 
``LoopStart`` label and run through the loop again. This time, the X register will become two, which is still not zero, 
and the loop will run again. Eventually, the X register's value will be 255. When we run ``INX`` this time, the X 
register will "roll over" to zero, and the carry flag will be set. Now that the last operation resulted in a zero, 
``BNE LoopStart`` will no longer be triggered, and the processor will continue on to whatever comes after the loop.

## A Review of Looping/Branching Opcodes
We've already seen ``INX`` and ``BNE``, but these are only two of the opcodes that you are likely to use for creating 
loops. Let's look at the ten new opcodes that you should add to your toolset.

### Incrementing and Decrementing Opcodes
These opcodes allow you to add or subtract by one in a single opcode. There is no need to explicitly set or clear the 
carry flag before using one of these opcodes.

``INX`` and ``INY`` will add one to ("increment") the X or Y register, respectively. In the opposite direction, ``DEX`` 
and ``DEY`` will subtract one from ("decrement") the X or Y register. Finally, you can use ``INC`` and ``DEC`` to 
increment or decrement the contents of a memory address. As an example, you could use ``INC $05`` to add one to whatever
is stored at memory address ``$05``, and store the result back in ``$05``.

All of the increment/decrement opcodes will update the values of the zero and carry flags of the processor status 
register.

### Branching Opcodes
There are branching opcodes for each flag of the processor status register. Each flag has two opcodes - one that 
branches if the flag is set, and one that branches if the flag is cleared. For our purposes, the only branching 
opcodes you will need to use check the values of the zero and carry flags.

``BEQ`` ("Branch if Equals zero") and ``BNE`` ("Branch if Not Equals zero") will change the flow of the program if the 
zero flag is set or cleared, respectively. ``BCS`` ("Branch if Carry Set") and ``BCC`` ("Branch if Carry Cleared") do 
the same for the carry flag. What follows each opcode should generally be a label for what code should be executed next 
if the branching opcode's conditions are met.

## Another Branching Example
This time, our loop will run eight times instead of 256.

````asm
LDY #$08
LoopTwo:
    ; do something
    DEY
    BNE LoopTwo
    ; end of loop
````

As in the previous loop example, here we first set up the pre-conditions of our loop by setting the Y register to 
``$08``. Then we have the label that our branching opcode will use later. After we've done whatever it is that we want 
our loop to do on each iteration, we decrement the Y register and then branch back to the start of the loop if the zero
flag is cleared.

## Making Comparisons
While the loops we have seen so far are useful, they require some careful setup. The loops above rely on our loop 
counter becoming zero in order to end the loop. To make more flexible and powerful loops, we need the ability to 
make arbitrary comparisons. In 6502 assembly, the opcodes that let us do that are ``CMP``, "Compare (with accumulator)",
``CPX``, "Compare with X register", and ``CPY``, "Compare with Y register".

Each of these opcodes works by performing a subtraction, setting the zero and carry flags as appropriate, and then 
discarding the result of the subtraction. Remember that when we perform a subtraction, we first set the carry flag. 
This means that we have three possible outcomes from a comparison, based on the register value and the value we are 
comparing it to:

1. Register is larger than comparison value: Carry flag set, zero flag clear 
2. Register is equal to comparison value: Carry flag set, zero flag set 
3. Register is smaller than comparison value: Carry flag clear, zero flag clear

We can use this information to create more complicated program logic. Consider the case where we load a value from 
memory and then check whether it is greater than, equal to, or less than ``$80``.

````asm
LDA $06
    CMP #$80
    BEQ reg_was_80
    BCS reg_gt_80
    ; neither branch taken; register less than $80
    ; do something here
    JMP done_with_comparison ; jump to skip branch-specific code
reg_was_80:
    ; register equalled $80
    ; do something here
    JMP done_with_comparison ; skip the following branch
reg_gt_80:
    ; register was greater than $80
    ; do something here
    ; no need to jump because done_With_comparison is next
done_with_comparison:
    ; continue with rest of the program
````

This kind of three-way branch is fairly common. Note the presence of a label to mark the end of all branch code, so that
earlier code can ``JMP`` over branch-specific code that shouldn't be executed if the branch was not taken.

## Using Comparisons in Loops
Here is a loop that runs eight times, but counts up from zero instead of counting down from eight.

````asm
LDX #$00
loop_start:
    ; do something
    INX
    CPX #$08
    BNE loop_start
    ; loop is finished here
````

Here, we set the X register to zero before starting our loop. After each loop iteration, we increment the X register and
then compare X to ``$08``. If the X register does not equal eight, the zero flag will not be set, and we will go back to
``loop_start``. Otherwise, the ``CPX`` will set the zero flag (because eight minus eight equals zero), and the loop will
be finished.