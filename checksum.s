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

/* $Id: checksum.s,v 1.4 2011/11/08 02:59:14 furrtek Exp $ */

.include "defines.inc"

.global selfcheck

selfcheck:
/*      Checksum verification */
        clr.l   d2
        clr.w   d0
        lea     0xC00000,a0
        move.l  #0x80-1,d1
1:
        move.b  (a0)+,d0
        add.w   d0,d2
        dbra    d1,1b                     | First 80 bytes

        lea     0xC00082,a0
        move.l  #0x20000-0x82-1,d1
1:
        move.b  (a0)+,d0
        add.w   d0,d2
        dbra    d1,1b                     | Rest

        cmp.w   (0xC00080),d2
        beq     2f

        move.b   d0,(REG_DIPSW)
	move.w   #BLACK,(PALETTES+(32*1)+0)	   | Text palette 1
	move.w   #WHITE,(PALETTES+(32*1)+2)
	move.w   #BLACK,(PALETTES+(32*2)+0)	   | Text palette 2
	move.w   #RED,(PALETTES+(32*2)+2)
        move.w   #0x2000,d2
       	lea	 Warn1,a0
	jsr	 text16_out
        move.w   #0x1000,d2
       	lea	 Warn2,a0
	jsr	 text8_out
1:
        move.b   d0,(REG_DIPSW)           | Display error message and stay in loop
        bra      1b
2:
        rts

 .section .rodata
.align 4
Warn1:
        dc.w  FIXMAP+(32*4)+10
        .string "ERROR: BIOS CHECKSUM FAIL"
.align 4
Warn2:
        dc.w  FIXMAP+(32*4)+13
        .string "The BIOS code has been found\xFFto be invalid.\xFFThis can lead to errors and/or\xFF\data loss.\xFF\xFFPlease refer to a qualified\xFFtechnician for BIOS replacement\xFFor hardware repair."
