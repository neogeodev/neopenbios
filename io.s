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

/* $Id: io.s,v 1.16 2011/11/09 14:38:00 elbarto Exp $ */

.global joy_read
.global check_start
.global check_mahjong_controller

.include "defines.inc"

/*! DEF joy_read
    \brief Read the P1 and P2 controller and put value in BIOS RAM
*/

joy_read:
	bsr	read_start
	movea.l	#INPUT_1, a0
	movea.l	#REG_P1CNT, a1
	bsr	read_port
	movea.l	#INPUT_2, a0
	movea.l	#REG_P2CNT, a1
	bsr	read_port
	rts

read_start:
	move.b	(REG_STATUS_B), d0      | (Reads only P1 & P2 starts)
        move.b  (PREV_SS),d1
	not.b   d0
	and.b	#0xF, d0
	move.b	d0,(INPUT_S)
	move.b	d0,(PREV_SS)
	eor.b   d0,d1
	and.b   d0,d1
	move.b  d1,(INPUT_S+1)
	bsr	check_pause
	rts

read_port:
	move.b	#1, (a0)		| Status Set to normal controller (TOFIX)
       	move.b  (a1),d0                 | save actual HW read
	move.b  2(a0),d1                | get previous
	not.b   d0                      | invert HW read
       	move.b  d0,1(a0)                | set actual
	move.b  d0,2(a0)                | set previous=actual
	eor.b   d0,d1                   | keep difference
	and.b   d0,d1                   | keep only rising edge
	move.b  d1,3(a0)                | set rising edge
	rts

check_pause:
	move.b	(INPUT_S+1), d0
	btst	#2, d0
	beq	2f
	btst	#7, (BIOS_SYSTEM_MODE)
	beq	1f
	move.b	#0x0, (BIOS_SYSTEM_MODE)
	jmp	2f
1:
	move.b	#0x80, (BIOS_SYSTEM_MODE)
2:
	rts

/*! DEF check_start
    \brief Check if start buttons have been pressed, if yes call the START routine of the game
*/
check_start:
	btst.b	#0, (INPUT_S+1)
	beq	1f
	tst.b	(SRAM_COIN1)		| Test if player 1 have enought credits
	beq	1f
	bset.b	#0, (BIOS_START_FLAG)   | Player 1 pushed start
	move.b	(SRAM_COIN1), d0
	moveq	#1, d1
	sbcd	d1, d0
	move.b	d0, (SRAM_COIN1)
1:
	btst.b	#2, (INPUT_S+1)
	beq	1f
	tst.b	(SRAM_COIN2)		| Test if player 1 have enought credits
	beq	1f
	bset.b	#1, (BIOS_START_FLAG)   | Player 2 pushed start
	move.b	(SRAM_COIN2), d0
	moveq	#1, d1
	sbcd	d1, d0
	move.b	d0, (SRAM_COIN2)
1:
        tst     (BIOS_START_FLAG)
        beq     1f
	move.b	#2, (BIOS_USER_REQUEST) | Game mode
	jmp	(PLAYER_START)
1:
	rts

check_mahjong_controller:
	rts
.section .bss
PREV_SS:		.byte 0
