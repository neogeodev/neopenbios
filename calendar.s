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

/* $Id: calendar.s,v 1.3 2011/11/08 02:59:14 furrtek Exp $ */

.global read_calendar
.global setup_calendar

read_calendar:
/* Sets possible values, just to be sure no games check this */
        lea     0x10FDD2,a0
        move.b  #0x99,(a0)+     | Year
        move.b  #0x01,(a0)+     | Month
        move.b  #0x02,(a0)+     | Day
        move.b  #0x04,(a0)+     | Week day
        move.b  #0x09,(a0)+     | Hour
        move.b  #0x34,(a0)+     | Minute
        move.b  #0x55,(a0)      | Seconds
	rts

setup_calendar:
	rts
