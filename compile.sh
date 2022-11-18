#!/usr/bin/bash

rm src/*.o spritegraphics.nes && \
ca65 src/sprites.asm && \
ca65 src/reset.asm && \
ld65 src/reset.o src/sprites.o -C nes.cfg -o spritegraphics.nes