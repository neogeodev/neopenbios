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

.global vblank_bootmenu
.global bootmenu_logoanim
.global	bootmenu_dispcur
.global palette_setup
.global logo_setup
.global disp_db_gamename
.global disp_real_gamename
.global disp_gamelogo
.global setup_bootmenu

setup_bootmenu:
        clr.l   VBL_HANDLER

	jsr	vram_clear
	jsr	fix_clear
	jsr	sprite_clear

        jsr	 logo_setup                        | Setup NEO*GEO logo sprites

	move.w  #BLACK,(PALETTES+(32*0)+0)	   | Text palette 0
	move.w  (SRAM_FIRSTCOLOR),(PALETTES+(32*0)+2)
	move.w  #BLACK,(PALETTES+(32*1)+0)	   | Text palette 1
	move.w  (SRAM_SECONDCOLOR),(PALETTES+(32*1)+2)
	move.w  #BLACK,(PALETTES+(32*2)+0)	   | Text palette 2
	move.w  (SRAM_THIRDCOLOR),(PALETTES+(32*2)+2)

        lea     PALETTES+(32*16),a0        	   | Sprite palette $10 (logo)
        clr.l   d0
        move.b  (SRAM_LOGOCOLOR),d0
        lsl.w   #3,d0
        lea     LogoPalettes,a1
        cmp.w   #1,(0x108)
        beq     1f
        move.w  #0,(a0)+
        move.w  0(d0,a1),(a0)+
	move.w  2(d0,a1),(a0)+
	move.w  4(d0,a1),(a0)+
	move.w  6(d0,a1),(a0)+
	bra     2f
1:
	| Special case for stupid NAM-1975 NG logo palette
	move.w  6(d0,a1),4(a0)
	move.w  2(d0,a1),8(a0)
	move.w  0(d0,a1),16(a0)
	move.w  4(d0,a1),24(a0)
2:

	move.w  #0x8000,(BACKDROPCOLOR)

        clr.w   d2                                 | Write fixed text
       	lea	Txt_Ver,a0
	jsr	text8_out
	lea	Txt_Regions,a0
	jsr	text16_out
	lea	Txt_Type,a0
	jsr	text16_out
	lea	Txt_Dev,a0
	jsr	text16_out
	lea	Txt_SDSin,a0
	jsr	text16_out

	jsr	disp_gamelogo

        btst.b  #7,(REG_STATUS_B)                  | Don't read SRAM if we're on an AES
        beq     2f
        lea     SETTINGS,a0
        move.b  (SRAM_REGION),d0                   | Set region from saved value
        cmp.b   #2,d0                              | SRAM sanitizing
        bhi     1f
        move.b  d0,(a0)+
1:
        move.b  (SRAM_SYSTEM),d0                   | Set board type from saved value
        cmp.b   #1,d0                              | SRAM sanitizing
        bhi     2f
        move.b  d0,(a0)
2:

	clr.b   (CUR_LIST)
	clr.w   (PREV_CUR)
	clr.b   (BIOS_FRAME_COUNTER)

        move.l  #vblank_bootmenu,VBL_HANDLER
        rts


get_gameinfos:
/* Searches for game infos in list, returns pointer in a0 */
        lea      gamelist,a0
        move.w   (0x108),d0               | NGH location in cart
searchname:
        tst.w    (a0)
        beq      notfound                 | Reached end of list
        cmp.w    (a0)+,d0
        beq      found
        adda.l   #4,a0                    | Next entry
        bra      searchname
found:
        movea.l  (a0),a0
        rts
notfound:
        move.l   #0,a0
        rts

disp_gamelogo:
/* Display game logo */
        jsr      get_gameinfos
        lea      gamename_200,a0
        cmp.l    #0,a0
        beq      2f
        adda.l   #3*22,a0                 | Skip strings
        move.l   (a0),d0                  | Point to logo infos
	beq	 2f
	movea.l	 d0, a0
        movea.l  (a0),a1                  | Point to logo display routine
        adda.l   #4,a0                    | Make a0 point to display data
        cmp.l    #0,a1
        bne      1f
        rts
1:
        jsr (a1)
2:
        rts

