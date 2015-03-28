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

.global  err_divzero
.global  err_addr
.global  err_illegal
.global  err_bus

ERRORBOX_X      =    10
ERRORBOX_Y      =     9

err_divzero:
    move.l  2(a7),(PCERROR)
    movem.l d0-d7/a0-a6,-(a7)
    lea     text_divzero,a0
    jmp     DispErr

err_addr:
    move.l  10(a7),(PCERROR)
    movem.l d0-d7/a0-a6,-(a7)
    lea     text_addr,a0
    jmp     DispErr

err_illegal:
    move.l  2(a7),(PCERROR)
    movem.l d0-d7/a0-a6,-(a7)
    lea     text_illegal,a0
    jmp     DispErr

err_bus:
    move.l  10(a7),(PCERROR)
    movem.l d0-d7/a0-a6,-(a7)
    lea     text_bus,a0
    jmp     DispErr


|Do not use a0 until first text8_out here
DispErr:
    move.b  d0,(REG_DIPSW)
    ori.w   #0x0700,sr

    |Def palette 15
    move.w  #BLACK,(BACKDROPCOLOR)
    move.w  #RED,(PALETTES+(15*32)+2)
    move.w  #0x0FB8,(PALETTES+(15*32)+4)
    |Def palette 14
    move.w  #BLACK,(BACKDROPCOLOR)
    move.w  #0x0400,(PALETTES+(14*32)+2)
    move.w  #0x0FB8,(PALETTES+(14*32)+4)
    
    move.w  #FIXMAP+ERRORBOX_Y+(ERRORBOX_X*32),d2
    move.l  #14,d1
    move.w  #0x20,(REG_VRAMMOD)
.clfixlperrout:
    move.w  d2,(REG_VRAMADDR)
    move.l  #20,d0
.clfixlperrin:
    move.w  #0xF320,(REG_VRAMRW)      | Palette $F, tile $320
    move.b  d0,(REG_DIPSW)
    dbra    d0,.clfixlperrin
    addi.w  #1,d2
    dbra    d1,.clfixlperrout

    move.w  #0xF000,d2
    jsr     text8_out
    lea     text_defs,a0
    move.w  #0xF000,d2
    jsr     text8_out

    move.l  #FIXMAP+ERRORBOX_Y+6+((ERRORBOX_X+1)*32),d3
    move.l  #8-1,d2
.printdataregs:
    move.w  d3,(REG_VRAMADDR)
    move.l  (a7)+,d0
    jsr     WriteRegister
    addi.w  #1,d3
    dbra    d2,.printdataregs

    move.l  #FIXMAP+ERRORBOX_Y+6+((ERRORBOX_X+11)*32),d3
    move.l  #7-1,d2
.printaddrregs:
    move.w  d3,(REG_VRAMADDR)
    move.l  (a7)+,d0
    jsr     WriteRegister
    addi.w  #1,d3
    dbra    d2,.printaddrregs

    move.w  #FIXMAP+ERRORBOX_Y+3+((ERRORBOX_X+4)*32),(REG_VRAMADDR)
    move.l  (PCERROR),d0
    jsr     WriteRegister
lp:
    move.b  d0,(REG_DIPSW)
    jmp lp


WriteRegister:
    move.w  #0x20,(REG_VRAMMOD)
    move.l  d0,d1
    move.l  #8-1,d7
.writerlp:
    move.b  d0,(REG_DIPSW)
    andi.l  #0xF0000000,d0
    rol.l   #4,d0
    jsr     hexshift
    addi.w  #0x30,d0
    ori.w   #0xE000,d0                 |Palette $E
    move.w  d0,(REG_VRAMRW)
    lsl.l   #4,d1
    move.l  d1,d0
    dbra    d7,.writerlp
    rts

hexshift:
    cmp.b   #0xA,d0
    blt.b   .r
    addq.w  #7,d0
.r:
    rts

.align 2
text_defs:
    dc.w FIXMAP+ERRORBOX_Y+3+((ERRORBOX_X+1)*32)
    .string "PC:\xFF\xFF\D0-D6:    A0-A6:"
.align 2
text_addr:
    dc.w FIXMAP+ERRORBOX_Y+1+((ERRORBOX_X+1)*32)
    .string "ADDRESS ERROR\0"
.align 2
text_divzero:
    dc.w FIXMAP+ERRORBOX_Y+1+((ERRORBOX_X+1)*32)
    .string "DIVIDE BY ZERO\0"
.align 2
text_illegal:
    dc.w FIXMAP+ERRORBOX_Y+1+((ERRORBOX_X+1)*32)
    .string "ILLEGAL INSTRUCTION\0"
.align 2
text_bus:
    dc.w FIXMAP+ERRORBOX_Y+1+((ERRORBOX_X+1)*32)
    .string "BUS ERROR\0"

.bss
PCERROR:    .long 0
