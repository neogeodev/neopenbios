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

/* $Id: hwtest.s,v 1.8 2011/11/11 01:13:17 furrtek Exp $ */

.include "defines.inc"

.global hardware_test
.global hblank_palette

hardware_test:
        move	#0x2700, sr               | Disable interrupts
	jsr	sprite_clear
	move.w  #0x2000,sr                | Enable interrupts

        clr.b   (HWTEST_SCREEN)           | Start first hw test screen

        move.l  vbl_rts,(VBL_TEST)
        lea     hwtests,a0
        movea.l (a0),a0
        jsr     (a0)
        move.l  #vbl_hwtest,(VBL_HANDLER)
1:
        bra     1b

.align 4
hwtests:
dc.l    hwtest_palette
dc.l    vbl_rts
dc.l    hwtest_input,vbl_rts
dc.l    hwtest_output,vbl_rts
dc.l    hwtest_memory,vbl_rts
dc.l    0

hwtest_memory:
        jsr     fix_clear

        move.w  #0x8000,PALETTES
        move.w  #0x7FFF,PALETTES+2

        clr.w   d2
	lea	Txt_Pushstart,a0
	jsr	text8_out
	lea	Txt_Testmemory,a0
	jsr	text16_out

        rts

hwtest_output:
        jsr     fix_clear

        move.w  #0x8000,PALETTES
        move.w  #0x7FFF,PALETTES+2

        clr.w   d2
	lea	Txt_Pushstart,a0
	jsr	text8_out
	lea	Txt_Testoutput,a0
	jsr	text16_out

        rts

hwtest_input:
        jsr     fix_clear
        
        move.w  #0x8000,PALETTES
        move.w  #0x7FFF,PALETTES+2

        clr.w   d2
	lea	Txt_Pushstart,a0
	jsr	text8_out
	lea	Txt_Testinput,a0
	jsr	text16_out

        rts

hwtest_palette:
        jsr     fix_clear

	lea     PALETTES,a0
	move.l  #(256*16)-1,d0
1:
        clr.w   (a0)+
        dbra    d0,1b

        clr.w   d2
	lea	Txt_Pushstart,a0
	jsr	text8_out
	lea	Txt_Testpalette,a0
	jsr	text16_out
	lea	Txt_Red,a0
	jsr	text16_out
	lea	Txt_Green,a0
	jsr	text16_out
	lea	Txt_Blue,a0
	jsr	text16_out
	lea	Txt_White,a0
	jsr	text16_out

	move.w  #FIXMAP+(32*16)+6,d1           | Draws color bands, palettes 0 to 15
        move.l  #16-1,d2
        move.w  #0x0000,d0
        move.w  #1,REG_VRAMMOD
1:
        move.w  d1,REG_VRAMADDR
        move.w  d0,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  #0xFF,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  #0xFF,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  #0xFF,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        move.w  d0,REG_VRAMRW
        addi.w  #0x1000,d0
        add.w   #32,d1
        dbra    d2,1b

        move.w  #0x00D0,REG_LSPCMODE            | Starts HBlank ints., 8 lines
        move.w  #0x0000,REG_TIMERHIGH
        move.w  #0x017F*8,REG_TIMERLOW
        rts

hblank_palette:
        move.w  REG_LSPCMODE,d0
        lsr.w   #7,d0
        cmp.w   #(3*8)+0x110,d0                 | <3:rts (white)
        blo     3f
        cmp.w   #(6*8)+0x110,d0                 | >6:green, blue, or white
        bhi     2f
	lea     PALETTES+2,a0                   | 3<L<6: red
	move.l  #0x0F00,d0
	move.l  #16-1,d1
1:
        move.w  d0,(a0)
        adda.l  #32,a0
        subi.w  #0x0100,d0
        dbra    d1,1b
3:
        rts
2:
        cmp.w   #(9*8)+0x110,d0                 | >9:blue, or white
        bhi     2f
	lea     PALETTES+2,a0                   | 6<L<9: green
	move.l  #0x00F0,d0
	move.l  #16-1,d1
1:
        move.w  d0,(a0)
        adda.l  #32,a0
        subi.w  #0x0010,d0
        dbra    d1,1b
        rts
2:
        cmp.w   #(13*8)+0x110,d0                | >13:white
        bhi     2f
	lea     PALETTES+2,a0                   | 9<L<13: blue
	move.l  #0x000F,d0
	move.l  #16-1,d1
1:
        move.w  d0,(a0)
        adda.l  #32,a0
        subi.w  #0x0001,d0
        dbra    d1,1b
        rts
2:
	lea     PALETTES+2,a0                   | L>13: white
	move.l  #0x0FFF,d0
	move.l  #16-1,d1
1:
        move.w  d0,(a0)
        adda.l  #32,a0
        subi.w  #0x0111,d0
        dbra    d1,1b
        rts
        
vbl_input:
        rts

vbl_hwtest:
	btst.b	#0,(INPUT_S+1)                  | jsr to setup routine if P1 presses start
	beq	3f
        addq.b  #1,(HWTEST_SCREEN)
2:
        lea     hwtests,a0
        moveq.l #0,d0
        move.b  (HWTEST_SCREEN),d0
        lsl.w   #3,d0
        move.l  0(a0,d0),a1
        cmp.l   #0,a1
        beq     1f
        move.l  4(a0,d0),d0
        move.l  d0,(VBL_TEST)
        move.w  #0x0000,(REG_LSPCMODE)
        jsr     (a1)
3:
        jsr     (VBL_TEST)
        rts
1:
        clr.b   (HWTEST_SCREEN)                 | loopback to first test screen
        bra     2b
        rts
        
vbl_rts:
        rts

.section .rodata
.align 4
Txt_Pushstart:
	dc.w  FIXMAP+(32*7)+26
	.string "Push P1 START for next test"
.align 4
Txt_Testpalette:
	dc.w  FIXMAP+(32*3)+3
	.string "Palette test"
.align 4
Txt_Testinput:
	dc.w  FIXMAP+(32*3)+3
	.string "I/O test"
.align 4
Txt_Testmemory:
	dc.w  FIXMAP+(32*3)+3
	.string "Memory test"
.align 4
Txt_Testoutput:
	dc.w  FIXMAP+(32*3)+3
	.string "Output test"
.align 4
Txt_Red:
	dc.w  FIXMAP+(32*10)+6
	.string "RED"
.align 4
Txt_Green:
	dc.w  FIXMAP+(32*10)+9
        .string "GREEN"
.align 4
Txt_Blue:
        dc.w  FIXMAP+(32*10)+12
        .string "BLUE"
.align 4
Txt_White:
        dc.w  FIXMAP+(32*10)+15
        .string "WHITE"
.align 4
Txt_Test:
        dc.w  FIXMAP+(32*10)+10
        .string "test"

.section .bss
HWTEST_SCREEN:		.byte 0
.align 4
VBL_TEST:               .long 0
