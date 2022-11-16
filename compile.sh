#!/usr/bin/bash

rm helloworld.o helloworld.nes && \
ca65 helloworld.asm && \
ld65 helloworld.o -t nes -o helloworld.nes