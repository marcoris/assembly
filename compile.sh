#!/usr/bin/bash

rm src/*.{o, nes} && \
ca65 src/helloworld.asm && \
ca65 src/reset.asm && \
ld65 src/reset.o src/helloworld.o -C nes.cfg -o helloworld.nes