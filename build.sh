#!/bin/sh

set -xe

nasm -felf64 main.asm -o main.o -g
gcc main.o -o main -no-pie -lSDL2 -g 
rm main.o
