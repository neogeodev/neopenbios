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

.global	vblank_ingamemenu
.global setup_ingamemenu

setup_ingamemenu:
        /* save palette 0 */
        lea     PALETTES+32,a0
        lea     PALETTE_SAVE,a1
        move.l  #(16/2)-1,d7
1:
        move.l  (a0)+,(a1)+
        dbra    d7,1b

        /* save fix */
        lea     FIX_SAVE,a0
        move.w  #FIXMAP+(32*12)+6,d0      | Box position
        move.l  #16-1,d6
2:
        move.l  #16-1,d7
1:
        move.w  d0,(REG_VRAMADDR)         | REG_VRAMMOD doesn't work when reading
        nop
        move.w  (REG_VRAMRW),(a0)+
        addq.w  #1,d0
        dbra    d7,1b
        addi.w  #32-16,d0                 | Next column
        dbra    d6,2b

	move.w  #BLACK,(PALETTES+(32*1)+0)	  | Text palette 1
	move.w  #TEXTCOLOR,(PALETTES+(32*1)+2)
	move.w  #0x0222,(PALETTES+(32*1)+4)

	/* Draws box */

        move.w  #0x1000,d2                | Write fixed text
       	lea	IGM,a0
	jsr	text16_out
        rts

vblank_ingamemenu:

	/* User input */
        move.b  (REG_P1CNT),d0
	move.b  (P1_PREV),d1
	eor.b   #0xFF,d0
	move.b  d0,(P1_PREV)
	eor.b   d0,d1
	and.b   d0,d1

	btst    #7,d1                     | D: quit ingame menu
	beq	.noa
	/* restore palette 0 */
        lea     PALETTE_SAVE,a0
        lea     PALETTES+32,a1
        move.l  #(16/2)-1,d7
1:
        move.l  (a0)+,(a1)+
        dbra    d7,1b

	/* restore fix */
        lea     FIX_SAVE,a0
        move.w  #FIXMAP+(32*12)+6,d0      | Box position
        move.w  #1,(REG_VRAMMOD)
        move.l  #16-1,d6
2:
        move.l  #16-1,d7
        move.w  d0,(REG_VRAMADDR)
1:
        nop
        move.w  (a0)+,(REG_VRAMRW)
        dbra    d7,1b
        addi.l  #32,d0                    | Next column
        dbra    d6,2b

        clr.b   (MENU_MODE)
	move.b  #0x80,(BIOS_SYSTEM_MODE)  | Game mode
	rts
.noa:

	rts

.section .bss

FIX_SAVE:		.fill 16*16,2,0
PALETTE_SAVE:           .fill 16,2,0

.section .rodata
.align 4
IGM:
	dc.w  FIXMAP+(32*12)+6
	.string "  NEOPEN  BIOS  \xFF  IN-GAME MENU  \xFF                \xFF SET SOFTDIPS   \xFF SET DEBUG DIPS \xFF CHEATS         \xFF TEST           "

