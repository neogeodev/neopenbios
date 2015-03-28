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

/* $Id: sram.s,v 1.3 2011/11/15 18:24:52 furrtek Exp $ */

.include "defines.inc"
	
.global test_sram

test_sram:
	movea.l	#0xD00010, a0
	lea	str_backupramok, a1
	move.l	#0xF, d0
1:
	cmp.b	(a0)+, (a1)+
	bne	init_sram		| If string isn't here, backupram must be init
	dbra	d0, 1b
	movea.l	#0xD00000, a0
	lea	str_neopenbiosok, a1
	move.l	#0xF, d0
1:
	cmp.b	(a0)+, (a1)+
	bne	init_sram		| Not a neopenbios compliant backupram
	dbra	d0, 1b
	rts

init_sram:
        move.b	#0, (REG_SRAMUNLOCK)
	movea.l	#0xD00000, a0
	lea	str_neopenbiosok, a1
	move.l	#0x1E, d0
1:	
	move.b	(a1)+, (a0)+
	dbra	d0, 1b
	move.w	#0x7FFF, (SRAM_FIRSTCOLOR)
	move.w	#0x7888, (SRAM_SECONDCOLOR)
	move.w	#0x4F00, (SRAM_THIRDCOLOR)
	move.b  #0, (SRAM_LOGOCOLOR)
	lea     SRAM_CUSTOMMESSAGE, a0
	lea	str_defaultmessage, a1
	move.l	#0x10-1, d0
1:	
	move.b	(a1)+, (a0)+
	dbra	d0, 1b
	move.b	#0, (REG_SRAMLOCK)
	rts

.section .rodata
.align 4
str_neopenbiosok:
	.string "NEOPENBIOS v0.1"
str_backupramok:
	.string "BACKUP RAM OK!\x80"
str_defaultmessage:
        .string "I love NeoGeo   "
