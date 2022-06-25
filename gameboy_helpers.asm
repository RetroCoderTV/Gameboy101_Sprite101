INCLUDE "inc/hardware.inc"


SECTION "Helper Routines",ROM0

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; a - byte to fill with
; hl - destination address
; bc - size of area to fill
fill::
    inc	b
    inc	c
    jr	.skip
.fill
ld	[hl+],a
.skip
    dec	c
    jr	nz,.fill
    dec	b
    jr	nz,.fill
    ret 
    
;-------------------------------------------------------------------------------	
;-------------------------------------------------------------------------------
    ; hl - source address
    ; de - destination
    ; bc - size
copy::
    inc	b
    inc	c
    jr	.skip
.copy:
    ld	a,[hl+]
    ld	[de],a
    inc	de
.skip:
    dec	c
    jr	nz,.copy
    dec	b
    jr	nz,.copy
    ret


SECTION "DMA Subroutine on ROM", ROM0
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;hard coded subroutine that can live in RAM.
;$C000 is set as space for Shadow OAM
dma_sub_start::
            db	$3E,$C0				; 	ld	a,$C0           ; ShadowOAM in RAM at $C000 
            db	$E0,$46				; 	ld	[rDMA],a
            db	$3E,$28				; 	ld	a,40		; delay = 160 cycles
                                                        ;.copy
            db	$3D				; 	dec	a
            db	$20,$FD				; 	jr	nz,.copy
            db	$C9				; 	ret
dma_sub_end::

SECTION "DMA Subroutine HRAM Space",HRAM

    DS 10

SECTION "Shadow OAM Area", WRAM0

    DS  40*4

