/*
 * Copyright (c) 2011 Emmanuel Vadot <elbarto@neogeodev.org>
 * Copyright (c) 2011 Furrtek <furrtek@neogeodev.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

.include "defines.inc"

.global	setup_colorpicker

setup_colorpicker:
        clr.l   VBL_HANDLER

	move.w  #BLACK,(PALETTES+(32*3)+0)	   | Text palette 3
	move.w  #WHITE,(PALETTES+(32*3)+2)
	move.w  #0x7777,(PALETTES+(32*3)+4)

	/* Clear a box */
	move.w  #FIXMAP+(32*8)+8,d1
	move.w  #1,(REG_VRAMMOD)
        move.l  #25-1,d6
2:
	move.l  #9-1,d7
	move.w  d1,(REG_VRAMADDR)
1:
        move.w  #0x3020,(REG_VRAMRW)
	dbra    d7,1b
        addi.w  #32,d1
        dbra    d6,2b
        
        /* Draw color bar */
	move.w  #FIXMAP+(32*13)+15,(REG_VRAMADDR)
	move.w  #32,(REG_VRAMMOD)
	move.l  #15-1,d7
1:
        move.w  #0xF000,(REG_VRAMRW)
	dbra    d7,1b

        move.w  #0x3000,d2
        lea	Txt_Colorpicker,a0
	jsr	text8_out

        movea.l (COLORTOPICK),a0
        move.w  (a0),(PALETTES+(32*15)+2)
	clr.w  (CUR_COLORPREV)

        move.l  #vblank_colorpicker,VBL_HANDLER
        rts
        

vblank_colorpicker:

        /* Display component cursor */
	clr.l   d0                        | Erase previous cursor
	move.w  (CUR_COLORPREV),d0
	move.w  d0,(REG_VRAMADDR)
	nop
	move.w  #0x3020,(REG_VRAMRW)
        clr.l   d0
	move.b  (CUR_COLOR),d0
	addi.w  #FIXMAP+(32*9)+11,d0      | offset
	move.w  d0,(CUR_COLORPREV)
	move.w  d0,(REG_VRAMADDR)
	move.w  #0x3011,d1	          | Red arrow
	move.w  d1,(REG_VRAMRW)
	
	/* Display sliders */
        move.w  #FIXMAP+(32*16)+11,d1
	move.w  #32,(REG_VRAMMOD)
	move.l  #8,d6
4:
	move.l  #16-1,d7
        move.w  d1,(REG_VRAMADDR)
        move.w  (PALETTES+(32*15)+2),d0
        not     d0
        lsr.w   d6,d0
        andi.w  #0x000F,d0
3:
        cmp.w   d0,d7
        bne     1f
        move.w  #0x3013,(REG_VRAMRW)
        bra     2f
1:
        move.w  #0x302D,(REG_VRAMRW)
2:
	dbra    d7,3b
	addq.w  #1,d1
	move.w  d6,d6
	beq     1f
        subi.w  #4,d6
	bra     4b
1:

        /* User input */
	btst	#0,(BIOS_P1CHANGE)
	beq	noup
        tst.b   (CUR_COLOR)
        beq     noup
        subq.b  #1,(CUR_COLOR)
noup:

	btst    #1,(BIOS_P1CHANGE)
	beq	nodown
        cmp.b   #2,(CUR_COLOR)
        beq     nodown
        addq.b  #1,(CUR_COLOR)
nodown:

	btst    #2,(BIOS_P1CHANGE)
	beq	noleft
        move.l  #0x0100,d0                | Color ncrement
        move.l  #0x0F00,d2                | Mask
        clr.l   d1
        move.b  (CUR_COLOR),d1
        lsl.w   #2,d1
        lsr.w   d1,d0                     | Move mask and increment to R, G, or B
        lsr.w   d1,d2
        move.w  (PALETTES+(32*15)+2),d1
        and.w   d2,d1                     | Test if component != 0
        beq     noleft
        sub.w   d0,(PALETTES+(32*15)+2)
noleft:

	btst    #3,(BIOS_P1CHANGE)
	beq	noright
        move.l  #0x0100,d0                | Color ncrement
        move.l  #0x0F00,d2                | Mask
        clr.l   d1
        move.b  (CUR_COLOR),d1
        lsl.w   #2,d1
        lsr.w   d1,d0                     | Move mask and increment to R, G, or B
        lsr.w   d1,d2
        move.w  (PALETTES+(32*15)+2),d1
        and.w   d2,d1
        cmp.w   d2,d1                     | Test if component < 0xF
        beq     noright
        add.w   d0,(PALETTES+(32*15)+2)
noright:

	btst    #4,(BIOS_P1CHANGE)
	beq	noa
	move.b  d0,(REG_SRAMUNLOCK)
        movea.l (COLORTOPICK),a0
        move.w  (PALETTES+(32*15)+2),(a0)
	move.b  d0,(REG_SRAMLOCK)
	movea.l (CALLBACK),a0
        jsr     (a0)
noa:

        rts

.align 4
Txt_Colorpicker:
        dc.w  FIXMAP+(32*10)+9
        .string "Color picker\xFF\xFF\RED\xFF\GREEN\xFF\BLUE"

.section .bss
.global RED_CUR
.global GREEN_CUR
.global BLUE_CUR
.global CUR_COLOR
.global CUR_COLORPREV
.global COLORTOPICK

CUR_COLOR:              .byte 0
.align 2
CUR_COLORPREV:          .byte 0
RED_CUR:		.byte 0
GREEN_CUR:		.byte 0
BLUE_CUR:		.byte 0
.align 4
COLORTOPICK:            .long 0
