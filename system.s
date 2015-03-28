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

.global	system_return
.global system_io
.global boot_game
.global init_game
.global init_softdips
.global sram_to_softdips
.global softdips_to_sram

system_return:
        move.b   #1,(0x10FEE1)
        cmp.b    #1,(BIOS_USER_REQUEST)   | Start game if return from command 1 (logo display)
        beq      1f
        tst.b    (BIOS_USER_REQUEST)
        bne      2f
	cmp.b    #1,(FLAG_EYECATCH)
	bne      1f
        move.b   #1,(BIOS_USER_REQUEST)
        clr.l    VBL_HANDLER
        jsr      fix_clear
	jmp     jumpto_user               | Jump to logo display (command 1) if needed
1:
        jmp      boot_game                | Or start game directly
2:
	rts


system_io:
        move.b	d0,(REG_SRAMUNLOCK)
	jsr	joy_read
	tst.b	(BIOS_SYSTEM_MODE)        | Skip start, coin and freezing detection if in system mode
	beq     1f
        jsr	check_start
	jsr     check_coin
	jsr     check_freeze
1:
	move.b	d0,(REG_SRAMLOCK)

        move.b  (REG_P1CNT),d0
	and.b   #0xF0,d0                  | A+B+C+D buttons: Reset
        bne     1f
        move.b  #0,(REG_SWPBIOS)
        jmp     START
1:

        move.b  (REG_P1CNT),d0
	and.b   #0x70,d0                  | A+B+C buttons: In-game menu
        bne     1f
        cmp.b   #FLAG_INGAME,(MENU_MODE)
        beq     1f                        | Already in In-game menu ?
        move.b  #FLAG_INGAME,(MENU_MODE)
        move.l	#vblank_ingamemenu,VBL_HANDLER
	move.b  #0x00,(BIOS_SYSTEM_MODE)  | System mode
	jsr     setup_ingamemenu
1:
	rts

	
check_freeze:
/* Freeze dipswitch */
        btst.b  #7,(REG_DIPSW)
        bne     2f
        move.w  sr,d1                     | Save SR
        move.w  #0x2700,sr                | Disable interrupts
1:
        move.b	d0, (REG_WATCHDOG)
        btst.b  #7,(REG_DIPSW)            | Sit in loop until freeze off
        beq     1b
        move.w  d1,sr                     | Restore SR
2:      
        rts


softdips_to_sram:
	move.b	d0,(REG_SRAMUNLOCK)
        lea      BIOS_GAME_DIP,a0        | Save softdips to 0xD00220
        lea      0xD00220,a1
        move.l   #16-1,d1
1:
        move.b   (a0)+,(a1)+
        dbra     d1,1b
	move.b	d0,(REG_SRAMLOCK)
        rts

sram_to_softdips:
        lea      BIOS_GAME_DIP,a1        | Load softdips from 0xD00220
        lea      0xD00220,a0
        move.l   #16-1,d1
1:
        move.b   (a0)+,(a1)+
        dbra     d1,1b
        rts


init_game:
        movea.l 0x00011E,a0
        lea     0xD002A0,a1
        move.l  #16-1,d1
1:
	move.b  d0,(REG_DIPSW)
        cmpm.b  (a0)+,(a1)+
        beq     2f
        jsr     init_softdips      | Init softdips if last game played != current game
        bra     1f
2:
        dbra    d1,1b
        jsr     sram_to_softdips   | Restore them if same game
1:
        clr.b   (BIOS_USER_REQUEST)
	move.b  #0x00,(BIOS_SYSTEM_MODE)        |System mode
	|Here should be other init stuff, see NG.pdf USER "input" paragraph, same must go in boot_game
	lea     0x10F300,a7
	jmp     jumpto_user        | USER, command 0 (init backup-work area)


init_softdips:
        /* Initialise soft DIPs to default values */
        movea.l 0x00011E,a0        | Pointer to euro softdips menu layout
        adda.l  #16,a0             | Skip game name
        lea     BIOS_GAME_DIP,a1
        move.l  #6-1,d1            | First 6 values are copied directly
1:
        move.b  (a0)+,(a1)+
        dbra    d1,1b
        move.l  #10-1,d1           | Last 10 have the default val. in their upper nibble
1:
        move.b  (a0)+,d0
        lsr.b   #4,d0
        move.b  d0,(a1)+
        dbra    d1,1b
        
        jsr     softdips_to_sram   | Store everything in SRAM

        /* Write game name to SRAM */
	move.b	d0,(REG_SRAMUNLOCK)
        movea.l 0x00011E,a0
        lea     0xD002A0,a1
        move.l  #16-1,d1
1:
        move.b  (a0)+,(a1)+
        dbra    d1,1b
	move.b	d0,(REG_SRAMLOCK)
        rts


boot_game:
	clr.l   VBL_HANDLER
        jsr     fix_clear
        move.w  #0x2700,sr
	move.w  #7,(REG_IRQACK)

        move.b  #1,(REG_SOUND)                  |Put Z80 PC in RAM
1:
        move.b  d0,(REG_DIPSW)
        move.b  (REG_SOUND),d0                  |Wait for Z80 to be ready for rom swap
        subq.b  #1,d0
        bne     1b

	move.b  (SETTINGS),(BIOS_COUNTRY_CODE)
	move.b  (SETTINGS+1),(BIOS_MVS_FLAG)
	move.b  (SETTINGS+2),(BIOS_DEVMODE)
	move.b  #0,(REG_SLOT)
        move.w  #0x0020,d0                      | ?
	move.b	d0,(REG_SRAMUNLOCK)
	move.b	#0x0, (SRAM_COIN1)
	move.b	#0x0, (SRAM_COIN2)
	move.b	d0,(REG_SRAMLOCK)
	move.b  #2,(BIOS_USER_REQUEST)	        |Game/demo request
	jmp     jumpto_user


jumpto_user:
        move.w  #0x2700,sr
	clr.l   0x10FDB6                        |Player modes
	move.b  #1,BIOS_USER_MODE
        move.b  #0x80,(BIOS_SYSTEM_MODE)        |Game mode (HW testing)
	move.b  #3,(REG_SOUND)                  |Reset Z80
        jsr     palette_clear
	move.w  #0x4000,REG_LSPCMODE
        move.b  d0,(REG_SWPROM)
	move.b  d0,(REG_CRTFIX)
	move.b  d0,(REG_SRAMLOCK)
	lea     0x10F300,a7
	jmp	(USER)