disp_db_gamename:
/* Display game name according to NGH and nat setting */
        move.l   d2,-(a7)
        jsr      get_gameinfos
        cmp.l    #0,a0
        beq      eol
	moveq	 #0, d0
	move.b	 (SETTINGS), d0
	mulu	 #22, d0                  | Game name string size (21+1)
	adda.l	 d0, a0
        move.w   #FIXMAP+(32*15)+20,d1
        move.w   #0x1000,d2               | Palette 1
        move.w   #20,d7
        jsr      text16_outfixlen
eol:
        move.l   (a7)+,d2
	rts

disp_real_gamename:
/* Display game name from game ROM */
	moveq	 #0x0, d0
	move.b	 (SETTINGS), d0
	lsl.w    #2,d0
	add.l	 #0x116, d0
	movea.l	 d0, a0
	movea.l	 (a0), a0
        move.l   #16-1,d1
        move.w   #FIXMAP+(32*8)+24,d1
        move.w   #0x1000,d2               | Palette 1
        move.w   #20,d7
        jsr      text16_outfixlen

	rts

vblank_bootmenu:
	cmp.b   #0x40,(BIOS_FRAME_COUNTER)
	bhs	1f
	jsr     bootmenu_logoanim         | Do logo animation if frame < 0x40
1:

	move.b	(BIOS_P1CHANGE), d1
	btst	#0,d1
	beq	noup
	clr.l   d0
	move.b  (CUR_LIST),d0
	lea	SETTINGS,a0
	tst.b   (a0,d0)
	beq	noup
	subq.b  #1,(a0,d0)             | Move cursor up if > 0
noup:

	btst    #1,d1
	beq	nodown
	clr.l   d0
	move.b  (CUR_LIST),d0
	lea	SETTINGS,a0
	lea	Ranges,a1
	move.b  (a1,d0),d2
	cmp.b   (a0,d0),d2
	beq	nodown
	addq.b  #1,(a0,d0)             | Move cursor down if < max
nodown:

	btst    #2,d1
	beq	noleft
	tst.b   (CUR_LIST)
	beq	noleft
	subq.b  #1,(CUR_LIST)          | Move cursor left if > 0
noleft:

	btst    #3,d1
	beq	noright
	cmp.b   #2,(CUR_LIST)
	beq	noright
	addq.b  #1,(CUR_LIST)          | Move cursor right if < max
noright:

	btst    #4,d1
	beq	noa
	bra	init_game
noa:

	btst    #6,d1
	beq	noc
	bra	setup_configmenu
noc:

	btst    #7,d1
	beq	nod
	bra	setup_softdips
nod:

	jsr	disp_db_gamename
	jsr	bootmenu_dispcur       | Take care of boot menu if in system mode and right flag
        rts


bootmenu_logoanim:
	move.w  #SCB2+1,(REG_VRAMADDR) | Set V zoom
	clr.w   d0
	move.b  (BIOS_FRAME_COUNTER),d0
	cmp.b   #0x20,d0
        lsl.b   #2,d0
	ori.w   #0x0F00,d0
	move.w  d0,(REG_VRAMRW)

	move.w  #SCB3+1,(REG_VRAMADDR) | Set sprite Y position
	clr.w   d0
	move.b  (BIOS_FRAME_COUNTER),d0
	lsr.b   #1,d0
	addi.w  #496-32,d0
	lsl.w   #7,d0
	ori.b   #4,d0
	move.w  d0,(REG_VRAMRW)
	rts


bootmenu_dispcur:
	clr.l   d0                     | Erase previous cursor
	move.w  (PREV_CUR),d0
	move.w  d0,(REG_VRAMADDR)
	nop
	move.w  #1,(REG_VRAMMOD)
	nop
	move.w  #0x00FF,(REG_VRAMRW)
	nop
	move.w  #0x00FF,(REG_VRAMRW)

	move.l  #3-1,d7                |Draw selections and actual cursor
