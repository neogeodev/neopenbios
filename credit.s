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

.global credit_check
.global credit_down
.global check_coin

/*! DEF check_coin
    \brief Checks if coins have been deposited and increments credits if so
*/

check_coin:
       	move.b  (REG_STATUS_A),d0      | save actual HW read
	move.b  (PREV_COIN),d1         | get previous
	not.b   d0                     | invert HW read
	move.b  d0,(PREV_COIN)         | set previous=actual
	eor.b   d0,d1                  | keep difference
	and.b   d0,d1                  | keep only rising edge
	andi.w	#0x3, d1
        btst.b  #0,d1			| Coin 1
        beq     1f
	move.b	(SRAM_COIN1), d0
	abcd    d1, d0
	move.b	d0, (SRAM_COIN1)
        jsr     (COIN_SOUND)
1:
	btst.b	#1, d1			| Coin 2
	beq	1f
	moveq	#1, d1
	move.b	(SRAM_COIN1), d0
	abcd    d1, d0
	move.b	d0, (SRAM_COIN1)
        jsr     (COIN_SOUND)	
1:
        rts


credit_check:
	tst.b	(BIOS_MVS_FLAG)
	beq	1f
	move.b	(REG_DIPSW), d0
	and.b	#0x40, d0
	beq	1f
	movea.l	CREDIT_DEC_P1, a0
	move.b	(SRAM_COIN1), (CREDIT_DEC_P1)
	move.b	(SRAM_COIN2), (CREDIT_DEC_P2)
1:
	rts

credit_down:
	rts

.section .bss
PREV_COIN:		.byte 0
