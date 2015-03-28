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

.global fix_clear
.global sprite_clear
.global vram_clear
.global palette_clear
.global text8_out
.global text16_out
.global text8_outdirect
.global text16_outdirect
.global wait_vsync
.global text8_outfixlen
.global text16_outfixlen
.global write_byte
.global write_byte16
.global	mess_out
.include "defines.inc"

/*! DEF palette_clear
    \brief Clears both palette banks to black
*/

palette_clear:
	move.b  d0,(REG_PALBANK0)
        lea     PALETTES,a0
	move.l  #((256*16*2)/4)-1,d0            |Clear palette bank 0
1:
	move.b  d0,(REG_DIPSW)
        move.l  #0,(a0)+
        dbra    d0,1b
	move.b  d0,(REG_PALBANK1)
	lea     PALETTES,a0
	move.l  #((256*16*2)/4)-1,d0            |Clear palettes bank 1
1:
	move.b  d0,(REG_DIPSW)
        move.l  #0,(a0)+
        dbra    d0,1b
        rts

/*! DEF fix_clear
    \brief Clear the FIX part of the VRAM with tile D0
*/

fix_clear:
        move.b  #0xFF,(0x10FCEF)        | Makes games such as mslug5 pass the slot test (SP-S2 does this)
	movea.l	#REG_VRAMRW, a0		| Set a0 to VRAM_RW
	move.w	#1, 2(a0)		| VRAM_INC to 1
	move.w	#0x7020, -2(a0)
	move.w	#0xFF, d0
	move.w	#0x4BF, d1
	bsr	vram_write
	move.w	#0x20, d0
	move.w	#0x1F, d1
	bsr	vram_write
	move.w	#0x7000, -2(a0)
	move.w	#0x1F, d1
	bsr	vram_write
	rts

/*! DEF sprite_clear
    \brief Clear the SPRITE part of the VRAM
*/

sprite_clear:
	movea.l	#REG_VRAMRW,a0
	move.w	#1,2(a0)
	move.w	#0x8000,-2(a0)
	move.w	#0xFFF, d0
	move.w	#0x1FF, d1
	jsr	vram_write

	moveq	#0, d0
	move.w	#0x1FF, d1
	jsr	vram_write

	move.w	#0xBE00, d0
	move.w	#0x1FF, d1
	jsr	vram_write

	move.w	#0,-2(a0)
	move.w	#0xFF, d0
	move.w	#2, 2(a0)
	moveq	#0x1F, d1
	jsr	vram_write
	rts

/*! DEF vram_write
    \brief Write a value to the VRAM
    \param a0 must contain REG_VRAMRW
    \param d0 contain the value to write
    \param d1 contain the number of times to write the value
*/

vram_write:
        move.b  d0,(REG_DIPSW)
	move.w	d0, (a0)
	dbf	d1, vram_write
	rts

vram_clear:
	movea.l	#REG_VRAMRW,a0
	move.w	#1,2(a0)
	move.w	#0x0000,d0
	move.w	#0xFFFF,d1
	bra	vram_write
	
/*! DEF mess_out
    \brief TODO
*/

mess_out:
	rts


/*! DEF text16_out
    \brief Writes fix text with the 16px font, 0xFF is newline, 0x00 ends
    \param a0 contains a pointer to the position (word address) and string
    \param d2 is the palette to use (in the last 4 bits)
*/

text16_out:
        move.w  (a0)+,d1
text16_outdirect:
	move.w  d1,(REG_VRAMADDR)
2:
	clr.w   d0
	move.b  (a0)+,d0
	beq	1f
	cmp.b   #0xFF,d0
	bne	 3f
	addq.w  #2,d1
	bra	 text16_outdirect
3:
        move.b  d0,(REG_DIPSW)
	add.w   #0x100,d0
	move.w  #1,(REG_VRAMMOD)
	or.w    d2,d0
	move.w  d0,(REG_VRAMRW)
	nop
	move.w  #31,(REG_VRAMMOD)
	add.w   #0x100,d0
	move.w  d0,(REG_VRAMRW)
	bra	2b
1:
	rts

/*! DEF text8_out
    \brief Writes fix text with the 8px font, 0xFF is newline, 0x00 ends
    \param a0 contains a pointer to the position (word address) and string
    \param d2 is the palette to use (in the last 4 bits)
*/

text8_out:
	move.w  (a0)+,d1
text8_outdirect:
1:
	move.w  d1,(REG_VRAMADDR)
