#!/usr/bin/bash

rm -rf src/*.o *.nes && \
ca65 src/backgrounds.asm && \
ca65 src/main.asm && \
ca65 src/reset.asm && \
ld65 src/backgrounds.o src/reset.o src/main.o -C nes.cfg -o main.nes