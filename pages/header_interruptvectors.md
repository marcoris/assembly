[< Back](../README.md)

## Interrupt Vectors
The events that can cause these interruptions are called interrupt vectors, and the NES/6502 has three of them:
- The reset vector occurs when the system is first turned on, or when the user presses the Reset button on the front of the console.
- The NMI vector ("Non-Maskable Interrupt") occurs when the PPU starts preparing the next frame of graphics, 60 times per second.
- The IRQ vector ("Interrupt Request") can be triggered by the NES' sound processor or from certain types of cartridge hardware.

When an interrupt is triggered, the processor stops whatever it is doing and executes the code specified as the "handler" 
for that interrupt. A handler is just a collection of assembly code that ends with a new opcode: RTI, for "Return from
Interrupt". Since the test project doesn't need to make use of NMI or IRQ handlers, they consist of just RTI:

````6502 assembly
.proc irq_handler
    RTI
.endproc
	
.proc nmi_handler
    RTI
.endproc

````
RTI marks the end of an interrupt handler, but how does the processor know where the handler for a given interrupt begins?

## Memory address
The processor looks to the last **six** bytes of memory - addresses `$fffa` to `$ffff` - to find the memory address of where each
handler begins.

| Memory address  | Use                    |
|-----------------|------------------------|
| `$fffa - $fffb` | Start of NMI handler   |
| `$fffc - $fffd` | Start of reset handler |
| `$fffe - $ffff` | Start of IRQ handler   |

Because these six bytes of memory are so important, ca65 has a specific segment type for them: .segment "VECTORS". The 
most common way to use this segment is to give it a list of three labels, which ca65 will convert to addresses when 
assembling your code. Here is what our test project's "VECTORS" segment looks like:

````6502 assembly
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

````

.addr is a new assembler directive. Given a label, it outputs the memory address that corresponds to that label. So, 
these two lines of assembly set bytes $fffa to $ffff of memory to the addresses of the NMI handler, reset handler,
and IRQ handler - exactly the same order as in the table above. Each label on line 40 is the start of the .proc for 
that handler.

## The Reset Handler
While the test project doesn't make use of the NMI or IRQ events, it does need a reset handler. The reset handler's job
is to set up the system when it is first turned on, and to put it back to that just-turned-on state when the user hits 
the reset button. Here is the test project's reset handler:

````6502 assembly
.proc reset_handler
    SEI
    CLD
    LDX #$00
    STX $2000
    STX $2001
vblankwait:
    BIT $2002
    BPL vblankwait
    JMP main
.endproc

````

A few things to note about this section of code. **First**, unlike the other interrupt handlers, it does not end in RTI - 
that's because when the system is first turned on, the processor wasn't in the middle of doing anything else, so there 
is nowhere to "return" to. Instead, it ends with JMP main. The operand for JMP is a full, two-byte memory address, but 
it is nearly always used with a label that the assembler will convert to a memory address at assemble time. JMP main,
here, tells the processor to start executing the code in main once it is done with the reset handler.

There are two opcodes that are, generally, only found in reset handlers. SEI is "Set Interrupt ignore bit". After an SEI, anything 
that would trigger an IRQ event does nothing instead. Our reset handler calls SEI before doing anything else because we 
don't want our code to jump to the IRQ handler before it has finished initializing the system. CLD stands for "Clear 
Decimal mode bit", disabling "binary-coded decimal" mode on the 6502.

We've seen $2001 before - it's PPUMASK - but $2000 is new. This address is commonly referred to as PPUCTRL, and it 
changes the operation of the PPU in ways more complicated than PPUMASK's ability to turn rendering on or off.

For the purpose of initializing the NES, the main thing to point out is that bit 7 controls whether or not the PPU will
trigger an NMI every frame. By storing $00 to both PPUCTRL and PPUMASK, we turn off NMIs and disable rendering to the 
screen during startup, to ensure that we don't draw random garbage to the screen.

The remainder of the reset handler is a loop that waits for the PPU to fully boot up before moving on to our main code. 
The PPU takes about 30,000 CPU cycles to become stable from first powering on, so this code repeatedly fetches the PPU's
status from PPUSTATUS ($2002) until it reports that it is ready. NES' 2A03 processor runs at 1.78 MHz, so 30,000 cycles 
is a tiny, tiny fraction of a second.

Turning on screen:
````6502 assembly
; wait for another vblank before continuing
vblankwait:
    BIT PPUSTATUS
    BPL vblankwait

    LDA #%10010000  ; turn on NMIs, sprites use first pattern table
    STA PPUCTRL
    ;76543210
    ;|||||||+- Greyscale enable (0: normal color, 1: greyscale)
    ;||||||+-- Left edge (8px) background enable (0: hide, 1: show)
    ;|||||+--- Left edge (8px) foreground enable (0: hide, 1: show)
    ;||||+---- Background enable
    ;|||+----- Foreground enable
    ;||+------ Emphasize red
    ;|+------- Emphasize green
    ;+-------- Emphasize blue
    LDA #%00011110  ; turn on screen
    STA PPUMASK
    
````