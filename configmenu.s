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

/* $Id: configmenu.s,v 1.4 2011/11/14 19:17:46 furrtek Exp $ */

.include "defines.inc"

.global setup_configmenu
.global vblank_configmenu

MAX_CONFIGITEMS =       13
CONFIGMENU_TOP  =       10

setup_configmenu:
        clr.l   VBL_HANDLER

	jsr     palette_clear
        jsr	vram_clear
	jsr	fix_clear
	jsr	sprite_clear

	move.w  #BLACK,(PALETTES+(32*0)+0)	   | Text palette 0
	move.w  (SRAM_FIRSTCOLOR),(PALETTES+(32*0)+2)
	move.w  #BLACK,(PALETTES+(32*1)+0)	   | Text palette 1
	move.w  (SRAM_SECONDCOLOR),(PALETTES+(32*1)+2)
	move.w  #BLACK,(PALETTES+(32*2)+0)	   | Text palette 2
	move.w  (SRAM_THIRDCOLOR),(PALETTES+(32*2)+2)
	move.w  #0x8000,(BACKDROPCOLOR)

	move.w  #0x0000,d2
        lea	Txt_Configmenu,a0
	jsr	text16_out
        lea	Txt_Configmenuitems,a0
	jsr	text8_out
	move.w  #0x1000,d2
        lea	Txt_Fontcolor2,a0
	jsr	text8_out
	move.w  #0x2000,d2
        lea	Txt_Fontcolor3,a0
	jsr	text8_out

	move.b  #9,(CUR_LIST)
	clr.w   (PREV_CUR)

        move.l  #vblank_configmenu,VBL_HANDLER
        rts

vblank_configmenu:

        /* Display cursor */
	clr.l   d0                        | Erase previous cursor
	move.w  (PREV_CUR),d0
	move.w  d0,(REG_VRAMADDR)
	nop
	move.w  #0x00FF,(REG_VRAMRW)
        clr.l   d0
	move.b  (CUR_LIST),d0
	addi.w  #FIXMAP+(32*3)+CONFIGMENU_TOP,d0       | offset
	move.w  d0,(PREV_CUR)
	move.w  d0,(REG_VRAMADDR)
	move.w  #0x2011,d1	          | Red arrow
	move.w  d1,(REG_VRAMRW)

	lea     Param_addresses,a1
        move.w  #0x1000,d2

        /* Display data */
        move.w  #FIXMAP+(32*22)+CONFIGMENU_TOP,d1
        lea     Txt_Type,a0
        movea.l (a1)+,a2
        move.b  (a2),d0
        beq     1f
        adda.l  #4,a0
1:
        jsr     text8_outdirect

        /* Region */
        move.w  #FIXMAP+(32*22)+1+CONFIGMENU_TOP,d1
        movea.l (a1)+,a2
        moveq.l #0,d0
        move.b  (a2),d0
        mulu    #6,d0
        lea     Txt_Region,a0
        adda.l  d0,a0
        jsr     text8_outdirect

        /* Coints needed P1 */
        move.w  #FIXMAP+(32*22)+2+CONFIGMENU_TOP,(REG_VRAMADDR)
        movea.l (a1)+,a2
        move.b  (a2),d0
        jsr     write_byte

        /* Credits added P1 */
        move.w  #FIXMAP+(32*22)+3+CONFIGMENU_TOP,(REG_VRAMADDR)
        movea.l (a1)+,a2
        move.b  (a2),d0
        jsr     write_byte

        /* Coints needed P2 */
        move.w  #FIXMAP+(32*22)+4+CONFIGMENU_TOP,(REG_VRAMADDR)
        movea.l (a1)+,a2
        move.b  (a2),d0
        jsr     write_byte

        /* Credits added P2 */
        move.w  #FIXMAP+(32*22)+5+CONFIGMENU_TOP,(REG_VRAMADDR)
        movea.l (a1)+,a2
        move.b  (a2),d0
        jsr     write_byte

        /* Game select */
        move.w  #FIXMAP+(32*22)+6+CONFIGMENU_TOP,d1
        lea     Txt_SelectFree,a0
        movea.l (a1)+,a2
        move.b  (a2),d0
        beq     1f
        lea     Txt_SelectCredited,a0
