#
# Copyright (c) 2011 Emmanuel Vadot <elbarto@neogeodev.org>
# Copyright (c) 2011 Furrtek <furrtek@neogeodev.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# $Id: Makefile,v 1.23 2011/11/12 10:02:40 elbarto Exp $

AS=	m68k-elf-as
GCC=	m68k-elf-gcc
LD=	m68k-elf-ld
OBJC=	m68k-elf-objcopy
DD=	dd
CHKSUM= ./checksumgen
RM=	rm -f

HOST_CC=	gcc

NAME=	neopenbios

SRCS=	header.s \
	bootmenu.s \
	calendar.s \
	card.s \
	checksum.s \
	colorpicker.s \
	configmenu.s \
	credit.s \
	displogo.s \
	exceptions.s \
	gamelist.s \
	graphics.s \
	howtoplay.s \
	hwtest.s \
	ingamemenu.s \
	io.s \
	softdips.s \
	sram.s \
	system.s

OBJS=	$(SRCS:.s=.o)

CHKSUM_SRC=	checksumgen.c
CHKSUM_OBJ=	$(CHKSUM_SRC:.c=.o)

AFLAGS=		-mcpu=68000 --register-prefix-optional
LDFLAGS=	-Tbios.ld -Map $(NAME).map

$(NAME).bin:	$(CHKSUM) $(OBJS)
		$(LD) $(LDFLAGS) $(OBJS) -o $(NAME).elf
		$(OBJC) -Obinary --pad-to=0xC20000 $(NAME).elf $(NAME).swap
		$(DD) if=$(NAME).swap of=$(NAME).bin conv=swab
		$(CHKSUM) $(NAME).bin

$(CHKSUM):	$(CHKSUM_OBJ)
		$(HOST_CC) $(CHKSUM_OBJ) -o $(CHKSUM)

clean:
	$(RM) $(OBJS) $(NAME).bin $(NAME).elf $(NAME).map $(NAME).swap *~ *#
	$(RM) $(CHKSUM_OBJ) $(CHKSUM)

.s.o:
	$(AS) $(AFLAGS) -o $@ $<

.c.o:
	$(HOST_CC) -c -o $@ $<

.PHONY:	clean

$(SRCS):	defines.inc

gamelist.o:	games/2020bb.s games/3countb.s games/alpham2.s games/androdun.s games/aodk.s games/aof.s games/aof2.s games/aof3.s games/bakatono.s games/bangbead.s games/bjourney.s games/blazstar.s games/breakers.s games/breakrev.s games/bstars.s games/bstars2.s games/burningf.s games/crsword.s games/ctomaday.s games/cyberlip.s games/diggerma.s games/doubledr.s games/eightman.s games/fatfursp.s games/fatfury1.s games/fatfury2.s games/fatfury3.s games/fbfrenzy.s games/fightfev.s games/flipshot.s games/fswords.s games/galaxyfg.s games/ganryu.s games/garou.s games/ghostlop.s games/goalx3.s games/gowcaizr.s games/gpilots.s games/gururin.s games/irrmaze.s games/janshin.s games/jockeygp.s games/joyjoy.s games/kabukikl.s games/karnovr.s games/kizuna.s games/kof2000.s games/kof2001.s games/kof2002.s games/kof2003.s games/kof94.s games/kof95.s games/kof96.s games/kof97.s games/kof98.s games/kof99.s games/kog.s games/kotm.s games/kotm2.s games/lans2004.s games/lastblad.s games/lastbld2.s games/lastsold.s games/lbowling.s games/legendos.s games/lresort.s games/magdrop2.s games/magdrop3.s games/maglord.s games/mahretsu.s games/marukodq.s games/matrim.s games/miexchng.s games/minasan.s games/mosyougi.s games/mslug.s games/mslug2.s games/mslug3.s games/mslug4.s games/mslug5.s games/mslugx.s games/mutnat.s games/nam1975.s games/ncombat.s games/ncommand.s games/neobombe.s games/neocup98.s games/neodrift.s games/neomrdo.s games/ninjamas.s games/nitd.s games/overtop.s games/panicbom.s games/pbobbl2n.s games/pbobblen.s games/pgoal.s games/pnyaa.s games/popbounc.s games/preisle2.s games/pspikes2.s games/pulstar.s games/puzzldpr.s games/puzzledp.s games/quizdai2.s games/quizdais.s games/quizkof.s games/ragnagrd.s games/rbff1.s games/rbff2.s games/rbffspec.s games/ridhero.s games/roboarmy.s games/rotd.s games/s1945p.s games/samsho.s games/samsho2.s games/samsho3.s games/samsho4.s games/samsho5.s games/savagere.s games/sdodgeb.s games/sengoku.s games/sengoku2.s games/sengoku3.s games/shocktr2.s games/shocktro.s games/socbrawl.s games/sonicwi2.s games/sonicwi3.s games/spinmast.s games/ssideki.s games/ssideki2.s games/ssideki3.s games/ssideki4.s games/stakwin.s games/stakwin2.s games/strhoop.s games/superspy.s games/svc.s games/svcplus.s games/tophuntr.s games/tpgolf.s games/trally.s games/turfmast.s games/twinspri.s games/tws96.s games/viewpoin.s games/vliner.s games/vlinero.s games/wakuwak7.s games/wh1.s games/wh2.s games/whp.s games/wjammers.s games/zedblade.s games/zintrckb.s games/zupapa.s
