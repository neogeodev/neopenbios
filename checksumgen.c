// Checksum generator for the Neopen bios
// Last mod: furrtek 22/10/2011
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[])
{
  char ch;
  FILE *romfile;
  int short checksum=0;   //16bits
  int size;
  
  if (argc != 2) {
         puts("Usage: checksumgen flippedrom.bin\n");
    } else {
         romfile = fopen(argv[1],"r+b");
         if (!romfile) {
            write("Can't open %s\n",argv[1]);
            return 1;
         }
         
         fseek(romfile,0,SEEK_SET);
  
         for (size=0;size<0x80;size++) {
             checksum += fgetc(romfile);
         }
         
         fseek(romfile,0x82,SEEK_SET);
         
         for (size=0;size<0x20000-0x82;size++) {
             checksum += fgetc(romfile);
         }
         
         printf("Checksum: %X\n",checksum & 0xFFFF);

         fseek(romfile,0x80,SEEK_SET);

         fwrite(&checksum,sizeof(int short),1,romfile);
         
         fclose(romfile);
  }
  return 0;
}