2:
	clr.w   d0
	move.b  (a0)+,d0
	beq	 1f
	cmp.b   #0xFF,d0
	bne	 3f
	addq.w  #1,d1
	bra	 1b
3:
        move.b  d0,(REG_DIPSW)
	move.w  #32,(REG_VRAMMOD)
	nop
	or.w    d2,d0
        move.w  d0,(REG_VRAMRW)
	bra	 2b
1:
	rts
	
/*! DEF text8_outfixlen
    \brief Writes fixed length fix text with the 8px font
    \param a0 contains a pointer to the text
    \param d1 si the VRAM address where to start writing
    \param d2 is the palette to use (in the last 4 bits)
    \param d7 is the text's length
*/

text8_outfixlen:
        move.w   #1,REG_VRAMMOD
        subq.w   #1,d7
1:
        move.w   d1,REG_VRAMADDR
        moveq.l  #0,d0
        move.b   (a0)+,d0
        or.w     d2,d0                  | Palette/tileset
        move.w   d0,REG_VRAMRW
        addi.w   #32,d1
        dbra     d7,1b
        rts

/*! DEF text16_outfixlen
    \brief Writes fixed length fix text with the 16px font
    \param a0 contains a pointer to the text
    \param d1 si the VRAM address where to start writing
    \param d2 is the palette to use (in the last 4 bits)
    \param d7 is the text's length
*/

text16_outfixlen:
        move.w   #1,REG_VRAMMOD
        subq.w   #1,d7
1:
        move.w   d1,REG_VRAMADDR
        moveq.l  #0,d0
        move.b   (a0)+,d0
        or.w     d2,d0                  | Palette/tileset
        ori.w    #0x0100,d0
        move.w   d0,REG_VRAMRW          | Top tile
        addi.w   #0x0100,d0
        move.w   d0,REG_VRAMRW          | Bottom tile
        addi.w   #32,d1
        dbra     d7,1b
        rts
        
/*! write_byte
    \brief Writes byte in hex with the 8x8 font
    \param d0 is the byte
    \param d2 is the palette to use
*/
write_byte:
    move.l  d1,-(a7)
    moveq.l #0,d1
    move.w  #0x20,(REG_VRAMMOD)
    move.b  d0,d1
    andi.b  #0xF0,d1
    lsr.b   #4,d1
    jsr     hexshift
    addi.w  #0x30,d1                   | ASCII offset
    or.w    d2,d1                      | Palette
    move.w  d1,(REG_VRAMRW)            | LSB high nibble

    move.b  d0,d1
    andi.b  #0x0F,d1
    jsr     hexshift
    addi.w  #0x30,d1                   | ASCII offset
    or.w    d2,d1                      | Palette
    move.w  d1,(REG_VRAMRW)            | LSB low nibble
    move.l  (a7)+,d1
    rts

hexshift:
    cmp.b   #0xA,d1
    blt.b   r
    addq.w  #7,d1
r:
    rts

/*! write_byte16
    \brief Writes byte in hex with the 8x16 font
    \param d0 is the byte
    \param d2 is the palette to use
*/
write_byte16:
    move.l  d1,-(a7)
    moveq.l #0,d1
    move.w  #0x1,(REG_VRAMMOD)
    move.b  d0,d1
    andi.b  #0xF0,d1
    lsr.b   #4,d1
    jsr     hexshift
    addi.w  #0x130,d1                  | ASCII offset
    or.w    d2,d1                      | Palette
    move.w  d1,(REG_VRAMRW)            | LSB high nibble
    addi.w  #0x100,d1
    move.w  #0x1F,(REG_VRAMMOD)
    move.w  d1,(REG_VRAMRW)

    move.w  #0x1,(REG_VRAMMOD)
    move.b  d0,d1
    andi.b  #0x0F,d1
    jsr     hexshift
    addi.w  #0x130,d1                  | ASCII offset
    or.w    d2,d1                      | Palette
    move.w  d1,(REG_VRAMRW)            | LSB low nibble
    addi.w  #0x100,d1
    move.w  #0x1F,(REG_VRAMMOD)
    move.w  d1,(REG_VRAMRW)
    move.l  (a7)+,d1
    rts

/*! DEF wait_vsync
    \brief Wait till the next vsync
*/
wait_vsync:
	move.b	#1, (VSYNC_FLAG)
1:
	tst.b	(VSYNC_FLAG)
	bne.s	1b
	rts
