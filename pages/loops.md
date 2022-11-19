[< Back](../README.md)

## Indexed Mode
Indexed mode combines a fixed, absolute memory address with the variable contents of an index register (hence the name 
"index register"). To use indexed addressing mode, write a memory address, a comma, and then a register name.

````asm
LDA $8000,X
````

The example code above will fetch the contents of memory address (``$8000`` + the value of the X register). If the 
current value of the X register is ``$05``, then the command ``LDA $8000,X`` will fetch the contents of memory address
``$8005``.

Using indexed mode allows us to perform actions across a range of memory addresses with ease. As a simple example, here 
is a code snippet that will set the 256 bytes of memory from ``$3000`` to ``$30FF`` to ``$00``.

````asm
LDA #$00
    TAX
clear_zeropage:
    STA $3000,X
    INX
    BNE clear_zeropage
````

To review, line 1 above sets the accumulator to zero (``#$00``), and then line 2 copies that zero to the X register. 
Line 4 stores the zero from the accumulator to memory address (``$3000`` plus X register), which will be ``$3000`` the 
first time through the loop. Line 5 increments the X register, and then line 6 checks the status of the zero flag in the
processor status register. If the last operation was not equal to zero, we return to the label at line 3. When we 
increment the X register from zero to one, the result of the last operation is one, so the zero flag will not be set and
the loop will repeat again. The next time through the loop, when we reach line 4, the zero from the accumulator will be
stored again at memory address (``$3000`` plus X register), which will now be memory address ``$3001``. The loop will 
repeat until the X register is already ``$ff`` and the increment at line 5 changes the X register to ``$00``.

## Loading Palettes and Sprites
By using loops and indexed addressing, we can separate the palette and sprite data from the code that sends that data to
the PPU, making it easier to update the data without inadvertently breaking things.

Old code:

````asm
...
    ; write a palette
    LDX PPUSTATUS
    LDX #$3f
    STX PPUADDR
    LDX #$00
    STX PPUADDR
    LDA #$29
    STA PPUDATA
    LDA #$19
    STA PPUDATA
    LDA #$09
    STA PPUDATA
    LDA #$0f
    STA PPUDATA
...
````

Let's separate out the palette values and store them somewhere else. The palette values here are read-only data, so we 
will store them in the ``RODATA`` segment and not in the current CODE segment. It will look something like this:

````asm
.segment "RODATA"
palettes:
.byte $29, $19, $09, $0f
````

We set a label (``palettes``) to easily identify the start of our palette data, and then we use the ``.byte`` directive 
to tell the assembler "what follows is a series of plain data bytes, do not try to interpret them as opcodes".

Next, we will need to adjust our palette-writing code to loop over the data in ``RODATA``. We'll keep lines 21-26 above 
that set the PPU address to ``$3f00``, but starting at line 27, we'll make use of a loop:

New code:

````asm
...
load_palettes:
    LDA palettes,x
    STA PPUDATA
    INX
    CPX #$04
    BNE load_palettes
...
````

Instead of hard-coding each palette value, we load it as "the address of the ``palettes`` label plus the value of the X 
register". By incrementing the X register each time through the loop (``INX``), we can sequentially access all of the 
palette values.

Note that to end the loop, we are comparing against ``#$04``. This ensures that we will run this loop for four, and only
four, values. If we set the comparison operand to something larger, we could end up reading memory beyond what we 
intended as palette storage, which can have unpredictable effects.

Now that our palettes are loading in a cleaner fashion, let's turn our attention to sprite data. Just like with 
palettes, we can store our sprite data in ``RODATA`` and read it with a loop. The current sprite loading code looks like
this:

Old code:

````asm
...
    ; write sprite data
    LDA #$70
    STA $0200
    LDA #$05
    STA $0201
    LDA #$00
    STA $0202
    LDA #$80
    STA $0203
...
````

Following the same process as with the sprites, our new sprite loading code will look like this:

````asm
...
    ; write sprite data
    LDX #$00
load_sprites:
    LDA sprites,X
    STA $0200,X
    INX
    CPX #$04
    BNE load_sprites
...
````

This code is subtly different from the palette loading code. Note that on line 40, instead of writing to a fixed address
(``PPUDATA``), we use indexed mode to increment the address to write to as well as the address to read from.

One more step: we still need to move our sprite data into ``RODATA``. Here is our sprite data, in a much more readable, 
one-line-per-sprite format:

````asm
sprites:
.byte $70, $05, $00, $80
````