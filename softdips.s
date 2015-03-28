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

.global setup_softdips
.global vblank_softdips

setup_softdips:
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

        clr.w   d2                        | Write fixed text
       	lea	Txt_SDS,a0
	jsr	text16_out
	move.w  #0x1000,d2
	lea     Txt_SDSQuit,a0
	jsr	text16_out
	
	jsr     sram_to_softdips          | Write saved softdips to BIOS RAM

	/* Write ROM game name */
	lea     0x11A,a0
        movea.l (a0),a0
        move.w   #FIXMAP+(32*3)+8,d1
        move.w   #0x1000,d2
        move.w   #16,d7
        jsr      text16_outfixlen

        /* Write menu items and build ITEMLIST */
	lea      0x11A,a0
        movea.l  (a0),a0
        movea.l  a0,a1
        adda.l   #16,a1                   | a1 points to item definitions
        adda.l   #32,a0                   | a0 points to strings
        lea      BIOS_GAME_DIP,a2         | a2 points to values of softdips in RAM

        move.w   #FIXMAP+(32*7)+11,d3     | VRAM start for writing items
        move.w   #0x1000,d2               | Use palette 1
        clr.b    (MAX_ITEMS)
        
        lea      ITEMLIST,a2

        /* Special items */
        move.w   (a1)+,d0                 | Timed option 1 (29:59)
        cmp.w    #0xFFFF,d0
        beq      1f
        move.w   d3,d1
        move.w   #12,d7                   | String is always 12 chars long
        jsr      text8_outfixlen
        add.w    #1,d3                    | Next line
        move.b   #0,(a2)+
        addq.b   #1,(MAX_ITEMS)
1:
        move.w   (a1)+,d0                 | Timed option 2 (29:59)
        cmp.w    #0xFFFF,d0
        beq      1f
        move.w   d3,d1
        move.w   #12,d7                   | String is always 12 chars long
        jsr      text8_outfixlen
        add.w    #1,d3                    | Next line
        move.b   #2,(a2)+
        addq.b   #1,(MAX_ITEMS)
1:
        move.b   (a1)+,d0                 | 1~99 option
        cmp.b    #0xFF,d0
        beq      1f
        move.w   d3,d1
        move.w   #12,d7                   | String is always 12 chars long
        jsr      text8_outfixlen
        add.w    #1,d3                    | Next line
        move.b   #4,(a2)+
        addq.b   #1,(MAX_ITEMS)
1:
        move.b   (a1)+,d0                 | 0~100 option
        cmp.b    #0xFF,d0
        beq      1f
        move.w   d3,d1
        move.w   #12,d7                   | String is always 12 chars long
        jsr      text8_outfixlen
        add.w    #1,d3                    | Next line
        move.b   #5,(a2)+
        addq.b   #1,(MAX_ITEMS)
1:

        /* Simple items */

        move.b   #6,d4
dispsimpleitems:
        move.b   (a1),d0
        tst.b    d0
        beq      1f                       | End of item definitions

        move.w   d3,d1
        move.w   #0x1000,d2
        move.w   #12,d7
        jsr      text8_outfixlen
        add.w    #1,d3

        clr.w    d0
        move.b   (a1)+,d0
        andi.b   #0x0F,d0                 | Number of strings to skip
        mulu     #12,d0
        adda.l   d0,a0
        move.b   d4,(a2)+
        addq.b   #1,d4
        addq.b   #1,(MAX_ITEMS)
        bra      dispsimpleitems
1:

	subq.b   #1,(MAX_ITEMS)           | Max cursor value is number of items-1
	move.w   #FIXMAP,(PREV_CUR)
        move.l   #vblank_softdips,VBL_HANDLER

        rts




vblank_softdips:

        /* Joypad edge detection */
	move.b	(BIOS_P1CHANGE), d1

        /* Joypad button handling */
	btst	#0,d1
	beq	noup
	move.b  (CUR_SDIPS),d0
	beq	noup
	subq.b  #1,(CUR_SDIPS)            | Move cursor up if > 0
noup:

	btst	#1,d1
	beq	nodown
	move.b  (CUR_SDIPS),d0
	cmp.b   (MAX_ITEMS),d0
	beq	nodown
	addq.b  #1,(CUR_SDIPS)            | Move cursor down if < 4
nodown:

	btst	#5,d1
	beq	nob
	/* Get softdip number in list */
	lea     ITEMLIST,a0
	clr.l   d0
	move.b  (CUR_SDIPS),d0
	clr.l   d1
        move.b  0(a0,d0),d1
        cmp.b   #6,d1
        blo     nob                       | Skip if item number < 6 (special)
        /* Find limit */
	lea     0x11A,a0
        movea.l (a0),a0
        adda.l  #16,a0                    | a0 points to item definitions
        move.b  0(d1,a0),d0
        andi.b  #0x0F,d0
        subq.b  #1,d0                     | Max is number of options -1
        lea     BIOS_GAME_DIP,a0          | Get address in BIOS RAM
        cmp.b   0(d1,a0),d0
        bls     nob
	addq.b  #1,0(d1,a0)               | Increment if lower than limit
