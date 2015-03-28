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

/* $Id: header.s,v 1.34 2011/11/12 10:02:40 elbarto Exp $ */

.global	START
.global HBLANK
.global VBLANK

.text

.include "defines.inc"

.org    0

Vectors:
	dc.l	0x10F300
	dc.l	0xC00402
	dc.l	err_bus
	dc.l	err_addr
	dc.l	err_illegal
	dc.l	err_divzero
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	VBLANK
	dc.l	HBLANK
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START
	dc.l	START

.org    0x100
        .string "ENPONEB OI S.0c1" | NEOPEN BIOS 0.1c

.org	0x402
	jmp	START
.org	0x408
	jmp	START
.org	0x40E
	jmp	START
.org	0x414
	jmp	START
.org	0x41A
	jmp	START
.org	0x420
	jmp	START
.org	0x426
	jmp	START
.org	0x42C
	jmp	START
.org	0x432
	jmp	START

.org	0x438
	jmp	VBLANK
.org	0x43E
	jmp	HBLANK

.org	0x444
	jmp	system_return
.org	0x44A
	jmp	system_io

.org	0x450
	jmp	credit_check
.org	0x456
	jmp	credit_down

.org	0x45C
	jmp	read_calendar
.org	0x462
	jmp	setup_calendar

.org	0x468
	jmp	card
.org	0x46E
	jmp	card_error

.org	0x474
	jmp	how_to_play
.org	0x47A
	jmp	START

.org	0x480
	jmp	null
.org	0x486
	jmp	null
.org	0x48C
	jmp	null
.org	0x492
	jmp	null
.org	0x498
	jmp	null
.org	0x49E
	jmp	null
.org	0x4A4
	jmp	null
.org	0x4AA
	jmp	null
.org	0x4B0
	jmp	null
.org	0x4B6
	jmp	null
.org	0x4BC
	jmp	null

.org	0x4C2
	jmp	fix_clear
.org	0x4C8
	jmp	sprite_clear
.org	0x4CE
	jmp	mess_out
.org	0x4D4
	jmp	check_mahjong_controller

null:
	rts

waitnop:
	bsr	2f
	bsr	1f
2:
	bsr	1f
	bsr	1f
1:
        nop
        nop
        nop
        nop
        nop
        nop
	rts


START:
        move	#0x2700, sr
	move.b	d0,(REG_WATCHDOG)
	move.w	#7,(REG_IRQACK)
        move.w  #0x4000,REG_LSPCMODE
        lea     0x10F300,a5

	|Testing on real HW
	move.b	#0xFF,(0x380031)
	bsr	waitnop
	move.b	#0xFF,(0x380041)
	move.b	#0xF7,(0x380031)
	bsr	waitnop
	move.b	#0xFF,(0x380031)
	bsr	waitnop
	move.b	#0xEF,(0x380031)
	bsr	waitnop
	move.b	#0xFF,(0x380031)
	bsr	waitnop
	move.b	#0xDF,(0x380031)
	bsr	waitnop
	move.b	#0xFF,(0x380031)
	move.b	d0,(0x3A0003)
	move.b	d0,(0x3A000B)
	move.b	d0,(0x380065)
	move.b	d0,(0x380067)

	|Testing on real HW
	move.l  #0xFFFFFFF,d7
.wait:
	move.b	d0,(REG_WATCHDOG)
        nop
        nop
        nop
        nop
        nop
        nop
        dbra    d7,.wait

	|Testing on real HW
	move.w  #0x7FFF,d7
	move.w  #1,(REG_VRAMMOD)
	move.w  #0,(REG_VRAMADDR)
.clvram:
	move.b	d0,(REG_WATCHDOG)
        move.w  #0,(REG_VRAMRW)
        nop
        dbra    d7,.clvram

	move	#0x2000, sr                 | Enable interrupts
	move.b	#3,(REG_SOUND)              | Reset Z80
	bsr	wait_vsync
	move	#0x2700, sr                 | Disable interrupts

        move.b  d0,(REG_SWPBIOS)
        move.b  d0,(REG_BRDFIX)
        move.b  d0,(REG_NOSHADOW)
	move.b	#0x0,(BIOS_SYSTEM_MODE)     | Set to SYSTEM_MODE

        jsr     fix_clear
        jsr     palette_clear

/*	Clear the whole RAM */
	move.l  #(0xFFFF/4)-1,d7
	lea	 RAMSTART,a0
1:
	clr.l   (a0)+
	move.b  d0,REG_DIPSW
	dbra	d7,1b

/*	Copy .data section into the ram */
	lea	_text_end, a0
	lea	0x10F300, a1
	move.l	#_data_size, d0
	beq	skip_data
1:
	move.w	(a0)+, (a1)+
	move.b  d0,REG_DIPSW
	dbra	d0, 1b

skip_data:
/*	Zeroing the .bss section */
	move.l	#_bss_size, d0
	beq	skip_bss
1:
	move.w	#0x0, (a1)+
	move.b  d0,REG_DIPSW
	dbra	d0, 1b
skip_bss:

        |Skip for debug purposes, must leave this later !
        |jsr     selfcheck                 | Checksum check

	move.w  #0x2000,sr                | Enable interrupts
	jsr     wait_vsync

/*      Shortcuts */
        move.b  REG_P1CNT,d0
	and.b   #0x30,d0                  | A+B buttons: quickboot
        bne     1f
        jmp     init_game
1:
        move.b  REG_DIPSW,d0
        btst.b  #0,d0                     | DIPSW1: HW test
        bne     1f
        jmp     hardware_test
1:
	jsr	test_sram
        jsr     setup_bootmenu

Loop:
	bra	Loop

HBLANK:
        movem.l	d0-a6, -(sp)
        jsr     hblank_palette
	move.w	#0x2, (REG_IRQACK)
	movem.l	(sp)+,d0-a6
	rte

VBLANK:
	move.w	#0x4, (REG_IRQACK)
	move.b	d0, (REG_WATCHDOG)
	clr.b	(VSYNC_FLAG)
        tst.b	(0x10FEE3)                | ?
	bne 	3f
	movem.l	d0-a6, -(sp)
	jsr	system_io                 | Do player input stuff

	tst.b	(BIOS_SYSTEM_MODE)
	bne	1f                        | System mode
        tst.l   VBL_HANDLER
        beq     1f
        movea.l VBL_HANDLER,a0
        jsr     (a0)
1:

	movem.l	(sp)+, d0-a6
3:
	addq.b	#1, (BIOS_FRAME_COUNTER)
	rte

.global VBL_HANDLER
.global MENU_MODE
.global CALLBACK
.section .bss
VBL_HANDLER:		.long 0
CALLBACK:               .long 0
MENU_MODE:              .byte 0
