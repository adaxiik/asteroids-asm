#!/bin/sh

set -xe

nasm -g -f elf64 -F dwarf src/main.asm -o main.o -I src
cc main.o -o main -g -no-pie -lSDL2 -lSDL2_image -lm 
rm main.o
