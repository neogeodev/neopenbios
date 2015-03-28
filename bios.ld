/*
 * Copyright (c) 2011 Emmanuel Vadot <elbarto@neogeodev.org>
 * Copyright (c) 2011 Sean Gonsalves <furrtek@neogeodev.org>
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

/* $Id: bios.ld,v 1.5 2011/09/30 14:51:50 elbarto Exp $ */

OUTPUT_ARCH(m68k)
__DYNAMIC  =  0;

MEMORY
{
	rom : ORIGIN = 0x00C00000, LENGTH = 0x00020000
	ram : ORIGIN = 0x0010F300, LENGTH = 0x000F0D00
}

PROVIDE (__stack = 0x0010F300);

SECTIONS
{
  .text 0x00C00000:
  {
    *(.text)
    . = ALIGN(0x4);
    *(.rodata)
    . = ALIGN(0x4);
    _text_end = .;
  } > rom

  .data 0x0010F300:
  AT (ADDR(.text) + SIZEOF(.text) )
  {
  *(.shdata)
  *(.data)
  } > ram
  _data_size = SIZEOF(.data);

  .bss 0x0010F300 + SIZEOF(.data):
  {
  *(.shbss)
  *(.bss)
  } > ram
  _bss_size = SIZEOF(.bss);
}
