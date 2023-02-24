.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
.exportzp player_x, player_y

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

    ; update tiles *after* DMA transfer
    JSR update_player
    JSR draw_player

    STA $2005
    RTI
.endproc

.import reset_handler

.export main
.proc main
    LDA #239   ; Y is only 240 lines tall!
    STA scroll

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
    STA ppuctrl_settings
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

.proc update_player
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    LDA player_x
    CMP #$e0
    BCC not_at_right_edge
    ; if BCC is not taken, we are greater than $e0
    LDA #$00
    STA player_dir    ; start moving left
    JMP direction_set ; we already chose a direction,
                    ; so we can skip the left side check
not_at_right_edge:
    LDA player_x
    CMP #$10
    BCS direction_set
    ; if BCS not taken, we are less than $10
    LDA #$01
    STA player_dir   ; start moving right
direction_set:
    ; now, actually update player_x
    LDA player_dir
    CMP #$01
    BEQ move_right
    ; if player_dir minus $01 is not zero,
    ; that means player_dir was $00 and
    ; we need to move left
    DEC player_x
    JMP exit_subroutine
move_right:
    INC player_x
exit_subroutine:
    ; all done, clean up and return
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

.proc draw_player
    ; save registers
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    ; write player ship tile numbers
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$07
    STA $0209
    LDA #$08
    STA $020d

    ; write player ship tile attributes
    ; use palette 0
    LDA #$00
    STA $0202
    STA $0206
    STA $020a
    STA $020e

    ; store tile locations
    ; top left tile:
    LDA player_y
    STA $0200
    LDA player_x
    STA $0203

    ; top right tile (x + 8):
    LDA player_y
    STA $0204
    LDA player_x
    CLC
    ADC #$08
    STA $0207

    ; bottom left tile (y + 8):
    LDA player_y
    CLC
    ADC #$08
    STA $0208
    LDA player_x
    STA $020b

    ; bottom right tile (x + 8, y + 8)
    LDA player_y
    CLC
    ADC #$08
    STA $020c
    LDA player_x
    CLC
    ADC #$08
    STA $020f

    ; restore registers and return
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
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