1:
        jsr     text8_outdirect

        /* Game start compulsion */
        move.w  #FIXMAP+(32*22)+7+CONFIGMENU_TOP,(REG_VRAMADDR)
        movea.l (a1)+,a2
        move.b  (a2),d0
        jsr     write_byte

        /* Demo sound */
        move.w  #FIXMAP+(32*22)+8+CONFIGMENU_TOP,d1
        lea     Txt_With,a0
        movea.l (a1)+,a2
        move.b  (a2),d0
        beq     1f
        lea     Txt_Without,a0
1:
        jsr     text8_outdirect
        
        movea.l (a1)+,a0                  | Skip color 1
        movea.l (a1)+,a0                  | Skip color 2
        movea.l (a1)+,a0                  | Skip color 3

        /* Logo palette */
        move.w  #FIXMAP+(32*22)+12+CONFIGMENU_TOP,d1
        clr.l   d0
        move.l  (a1)+,a2
        move.b  (a2),d0
        lsl.w   #3,d0
        lea     LogoPalettes,a0
        move.w  0(a0,d0),d0
        move.w  d0,PALETTES+(32*4)+2
        lea     Txt_LogoColors,a0
        clr.l   d0
        move.b  (a2),d0
        lsl.w   #3,d0                     | *8
        adda.l  d0,a0
        move.w  #0x4000,d2                | Palette 4
        move.l  #7,d7
        jsr     text8_outfixlen

        /* Custom message */
        move.w  #FIXMAP+(32*22)+13+CONFIGMENU_TOP,d1
        movea.l (a1),a0
        move.l  #16,d7
        clr.l   d2
        jsr     text8_outfixlen

        /* User input */
	btst	#0,(BIOS_P1CHANGE)
	beq	noup
	clr.l   d0
	move.b  (CUR_LIST),d0
	beq	noup
	subq.b  #1,(CUR_LIST)             | Move cursor up if > 0
noup:

	btst    #1,(BIOS_P1CHANGE)
	beq	nodown
	clr.l   d0
	move.b  (CUR_LIST),d0
	cmp.b   #MAX_CONFIGITEMS,d0
	beq	nodown
	addq.b  #1,(CUR_LIST)             | Move cursor down if < MAX_CONFIGITEMS
nodown:

	btst    #4,(BIOS_P1CHANGE)
	beq	noa
	lea     Handle_a_button,a0        | Get A button handler, jump to if nonzero
	moveq.l #0,d0
	move.b  (CUR_LIST),d0
	lsl.w   #2,d0
        movea.l 0(a0,d0),a0
	cmp.l   #0,a0
	beq     noa
        jsr     (a0)
noa:

	btst    #5,(BIOS_P1CHANGE)
	beq	nob
	lea     Handle_b_button,a0        | Get B button handler, jump to if nonzero
	moveq.l #0,d0
	move.b  (CUR_LIST),d0
	lsl.w   #2,d0
	movea.l 0(a0,d0),a0
	cmp.l   #0,a0
	beq     nob
        jsr     (a0)
nob:

	btst	#6,(BIOS_P1CHANGE)
	beq	noc
        bra     setup_bootmenu
noc:

        rts


incnormal:
        lea     Param_addresses,a0
	lea     Max_values,a1
	moveq.l #0,d1
	move.b  (CUR_LIST),d1
	move.b  0(a1,d1),d0               | d0=max value
        lsl.w   #2,d1
	move.l  0(a0,d1),a0
	cmp.b   (a0),d0
	beq     1f
	move.b  d0,(REG_SRAMUNLOCK)
        addq.b  #1,(a0)
	move.b  d0,(REG_SRAMLOCK)
1:
	rts


incbcd:
        lea     Param_addresses,a0
	lea     Max_values,a1
	moveq.l #0,d1
	move.b  (CUR_LIST),d1
	move.b  0(a1,d1),d0               | d0=max value
        lsl.w   #2,d1
	move.l  0(a0,d1),a0
	cmp.b   (a0),d0
	beq     1f
	move.b  d0,(REG_SRAMUNLOCK)
        move.b  (a0),d0
        moveq.l #1,d1
        abcd    d1,d0
        move.b  d0,(a0)
	move.b  d0,(REG_SRAMLOCK)
1:
	rts


decnormal:
        lea     Param_addresses,a0
	moveq.l #0,d1
	move.b  (CUR_LIST),d1
        lsl.w   #2,d1
	move.l  0(a0,d1),a0
	tst.b   (a0)
	beq     1f
	move.b  d0,(REG_SRAMUNLOCK)
        subq.b  #1,(a0)
	move.b  d0,(REG_SRAMLOCK)
