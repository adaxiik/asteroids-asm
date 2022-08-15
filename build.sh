#!/bin/sh

set -xe

nasm -g -f elf64 -Fdwarf src/main.asm -o main.o -I src
cc main.o -o main -g -no-pie -lSDL2 -lSDL2_image 
rm main.o
