/*
Simple Sprite and background display
DMA Shadow OAM routine
*/

INCLUDE "inc/hardware.inc"

SECTION "Header",ROM0[$100]
    jp Game

    DS $150 - @,0

SECTION "Game",ROM0[$150]

Game:
    ; di
    ld sp, $E000   

.WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, .WaitVBlank

    ;reset important registers
	xor	a
	ld	[rIF],a
	ld	[rLCDC],a
	ld	[rSTAT],a
	ld	[rSCX],a
	ld	[rSCY],a
	ld	[rLYC],a
	ld	[rIE],a

    ;clear RAM
	ld	hl,_RAM             ; clear ram (fill with a which is 0 here)
	ld	bc,$2000-2			; watch out for stack ;)
	call fill

	ld	hl,_HRAM			; clear hram
	ld	c,$80				; a = 0, b = 0 here, so let's save a byte and 4 cycles (ld c,$80 - 2/8 vs ld bc,$80 - 3/12)
	call	fill

	ld	hl,_VRAM			; clear vram
	ld	b,$18				; c should be already 00
	call	fill

    ;copy the DMA routine to WRAM
    ld de,$FF80
    ld hl,dma_sub_start
    ld bc,dma_sub_end-dma_sub_start
    call copy

    ;palette
    ld	a,%11100100			
	ld	[rBGP],a			
	ld	[rOBP0],a			
	ld	[rOBP1],a

    ; Copy the tile data
	ld de, _VRAM_BLOCK2
	ld hl, BG_Tiles
	ld bc, BG_TilesEnd - BG_Tiles
    call copy

	; Copy the tilemap
	ld de, _SCRN0
	ld hl, BG_Tilemap
	ld bc, BG_TilemapEnd - BG_Tilemap
    call copy

    ; Copy sprite data
    ld de, _VRAM_BLOCK0
    ld hl, Sprite_Tiles
    ld bc, Sprite_TilesEnd-Sprite_Tiles
    call copy

    ; ;enable vblank (in FFFF interrupt Enable memory)
	; ld	a,IEF_VBLANK
	; ld	[rIE],a

	; Bit 7 - LCD Display Enable             (0=Off, 1=On)
	; Bit 6 - Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
	; Bit 5 - Window Display Enable          (0=Off, 1=On)
	; Bit 4 - BG & Window Tile Data Select   (0=8800-97FF, 1=8000-8FFF)
	; Bit 3 - BG Tile Map Display Select     (0=9800-9BFF, 1=9C00-9FFF)
	; Bit 2 - OBJ (Sprite) Size              (0=8x8, 1=8x16)
	; Bit 1 - OBJ (Sprite) Display Enable    (0=Off, 1=On)
	; Bit 0 - BG/Window Display/Priority     (0=Off, 1=On)
	ld a, %10000011
	ld [rLCDC], a

    ; ei

    ;each sprite has 4 attributes:
    ;0=Y
    ;1=X
    ;2=TileID
    ;3=Flags
    ld de, SHADOW_OAM
    ld a,80
    ld [de],a ; y attr
    inc de
    ld a,80 
    ld [de],a ; x attr
    inc de
    ld a,0 ;t
    ld [de],a
    inc de
    ld a,0 ;f
    ld [de],a

    call DMA_TRANSFER_ROUTINE



.gameloop:
    halt
    jr .gameloop

SECTION "Sprite Tiles", ROM0

Sprite_Tiles:
    DB $55,$7F,$81,$FF,$A5,$FF,$81,$FF,$A5,$FF,$BD,$FF,$81,$FF,$7E,$7E ;face
Sprite_TilesEnd:

SECTION "BG Tiles", ROM0

BG_Tiles:
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$00,$FF,$01,$FE,$3A,$C4,$44,$82,$82,$82,$82,$80,$80,$FF,$7F
    DB $FF,$F8,$07,$04,$03,$02,$01,$01,$01,$01,$01,$01,$01,$01,$FF,$FE
    DB $F8,$07,$E0,$1F,$C0,$3F,$80,$7F,$80,$7F,$00,$FF,$00,$FF,$00,$FF
    DB $1F,$E0,$07,$F8,$03,$FC,$01,$FE,$01,$FE,$00,$FF,$00,$FF,$00,$FF
    DB $00,$FF,$00,$FF,$00,$FF,$80,$7F,$80,$7F,$C0,$3F,$E0,$1F,$F8,$07
    DB $00,$FF,$00,$FF,$00,$FF,$01,$FE,$01,$FE,$03,$FC,$07,$F8,$1F,$E0
BG_TilesEnd:
    

SECTION "BG Tilemap", ROM0
    
BG_Tilemap:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00
    DB $05,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00
    DB $00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
BG_TilemapEnd: