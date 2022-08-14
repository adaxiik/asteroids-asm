#!/bin/sh

set -xe

nasm -felf64 src/main.asm -o main.o -g -I src
gcc main.o -o main -no-pie -lSDL2 -lSDL2_image -g
rm main.o
