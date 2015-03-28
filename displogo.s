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

/* $Id: displogo.s,v 1.3 2011/10/27 10:46:17 furrtek Exp $ */

.include "defines.inc"

.global displogo_map
.global displogo_ms2

displogo_map:
/* Display fix logo of game, palette at (a0), map/sizes at (a0+4) */
        move.b  d0,(REG_CRTFIX)

        movea.l  (a0)+,a1
        lea      PALETTES+(32*0xF),a2
        move.l   #16-1,d7
1:
        move.w   (a1)+,(a2)+
        dbra     d7,1b

        movea.l  (a0)+,a1
        move.w   #FIXMAP+(32*4)+21,d1
        move.w   #32,REG_VRAMMOD
        moveq.l  #0,d2
        moveq.l  #0,d3
        move.w   (a1)+,d2       | Height
        move.w   (a1)+,d3       | Width
2:
        move.w   d1,REG_VRAMADDR
        move.l   d3,d4
3:
        move.w   (a1)+,d0
        ori.w    #0xF000,d0
        move.w   d0,REG_VRAMRW
        dbra     d4,3b
        dbra     d2,2b
        rts