1:
	rts


decbcd:
        lea     Param_addresses,a0
	moveq.l #0,d1
	move.b  (CUR_LIST),d1
        lsl.w   #2,d1
	move.l  0(a0,d1),a0
	tst.b   (a0)
	beq     1f
	move.b  d0,(REG_SRAMUNLOCK)
        move.b  (a0),d0
        moveq.l #1,d1
        sbcd    d1,d0
        move.b  d0,(a0)
	move.b  d0,(REG_SRAMLOCK)
1:
	rts


choosecolor:
        move.l  #setup_configmenu,(CALLBACK)
        lea     Param_addresses,a0
	moveq.l #0,d1
	move.b  (CUR_LIST),d1
        lsl.w   #2,d1
	move.l  (a0,d1),(COLORTOPICK)
        jsr     setup_colorpicker
        rts

choosetext:
        rts

Max_values:
        dc.b 1,2,9,9,9,9,1,0x30,1,0,0,0,7,0

Param_addresses:
        dc.l SRAM_SYSTEM
        dc.l SRAM_REGION
        dc.l SRAM_COINS_P1_NEEDED
        dc.l SRAM_CREDITS_P1_ADDED
        dc.l SRAM_COINS_P2_NEEDED
        dc.l SRAM_CREDITS_P2_ADDED
        dc.l SRAM_GAMESELECT
        dc.l SRAM_STARTCOMPULSION
        dc.l SRAM_SOUND_STOP
        dc.l SRAM_FIRSTCOLOR
        dc.l SRAM_SECONDCOLOR
        dc.l SRAM_THIRDCOLOR
        dc.l SRAM_LOGOCOLOR
        dc.l 0xD0FFF0

Handle_a_button:
        dc.l incnormal          | System mode
        dc.l incnormal          | Region
        dc.l incnormal          | P1 coins needed
        dc.l incnormal          | P1 credits added
        dc.l incnormal          | P2 coins needed
        dc.l incnormal          | P2 credits added
        dc.l incnormal          | Game select allowance
        dc.l incbcd             | Start compulsion (seconds)
        dc.l incnormal          | Demo sound stop
        dc.l choosecolor        | Color 1
        dc.l choosecolor        | Color 2
        dc.l choosecolor        | Color 3
        dc.l incnormal          | Logo color
        dc.l choosetext

Handle_b_button:
        dc.l decnormal
        dc.l decnormal
        dc.l decnormal
        dc.l decnormal
        dc.l decnormal
        dc.l decnormal
        dc.l decnormal
        dc.l decbcd
        dc.l decnormal
        dc.l 0
        dc.l 0
        dc.l 0
        dc.l decnormal
        dc.l 0

.section .rodata
.align 4
Txt_Configmenu:
	dc.w  FIXMAP+(32*5)+4
	.string "NEOPEN CONFIGURATION MENU"
.align 4
Txt_Configmenuitems:
	dc.w  FIXMAP+(32*5)+CONFIGMENU_TOP
	.string "SYSTEM TYPE\xFF\REGION\xFF\P1 COINS NEEDED     COINS\xFFP1 CREDITING        CREDITS\xFF\P2 COINS NEEDED     COINS\xFFP2 CREDITING        CREDITS\xFF\GAME SELECTION\xFF\START COMPULSION   s\xFF\DEMO SOUND\xFF\FONT COLOR 1\xFF\xFF\xFFLOGO COLOR\xFF\CUSTOM MESSAGE"
.align 4
Txt_Fontcolor2:
        dc.w  FIXMAP+(32*5)+10+CONFIGMENU_TOP
        .string "FONT COLOR 2"
.align 4
Txt_Fontcolor3:
        dc.w  FIXMAP+(32*5)+11+CONFIGMENU_TOP
        .string "FONT COLOR 3"
.align 4
Txt_Type:
        .string "AES"
        .string "MVS"
Txt_Region:
        .string "JAPAN"
        .string "US   "
        .string "EURO "
Txt_SelectFree:
        .string "ALWAYS       "
Txt_SelectCredited:
        .string "WHEN CREDITED"
Txt_With:
        .string "WITH   "
Txt_Without:
        .string "WITHOUT"
.align 2
Txt_LogoColors:
        .string "WHITE  "
        .string "RED    "
        .string "GREEN  "
        .string "BLUE   "
        .string "YELLOW "
        .string "CYAN   "
        .string "MAGENTA"
        .string "ORANGE "