.curlp:
	move.l  d7,d0
	lsl.w   #8,d0		       |X position in fix (8 columns * 32)
	addi.w  #8*32,d0	       |X offset
	lea	 SETTINGS,a0
	add.b   (a0,d7),d0	       |2 tiles per line
	add.b   (a0,d7),d0
	addi.w  #FIXMAP+13,d0          |Y offset
	move.w  d0,(REG_VRAMADDR)
	clr.w   d1		       |Palette 0 for selections
	cmp.b   (CUR_LIST),d7	       |Is current ?
	bne	 .skip
	move.w  #0x2000,d1	       |Palette 2 for current
	move.w  d0,(PREV_CUR)	       |Et sauvegarder sa position pour l'effacement prochain
.skip:
	ori.w   #0x0111,d1	       |Arrow tile
	move.w  d1,(REG_VRAMRW)
	addi.w  #0x0100,d1
	move.w  d1,(REG_VRAMRW)
	dbra	d7,.curlp

	rts


logo_setup:
	move.w  #64,(REG_VRAMADDR)
	move.w	#1, (REG_VRAMMOD)
	lea	Logomap,a0
	move.b  (0x115),d1
	lsl.w   #8,d1
	move.l  #14,d7                             |14 sprites to set up
.mapsprs:
	move.l  #4-1,d6                            |4 tiles per sprite
.mapspr:
	move.b  (a0)+,d1
	move.w  d1,(REG_VRAMRW)
	nop
	move.w  #0x1000,(REG_VRAMRW)		   |Palette $10
	dbra	d6,.mapspr
	move.l  #32-4-1,d6
.mapfill:
	move.w  #0x00,(REG_VRAMRW)                 |Fill up with empty tiles
	nop
	move.w  #0,(REG_VRAMRW)
	dbra	d6,.mapfill
	dbra	d7,.mapsprs

	move.w  #SCB2+1,(REG_VRAMADDR)             |Set zooms
	move.l  #14,d7
.setzl:
	move.w  #0x0F00,(REG_VRAMRW)
	dbra	d7,.setzl

	move.w  #SCB3+1,(REG_VRAMADDR)             |SetY position and Y positions
	move.w  #((496-10)<<7)+4,(REG_VRAMRW)
	move.l  #14-1,d7
.setyl:
	move.w  #64+4,(REG_VRAMRW)
	dbra	d7,.setyl

	move.w  #SCB4+1,(REG_VRAMADDR)             |Set X position
	move.w  #48<<7,(REG_VRAMRW)
	rts

Ranges:
  dc.b  2,1,1                                      |Menu item ranges

.section .rodata
.global LogoPalettes

Logomap:
  .incbin "logomap.inc"
.align 4
Txt_Ver:
	dc.w  FIXMAP+(32*13)+9
	.string "NEOPEN BIOS 0.1"
.align 4
Txt_Regions:
	dc.w  FIXMAP+(32*9)+13
	.string "JAPAN\xFFUSA\xFF\EURO"
.align 4
Txt_Type:
	dc.w  FIXMAP+(32*17)+13
	.string "AES\xFFMVS"
.align 4
Txt_Dev:
	dc.w  FIXMAP+(32*25)+13
	.string "NORMAL\xFF\DEVMODE"
.align 4
Txt_SDSin:
	dc.w  FIXMAP+(32*8)+24
	.string "PRESS D TO SET SOFTDIPS\xFFPRESS C FOR CONFIG MENU"

.align 2
LogoPalettes:
        dc.w    0x7FFF,0x0999,0x0555,0x0333 | White
        dc.w    0x7F22,0x0911,0x0500,0x0300 | Red
        dc.w    0x72F2,0x0191,0x0050,0x0030 | Green
        dc.w    0x722F,0x0119,0x0005,0x0003 | Blue
        dc.w    0x7FF2,0x0991,0x0550,0x0330 | Yellow
        dc.w    0x72FF,0x0199,0x0055,0x0033 | Cyan
        dc.w    0x7F2F,0x0919,0x0505,0x0303 | Mangenta
        dc.w    0x7F42,0x0921,0x0510,0x0300 | Orange

.section .bss
.global P1_PREV
.global SETTINGS
.global PREV_CUR
.global CUR_LIST

SETTINGS:		.byte 0,0,0
CUR_LIST:		.byte 0
P1_PREV:		.byte 0
.align 2
PREV_CUR:		.word 0

