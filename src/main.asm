.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
    RTI
.endproc

.proc nmi_handler
    LDA #$00
    STA OAMADDR
    LDA #$02
    STA OAMDMA
    LDA #$00
    STA $2005
    RTI
.endproc

.import reset_handler

.export main
.proc main
    ; write color palettes from 3f00 to 3f20
    LDX PPUSTATUS
    LDX #$3f
    STX PPUADDR
    LDX #$00
    STX PPUADDR
load_color_palettes:
    LDA color_palettes,x
    STA PPUDATA
    INX
    CPX #$20
    BNE load_color_palettes

    ; write sprite data
    LDX #$00
load_sprites:
    LDA sprites,X
    STA $0200,X
    INX
    CPX #$20
    BNE load_sprites

    ; write a nametable (background)
    ; 4 big stars
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$6b
    STA PPUADDR
    LDX #$2f
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$57
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$23
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$52
    STA PPUADDR
    STX PPUDATA

    ; 6 small stars
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$74
    STA PPUADDR
    LDX #$2d
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$43
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$5d
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$73
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$2f
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$f7
    STA PPUADDR
    STX PPUDATA

    ; 5 smaller stars
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$f1
    STA PPUADDR
    LDX #$2e
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$a8
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$7a
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$44
    STA PPUADDR
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$7c
    STA PPUADDR
    STX PPUDATA

    ; Mario star
    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$eb
    STA PPUADDR
    LDX #$29
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$21
    STA PPUADDR
    LDA #$ec
    STA PPUADDR
    LDX #$2a
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$0b
    STA PPUADDR
    LDX #$2b
    STX PPUDATA

    LDA PPUSTATUS
    LDA #$22
    STA PPUADDR
    LDA #$0c
    STA PPUADDR
    LDX #$2c
    STX PPUDATA

    ; attribute table bits as palette 0-3
    ;7654 3210
    ;|||| ||++- Color bits 0-1 for top left quadrant
    ;|||| ++--- Color bits 2-3 for top right quadrant
    ;||++------ Color bits 4-5 for bottom left quadrant
    ;++-------- Color bits 6-7 for bottom right quadrant

    ; Big star top
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$c2
    STA PPUADDR
    LDA #%11000000  ; bottom right
    STA PPUDATA

    ; Big star left
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$e0
    STA PPUADDR
    LDA #%00001100  ; top right
    STA PPUDATA

    ; Mario star
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$da
    STA PPUADDR
    LDA #%01000000  ; bottom right color palette 1
    STA PPUDATA

    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$db
    STA PPUADDR
    LDA #%00100000  ; bottom left color palette 2
    STA PPUDATA

    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$e3
    STA PPUADDR
    LDA #%00000011  ; top left color palette 3
    STA PPUDATA

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

forever:
    JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
color_palettes:             ; the 8 color palettes for background and sprites
; Background color palettes
.byte $0d, $12, $23, $27	; 0
.byte $0d, $2b, $3c, $39	; 1
.byte $0d, $0c, $07, $13	; 2
.byte $0d, $16, $27, $37	; 3

; Sprite color palettes
.byte $0d, $2d, $10, $15	; 0 (4)
.byte $0d, $19, $09, $29	; 1 (5)
.byte $0d, $19, $07, $13	; 2 (6)
.byte $0d, $15, $16, $27	; 3 (7)

sprites:
;76543210
;||||||||
;||||||++- Palette (4 to 7) of sprite
;|||+++--- Unimplemented (read 0)
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically

; y position, tile, attribute, x position

; Spaceship 2x2 sprites
.byte $70, $05, %00000011, $80  ; use color palette 3
.byte $70, $05, %01000000, $88  ; flip horizontal sprite nr 05 and use color palette 0
.byte $78, $07, %00000010, $80  ; use color palette 2
.byte $78, $07, %01000001, $88  ; flip horizontal sprite nr 07 and use color palette 1

; Ball 2x2 sprites with 1 origin and 3 flipped parts
.byte $14, $04, %00000000, $50	; use color palette 0
.byte $14, $04, %01100001, $58	; flip horizontal sprite, set behind star in background and use color palette 1
.byte $1c, $04, %10000010, $50	; flip vertical and color palette 2
.byte $1c, $04, %11000011, $58	; flip vertical and flip horizontal and color palette 3

.segment "CHR"
.incbin "graphics.chr"