nob:

	btst	#4,d1
	beq	noa
	/* Get softdip number in list */
	lea     ITEMLIST,a0
	clr.l   d0
	move.b  (CUR_SDIPS),d0
	clr.l   d1
        move.b  0(a0,d0),d1
        cmp.b   #6,d1
        blo     noa                       | Skip if item number < 6 (special)
        lea     BIOS_GAME_DIP,a0          | Get address in BIOS RAM
        tst.b   0(d1,a0)
        beq     noa
	subq.b  #1,0(d1,a0)               | Decrement if higher than 0
noa:

	btst	#6,d1
	beq	noc
        /* Save to SRAM and exit to bootmenu */
        jsr     softdips_to_sram
        bra     setup_bootmenu
noc:

        /* Display cursor */
	move.w  (PREV_CUR),d0             | Erase previous cursor
	move.w  d0,(REG_VRAMADDR)
	nop
	move.w  #0x00FF,(REG_VRAMRW)

	clr.l   d0
	move.w  #FIXMAP+(32*5)+11,d0      | Y offset
	add.b  (CUR_SDIPS),d0
	move.w  d0,(PREV_CUR)
	move.w  d0,(REG_VRAMADDR)
	move.w  #0x2011,d1	          | > arrow tile palette 2
	move.w  d1,(REG_VRAMRW)

	/* Display special values */
	lea      0x11A,a0
        movea.l  (a0),a0
        movea.l  a0,a1
        adda.l   #16,a1                   | a1 points to item definitions
        adda.l   #32,a0                   | a0 points to strings

        move.w   #FIXMAP+(32*20)+11,d3    | VRAM start for writing values
        move.w   #0x1000,d2               | Use palette 1

        move.w   (a1)+,d0                 | Timed option 1
        cmp.w    #0xFFFF,d0
        beq      1f
        |TODO: Display value
        jsr      writetime
        add.w    #1,d3                    | Next line
        adda.l   #12,a0
1:
        move.w   (a1)+,d0                 | Timed option 2
        cmp.w    #0xFFFF,d0
        beq      1f
        |TODO: Display value
        jsr      writetime
        add.w    #1,d3                    | Next line
        adda.l   #12,a0
1:
        move.b   (a1)+,d0                 | 1~99 option
        cmp.b    #0xFF,d0
        beq      1f
        |TODO: Display value
        move.w   d3,(REG_VRAMADDR)
        move.b   (BIOS_GAME_DIP+4),d0
        jsr      write_byte
        add.w    #1,d3                    | Next line
        adda.l   #12,a0
1:
        move.b   (a1)+,d0                 | 0~100 option
        cmp.b    #0xFF,d0
        beq      1f
        |TODO: Display value
        move.w   d3,(REG_VRAMADDR)
        move.b   (BIOS_GAME_DIP+5),d0
        jsr      write_byte
        add.w    #1,d3                    | Next line
        adda.l   #12,a0
1:
        adda.l   #12,a0                   | Skip one last string

        /* Display simple values */
	lea      BIOS_GAME_DIP+6,a2       | a2 points to values of softdips in RAM

        move.w   #0x1000,d2               | Use palette 1

        move.l   #10-1,d6
dispsimplevalues:
        move.b   (a1),d0                  | End of list if item def is 0x00
        beq      1f
        clr.l    d0
        move.b   (a2),d0
        mulu     #12,d0                   | Find string location according to set value
        adda.l   d0,a0
        move.w   d3,d1
        move.w   #0x1000,d2
        move.l   #12,d7
        jsr      text8_outfixlen
        add.w    #1,d3                    | Next line
        clr.l    d0
        move.b   (a1)+,d0
        andi.b   #0x0F,d0                 | Number of next strings to skip:
        sub.b    (a2)+,d0                 | Total-Value
        mulu     #12,d0
        adda.l   d0,a0
        dbra     d6,dispsimplevalues
1:
        rts
        
        
writetime:
        move.w   d3,(REG_VRAMADDR)
        move.b   (BIOS_GAME_DIP),d0
        jsr      write_byte
        move.w   #'m'+0x1000,(REG_VRAMRW)
        move.w   d3,d0
        addi.w   #32*3,d0
        move.w   d0,(REG_VRAMADDR)
        move.b   (BIOS_GAME_DIP+1),d0
        jsr      write_byte
        move.w   #'s'+0x1000,(REG_VRAMRW)
        rts

.section .rodata
.align 4
Txt_SDS:
	dc.w  FIXMAP+(32*21)+8
	.string "SOFTDIP SETTINGS"
.align 4
Txt_SDSQuit:
	dc.w  FIXMAP+(32*8)+24
	.string "PRESS C TO SAVE AND EXIT"

.section .bss
CUR_SDIPS:		.byte 0           | Selected menu item
CUR_TIME:               .byte 0           | 0=minutes 1=seconds
MAX_ITEMS:              .byte 0           | Cursor's max value
ITEMLIST:               .fill 16,1,0      | List of items, corresponding to the number of softdip setting (0~15)
