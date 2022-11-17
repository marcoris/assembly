[< Back](README.md)

## Constants
There are several places in our code where we use a particular number that doesn't change, such as MMIO addresses for
talking with the PPU. It's hard to tell what these numbers are referring to when looking at the code.

| Constants and its addresses |
|-----------------------------|
| PPUCTRL   = $2000           |
| PPUMASK   = $2001           |
| PPUSTATUS = $2002           |
| PPUADDR   = $2006           |
| PPUDATA   = $2007           |

## Constants File
We'll call the constants file `constants.inc`. Then, we include the constants file at the top of our .asm file like this:

````asm
.include "constants.inc"
````

## Header File
We can do the same thing with the .header segment, since it will generally be the same from project to project. Let's 
make a `header.inc` file to hold our header content.

````asm
.segment "HEADER"
.byte $4e, $45, $53, $1a ; Magic string that always begins an iNES header
.byte $02        ; Number of 16KB PRG-ROM banks
.byte $01        ; Number of 8KB CHR-ROM banks
.byte %00000001  ; Vertical mirroring, no save RAM, no mapper
.byte %00000000  ; No special-case flags set, no mapper
.byte $00        ; No PRG-RAM present
.byte $00        ; NTSC format
````

## ca65 Imports and Exports
A full reset handler can become quite large, so it can be useful to put it into a separate file.
But we can't just .include it, because we need a way to reference the reset handler in the VECTORS segment.
The solution is to use ca65's ability to import and export .proc code. We use the .export directive to inform the 
assembler that a certain proc should be available in other files, and the .import directive to use the proc somewhere 
else.
`reset.asm` including the .export directive:

````asm
.include "constants.inc"

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCTRL
    STX PPUMASK
vblankwait:
    BIT PPUSTATUS
    BPL vblankwait
    JMP main
.endproc
````

## Custom Linker Configuration
`ld65 helloworld.o -t nes -o helloworld.nes`

Our custom linker config will be in a file called nes.cfg, which will look like this:
````cfg
MEMORY {
  HEADER: start=$00, size=$10, fill=yes, fillval=$00;
  ZEROPAGE: start=$10, size=$ff;
  STACK: start=$0100, size=$0100;
  OAMBUFFER: start=$0200, size=$0100;
  RAM: start=$0300, size=$0500;
  ROM: start=$8000, size=$8000, fill=yes, fillval=$ff;
  CHRROM: start=$0000, size=$2000;
}

SEGMENTS {
  HEADER: load=HEADER, type=ro, align=$10;
  ZEROPAGE: load=ZEROPAGE, type=zp;
  STACK: load=STACK, type=bss, optional=yes;
  OAM: load=OAMBUFFER, type=bss, optional=yes;
  BSS: load=RAM, type=bss, optional=yes;
  DMC: load=ROM, type=ro, align=64, optional=yes;
  CODE: load=ROM, type=ro, align=$0100;
  RODATA: load=ROM, type=ro, align=$0100;
  VECTORS: load=ROM, type=ro, start=$FFFA;
  CHR: load=CHRROM, type=ro, align=16, optional=yes;
}
````

## Putting It All Together
```
root
    |
    |-- nes.cfg
    |-- src
        |
        |-- constants.inc
        |-- header.inc
        |-- helloworld.asm
        |-- reset.asm
```